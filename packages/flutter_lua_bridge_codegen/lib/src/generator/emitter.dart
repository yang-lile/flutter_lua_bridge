import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dart_style/dart_style.dart';
import 'model.dart';

String _dartString(String value) => jsonEncode(value).replaceAll(r'$', r'\$');
String _luaString(String value) => jsonEncode(value);
String _codec(BridgeType type) {
  if (type.nullable) {
    return '_bridge.bridgeNullable(${_codec(type.nonNullable)})';
  }
  return switch (type.name) {
    'int' => '_bridge.bridgeInt',
    'double' => '_bridge.bridgeDouble',
    'bool' => '_bridge.bridgeBool',
    'String' => '_bridge.bridgeString',
    'List' => '_bridge.bridgeList(${_codec(type.arguments.single)})',
    'Map' => '_bridge.bridgeMap(${_codec(type.arguments.last)})',
    _ => '_codec${type.name}',
  };
}

String _teal(BridgeType type) {
  // Teal currently permits nil for every type. Dart nullability is still checked
  // by the generated runtime codecs, including required DTO fields.
  return switch (type.name) {
    'int' => 'integer',
    'double' => 'number',
    'bool' => 'boolean',
    'String' => 'string',
    'void' => '()',
    'List' => '{${_teal(type.arguments.single)}}',
    'Map' => '{string: ${_teal(type.arguments.last)}}',
    _ => type.name,
  };
}

String _params(BridgeMethod method) {
  final positional = method.parameters
      .where((p) => !p.named)
      .map((p) => '${p.type.dart} ${p.name}')
      .join(', ');
  final named = method.parameters
      .where((p) => p.named)
      .map((p) => 'required ${p.type.dart} ${p.name}')
      .join(', ');
  return [
    if (positional.isNotEmpty) positional,
    if (named.isNotEmpty) '{$named}',
  ].join(', ');
}

String _bridgeModule(BridgeSchema schema) {
  final configured = schema.outputs['luaOut'];
  if (configured == null || configured.isEmpty) return 'bridge';
  final file = configured.split(RegExp(r'[/\\]')).last;
  return file.endsWith('.lua') ? file.substring(0, file.length - 4) : file;
}

String _validatorKey(BridgeType type) => switch (type.name) {
  'List' => 'list_${_validatorKey(type.arguments.single)}',
  'Map' => 'map_${_validatorKey(type.arguments.last)}',
  _ => '${type.name}${type.nullable ? '_nullable' : ''}',
}.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

String _validatorName(BridgeType type) => '_check_${_validatorKey(type)}';

String _luaPath(String path) => jsonEncode(path);

