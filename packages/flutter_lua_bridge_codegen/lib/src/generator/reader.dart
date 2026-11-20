import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import 'model.dart';

const _annotations =
    'package:flutter_lua_bridge_codegen_annotation/flutter_lua_bridge_codegen_annotation.dart';
const _luaApi = TypeChecker.fromUrl('$_annotations#LuaApi');
const _dartApi = TypeChecker.fromUrl('$_annotations#DartApi');
const _luaNameAnnotation = TypeChecker.fromUrl('$_annotations#LuaName');

const _luaKeywords = {
  'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function',
  'goto', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat', 'return', 'then',
  'true', 'until', 'while',
  // Teal
  'record', 'enum', 'type', 'global', 'interface',
};

final _identifierPattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');
final _modulePattern = RegExp(
  r'^[a-zA-Z_][a-zA-Z0-9_]*(\.[a-zA-Z_][a-zA-Z0-9_]*)*$',
);

Never _fail(String message, Element? element) =>
    throw InvalidGenerationSource(message, element: element);

void _memberName(String name, Element element) {
  if (!_identifierPattern.hasMatch(name)) {
    _fail('Use a public Dart identifier: $name', element);
  }
  if (const {
    'toString',
    'hashCode',
    'runtimeType',
    'noSuchMethod',
  }.contains(name)) {
    _fail('Object member names are reserved: $name', element);
  }
}

String _luaName(Element element, String fallback) {
  final annotation = _luaNameAnnotation.firstAnnotationOfExact(element);
  final name = annotation?.getField('name')?.toStringValue() ?? fallback;
  if (!_identifierPattern.hasMatch(name) || _luaKeywords.contains(name)) {
    _fail(
      'Unsupported Lua name "$name"; use @LuaName with a Lua identifier',
      element,
    );
  }
  return name;
}

void _unique(Iterable<String> names, String description, Element element) {
  final seen = <String>{};
  for (final name in names) {
    if (!seen.add(name)) _fail('Duplicate $description "$name"', element);
  }
}

/// Reads the bridge contract declared by [library].
///
/// Returns null when the library declares no `@LuaApi` or `@DartApi`.
/// [name] names the contract (see [BridgeSchema.name]); [optimization] applies
/// to every `@LuaApi` that does not choose its own.
BridgeSchema? readBridgeSchema(
  LibraryElement library, {
  required String name,
  BridgeOptimization optimization = BridgeOptimization.o1,
}) {
  final apiClasses = [
    for (final element in library.classes)
      if (_luaApi.hasAnnotationOfExact(element) ||
          _dartApi.hasAnnotationOfExact(element))
        element,
  ];
  if (apiClasses.isEmpty) return null;
  return _Reader(name, optimization).read(apiClasses);
}

class _Reader {
  _Reader(this.name, this.optimization);
  final String name;
  final BridgeOptimization optimization;

  final _apiElements = <Element>{};
  final _elements = <String, Element>{};
  final _data = <String, BridgeData>{};
  final _enums = <String, BridgeEnum>{};
  final _visiting = <String>{};

  BridgeSchema read(List<ClassElement> classes) {
    _apiElements.addAll(classes);
    final apis = classes.map(_api).toList();
    _unique(apis.map((api) => api.module), 'module', classes.first);
    return BridgeSchema(
      name: name,
      apis: apis,
      data: _data.values.toList(),
      enums: _enums.values.toList(),
    );
  }

