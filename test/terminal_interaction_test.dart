import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/core/app_scope.dart';
import 'package:flit/features/terminal/global_terminal_panel.dart';
import 'package:flit/features/terminal/console_session.dart';
import 'package:flit/features/terminal/pty_session.dart';
import 'package:flit/features/terminal/terminal_host.dart';
import 'package:xterm/xterm.dart';

import 'support/app_scope.dart';
import 'support/fake_session_process.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  String? copiedText;
  // 每个测试一套新的应用对象: 工作台 shell 不跨测试残留选区/缓冲
  late PtySession shell;
  late AppServices services;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flit/env'),
          (call) async => {
            'prefix': '/does-not-exist',
            'home': '/does-not-exist',
          },
        );
    shell = PtySession(launcher: noProcess);
    services = testServices(workbenchShell: shell, launcher: noProcess);
    copiedText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText = (call.arguments as Map)['text'] as String;
          }
          if (call.method == 'Clipboard.getData') return {'text': copiedText};
          return null;
        });
  });

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.view.resetPadding);
  }

  Offset cell(WidgetTester tester, int column, int row) {
    final render = tester
        .state<TerminalViewState>(find.byType(TerminalView))
        .renderTerminal;
    return render.localToGlobal(
      Offset(
        (column + .5) * render.cellSize.width,
        (row + .5) * render.cellSize.height,
      ),
    );
  }

  Future<void> openHost(
    WidgetTester tester, {
    bool hideContentWithKeyboard = false,
  }) async {
    var expanded = true;
    await tester.pumpWidget(
      AppScope(
        services: services,
        child: MaterialApp(
          navigatorObservers: [services.routeObserver],
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              appBar: AppBar(title: const Text('页面')),
              body: TerminalHost(
                expanded: expanded,
                onToggle: () => setState(() => expanded = !expanded),
                hideContentWithKeyboard: hideContentWithKeyboard,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          const TextField(),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => Scaffold(
                                  appBar: AppBar(title: const Text('下一页')),
                                  body: TerminalHost(
                                    expanded: true,
                                    preferredHeight: 220,
                                    onToggle: () {},
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                              ),
                            ),
                            child: const Text('下一页'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48, child: Text('编辑状态栏')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('long press and drag select without requesting the keyboard', (
    tester,
  ) async {
    final terminal = Terminal()..write('hello world again\r\n');
    final controller = TerminalController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TerminalView(terminal, controller: controller)),
      ),
    );
    await tester.pumpAndSettle();
    tester.testTextInput.log.clear();
    final gesture = await tester.startGesture(cell(tester, 2, 0));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    expect(terminal.buffer.getText(controller.selection!), 'hello');
    expect(tester.testTextInput.isVisible, false);
    expect(
      tester.testTextInput.log.where((call) => call.method == 'TextInput.show'),
      isEmpty,
    );
    await gesture.moveTo(cell(tester, 8, 0));
    await tester.pump();
    await gesture.up();
    expect(terminal.buffer.getText(controller.selection!), 'hello world');
    // A first tap dismisses the selection; the next tap opens input.
    await tester.tapAt(cell(tester, 2, 2));
    await tester.pump(kDoubleTapTimeout);
    expect(controller.selection, isNull);
    expect(tester.testTextInput.isVisible, false);
    await tester.tapAt(cell(tester, 2, 2));
    await tester.pump(kDoubleTapTimeout);
    expect(tester.testTextInput.isVisible, true);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('selection toolbar and copy keep viewport and focus unchanged', (
    tester,
  ) async {
    phone(tester);
    await openHost(tester);
    final session = shell;
    session.terminal.write('\x1b[2J\x1b[Hfirst line\r\ncopy this word\r\n');
    await tester.pumpAndSettle();
    final before = tester.getRect(find.byType(TerminalView));
    final rows = session.terminal.viewHeight;
    await tester.longPressAt(cell(tester, 2, 1));
    await tester.pumpAndSettle();
    expect(session.copySelection(), 'copy');
    expect(tester.getRect(find.byType(TerminalView)), before);
    expect(session.terminal.viewHeight, rows);
    await tester.tap(find.text('复制'));
    await tester.pump();
    expect(copiedText, 'copy');
    expect(session.copySelection(), 'copy');
    expect(session.terminal.viewHeight, rows);
    expect(tester.testTextInput.isVisible, false);
    tester
        .state<TerminalViewState>(find.byType(TerminalView))
        .requestKeyboard();
    await tester.pump();
    final focus = tester
        .widget<TerminalView>(find.byType(TerminalView))
        .focusNode!;
    expect(focus.hasFocus, true);
    await tester.tap(find.text('复制'));
    await tester.pump();
    expect(focus.hasFocus, true);
    expect(tester.testTextInput.isVisible, true);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('switching consoles retains input client and isolates actions', (
    tester,
  ) async {
    phone(tester);
    final processes = [FakeProcess(), FakeProcess()];
    final sessions = List.generate(
      2,
      (index) => ConsoleSession(
        title: 'task $index',
        kind: SessionKind.shell, // 输入连接只对可输入会话有意义
        launcher:
            ({
              required command,
              required workingDirectory,
              required rows,
              required columns,
            }) async => processes[index],
      ),
    );
    for (final session in sessions) {
      await session.start(command: 'task');
    }
    processes[0].emit('first console\r\n');
    processes[1].emit('second console\r\n');
    int selected = 0;
    late StateSetter change;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            change = setState;
            return Scaffold(
              body: GlobalTerminalPanel(
                session: sessions[selected],
                expanded: true,
                onToggle: () {},
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester
        .state<TerminalViewState>(find.byType(TerminalView))
        .requestKeyboard();
    await tester.pump();
    final view = tester.state<TerminalViewState>(find.byType(TerminalView));
    sessions[0].selectAll();
    final firstSelection = sessions[0].copySelection();
    change(() => selected = 1);
    await tester.pumpAndSettle();
    expect(
      tester.state<TerminalViewState>(find.byType(TerminalView)),
      same(view),
    );
    expect(view.hasInputConnection, true);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '  a',
        selection: TextSelection.collapsed(offset: 3),
      ),
    );
    expect(processes[0].writes, isEmpty);
    expect(processes[1].writes.join(), 'a');
    await tester.longPressAt(cell(tester, 2, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('复制'));
    await tester.pump();
    expect(copiedText, 'second');
    await tester.tap(find.byTooltip('清空终端'));
    await tester.pump();
    sessions[1].selectAll();
    expect(sessions[1].copySelection(), isNot(contains('second console')));
    expect(sessions[0].copySelection(), firstSelection);
    Future<void> closeConsole(ConsoleSession session) async {
      var closed = false;
      final closing = session.close().then((_) => closed = true);
      for (var frame = 0; frame < 50 && !closed; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(closed, true);
      await closing;
    }

    await closeConsole(sessions[1]);
    expect(find.byType(TerminalView), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await closeConsole(sessions[0]);
  });

  testWidgets('dock, keyboard, fullscreen and back retain the same view', (
    tester,
  ) async {
    phone(tester);
    await openHost(tester);
    final state = tester.state<TerminalViewState>(find.byType(TerminalView));
    final height = tester.getSize(find.byType(GlobalTerminalPanel)).height;
    await tester.drag(find.text('bash · 就绪'), const Offset(0, -60));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(GlobalTerminalPanel)).height,
      greaterThan(height),
    );
    tester
        .state<TerminalViewState>(find.byType(TerminalView))
        .requestKeyboard();
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(GlobalTerminalPanel)).bottom, 544);
    expect(tester.testTextInput.isVisible, true);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('全屏终端'));
    await tester.pumpAndSettle();
    expect(tester.state<TerminalViewState>(find.byType(TerminalView)), state);
    expect(find.text('编辑状态栏'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('编辑状态栏'), findsOneWidget);
    expect(find.byTooltip('全屏终端'), findsOneWidget);
    expect(tester.state<TerminalViewState>(find.byType(TerminalView)), state);
    tester.state<TerminalViewState>(find.byType(TerminalView)).closeKeyboard();
    await tester.pump();
    expect(tester.testTextInput.isVisible, false);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('environment gives terminal remaining height while typing', (
    tester,
  ) async {
    phone(tester);
    await openHost(tester, hideContentWithKeyboard: true);
    final state = tester.state<TerminalViewState>(find.byType(TerminalView));
    tester
        .state<TerminalViewState>(find.byType(TerminalView))
        .requestKeyboard();
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byType(GlobalTerminalPanel)),
      const Rect.fromLTRB(0, 56, 390, 544),
    );
    expect(find.text('编辑状态栏'), findsNothing);
    expect(tester.state<TerminalViewState>(find.byType(TerminalView)), state);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.text('编辑状态栏'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('only the visible route mounts and resizes the shared terminal', (
    tester,
  ) async {
    phone(tester);
    await openHost(tester);
    final terminal = shell.terminal;
    final rows = terminal.viewHeight;
    final resizes = <int>[];
    final originalResize = terminal.onResize;
    terminal.onResize = (columns, rows, pw, ph) => resizes.add(rows);
    addTearDown(() => terminal.onResize = originalResize);
    await tester.tap(find.text('下一页'));
    await tester.pumpAndSettle();
    expect(find.byType(TerminalView, skipOffstage: false), findsOneWidget);
    expect(terminal.viewHeight, lessThan(rows));
    expect(resizes.toSet(), {terminal.viewHeight});
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(TerminalView, skipOffstage: false), findsOneWidget);
    expect(terminal.viewHeight, rows);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('short landscape viewport retains input client and valid rows', (
    tester,
  ) async {
    phone(tester);
    await openHost(tester);
    tester
        .state<TerminalViewState>(find.byType(TerminalView))
        .requestKeyboard();
    await tester.pump();
    final state = tester.state<TerminalViewState>(find.byType(TerminalView));
    tester.view.physicalSize = const Size(844, 390);
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    await tester.pumpAndSettle();
    expect(tester.state<TerminalViewState>(find.byType(TerminalView)), state);
    expect(state.hasInputConnection, true);
    expect(shell.terminal.viewHeight, greaterThan(0));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('fullscreen transfers keyboard focus away from page inputs', (
    tester,
  ) async {
    phone(tester);
    await openHost(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('全屏终端'));
    await tester.pumpAndSettle();
    final terminal = tester.widget<TerminalView>(find.byType(TerminalView));
    expect(terminal.focusNode!.hasFocus, true);
    final input = <String>[];
    terminal.terminal.onOutput = input.add;
    addTearDown(() => terminal.terminal.onOutput = null);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(text: '  echo hi'),
    );
    expect(input.join(), 'echo hi');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'collapsed dock keeps controls above the gesture navigation area',
    (tester) async {
      phone(tester);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      tester.view.padding = const FakeViewPadding(bottom: 34);
      await openHost(tester);
      await tester.tap(find.byTooltip('收起终端'));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(GlobalTerminalPanel)).height, 78);
      expect(
        tester.getRect(find.byTooltip('展开终端')).bottom,
        lessThanOrEqualTo(810),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'workbench footer stays above IME and safe area without replacing terminal input',
    (tester) async {
      phone(tester);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      tester.view.padding = const FakeViewPadding(bottom: 34);
      await tester.pumpWidget(
        testApp(
          services: services,
          home: Scaffold(
            appBar: AppBar(title: const Text('项目')),
            body: TerminalHost(
              expanded: true,
              onToggle: () {},
              footer: const SizedBox(
                height: 44,
                child: Center(child: Text('运行控制')),
              ),
              child: const Text('编辑器'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = tester.state<TerminalViewState>(find.byType(TerminalView));
      expect(tester.getRect(find.text('运行控制')).bottom, lessThan(810));
      tester
          .state<TerminalViewState>(find.byType(TerminalView))
          .requestKeyboard();
      await tester.pump();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      tester.view.padding = FakeViewPadding.zero;
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('运行控制')).bottom, lessThan(544));
      expect(
        tester.state<TerminalViewState>(find.byType(TerminalView)),
        same(state),
      );
      tester.view.physicalSize = const Size(844, 390);
      tester.view.viewInsets = const FakeViewPadding(bottom: 170);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('运行控制')).bottom, lessThan(220));
      expect(
        tester.state<TerminalViewState>(find.byType(TerminalView)),
        same(state),
      );
      expect(state.hasInputConnection, true);
      expect(state.widget.terminal.viewHeight, greaterThan(0));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