void _emitValidator(
  StringBuffer out,
  BridgeType type,
  Map<String, BridgeData> data,
  Map<String, BridgeEnum> enums,
  Set<String> emitted,
) {
  final key = _validatorKey(type);
  if (!emitted.add(key)) return;
  final nonNullable = type.nonNullable;
  if (type.nullable) {
    _emitValidator(out, nonNullable, data, enums, emitted);
    out.writeln('local function ${_validatorName(type)}(value, path)');
    out.writeln('  if value == nil then return true end');
    out.writeln('  return ${_validatorName(nonNullable)}(value, path)');
    out.writeln('end');
    return;
  }
  if (type.name == 'int') {
    out.writeln('local function ${_validatorName(type)}(value, path)');
    out.writeln(
      '  if type(value) ~= "number" or (math.type and math.type(value) ~= "integer") or (not math.type and value % 1 ~= 0) then return false, path .. ": expected integer" end',
    );
    out.writeln('  return true');
    out.writeln('end');
    return;
  }
  if (type.name == 'double') {
    out.writeln('local function ${_validatorName(type)}(value, path)');
    out.writeln(
      '  if type(value) ~= "number" then return false, path .. ": expected number" end',
    );
    out.writeln('  return true');
    out.writeln('end');
    return;
  }
  if (type.name == 'bool' || type.name == 'String') {
    final luaType = type.name == 'bool' ? 'boolean' : 'string';
    out.writeln('local function ${_validatorName(type)}(value, path)');
    out.writeln(
      '  if type(value) ~= "$luaType" then return false, path .. ": expected $luaType" end',
    );
    out.writeln('  return true');
    out.writeln('end');
    return;
  }
  if (type.name == 'List') {
    final element = type.arguments.single;
    _emitValidator(out, element, data, enums, emitted);
    out.writeln('local function ${_validatorName(type)}(value, path)');
    out.writeln(
      '  if type(value) ~= "table" then return false, path .. ": expected array" end',
    );
    out.writeln('  local count = 0');
    out.writeln('  for key, _ in pairs(value) do');
    out.writeln(
      '    if type(key) ~= "number" or key % 1 ~= 0 or key < 1 then return false, path .. ": expected dense array" end',
    );
    out.writeln('    count = count + 1');
    out.writeln('  end');
    out.writeln('  for index = 1, count do');
    out.writeln(
      '    if rawget(value, index) == nil then return false, path .. ": expected dense array" end',
    );
    out.writeln(
      '    local valid, message = ${_validatorName(element)}(rawget(value, index), path .. "[" .. (index - 1) .. "]")',
    );
    out.writeln('    if not valid then return false, message end');
    out.writeln('  end');
    out.writeln('  return true');
    out.writeln('end');
    return;
  }
  if (type.name == 'Map') {
    final valueType = type.arguments.last;
    _emitValidator(out, valueType, data, enums, emitted);
    out.writeln('local function ${_validatorName(type)}(value, path)');
    out.writeln(
      '  if type(value) ~= "table" then return false, path .. ": expected map" end',
    );
    out.writeln('  for key, item in pairs(value) do');
    out.writeln(
      '    if type(key) ~= "string" then return false, path .. ": expected string map key" end',
    );
    out.writeln(
      '    local valid, message = ${_validatorName(valueType)}(item, path .. "." .. key)',
    );
    out.writeln('    if not valid then return false, message end');
    out.writeln('  end');
    out.writeln('  return true');
    out.writeln('end');
    return;
  }
  final enumeration = enums[type.name];
  if (enumeration != null) {
    out.writeln('local function ${_validatorName(type)}(value, path)');
    final values = enumeration.values.values
        .map((value) => 'value ~= ${_luaString(value)}')
        .join(' and ');
    out.writeln(
      '  if $values then return false, path .. ": expected ${type.name}" end',
    );
    out.writeln('  return true');
    out.writeln('end');
    return;
  }
  final dto = data[type.name];
  if (dto == null) return;
  for (final field in dto.fields) {
    _emitValidator(out, field.type, data, enums, emitted);
  }
  out.writeln('local function ${_validatorName(type)}(value, path)');
  out.writeln(
    '  if type(value) ~= "table" then return false, path .. ": expected ${type.name} table" end',
  );
  for (final field in dto.fields) {
    final keyLiteral = _luaString(field.luaName);
    final fieldPath = 'path .. "." .. $keyLiteral';
    if (field.type.nullable) {
      out.writeln(
        '  local valid_${field.name}, message_${field.name} = ${_validatorName(field.type)}(rawget(value, $keyLiteral), $fieldPath)',
      );
    } else {
      out.writeln(
        '  if rawget(value, $keyLiteral) == nil then return false, $fieldPath .. ": required field" end',
      );
      out.writeln(
        '  local valid_${field.name}, message_${field.name} = ${_validatorName(field.type)}(rawget(value, $keyLiteral), $fieldPath)',
      );
    }
    out.writeln(
      '  if not valid_${field.name} then return false, message_${field.name} end',
    );
  }
  out.writeln('  return true');
  out.writeln('end');
}

void _collectTypes(BridgeSchema schema, void Function(BridgeType) visit) {
  for (final api in schema.apis) {
    for (final method in api.methods) {
      visit(method.result);
      for (final parameter in method.parameters) {
        visit(parameter.type);
      }
    }
  }
}

String _safeLuaName(String value) =>
    value.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

