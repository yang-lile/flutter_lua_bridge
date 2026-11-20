// Drives the real Lua Canvas Studio through every example and interaction,
// and fails if the app reports any Flutter error or uncaught exception:
//
//   flutter drive -t lib/driver_main.dart \
//     --driver test_driver/studio_test.dart -d macos
import 'dart:convert';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

const _timeout = Duration(seconds: 20);

void main() {
  late FlutterDriver driver;

  setUpAll(() async {
    driver = await FlutterDriver.connect();
    await driver.waitForAbsent(
      find.text('正在启动 Lua 运行时'),
      timeout: const Duration(seconds: 30),
    );
  });

  tearDownAll(() async => driver.close());

  /// Fails with the app's own report if anything was thrown so far.
  Future<void> expectNoAppErrors(String step) async {
    final errors = jsonDecode(await driver.requestData('errors')) as List;
    // Clear what was reported, so one failure does not fail every later step.
    if (errors.isNotEmpty) await driver.requestData('clear_errors');
    expect(errors, isEmpty, reason: 'after $step:\n${errors.join('\n\n')}');
  }

  final luaError = find.text('Lua 报错');

  Future<void> idle() async {
    await driver.waitForAbsent(find.text('执行中'), timeout: _timeout);
    await driver.waitUntilNoTransientCallbacks(timeout: _timeout);
  }

  Future<void> tap(SerializableFinder finder, String step) async {
    await driver.tap(finder, timeout: _timeout);
    await idle();
    await expectNoAppErrors(step);
  }

  Future<void> see(String text) =>
      driver.waitFor(find.text(text), timeout: _timeout);

  Future<void> loadSnippet(String name) async {
    await tap(_tooltip('载入示例'), 'open the examples menu');
    await tap(
      find.descendant(
        of: find.byType('PopupMenuItem<String>'),
        matching: find.text(name),
        firstMatchOnly: true,
      ),
      'load $name',
    );
  }

  test('starts without errors', () async {
    await idle();
    await driver.waitForAbsent(luaError, timeout: _timeout);
    await expectNoAppErrors('start');
  });

  group('component mode', () {
    test('local state and a Lua event', () async {
      const note = '这段内容由 rfw 的本地状态控制显示，点击没有产生任何事件，也没有回到 Lua。';
      await tap(find.text('展开'), 'expand');
      await driver.waitFor(find.text(note), timeout: _timeout);
      await tap(find.text('标记'), 'mark');
      await see('1');
      await tap(find.text('收起'), 'collapse');
      await driver.waitForAbsent(find.text(note), timeout: _timeout);
      await tap(find.text('提交（会回 Lua）'), 'submit');
      await see('已提交 1 次');
      await tap(find.text('提交（会回 Lua）'), 'submit again');
      await see('已提交 2 次');
    });

    test('counter: buttons, toggle and rapid taps', () async {
      await loadSnippet('计数器');
      await see('点了几下');
      await tap(find.text('+1'), '+1');
      await tap(find.text('+1'), '+1');
      await see('2');
      await tap(find.text('-1'), '-1');
      await see('1');
      await tap(find.text('归零'), 'reset');
      await see('0');
      await tap(find.byType('Switch'), 'toggle');
      // Rapid taps while dispatching: later taps may be dropped, but
      // nothing may throw.
      for (var i = 0; i < 10; i++) {
        await driver.tap(find.text('+1'));
      }
      await idle();
      await expectNoAppErrors('rapid taps');
    });

    test('list: event arguments', () async {
      await loadSnippet('列表与事件参数');
      await see('苹果（第 1 个）');
      await tap(find.text('樱桃'), 'pick');
      await see('樱桃（第 3 个）');
      await tap(find.text('下一个'), 'next');
      await see('西瓜（第 4 个）');
      await tap(find.text('下一个'), 'wrap around');
      await see('苹果（第 1 个）');
    });

    test('slider and custom toggle', () async {
      await loadSnippet('自定义组件与滑条');
      await see('40');
      await driver.scroll(
        find.byType('Slider'),
        150,
        0,
        const Duration(milliseconds: 300),
      );
      await idle();
      await expectNoAppErrors('drag the slider');
      await driver.waitForAbsent(find.text('40'), timeout: _timeout);
      await tap(find.byType('Switch'), 'flip');
      await see('关');
    });

    test('a failing example shows the Lua error', () async {
      await loadSnippet('会报错的样子');
      await driver.waitFor(luaError, timeout: _timeout);
      await loadSnippet('计数器');
      await driver.waitForAbsent(luaError, timeout: _timeout);
    });
  });

  group('canvas mode', () {
    test('every example', () async {
      await tap(find.text('画布'), 'switch to canvas');
      for (final name in ['基础图元', '折线图', '柱状图', '带参数的函数', 'print 调试']) {
        await loadSnippet(name);
        await driver.waitForAbsent(luaError, timeout: _timeout);
        await driver.waitForAbsent(find.text('没有产出显示列表'), timeout: _timeout);
      }
    });

    test('zoom and frame', () async {
      await tap(_tooltip('放大'), 'zoom in');
      await tap(_tooltip('放大'), 'zoom in');
      await tap(_tooltip('缩小'), 'zoom out');
      await tap(_tooltip('隐藏画布边界'), 'hide frame');
      await tap(_tooltip('显示画布边界'), 'show frame');
    });

    test('a failing example, then back and forth between modes', () async {
      await loadSnippet('会报错的样子');
      await driver.waitFor(luaError, timeout: _timeout);
      await tap(find.text('组件'), 'switch to components');
      await driver.waitForAbsent(luaError, timeout: _timeout);
      await tap(find.text('画布'), 'switch to canvas');
      await driver.waitForAbsent(luaError, timeout: _timeout);
    });

    test('typing: broken code, a runaway loop and rapid edits', () async {
      // A focused editor blinks its cursor, so frames never settle; drive it
      // without frame synchronization and wait for the results instead.
      await driver.runUnsynchronized(() => _typing(driver, luaError));
      await expectNoAppErrors('typing');
    });
  });
}

