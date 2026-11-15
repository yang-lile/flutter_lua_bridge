import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';

/// Lines of the worker protocol carry this marker; anything else on the
/// worker's stdout (tool chatter) is ignored.
const tealWorkerMarker = 'FLB-TEAL:';

/// One Teal compiler process shared by a whole build, and by successive
/// builds in watch mode.
///
/// build_runner cannot load the native Lua library into its own process, so
/// the Teal compiler (a Lua program) runs in a `dart run` child, which can.
final tealWorker = Resource<TealWorkerClient>(
  TealWorkerClient.start,
  beforeExit: TealWorkerClient.stopAll,
);

class TealResult {
  const TealResult({this.lua, this.errors = const []});
  final String? lua;
  final List<String> errors;
}

class TealWorkerClient {
  TealWorkerClient._(this._process);

  static final _running = <TealWorkerClient>{};

  final Process _process;
  final _pending = <int, Completer<Map<String, Object?>>>{};
  final _stderr = StringBuffer();
  final _ready = Completer<void>();
  var _nextId = 0;

  static Future<TealWorkerClient> start() async {
    final dart = File(
      Platform.resolvedExecutable,
    ).parent.uri.resolve(Platform.isWindows ? 'dart.exe' : 'dart').toFilePath();
    final process = await Process.start(dart, const [
      'run',
      'flutter_lua_bridge_codegen:teal_worker',
    ]);
    final client = TealWorkerClient._(process);
    _running.add(client);
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(client._onLine);
    process.stderr.transform(utf8.decoder).listen(client._stderr.write);
    unawaited(process.exitCode.then(client._onExit));
    await client._ready.future;
    return client;
  }

  static Future<void> stopAll() async {
    for (final client in _running.toList()) {
      await client._process.stdin.close();
      await client._process.exitCode;
    }
  }

  void _onLine(String line) {
    // `dart run` may print progress such as "Running build hooks..." without
    // a line break, so the marker is not always at the start of the line.
    final start = line.indexOf(tealWorkerMarker);
    if (start < 0) return;
    final message =
        jsonDecode(line.substring(start + tealWorkerMarker.length))
            as Map<String, Object?>;
    if (message['ready'] == true) {
      if (!_ready.isCompleted) _ready.complete();
      return;
    }
    _pending.remove(message['id'])?.complete(message);
  }

  void _onExit(int code) {
    _running.remove(this);
    final error = StateError(
      'The Teal worker exited with code $code.\n$_stderr',
    );
    if (!_ready.isCompleted) _ready.completeError(error);
    for (final completer in _pending.values) {
      completer.completeError(error);
    }
    _pending.clear();
  }

  Future<TealResult> compile({
    required String path,
    required String source,
    required Map<String, Map<String, Map<String, String>>> modules,
  }) async {
    final id = _nextId++;
    final completer = _pending[id] = Completer();
    _process.stdin.writeln(
      jsonEncode({
        'id': id,
        'path': path,
        'source': source,
        'modules': modules,
      }),
    );
    final message = await completer.future;
    return TealResult(
      lua: message['lua'] as String?,
      errors: [...?(message['errors'] as List?)?.cast<String>()],
    );
  }
}