void _emitSafeWrapper(
  StringBuffer out,
  BridgeApi api,
  BridgeMethod method,
  BridgeOptimization optimization,
) {
  final wrapper =
      '_wrap_${_safeLuaName(api.name)}_${_safeLuaName(method.luaName)}';
  final arguments = [
    for (var index = 0; index < method.parameters.length; index++) 'arg$index',
  ];
  out.writeln('local function $wrapper(fn)');
  out.writeln('  return function(...)');
  if (arguments.isNotEmpty) {
    out.writeln('    local ${arguments.join(', ')} = ...');
  }
  if (optimization.checksTypes) {
    for (var index = 0; index < method.parameters.length; index++) {
      final parameter = method.parameters[index];
      final path = _luaPath('${api.name}.${method.name}.${parameter.name}');
      out.writeln(
        '    local valid_$index, message_$index = ${_validatorName(parameter.type)}(${arguments[index]}, $path)',
      );
      out.writeln(
        '    if not valid_$index then return _flb_error("type", message_$index) end',
      );
    }
  }
  final callArguments = arguments.join(', ');
  out.writeln(
    '    local call_ok, result = pcall(fn${callArguments.isEmpty ? '' : ', $callArguments'})',
  );
  out.writeln(
    '    if not call_ok then return _flb_error("runtime", tostring(result)) end',
  );
  if (optimization.checksTypes && method.result.name != 'void') {
    final path = _luaPath('${api.name}.${method.name}.result');
    out.writeln(
      '    local valid_result, result_message = ${_validatorName(method.result)}(result, $path)',
    );
    out.writeln(
      '    if not valid_result then return _flb_error("type", result_message) end',
    );
  }
  out.writeln('    return _flb_ok(result)');
  out.writeln('  end');
  out.writeln('end');
}

String contractFingerprint(BridgeSchema schema) => sha256
    .convert(
      utf8.encode(
        jsonEncode({
          'protocol': 1,
          'lua': 504,
          'optimization': schema.optimization.label,
          'apis': [
            for (final a in schema.apis)
              [
                a.name,
                a.module,
                a.isLua,
                [
                  for (final m in a.methods)
                    [
                      m.name,
                      m.luaName,
                      m.result.dart,
                      [
                        for (final p in m.parameters)
                          [p.name, p.type.dart, p.named],
                      ],
                    ],
                ],
              ],
          ],
          'data': [
            for (final d in schema.data)
              [
                d.name,
                [
                  for (final f in d.fields) [f.name, f.luaName, f.type.dart],
                ],
              ],
          ],
          'enums': [
            for (final e in schema.enums) [e.name, e.values],
          ],
        }),
      ),
    )
    .toString();