  BridgeApi _api(ClassElement element) {
    final lua = _luaApi.firstAnnotationOfExact(element);
    final dart = _dartApi.firstAnnotationOfExact(element);
    final apiName = element.name!;
    if (lua != null && dart != null) {
      _fail('Choose @LuaApi or @DartApi for $apiName', element);
    }
    if (!_identifierPattern.hasMatch(apiName)) {
      _fail('API classes must be public: $apiName', element);
    }
    if (!element.isAbstract) _fail('API classes must be abstract', element);
    _checkInterface(element, apiName);
    final annotation = (lua ?? dart)!;
    final module = annotation.getField('module')!.toStringValue()!;
    if (!_modulePattern.hasMatch(module)) {
      _fail('Invalid module name $module', element);
    }
    var level = optimization;
    final override = lua?.getField('optimization');
    if (override != null && !override.isNull) {
      level =
          BridgeOptimization.values[override.getField('index')!.toIntValue()!];
    }
    final methods = <BridgeMethod>[];
    final seen = <String>{};
    for (final method in _interfaceMethods(element)) {
      if (!seen.add(method.name!)) continue;
      if (!method.isAbstract || method.typeParameters.isNotEmpty) {
        _fail('APIs contain abstract instance methods only', method);
      }
      final methodName = method.name!;
      _memberName(methodName, method);
      final parameters = <BridgeField>[];
      for (final parameter in method.formalParameters) {
        if (parameter.isOptional) {
          _fail(
            'Use required positional or required named parameters; '
            'defaults are unsupported',
            parameter,
          );
        }
        final parameterName = parameter.name!;
        if (!_identifierPattern.hasMatch(parameterName)) {
          _fail('Use a public Dart identifier: $parameterName', parameter);
        }
        parameters.add(
          BridgeField(
            parameterName,
            parameterName,
            _type(parameter.type, parameter),
            named: parameter.isNamed,
          ),
        );
      }
      final returnType = method.returnType;
      final isAsync =
          returnType is InterfaceType && returnType.isDartAsyncFuture;
      final isStream =
          returnType is InterfaceType && returnType.isDartAsyncStream;
      if ((isAsync || isStream) &&
          returnType.nullabilitySuffix == NullabilitySuffix.question) {
        _fail('A Future or Stream result cannot be nullable', method);
      }
      final result = _type(
        isAsync || isStream ? returnType.typeArguments.single : returnType,
        method,
        result: !isStream,
      );
      if (isStream && result.nullable) {
        // nil ends a Lua iteration, so it cannot also be an item.
        _fail('Stream items cannot be nullable', method);
      }
      methods.add(
        BridgeMethod(
          methodName,
          _luaName(method, methodName),
          result,
          parameters,
          isAsync: isAsync,
          isStream: isStream,
        ),
      );
    }
    _unique(methods.map((m) => m.luaName), 'Lua method', element);
    if (methods.isEmpty) {
      _fail('API interfaces must declare at least one method', element);
    }
    return BridgeApi(
      apiName,
      module,
      lua != null,
      methods,
      optimization: level,
    );
  }

  /// Rejects generics, `extends`, mixins and members other than abstract
  /// instance methods, in [element] and in every interface it implements.
  /// An API may implement plain abstract interfaces (for example one
  /// interface shared by several APIs that differ in their optimization);
  /// their methods become methods of the API.
  void _checkInterface(ClassElement element, String apiName) {
    if (element.typeParameters.isNotEmpty ||
        element.mixins.isNotEmpty ||
        !(element.supertype?.isDartCoreObject ?? true)) {
      _fail(
        'Generic classes, extends and mixins are unsupported: $apiName',
        element,
      );
    }
    if (element.fields.any((field) => !field.isStatic) ||
        element.getters.any((getter) => !getter.isStatic) ||
        element.setters.any((setter) => !setter.isStatic)) {
      _fail('APIs contain abstract instance methods only', element);
    }
    for (final interface in element.interfaces) {
      final base = interface.element;
      if (base is! ClassElement ||
          !base.isAbstract ||
          interface.typeArguments.isNotEmpty ||
          base.library.isInSdk) {
        _fail(
          'An API can only implement abstract interfaces without type '
          'arguments: ${interface.getDisplayString()}',
          element,
        );
      }
      if (_luaApi.hasAnnotationOfExact(base) ||
          _dartApi.hasAnnotationOfExact(base)) {
        _fail('An API cannot implement another API: ${base.name}', element);
      }
      _checkInterface(base, apiName);
    }
  }

  /// The instance methods of [element], then those of its interfaces.
  Iterable<MethodElement> _interfaceMethods(ClassElement element) sync* {
    for (final method in element.methods) {
      if (!method.isStatic) yield method;
    }
    for (final interface in element.interfaces) {
      yield* _interfaceMethods(interface.element as ClassElement);
    }
  }

