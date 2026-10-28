import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'model.dart';

Never _fail(String message) => throw FormatException(message);
const _luaKeywords = {
  'and',
  'break',
  'do',
  'else',
  'elseif',
  'end',
  'false',
  'for',
  'function',
  'goto',
  'if',
  'in',
  'local',
  'nil',
  'not',
  'or',
  'repeat',
  'return',
  'then',
  'true',
  'until',
  'while',
  'record',
  'enum',
  'type',
  'global',
  'interface',
};
void _identifier(String name) {
  if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(name) ||
      _luaKeywords.contains(name) ||
      name == '__flb_contract') {
    _fail('Unsupported name "$name"; use a public Dart/Lua identifier');
  }
}

void _dartIdentifier(String name) {
  if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(name)) {
    _fail('Use a public Dart identifier: $name');
  }
}

void _memberName(String name) {
  _dartIdentifier(name);
  if (const {
    'toString',
    'hashCode',
    'runtimeType',
    'noSuchMethod',
  }.contains(name)) {
    _fail('Object member names are reserved: $name');
  }
}

Annotation? _annotation(AnnotatedNode node, String name) {
  final matches = node.metadata.where((a) => a.name.name == name).toList();
  if (matches.length > 1) _fail('Duplicate @$name');
  return matches.isEmpty ? null : matches.single;
}

String _literal(Expression expression) {
  if (expression is SimpleStringLiteral) return expression.value;
  return _fail('Annotation options must be literal strings');
}

String _named(Annotation annotation, String name) {
  final allowed = annotation.name.name == 'ConfigureLuaBridge'
      ? const {'dartOut', 'luaOut', 'tealOut', 'optimization'}
      : const {'module'};
  for (final argument in annotation.arguments?.arguments ?? <Expression>[]) {
    if (argument is! NamedExpression ||
        !allowed.contains(argument.name.label.name)) {
      _fail('Unknown option for @${annotation.name.name}: $argument');
    }
  }
  final args =
      annotation.arguments?.arguments
          .whereType<NamedExpression>()
          .where((a) => a.name.label.name == name)
          .toList() ??
      [];
  if (args.length != 1) _fail('@${annotation.name.name} requires $name');
  return _literal(args.single.expression);
}

String? _optionalNamed(Annotation annotation, String name) {
  final args =
      annotation.arguments?.arguments
          .whereType<NamedExpression>()
          .where((a) => a.name.label.name == name)
          .toList() ??
      [];
  if (args.length > 1) _fail('Duplicate ${annotation.name.name} option $name');
  return args.isEmpty ? null : _literal(args.single.expression);
}

String _luaName(AnnotatedNode node, String fallback) {
  final annotation = _annotation(node, 'LuaName');
  if (annotation != null &&
      (annotation.arguments?.arguments.length != 1 ||
          annotation.arguments!.arguments.single is NamedExpression)) {
    _fail('@LuaName requires one literal string');
  }
  final name = annotation == null
      ? fallback
      : _literal(annotation.arguments!.arguments.single);
  _identifier(name);
  return name;
}

BridgeType _type(TypeAnnotation? annotation) {
  if (annotation is! NamedType || annotation.importPrefix != null) {
    return _fail(
      'Use an explicit supported type; function types and imported types are unsupported',
    );
  }
  return BridgeType(
    annotation.name.lexeme,
    arguments: annotation.typeArguments?.arguments.map(_type).toList() ?? [],
    nullable: annotation.question != null,
  );
}

void _unique(Iterable<String> names, String description) {
  final set = <String>{};
  for (final name in names) {
    if (!set.add(name)) _fail('Duplicate $description "$name"');
  }
}

