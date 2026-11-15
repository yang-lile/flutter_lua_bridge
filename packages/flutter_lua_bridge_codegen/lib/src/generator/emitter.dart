import 'dart:convert';

import 'model.dart';

String _dartString(String value) => jsonEncode(value).replaceAll(r'$', r'\$');
String _luaString(String value) => jsonEncode(value);
String _codec(BridgeType type) {
  if (type.nullable) {
    return 'bridgeNullable(${_codec(type.nonNullable)})';
  }
  return switch (type.name) {
    'int' => 'bridgeInt',
    'double' => 'bridgeDouble',
    'bool' => 'bridgeBool',
    'String' => 'bridgeString',
    'List' => 'bridgeList(${_codec(type.arguments.single)})',
    'Map' => 'bridgeMap(${_codec(type.arguments.last)})',
    _ => '_\$${type.name}Codec',
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
    out.writeln('local function ${_validatorName(type)}(value, path, depth)');
    out.writeln('  if value == nil then return true end');
    out.writeln('  return ${_validatorName(nonNullable)}(value, path, depth)');
    out.writeln('end');
    return;
  }
  if (type.name == 'int') {
    out.writeln('local function ${_validatorName(type)}(value, path, depth)');
    out.writeln(
      '  if math.type(value) ~= "integer" then return false, path .. ": expected integer" end',
    );
    out.writeln('  return true');
    out.writeln('end');
    return;
  }
  if (type.name == 'double') {
    out.writeln('local function ${_validatorName(type)}(value, path, depth)');
    out.writeln(
      '  if type(value) ~= "number" then return false, path .. ": expected number" end',
    );
    out.writeln('  return true');
    out.writeln('end');
    return;
  }
  if (type.name == 'bool' || type.name == 'String') {
    final luaType = type.name == 'bool' ? 'boolean' : 'string';
    out.writeln('local function ${_validatorName(type)}(value, path, depth)');
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
    out.writeln('local function ${_validatorName(type)}(value, path, depth)');
    out.writeln(
      '  if type(value) ~= "table" then return false, path .. ": expected array" end',
    );
    out.writeln(
      '  if depth > 64 then return false, path .. ": maximum nesting depth exceeded" end',
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
      '    local valid, message = ${_validatorName(element)}(rawget(value, index), path .. "[" .. (index - 1) .. "]", depth + 1)',
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
    out.writeln('local function ${_validatorName(type)}(value, path, depth)');
    out.writeln(
      '  if type(value) ~= "table" then return false, path .. ": expected map" end',
    );
    out.writeln(
      '  if depth > 64 then return false, path .. ": maximum nesting depth exceeded" end',
    );
    out.writeln('  for key, item in pairs(value) do');
    out.writeln(
      '    if type(key) ~= "string" then return false, path .. ": expected string map key" end',
    );
    out.writeln(
      '    local valid, message = ${_validatorName(valueType)}(item, path .. "." .. key, depth + 1)',
    );
    out.writeln('    if not valid then return false, message end');
    out.writeln('  end');
    out.writeln('  return true');
    out.writeln('end');
    return;
  }
  final enumeration = enums[type.name];
  if (enumeration != null) {
    out.writeln('local function ${_validatorName(type)}(value, path, depth)');
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
  out.writeln('local function ${_validatorName(type)}(value, path, depth)');
  out.writeln(
    '  if type(value) ~= "table" then return false, path .. ": expected ${type.name} table" end',
  );
  out.writeln(
    '  if depth > 64 then return false, path .. ": maximum nesting depth exceeded" end',
  );
  for (final field in dto.fields) {
    final keyLiteral = _luaString(field.luaName);
    final fieldPath = 'path .. "." .. $keyLiteral';
    if (field.type.nullable) {
      out.writeln(
        '  local valid_${field.name}, message_${field.name} = ${_validatorName(field.type)}(rawget(value, $keyLiteral), $fieldPath, depth + 1)',
      );
    } else {
      out.writeln(
        '  if rawget(value, $keyLiteral) == nil then return false, $fieldPath .. ": required field" end',
      );
      out.writeln(
        '  local valid_${field.name}, message_${field.name} = ${_validatorName(field.type)}(rawget(value, $keyLiteral), $fieldPath, depth + 1)',
      );
    }
    out.writeln(
      '  if not valid_${field.name} then return false, message_${field.name} end',
    );
  }
  out.writeln('  return true');
  out.writeln('end');
}

void _collectCheckedTypes(
  BridgeSchema schema,
  void Function(BridgeType) visit,
) {
  for (final api in schema.apis) {
    if (!api.isLua || !api.optimization.checksTypes) continue;
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
    final path = _luaString('${api.name}.${method.name}');
    out.writeln(
      '    if select("#", ...) ~= ${arguments.length} then return _flb_error("type", $path .. ": expected ${arguments.length} arguments") end',
    );
    for (var index = 0; index < method.parameters.length; index++) {
      final parameter = method.parameters[index];
      final parameterPath = _luaPath(
        '${api.name}.${method.name}.${parameter.name}',
      );
      out.writeln(
        '    local valid_$index, message_$index = ${_validatorName(parameter.type)}(${arguments[index]}, $parameterPath, 0)',
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
      '    local valid_result, result_message = ${_validatorName(method.result)}(result, $path, 0)',
    );
    out.writeln(
      '    if not valid_result then return _flb_error("type", result_message) end',
    );
  }
  out.writeln('    return _flb_ok(result)');
  out.writeln('  end');
  out.writeln('end');
}

String _resultType(BridgeApi api, BridgeMethod method) =>
    api.optimization.catchesErrors
    ? 'LuaCallResult<${method.result.dart}>'
    : method.result.dart;

/// The Dart declarations for a contract, to be placed in a `part` of the
/// library that declares it. That library imports
/// `package:flutter_lua_bridge/flutter_lua_bridge.dart`.
String emitDart(BridgeSchema schema) {
  final module = _dartString(schema.bridgeModule);
  final out = StringBuffer()
    ..writeln('const _\$bridgeLua = ${_dartString(emitLua(schema))};');
  for (final enumeration in schema.enums) {
    final name = enumeration.name;
    out.writeln('final _\$${name}Codec = BridgeCodec<$name>(');
    out.writeln('(value, path) => switch (value) {');
    for (final e in enumeration.values.entries) {
      out.writeln('$name.${e.key} => ${_dartString(e.value)},');
    }
    out.writeln('}, (value, path) => switch (value) {');
    for (final e in enumeration.values.entries) {
      out.writeln('${_dartString(e.value)} => $name.${e.key},');
    }
    out.writeln(
      '_ => throw LuaTypeException(path, ${_dartString(name)}, value), });',
    );
  }
  for (final data in schema.data) {
    final name = data.name;
    out.writeln(
      'final _\$${name}Codec = BridgeCodec<$name>((value, path) => BridgeTable({',
    );
    for (final f in data.fields) {
      out.writeln(
        '${_dartString(f.luaName)}: ${_codec(f.type)}.encode(value.${f.name}, "\$path.${f.luaName}"),',
      );
    }
    out.writeln(
      '}), (value, path) { final fields = bridgeFields(value, path); return $name(',
    );
    for (final f in data.fields) {
      out.writeln(
        '${f.named ? '${f.name}: ' : ''}${_codec(f.type)}.decode(fields[${_dartString(f.luaName)}], "\$path.${f.luaName}"),',
      );
    }
    out.writeln('); });');
  }
  for (final api in schema.apis) {
    final name = api.name;
    if (!api.isLua) {
      out.writeln(
        '/// Exposes [api] to Lua as the module `${api.module}`; null removes it.',
      );
      out.writeln(
        'void register$name($name? api, {required LuaRuntime runtime}) {',
      );
      out.writeln('runtime.ensureModule($module, source: _\$bridgeLua);');
      out.writeln(
        'runtime.registerDart(module: ${_dartString(api.module)}, methods: api == null ? null : {',
      );
      for (final method in api.methods) {
        final path = '$name.${method.name}';
        out.writeln(
          '${_dartString(method.luaName)}: BridgeHostMethod((arguments) {',
        );
        out.writeln(
          'bridgeArgumentCount(arguments, ${method.parameters.length}, ${_dartString(path)});',
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
      continue;
    }
    final catchesErrors = api.optimization.catchesErrors;
    final client = '${name}Client';
    out.writeln(
      '/// Calls the Lua module `${api.module}`, which implements [$name] '
      '(safety level ${api.optimization.label}).',
    );
    out.writeln('class $client ${catchesErrors ? '' : 'implements $name '}{');
    out.writeln('/// Binds to the already loaded module `${api.module}`.');
    out.writeln(
      '$client({required LuaRuntime runtime}): _binding = runtime.bindLua(module: ${_dartString(api.module)}, methods: [${api.methods.map((m) => _dartString(m.luaName)).join(', ')}]);',
    );
    out.writeln(
      '/// Loads [source] as the module `${api.module}` and binds to it.',
    );
    out.writeln(
      'factory $client.load({required LuaRuntime runtime, required String source}) {',
    );
    out.writeln('runtime.ensureModule($module, source: _\$bridgeLua);');
    out.writeln(
      'runtime.loadModule(${_dartString(api.module)}, source: source);',
    );
    out.writeln('return $client(runtime: runtime); }');
    out.writeln('final LuaBinding _binding;');
    for (final method in api.methods) {
      final path = '$name.${method.name}';
      final args = method.parameters
          .map(
            (p) =>
                '${_codec(p.type)}.encode(${p.name}, ${_dartString('$path.${p.name}')})',
          )
          .join(', ');
      final isVoid = method.result.name == 'void';
      final call =
          '_binding.call(${_dartString(method.luaName)}, [$args], isVoid: ${catchesErrors ? false : isVoid})';
      out.writeln(
        '${catchesErrors ? '' : '@override '}${_resultType(api, method)} ${method.name}(${_params(method)}) {',
      );
      if (catchesErrors) {
        final decoder = isVoid ? 'null' : '${_codec(method.result)}.decode';
        out.writeln(
          'return decodeLuaResult<${method.result.dart}>($call, ${_dartString('$path.result')}, $decoder);',
        );
      } else if (isVoid) {
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
  return out.toString();
}

String _levelDescription(BridgeOptimization level) => switch (level) {
  BridgeOptimization.o1 => 'runtime type checks + pcall',
  BridgeOptimization.o2 => 'pcall error fallback',
  BridgeOptimization.o3 => 'raw calls',
};

/// The Lua protocol glue for a contract. It is embedded in the generated Dart
/// and loaded as the module [BridgeSchema.bridgeModule].
String emitLua(BridgeSchema schema) {
  final luaApis = schema.apis.where((api) => api.isLua).toList();
  final out = StringBuffer(
    '-- Generated by flutter_lua_bridge. Do not edit.\n',
  );
  for (final api in luaApis) {
    out.writeln(
      '-- ${api.name} (module "${api.module}"): safety level '
      '${api.optimization.label}, ${_levelDescription(api.optimization)}',
    );
  }
  out.writeln(
    '-- This file is protocol glue. Put business logic in the modules above.',
  );
  out.writeln('local bridge = {}');
  if (luaApis.any((api) => api.optimization.catchesErrors)) {
    out.writeln(
      'local function _flb_ok(value) return { status = "ok", value = value } end',
    );
    out.writeln(
      'local function _flb_error(kind, message) return { status = "error", kind = kind, message = tostring(message) } end',
    );
    out.writeln('local _flb_wrapped = setmetatable({}, { __mode = "k" })');
    final data = {for (final item in schema.data) item.name: item};
    final enums = {for (final item in schema.enums) item.name: item};
    final emitted = <String>{};
    _collectCheckedTypes(schema, (type) {
      _emitValidator(out, type, data, enums, emitted);
    });
    for (final api in luaApis.where((api) => api.optimization.catchesErrors)) {
      for (final method in api.methods) {
        _emitSafeWrapper(out, api, method, api.optimization);
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
    if (api.isLua && api.optimization.catchesErrors) {
      out.writeln('  if not _flb_wrapped[implementation] then');
      for (final method in api.methods) {
        final wrapper =
            '_wrap_${_safeLuaName(api.name)}_${_safeLuaName(method.luaName)}';
        out.writeln(
          '    rawset(implementation, ${_luaString(method.luaName)}, $wrapper(rawget(implementation, ${_luaString(method.luaName)})))',
        );
      }
      out.writeln('    _flb_wrapped[implementation] = true');
      out.writeln('  end');
    }
    out.writeln('  return implementation\nend');
  }
  out.writeln('return bridge');
  return out.toString();
}

/// Teal declarations for the module [BridgeSchema.bridgeModule].
String emitTeal(BridgeSchema schema) {
  final out = StringBuffer(
    '-- Generated by flutter_lua_bridge. Do not edit.\n'
    '-- Types for require("${schema.bridgeModule}"); use them from your '
    'editable .tl implementation.\n'
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
