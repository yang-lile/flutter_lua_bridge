// The Teal compiler process started by the `teal` builder. It is not meant
// to be run by hand: it reads one JSON request per line on stdin and answers
// with one marked JSON line on stdout.
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge_codegen/src/builders/teal_worker_client.dart';

const _driver = r'''
local tl = require("tl")
local modules = {}

-- Resolve require() from the sources sent with each request instead of the
-- file system, so the compiler sees exactly what the build sees.
tl.search_module = function(name, search_all)
  local entry = modules[name]
  if entry then
    local kinds = search_all and { "d.tl", "tl", "lua" } or { "tl" }
    for _, kind in ipairs(kinds) do
      local item = entry[kind]
      if item then
        local source = item.source
        return item.path, {
          read = function() return source end,
          close = function() end,
        }
      end
    end
  end
  return nil, nil, { "no module '" .. name .. "' in the Teal sources" }
end

function __flb_compile(path, source, available, target)
  modules = available
  local env, env_error = tl.new_env({
    defaults = { gen_target = target, gen_compat = "off" },
  })
  if not env then return nil, env_error end
  local result = tl.check_string(source, env, path)
  local errors, seen = {}, {}
  local function add(list)
    for _, e in ipairs(list or {}) do
      local line = (e.filename or path) .. ":" .. e.y .. ":" .. e.x .. ": " .. e.msg
      if not seen[line] then
        seen[line] = true
        errors[#errors + 1] = line
      end
    end
  end
  add(result.syntax_errors)
  add(result.type_errors)
  for _, name in ipairs(env.loaded_order) do
    local loaded = env.loaded[name]
    add(loaded.syntax_errors)
    add(loaded.type_errors)
  end
  if #errors > 0 then return nil, table.concat(errors, "\n") end
  local code, gen_error = tl.generate(result.ast, target)
  if not code then return nil, tostring(gen_error) end
  return code
end
''';

void _send(Map<String, Object?> message) =>
    stdout.writeln('$tealWorkerMarker${jsonEncode(message)}');

Future<void> main() async {
  final compiler = await Isolate.resolvePackageUri(
    Uri.parse('package:flutter_lua_bridge_codegen/src/teal/tl.lua'),
  );
  final lua = LuaRuntime.create(libraries: LuaLibrary.all);
  try {
    final tl = lua
        .load(File.fromUri(compiler!).readAsStringSync(), name: '@tl.lua')
        .call()
        .first;
    lua.setModule('tl', tl);
    lua.run(_driver, name: '@teal_worker');
    final compile = lua['__flb_compile']! as LuaFunction;
    // Teal targets "5.3" or "5.4"; later Lua releases run the 5.4 output.
    final target = LuaRuntime.luaVersion >= 504 ? '5.4' : '5.3';
    _send({'ready': true, 'lua': LuaRuntime.luaRelease});
    await for (final line
        in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.isEmpty) continue;
      final request = jsonDecode(line) as Map<String, Object?>;
      final response = <String, Object?>{'id': request['id']};
      try {
        final results = compile.call([
          request['path'],
          request['source'],
          request['modules'],
          target,
        ]);
        final code = results.isEmpty ? null : results.first;
        if (code is String) {
          response['lua'] = code.endsWith('\n') ? code : '$code\n';
        } else {
          final errors = results.length > 1 ? results[1] : null;
          response['errors'] = '${errors ?? 'Teal produced no output'}'.split(
            '\n',
          );
        }
      } on LuaBridgeException catch (error) {
        response['errors'] = ['Teal compiler failure: ${error.message}'];
      }
      _send(response);
    }
  } finally {
    lua.close();
  }
}
