/// Shared contract model. A future Teal frontend can target this same model.
class BridgeType {
  const BridgeType(
    this.name, {
    this.arguments = const [],
    this.nullable = false,
  });
  final String name;
  final List<BridgeType> arguments;
  final bool nullable;
  String get dart =>
      '$name${arguments.isEmpty ? '' : '<${arguments.map((t) => t.dart).join(', ')}>'}${nullable ? '?' : ''}';
  BridgeType get nonNullable => BridgeType(name, arguments: arguments);
}

enum BridgeOptimization { o1, o2, o3 }

extension BridgeOptimizationName on BridgeOptimization {
  String get label => switch (this) {
    BridgeOptimization.o1 => 'O1',
    BridgeOptimization.o2 => 'O2',
    BridgeOptimization.o3 => 'O3',
  };

  bool get catchesErrors => this != BridgeOptimization.o3;
  bool get checksTypes => this == BridgeOptimization.o1;
}

BridgeOptimization parseBridgeOptimization(String value) =>
    switch (value.toUpperCase()) {
      'O1' => BridgeOptimization.o1,
      'O2' => BridgeOptimization.o2,
      'O3' => BridgeOptimization.o3,
      _ => throw FormatException('optimization must be O1, O2 or O3'),
    };

class BridgeField {
  const BridgeField(this.name, this.luaName, this.type, {this.named = false});
  final String name, luaName;
  final BridgeType type;
  final bool named;
}

class BridgeMethod {
  const BridgeMethod(this.name, this.luaName, this.result, this.parameters);
  final String name, luaName;
  final BridgeType result;
  final List<BridgeField> parameters;
}

class BridgeApi {
  const BridgeApi(this.name, this.module, this.isLua, this.methods);
  final String name, module;
  final bool isLua;
  final List<BridgeMethod> methods;
}

class BridgeData {
  const BridgeData(this.name, this.fields);
  final String name;
  final List<BridgeField> fields;
}

class BridgeEnum {
  const BridgeEnum(this.name, this.values);
  final String name;
  final Map<String, String> values;
}

class BridgeSchema {
  const BridgeSchema({
    required this.apis,
    required this.data,
    required this.enums,
    this.outputs = const {},
    this.optimization = BridgeOptimization.o1,
  });
  final List<BridgeApi> apis;
  final List<BridgeData> data;
  final List<BridgeEnum> enums;
  final Map<String, String> outputs;
  final BridgeOptimization optimization;

  BridgeSchema withOptimization(BridgeOptimization value) => BridgeSchema(
    apis: apis,
    data: data,
    enums: enums,
    outputs: outputs,
    optimization: value,
  );
}
