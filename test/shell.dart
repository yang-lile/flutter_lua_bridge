import 'dart:ffi';
import 'dart:io';

import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

/// 模拟 C 语言版本的 Lua Shell
/// 从标准输入读取 Lua 代码，解释执行后输出结果和异常
///
/// 参考 C 代码:
/// ```c
/// int main(void)
/// {
///      char buff[256];
///      int error;
///      lua_State *L = luaL_newstate(); //opens lua
///      luaL_openlibs(L); //open the standar libraries
///
///      while(fgets(buff, sizeof(buff), stdin) != NULL) {
///           error = luaL_loadstring(L, buff) || lua_pcall(L, 0, 0, 0);
///           if(error) {
///                fprintf(stderr, "%s\n", lua_tostring(L, -1));
///                lua_pop(L, 1);
///           }
///      }
///
///      lua_close(L);
///      return 0;
/// }
/// ```
void main(List<String> args) {
  // 创建 Lua 状态 (对应 luaL_newstate)
  final Pointer<lua_State> L = luaL_newstate();

  // 打开标准库 (对应 luaL_openlibs)
  luaL_openlibs(L);

  // 交互模式提示
  if (stdin.hasTerminal) {
    stdout.writeln('$LUA_RELEASE Shell (输入 exit 或 quit 退出)');
    stdout.write('> ');
  }

  // 循环读取标准输入 (对应 while(fgets(...)))
  while (true) {
    final String? line = stdin.readLineSync();

    if (line == null) {
      // EOF (Ctrl+D/Ctrl+Z)
      break;
    }

    final String trimmedLine = line.trim();

    // 处理退出命令
    if (trimmedLine == 'exit' || trimmedLine == 'quit') {
      break;
    }

    // 跳过空行
    if (trimmedLine.isEmpty) {
      if (stdin.hasTerminal) {
        stdout.write('> ');
      }
      continue;
    }

    // 尝试执行原始代码
    int error = _dostring(L, trimmedLine);

    // 如果失败，尝试作为表达式执行（自动添加 return）
    if (error != 0) {
      // 清除错误
      lua_pop(L, 1);

      // 尝试添加 return 前缀
      final String returnLine = 'return $trimmedLine';
      error = _dostring(L, returnLine);

      if (error != 0) {
        // 还是失败，打印错误
        stderr.writeln(lua_tostring(L, -1));
        lua_pop(L, 1);
      } else {
        // 成功作为表达式执行，打印返回值
        _printReturnValues(L);
      }
    } else {
      // 原始代码执行成功，检查是否有返回值
      _printReturnValues(L);
    }

    if (stdin.hasTerminal) {
      stdout.write('> ');
    }
  }

  // 关闭 Lua 状态 (对应 lua_close)
  lua_close(L);

  if (stdin.hasTerminal) {
    stdout.writeln();
  }
}

/// 加载并执行 Lua 代码
/// 对应 luaL_loadstring(L, s) || lua_pcall(L, 0, LUA_MULTRET, 0)
int _dostring(Pointer<lua_State> L, String code) {
  final Pointer<Char> codePtr = code.toPointChar();

  // luaL_loadstring: 加载代码（自动计算长度，使用代码内容作为 chunkname）
  int status = luaL_loadstring(L, codePtr);

  if (status == 0) {
    // 加载成功，执行代码，返回所有结果 (LUA_MULTRET = -1)
    status = lua_pcall(L, 0, -1, 0);
  }

  return status;
}

/// 打印栈上的返回值
void _printReturnValues(Pointer<lua_State> L) {
  final int returnCount = lua_gettop(L);
  if (returnCount > 0) {
    for (int i = 1; i <= returnCount; i++) {
      if (i > 1) stdout.write('\t');
      _printValue(L, i);
    }
    stdout.writeln();
    lua_pop(L, returnCount);
  }
}

/// 使用 luaL_tolstring 将 Lua 值格式化为字符串并打印
/// luaL_tolstring 会自动调用 __tostring 元方法
void _printValue(Pointer<lua_State> L, int idx) {
  // luaL_tolstring 会将值转换为字符串（支持 __tostring 元方法）
  final Pointer<Char> str = luaL_tolstring(L, idx, nullptr);
  stdout.write(str.toDartString());
  // luaL_tolstring 将结果压入栈顶，需要弹出
  lua_pop(L, 1);
}