BridgeSchema parseBridgeSchema(String source) {
  final parsed = parseString(content: source, throwIfDiagnostics: false);
  if (parsed.errors.isNotEmpty) {
    _fail('Invalid contract Dart: ${parsed.errors.first}');
  }
  final classes = <String, ClassDeclaration>{};
  final enums = <String, EnumDeclaration>{};
  final apis = <BridgeApi>[];
  final outputs = <String, String>{};
  var optimization = BridgeOptimization.o1;
  for (final declaration in parsed.unit.declarations) {
    if (declaration is! ClassDeclaration && declaration is! EnumDeclaration) {
      _fail('Contract files contain only API classes, DTO classes and enums');
    }
    final name = (declaration as NamedCompilationUnitMember).name.lexeme;
    _identifier(name);
    if (const {
      'int',
      'double',
      'bool',
      'String',
      'List',
      'Map',
      'Future',
      'Stream',
      'Object',
      'BridgeContract',
      'bridgeLuaSource',
    }.contains(name)) {
      _fail('Reserved declaration name $name');
    }
    if (classes.containsKey(name) || enums.containsKey(name)) {
      _fail('Duplicate declaration $name');
    }
    if (declaration is ClassDeclaration) {
      classes[name] = declaration;
    } else {
      enums[name] = declaration as EnumDeclaration;
    }
    final config = _annotation(declaration, 'ConfigureLuaBridge');
    if (config != null) {
      if (outputs.isNotEmpty) {
        _fail('Use one @ConfigureLuaBridge per contract file');
      }
      for (final option in ['dartOut', 'luaOut', 'tealOut']) {
        outputs[option] = _named(config, option);
      }
      final configuredOptimization = _optionalNamed(config, 'optimization');
      if (configuredOptimization != null) {
        try {
          optimization = parseBridgeOptimization(configuredOptimization);
        } on FormatException catch (error) {
          _fail(error.message);
        }
      }
    }
  }
  for (final declaration in classes.values) {
    if (declaration.extendsClause != null ||
        declaration.implementsClause != null ||
        declaration.withClause != null ||
        declaration.typeParameters != null) {
      _fail(
        'Inheritance and generic classes are unsupported: ${declaration.name.lexeme}',
      );
    }
    final lua = _annotation(declaration, 'LuaApi');
    final dart = _annotation(declaration, 'DartApi');
    if (lua == null && dart == null) continue;
    if (lua != null && dart != null) {
      _fail('Choose @LuaApi or @DartApi for ${declaration.name.lexeme}');
    }
    if (declaration.abstractKeyword == null) {
      _fail('API classes must be abstract');
    }
    final module = _named((lua ?? dart)!, 'module');
    if (!RegExp(
      r'^[a-zA-Z_][a-zA-Z0-9_]*(\.[a-zA-Z_][a-zA-Z0-9_]*)*$',
    ).hasMatch(module)) {
      _fail('Invalid module name $module');
    }
    final methods = <BridgeMethod>[];
    for (final member in declaration.members) {
      if (member is! MethodDeclaration ||
          member.isStatic ||
          member.isGetter ||
          member.isSetter ||
          member.typeParameters != null ||
          member.body is! EmptyFunctionBody ||
          member.parameters == null) {
        _fail('APIs contain abstract instance methods only');
      }
      final name = member.name.lexeme;
      _memberName(name);
      if (name == 'setUp') _fail('setUp is reserved for generated setup');
      final parameters = <BridgeField>[];
      for (final parameter in member.parameters!.parameters) {
        final normal = parameter is DefaultFormalParameter
            ? parameter.parameter
            : parameter;
        if (normal is! SimpleFormalParameter ||
            parameter.isOptional ||
            normal.name == null) {
          _fail(
            'Use required positional or required named parameters; callbacks/defaults are unsupported',
          );
        }
        final paramName = normal.name!.lexeme;
        _dartIdentifier(paramName);
        parameters.add(
          BridgeField(
            paramName,
            paramName,
            _type(normal.type),
            named: parameter.isNamed,
          ),
        );
      }
      _unique(parameters.map((p) => p.name), 'parameter');
      methods.add(
        BridgeMethod(
          name,
          _luaName(member, name),
          _type(member.returnType),
          parameters,
        ),
      );
    }
    _unique(methods.map((m) => m.luaName), 'Lua method');
    _unique(methods.map((m) => m.name), 'Dart method');
    if (methods.isEmpty) {
      _fail('API interfaces must declare at least one method');
    }
    apis.add(BridgeApi(declaration.name.lexeme, module, lua != null, methods));
  }
  if (apis.isEmpty) _fail('Declare at least one @LuaApi or @DartApi');
  _unique(apis.map((a) => a.module), 'module');
  final data = <String, BridgeData>{};
  final enumModels = <String, BridgeEnum>{};
  final visiting = <String>{};
  void visit(BridgeType type, {bool result = false}) {
    if (type.name == 'void') {
      if (!result || type.nullable || type.arguments.isNotEmpty) {
        _fail('void is only a method return type');
      }
      return;
    }
    if (type.name == 'List' || type.name == 'Map') {
      if (type.arguments.length != (type.name == 'List' ? 1 : 2)) {
        _fail('Specify all collection type arguments');
      }
      if (type.name == 'Map' && type.arguments.first.dart != 'String') {
        _fail('Map keys must be non-null String');
      }
      final element = type.arguments.last;
      if (element.nullable) {
        _fail(
          'Nullable collection elements are unsupported because Lua nil removes entries',
        );
      }
      visit(element);
      return;
    }
    if (type.arguments.isNotEmpty) {
      _fail('Unsupported generic type ${type.dart}');
    }
    if (const {'int', 'double', 'bool', 'String'}.contains(type.name)) return;
    if (apis.any((a) => a.name == type.name)) {
      _fail('API objects cannot be passed as DTOs');
    }
    if (visiting.contains(type.name)) {
      _fail('Recursive DTO types are unsupported: ${type.name}');
    }
    if (data.containsKey(type.name) || enumModels.containsKey(type.name)) {
      return;
    }
    final enumeration = enums[type.name];
    if (enumeration != null) {
      if (enumeration.members.isNotEmpty) {
        _fail('Enhanced enums are unsupported');
      }
      final values = <String, String>{};
      for (final value in enumeration.constants) {
        if (value.arguments != null) {
          _fail('Enhanced enum values are unsupported');
        }
        _memberName(value.name.lexeme);
        values[value.name.lexeme] = _luaName(value, value.name.lexeme);
      }
      _unique(values.values, 'enum Lua name');
      enumModels[type.name] = BridgeEnum(type.name, values);
      return;
    }
    final declaration = classes[type.name];
    if (declaration == null) {
      _fail(
        'Unsupported type ${type.dart}; use primitives, collections, DTOs or enums defined in this file',
      );
    }
    visiting.add(type.name);
    final fields = <BridgeField>[];
    for (final member in declaration.members) {
      if (member is ConstructorDeclaration) continue;
      if (member is! FieldDeclaration ||
          member.isStatic ||
          member.fields.isLate ||
          !member.fields.isFinal) {
        _fail('DTOs contain final instance fields only: ${type.name}');
      }
      for (final field in member.fields.variables) {
        if (field.initializer != null) {
          _fail('DTO field defaults are unsupported');
        }
        _memberName(field.name.lexeme);
        final fieldType = _type(member.fields.type);
        visit(fieldType);
        fields.add(
          BridgeField(
            field.name.lexeme,
            _luaName(member, field.name.lexeme),
            fieldType,
          ),
        );
      }
    }
    _unique(fields.map((f) => f.luaName), 'DTO Lua field');
    visiting.remove(type.name);
    data[type.name] = BridgeData(type.name, fields);
  }

  for (final api in apis) {
    for (final method in api.methods) {
      visit(method.result, result: true);
      for (final parameter in method.parameters) {
        visit(parameter.type);
      }
    }
  }
  return BridgeSchema(
    apis: apis,
    data: data.values.toList(),
    enums: enumModels.values.toList(),
    outputs: outputs,
    optimization: optimization,
  );
}
