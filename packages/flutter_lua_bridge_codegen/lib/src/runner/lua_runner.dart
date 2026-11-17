// Runs hand-written Lua or Teal entry files, such as `lua/test/*_test.tl`, on
// LuaRuntime, so the Lua side of a project can be exercised without starting
// the app. `bin/run.dart` is the command line front end.
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:path/path.dart' as p;

/// What [LuaRunner] runs when it is given a directory.
bool isLuaEntry(String path) {
  final name = p.basename(path);
  return name == 'main.tl' ||
      name == 'main.lua' ||
      name.endsWith('_test.tl') ||
      name.endsWith('_test.lua');
}

/// Outcome of one entry file.
class LuaRunResult {
  const LuaRunResult({
    required this.path,
    required this.passed,
    required this.elapsed,
    this.error,
  });

  final String path;
  final bool passed;
  final Duration elapsed;

  /// Teal errors, or the Lua error with its traceback.
  final String? error;
}

/// Where `require` looks while running [entry].
class LuaProject {
  const LuaProject({required this.root, required this.searchDirs, this.config});

  /// The directory of [config], or of the entry when there is no config.
  final String root;

  /// Absolute directories, in lookup order.
  final List<String> searchDirs;

  /// The `tlconfig.lua` used, if any.
  final String? config;
}

const _driver = r'''
local tl = require("tl")
local dirs, target = ...

local entries = {}
for _, dir in ipairs(dirs) do
  entries[#entries + 1] = dir .. "/?.lua"
  entries[#entries + 1] = dir .. "/?/init.lua"
end
package.path = table.concat(entries, ";")
tl.path = package.path

local function read(filename)
  local file, message = io.open(filename, "rb")
  if not file then return nil, message end
  local source = file:read("a")
  file:close()
  return source
end

-- Type checks and compiles one Teal file the way the build does.
local function compile(filename, source)
  local env, env_error = tl.new_env({
    defaults = { gen_target = target, gen_compat = "off" },
  })
  if not env then return nil, env_error end
  local result = tl.check_string(source, env, filename)
  local errors, seen = {}, {}
  local function add(list)
    for _, e in ipairs(list or {}) do
      local line = (e.filename or filename) .. ":" .. e.y .. ":" .. e.x .. ": " .. e.msg
      if not seen[line] then
        seen[line] = true
        errors[#errors + 1] = line
      end
    end
  end
  add(result.syntax_errors)
  add(result.type_errors)
  for _, name in ipairs(env.loaded_order) do
    add(env.loaded[name].syntax_errors)
    add(env.loaded[name].type_errors)
  end
  if #errors > 0 then return nil, table.concat(errors, "\n") end
  return tl.generate(result.ast, target)
end

local function load_file(filename)
  local source, message = read(filename)
  if not source then return nil, message end
  if filename:match("%.tl$") then
    local code, errors = compile(filename, source)
    if not code then return nil, errors end
    source = code
  end
  return load(source, "@" .. filename, "t")
end

-- Teal modules are found before Lua modules of the same name.
table.insert(package.searchers, 2, function(name)
  local filename, file, tried = tl.search_module(name, false)
  if not filename then return "\n\t" .. table.concat(tried, "\n\t") end
  file:close()
  local chunk, message = load_file(filename)
  if not chunk then error(message, 0) end
  return chunk, filename
end)

-- The generated `<contract>_bridge` glue only exists inside the app's
-- .g.dart files. Without it, `bindXxx(implementation)` returns the
-- implementation unchanged, and `getXxx()` returns a table the entry fills
-- with stand-ins for the Dart functions.
local function stub(module)
  local hosts = {}
  return setmetatable({}, {
    __index = function(_, key)
      if type(key) ~= "string" then return nil end
      if key:match("^bind.") then
        return function(implementation) return implementation end
      end
      local api = key:match("^get(.+)$")
      if not api then return nil end
      return function()
        local host = hosts[api]
        if not host then
          host = setmetatable({}, {
            __index = function(_, method)
              error(module .. ": " .. api .. "." .. tostring(method)
                .. " is not stubbed; assign it before calling", 2)
            end,
          })
          hosts[api] = host
        end
        return host
      end
    end,
  })
end
package.searchers[#package.searchers + 1] = function(name)
  if not name:match("_bridge$") then
    return "\n\tno stub for '" .. name .. "' (only *_bridge modules are stubbed)"
  end
  return function() return stub(name) end, "stub"
end

function __flb_run(filename, ...)
  local chunk, message = load_file(filename)
  if not chunk then return false, message end
  local args = table.pack(...)
  arg = { [0] = filename, table.unpack(args, 1, args.n) }
  return xpcall(function() return chunk(table.unpack(args, 1, args.n)) end,
    function(e)
      -- Keep the entry's frames, drop the runner's.
      local lines = {}
      for line in debug.traceback(tostring(e), 2):gmatch("[^\n]+") do
        if line:find("tail calls", 1, true) or line:find("'xpcall'", 1, true) then break end
        if not line:find("flb_run:", 1, true) then lines[#lines + 1] = line end
      end
      return table.concat(lines, "\n")
    end)
end
''';