String emitDart(BridgeSchema schema) {
  final hash = contractFingerprint(schema);
  final bridgeModule = _bridgeModule(schema);
  final out = StringBuffer('''// Generated by flutter_lua_bridge. Do not edit.
// ignore_for_file: no_leading_underscores_for_library_prefixes
// Lua 5.4; optimization ${schema.optimization.label}; contract $hash
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart' as _lua;
import 'package:flutter_lua_bridge/generated.dart' as _bridge;
''');
  out.writeln('const bridgeLuaSource = ${_dartString(emitLua(schema))};');
  for (final enumeration in schema.enums) {
    out.writeln(
      'enum ${enumeration.name} { ${enumeration.values.keys.join(', ')} }',
    );
    out.writeln(
      'final _codec${enumeration.name} = _bridge.BridgeCodec<${enumeration.name}>(',
    );
    out.writeln('(value, path) => switch (value) {');
    for (final e in enumeration.values.entries) {
      out.writeln('${enumeration.name}.${e.key} => ${_dartString(e.value)},');
    }
    out.writeln('}, (value, path) => switch (value) {');
    for (final e in enumeration.values.entries) {
      out.writeln('${_dartString(e.value)} => ${enumeration.name}.${e.key},');
    }
    out.writeln(
      '_ => throw _bridge.LuaTypeException(path, ${_dartString(enumeration.name)}, value), });',
    );
  }
  for (final data in schema.data) {
    out.writeln('class ${data.name} {');
    out.writeln(
      'const ${data.name}(${data.fields.isEmpty ? '' : '{${data.fields.map((f) => 'required this.${f.name}').join(', ')}}'});',
    );
    for (final f in data.fields) {
      out.writeln('final ${f.type.dart} ${f.name};');
    }
    out.writeln('}');
    out.writeln(
      'final _codec${data.name} = _bridge.BridgeCodec<${data.name}>((value, path) => _bridge.BridgeTable({',
    );
    for (final f in data.fields) {
      out.writeln(
        '${_dartString(f.luaName)}: ${_codec(f.type)}.encode(value.${f.name}, "\$path.${f.luaName}"),',
      );
    }
    out.writeln(
      '}), (value, path) { final fields = _bridge.bridgeFields(value, path); return ${data.name}(',
    );
    for (final f in data.fields) {
      out.writeln(
        '${f.name}: ${_codec(f.type)}.decode(fields[${_dartString(f.luaName)}], "\$path.${f.luaName}"),',
      );
    }
    out.writeln('); });');
  }
  for (final api in schema.apis) {
    out.writeln('abstract class ${api.name} {');
    if (api.isLua) {
      out.writeln(
        'static ${api.name} load({required _lua.LuaRuntime runtime, required String source}) {',
      );
      out.writeln(
        'runtime.ensureModule(${_dartString(bridgeModule)}, source: bridgeLuaSource);',
      );
      out.writeln(
        'runtime.loadModule(${_dartString(api.module)}, source: source);',
      );
      out.writeln('return ${api.name}(runtime: runtime); }');
      out.writeln(
        'factory ${api.name}({required _lua.LuaRuntime runtime}) = _${api.name};',
      );
    } else {
      out.writeln(
        'static void setUp(${api.name}? api, {required _lua.LuaRuntime runtime}) {',
      );
      out.writeln(
        'runtime.ensureModule(${_dartString(bridgeModule)}, source: bridgeLuaSource);',
      );
      out.writeln(
        'runtime.registerDart(module: ${_dartString(api.module)}, contract: "$hash", methods: api == null ? null : {',
      );
      for (final method in api.methods) {
        final path = '${api.name}.${method.name}';
        out.writeln(
          '${_dartString(method.luaName)}: _bridge.BridgeHostMethod((arguments) {',
        );
        out.writeln(
          '_bridge.bridgeArgumentCount(arguments, ${method.parameters.length}, ${_dartString(path)});',
        );
        final args = <String>[];
        for (var i = 0; i < method.parameters.length; i++) {
          final p = method.parameters[i];
          args.add(
            '${p.named ? '${p.name}: ' : ''}${_codec(p.type)}.decode(arguments[$i], ${_dartString('$path.${p.name}')})',
          );
        }
        final call = 'api.${method.name}(${args.join(', ')})';
        if (method.result.name == 'void') {
          out.writeln('$call; return null;');
        } else {
          out.writeln(
            'return ${_codec(method.result)}.encode($call, ${_dartString('$path.result')});',
          );
        }
        out.writeln('}, isVoid: ${method.result.name == 'void'}),');
      }
      out.writeln('}); }');
    }
    for (final method in api.methods) {
      final result = api.isLua && schema.optimization.catchesErrors
          ? '_lua.LuaCallResult<${method.result.dart}>'
          : method.result.dart;
      out.writeln('$result ${method.name}(${_params(method)});');
    }
    out.writeln('}');
    if (api.isLua) {
      out.writeln('class _${api.name} implements ${api.name} {');
      out.writeln(
        '_${api.name}({required _lua.LuaRuntime runtime}): _binding = runtime.bindLua(module: ${_dartString(api.module)}, contract: "$hash", methods: [${api.methods.map((m) => _dartString(m.luaName)).join(', ')}]);',
      );
      out.writeln('final _bridge.LuaBinding _binding;');
      for (final method in api.methods) {
        final path = '${api.name}.${method.name}';
        final args = method.parameters
            .map(
              (p) =>
                  '${_codec(p.type)}.encode(${p.name}, ${_dartString('$path.${p.name}')})',
            )
            .join(', ');
        final catchesErrors = schema.optimization.catchesErrors;
        final resultType = catchesErrors
            ? '_lua.LuaCallResult<${method.result.dart}>'
            : method.result.dart;
        final call =
            '_binding.call(${_dartString(method.luaName)}, [$args], isVoid: ${catchesErrors ? false : method.result.name == 'void'})';
        out.writeln(
          '@override $resultType ${method.name}(${_params(method)}) {',
        );
        if (catchesErrors) {
          final decoder = method.result.name == 'void'
              ? 'null'
              : '(value, path) => ${_codec(method.result)}.decode(value, path)';
          out.writeln(
            'return _bridge.decodeLuaResult<${method.result.dart}>($call, ${_dartString('$path.result')}, $decoder);',
          );
        } else if (method.result.name == 'void') {
          out.writeln('$call;');
        } else {
          out.writeln(
            'return ${_codec(method.result)}.decode($call, ${_dartString('$path.result')});',
          );
        }
        out.writeln('}');
      }
      out.writeln('}');
    }
  }
  return DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format(out.toString());
}