Future<void> _typing(FlutterDriver driver, SerializableFinder luaError) async {
  final editor = find.byType('TextField');
  await driver.tap(editor, timeout: _timeout);

  await driver.enterText('local x = ');
  await driver.waitFor(luaError, timeout: _timeout);

  // Leave the error state first, so the next wait sees a fresh error.
  await driver.enterText(
    'return json.encode(canvas.new({ width = 10, height = 10 }):build())',
  );
  await driver.waitForAbsent(luaError, timeout: _timeout);
  await driver.enterText('while true do end');
  await driver.waitFor(luaError, timeout: const Duration(seconds: 30));

  // Each edit restarts the 0.4 s debounce; only the last one runs.
  for (var r = 10; r <= 40; r += 5) {
    await driver.enterText(
      'local c = canvas.new({ width = 200, height = 100 })\n'
      'c:circle(50, 50, $r, { fill = "#4a9eff" })\n'
      'return json.encode(c:build())',
    );
  }
  await driver.waitForAbsent(luaError, timeout: _timeout);
  await driver.waitForAbsent(find.text('执行中'), timeout: _timeout);
  await driver.tap(find.text('运行'), timeout: _timeout);
  await driver.waitForAbsent(find.text('执行中'), timeout: _timeout);
  await driver.waitForAbsent(luaError, timeout: _timeout);
}

/// A package:material_ui Tooltip with [message]: flutter_driver's own
/// `find.byTooltip` only matches the Tooltip of package:flutter/material. The
/// app side is registered in lib/driver_main.dart.
SerializableFinder _tooltip(String message) => _Tooltip(message);

class _Tooltip extends SerializableFinder {
  const _Tooltip(this.message);

  final String message;

  @override
  String get finderType => 'MaterialUiTooltip';

  @override
  Map<String, String> serialize() => super.serialize()..['message'] = message;
}
