# flutter_lua_bridge_codegen_annotation

Small, dependency free annotations for describing a Dart/Lua bridge contract.
Application packages import this library in their contract files; generated
code and the runtime do not need to expose the generator implementation.

`ConfigureLuaBridge.optimization` accepts `O1`, `O2` or `O3`; command line
options on the code generator can override the contract setting.