  BridgeType _type(DartType type, Element owner, {bool result = false}) {
    if (type is VoidType) {
      if (!result) _fail('void is only a method return type', owner);
      return const BridgeType('void');
    }
    if (type is! InterfaceType) {
      _fail(
        'Unsupported type ${type.getDisplayString()}; use primitives, '
        'collections, data classes or enums',
        owner,
      );
    }
    final nullable = type.nullabilitySuffix == NullabilitySuffix.question;
    if (type.isDartCoreInt) return BridgeType('int', nullable: nullable);
    if (type.isDartCoreDouble) return BridgeType('double', nullable: nullable);
    if (type.isDartCoreBool) return BridgeType('bool', nullable: nullable);
    if (type.isDartCoreString) return BridgeType('String', nullable: nullable);
    if (type.isDartCoreList || type.isDartCoreMap) {
      if (type.isDartCoreMap &&
          (!type.typeArguments.first.isDartCoreString ||
              type.typeArguments.first.nullabilitySuffix !=
                  NullabilitySuffix.none)) {
        _fail('Map keys must be non-null String', owner);
      }
      final elementType = type.typeArguments.last;
      if (elementType is DynamicType) {
        _fail('Specify all collection type arguments', owner);
      }
      final element = _type(elementType, owner);
      if (element.nullable) {
        _fail(
          'Nullable collection elements are unsupported because Lua nil '
          'removes entries',
          owner,
        );
      }
      return BridgeType(
        type.isDartCoreList ? 'List' : 'Map',
        arguments: [
          if (type.isDartCoreMap) const BridgeType('String'),
          element,
        ],
        nullable: nullable,
      );
    }
    final element = type.element;
    final typeName = element.name;
    if (typeName == null ||
        type.typeArguments.isNotEmpty ||
        element.library.isInSdk) {
      _fail(
        'Unsupported type ${type.getDisplayString()}; use primitives, '
        'collections, data classes or enums',
        owner,
      );
    }
    if (_apiElements.contains(element)) {
      _fail('API objects cannot be passed as data', owner);
    }
    if (!_identifierPattern.hasMatch(typeName) ||
        _luaKeywords.contains(typeName)) {
      _fail('Unsupported type name $typeName', element);
    }
    final known = _elements[typeName];
    if (known != null && known != element) {
      _fail(
        'Two different types are named $typeName; contract type names must '
        'be unique',
        owner,
      );
    }
    _elements[typeName] = element;
    if (element is EnumElement) {
      _enums[typeName] ??= _enum(element);
    } else if (element is ClassElement) {
      if (_visiting.contains(typeName)) {
        _fail('Recursive data types are unsupported: $typeName', owner);
      }
      if (!_data.containsKey(typeName)) {
        _visiting.add(typeName);
        final data = _dataClass(element);
        _visiting.remove(typeName);
        _data[typeName] = data;
      }
    } else {
      _fail('Unsupported type $typeName', owner);
    }
    return BridgeType(typeName, nullable: nullable);
  }

  BridgeEnum _enum(EnumElement element) {
    if (element.methods.isNotEmpty ||
        element.getters.any((getter) => getter.isOriginDeclaration) ||
        element.setters.any((setter) => setter.isOriginDeclaration) ||
        element.fields.any(
          (field) =>
              !field.isEnumConstant &&
              field.isOriginDeclaration &&
              !field.isStatic,
        ) ||
        element.interfaces.isNotEmpty ||
        element.mixins.isNotEmpty) {
      _fail('Enhanced enums are unsupported', element);
    }
    final values = <String, String>{};
    for (final constant in element.constants) {
      final constantName = constant.name!;
      _memberName(constantName, constant);
      values[constantName] = _luaName(constant, constantName);
    }
    _unique(values.values, 'enum Lua name', element);
    return BridgeEnum(element.name!, values);
  }

  BridgeData _dataClass(ClassElement element) {
    final className = element.name!;
    if (element.isAbstract ||
        element.typeParameters.isNotEmpty ||
        element.interfaces.isNotEmpty ||
        element.mixins.isNotEmpty ||
        !(element.supertype?.isDartCoreObject ?? true)) {
      _fail(
        'Inheritance and generic classes are unsupported: $className',
        element,
      );
    }
    final constructor = element.unnamedConstructor;
    if (constructor == null || constructor.isPrivate) {
      _fail('$className needs an unnamed constructor', element);
    }
    final instanceFields = {
      for (final field in element.fields)
        if (!field.isStatic && field.isOriginDeclaration) field.name!: field,
    };
    final fields = <BridgeField>[];
    for (final parameter in constructor.formalParameters) {
      final field = instanceFields.remove(parameter.name);
      if (field == null ||
          parameter.isOptional ||
          parameter.type != field.type) {
        _fail(
          'Every constructor parameter of $className must be required and '
          'initialize the field of the same name',
          parameter,
        );
      }
      if (!field.isFinal || field.isLate) {
        _fail(
          'Data classes contain final instance fields only: $className',
          field,
        );
      }
      final fieldName = field.name!;
      _memberName(fieldName, field);
      fields.add(
        BridgeField(
          fieldName,
          _luaName(field, fieldName),
          _type(field.type, field),
          named: parameter.isNamed,
        ),
      );
    }
    if (instanceFields.isNotEmpty) {
      _fail(
        'Every field of $className must be a constructor parameter: '
        '${instanceFields.keys.join(', ')}',
        instanceFields.values.first,
      );
    }
    _unique(fields.map((f) => f.luaName), 'Lua field', element);
    return BridgeData(className, fields);
  }
}
