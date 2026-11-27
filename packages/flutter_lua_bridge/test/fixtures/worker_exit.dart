// Run by worker_test.dart in a process of its own: the process must exit
// once main returns, without LuaWorker.close, and still finish the calls in
// flight and a close in progress.
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

Future<void> main(List<String> args) async {
  final worker = await LuaWorker.spawn();
  switch (args.single) {
    case 'idle':
      print(await worker.run('return 1'));
    case 'pending':
      // Not awaited: the call keeps the program running until it completes.
      worker
          .run('local n = 0 for i = 1, 3e6 do n = n + i end return n')
          .then(print);
    case 'close':
      await worker.close();
      print('closed');
  }
}