/// Relative to the working directory when that is shorter, for readable
/// chunk names in errors and tracebacks.
String _short(String path) {
  final relative = p.relative(path);
  return relative.length < path.length ? relative : path;
}

/// Runs Lua and Teal entry files, each in a fresh [LuaRuntime].
class LuaRunner {
  LuaRunner({void Function(String line)? output})
    : output = output ?? stdout.writeln;

  /// Receives the lines the entries `print`.
  final void Function(String line) output;

  String? _compiler;

  Future<String> _tealCompiler() async {
    final uri = await Isolate.resolvePackageUri(
      Uri.parse('package:flutter_lua_bridge_codegen/src/teal/tl.lua'),
    );
    return _compiler ??= File.fromUri(uri!).readAsStringSync();
  }

  /// Expands [targets] (files or directories) into entry files. Directories
  /// are searched recursively for `main.tl|lua` and `*_test.tl|lua`.
  static List<String> entries(Iterable<String> targets) {
    final found = <String>[];
    for (final target in targets) {
      final type = FileSystemEntity.typeSync(target);
      if (type == FileSystemEntityType.file) {
        found.add(p.normalize(p.absolute(target)));
      } else if (type == FileSystemEntityType.directory) {
        final files =
            Directory(target)
                .listSync(recursive: true)
                .whereType<File>()
                .map((file) => p.normalize(p.absolute(file.path)))
                .where(isLuaEntry)
                .toList()
              ..sort();
        found.addAll(files);
      } else {
        throw ArgumentError.value(
          target,
          'target',
          'No such file or directory',
        );
      }
    }
    return found;
  }

  /// Finds the nearest `tlconfig.lua` at or above the entry's directory and
  /// resolves its `include_dir` and `source_dir` against it. The entry's own
  /// directory is searched first, so helpers next to it can be required.
  static LuaProject project(String entry) {
    final entryDir = p.dirname(p.normalize(p.absolute(entry)));
    for (var dir = entryDir; ; dir = p.dirname(dir)) {
      final config = File(p.join(dir, 'tlconfig.lua'));
      if (config.existsSync()) {
        final dirs = <String>[entryDir];
        for (final relative in _configDirs(config.path)) {
          final absolute = p.normalize(p.join(dir, relative));
          if (!dirs.contains(absolute)) dirs.add(absolute);
        }
        return LuaProject(root: dir, searchDirs: dirs, config: config.path);
      }
      if (p.dirname(dir) == dir) break;
    }
    return LuaProject(root: entryDir, searchDirs: [entryDir]);
  }

  static List<String> _configDirs(String path) {
    final lua = LuaRuntime.create();
    try {
      final config = lua
          .load(File(path).readAsStringSync(), name: '@$path')
          .call();
      final table = config.isEmpty ? null : config.first;
      if (table is! LuaTable) return const [];
      final dirs = <String>[];
      final include = table['include_dir'];
      if (include is LuaTable) {
        for (var i = 1; include[i] is String; i++) {
          dirs.add(include[i]! as String);
        }
      }
      final source = table['source_dir'];
      if (source is String) dirs.add(source);
      return dirs;
    } on LuaBridgeException catch (error) {
      throw FormatException('Cannot read $path: ${error.message}');
    } finally {
      lua.close();
    }
  }

  /// Runs one entry file and passes [arguments] to it as `...` and `arg`.
  Future<LuaRunResult> run(
    String entry, {
    List<String> arguments = const [],
  }) async {
    final path = p.normalize(p.absolute(entry));
    final watch = Stopwatch()..start();
    final lua = LuaRuntime.create(libraries: LuaLibrary.all);
    try {
      final tl = lua.load(await _tealCompiler(), name: '@tl.lua').call().first;
      lua.setModule('tl', tl);
      lua['print'] = lua.function((values) {
        output(values.map(lua.describe).join('\t'));
        return null;
      });
      // Teal targets "5.3" or "5.4"; later Lua releases run the 5.4 output.
      final target = LuaRuntime.luaVersion >= 504 ? '5.4' : '5.3';
      lua.load(_driver, name: '@flb_run').call([
        lua.table([for (final dir in project(path).searchDirs) _short(dir)]),
        target,
      ]);
      final results = (lua['__flb_run']! as LuaFunction).call([
        _short(path),
        ...arguments,
      ]);
      final passed = results.isNotEmpty && results.first == true;
      return LuaRunResult(
        path: path,
        passed: passed,
        elapsed: watch.elapsed,
        error: passed
            ? null
            : results.length > 1
            ? lua.describe(results[1])
            : 'failed without a message',
      );
    } on LuaBridgeException catch (error) {
      return LuaRunResult(
        path: path,
        passed: false,
        elapsed: watch.elapsed,
        error: error.message,
      );
    } finally {
      lua.close();
    }
  }
}