String emitLua(BridgeSchema schema) {
  final hash = contractFingerprint(schema);
  final out = StringBuffer(
    '-- Generated by flutter_lua_bridge. Do not edit.\n'
    '-- Safety level ${schema.optimization.label}: '
    '${schema.optimization == BridgeOptimization.o1
        ? 'runtime type checks + pcall'
        : schema.optimization == BridgeOptimization.o2
        ? 'pcall error fallback'
        : 'raw calls'}\n'
    '-- This file is protocol glue. Put business logic in the module "${schema.apis.where((a) => a.isLua).map((a) => a.module).join(', ')}".\n'
    'local bridge = {}\n',
  );
  if (schema.optimization.catchesErrors) {
    out.writeln(
      'local function _flb_ok(value) return { status = "ok", value = value } end',
    );
    out.writeln(
      'local function _flb_error(kind, message) return { status = "error", kind = kind, message = tostring(message) } end',
    );
    if (schema.optimization.checksTypes) {
      final data = {for (final item in schema.data) item.name: item};
      final enums = {for (final item in schema.enums) item.name: item};
      final emitted = <String>{};
      _collectTypes(schema, (type) {
        _emitValidator(out, type, data, enums, emitted);
      });
    }
    for (final api in schema.apis.where((api) => api.isLua)) {
      for (final method in api.methods) {
        _emitSafeWrapper(out, api, method, schema.optimization);
      }
    }
  }
  for (final api in schema.apis) {
    out.writeln(
      'function bridge.${api.isLua ? 'bind' : 'get'}${api.name}(${api.isLua ? 'implementation' : ''})',
    );
    if (!api.isLua) {
      out.writeln(
        '  local implementation = require(${_luaString(api.module)})',
      );
    }
    out.writeln(
      '  assert(type(implementation) == "table", "${api.name} must be a table")',
    );
    for (final method in api.methods) {
      out.writeln(
        '  assert(type(rawget(implementation, ${_luaString(method.luaName)})) == "function", "${api.name}.${method.luaName} is missing")',
      );
    }
    if (api.isLua) {
      if (schema.optimization.catchesErrors) {
        out.writeln(
          '  if rawget(implementation, "__flb_wrapped") ~= true then',
        );
        for (final method in api.methods) {
          final wrapper =
              '_wrap_${_safeLuaName(api.name)}_${_safeLuaName(method.luaName)}';
          out.writeln(
            '    rawset(implementation, ${_luaString(method.luaName)}, $wrapper(rawget(implementation, ${_luaString(method.luaName)})))',
          );
        }
        out.writeln('    rawset(implementation, "__flb_wrapped", true)');
        out.writeln('  end');
      }
      out.writeln('  rawset(implementation, "__flb_contract", "$hash")');
    } else {
      out.writeln(
        '  assert(rawget(implementation, "__flb_contract") == "$hash", "bridge contract mismatch")',
      );
    }
    out.writeln('  return implementation\nend');
  }
  out.writeln('return bridge');
  return out.toString();
}

String emitTeal(BridgeSchema schema) {
  final out = StringBuffer(
    '-- Generated by flutter_lua_bridge. Lua 5.4. Do not edit.\n'
    '-- Import these declarations from your editable .tl implementation.\n'
    'local record BridgeContract\n',
  );
  for (final enumeration in schema.enums) {
    out.writeln('  enum ${enumeration.name}');
    for (final value in enumeration.values.values) {
      out.writeln('    ${_luaString(value)}');
    }
    out.writeln('  end');
  }
  for (final data in schema.data) {
    out.writeln('  record ${data.name}');
    for (final field in data.fields) {
      out.writeln('    ${field.luaName}: ${_teal(field.type)}');
    }
    out.writeln('  end');
  }
  for (final api in schema.apis) {
    out.writeln('  record ${api.name}');
    for (final method in api.methods) {
      out.writeln(
        '    ${method.luaName}: function(${method.parameters.map((p) => _teal(p.type)).join(', ')}): ${_teal(method.result)}',
      );
    }
    out.writeln('  end');
    out.writeln(
      '  ${api.isLua ? 'bind' : 'get'}${api.name}: function(${api.isLua ? api.name : ''}): ${api.name}',
    );
  }
  out.writeln('end\nreturn BridgeContract');
  return out.toString();
}
