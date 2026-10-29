import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/core/app_scope.dart';
import 'package:flit/core/theme.dart';
import 'package:flit/features/settings/appearance_preferences.dart';
import 'package:flit/features/editor/widgets/code_field.dart';
import 'package:flit/features/editor/widgets/completion_popup.dart';
import 'package:flit/features/editor/widgets/file_tree_drawer.dart';
import 'package:flit/features/terminal/global_terminal_panel.dart';
import 'package:flit/features/editor/editor_page.dart';
import 'package:flit/features/editor/file_kind.dart';
import 'package:flit/features/workspace/editor_tabs.dart';
import 'package:flit/features/workspace/project_session.dart';

import 'support/app_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Completer<String>? pendingCompletion;
  final methods = <String>[];
  final notifications = <Map>[];
  final commands = <String>[];
  var failSave = false;
  final boundary = GlobalKey();
  late AppServices services;
  const source =
      "import 'package:flutter/material.dart';\n\nclass WelcomeCard extends StatelessWidget {\n  const WelcomeCard({super.key});\n\n  @override\n  Widget build(BuildContext context) {\n    return const Padding(\n      padding: EdgeInsets.all(16),\n      child: Text('Hello, Flit'),\n    );\n  }\n}\n\nSt";
  const result =
      '{"result":[{"label":"State","kind":7,"detail":"State<T extends StatefulWidget>"},{"label":"StatefulWidget","kind":7,"detail":"abstract class StatefulWidget extends Widget"},{"label":"StatelessWidget","kind":7,"detail":"abstract class StatelessWidget extends Widget"}]}';
  var diskSource = source;
  var mdSource = '# Flit README\n\n- item one\n';
  var listing = 'lib/main.dart\nlib/other.dart';

  setUpAll(() async {
    // 偏好在任何测试的假时钟之外加载一次; 应用级对象集跨测试共享(如同生产)
    messenger.setMockMethodCallHandler(
      const MethodChannel('flit/env'),
      (_) async => {'home': ''},
    );
    final preferences = AppearancePreferences();
    await preferences.load();
    services = testServices(preferences: preferences);
  });

  setUp(() {
    pendingCompletion = null;
    methods.clear();
    commands.clear();
    notifications.clear();
    failSave = false;
    diskSource = source;
    mdSource = '# Flit README\n\n- item one\n';
    listing = 'lib/main.dart\nlib/other.dart';
    messenger.setMockMethodCallHandler(
      const MethodChannel('flit/lspEvents'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(const MethodChannel('flit/lsp'), (
      call,
    ) async {
      switch (call.method) {
        case 'start':
        case 'stop':
          return true;
        case 'notify':
          notifications.add(call.arguments as Map);
          return true;
        case 'request':
          final method = (call.arguments as Map)['method'];
          methods.add(method as String);
          if (method == 'initialize') return '{"result":{"capabilities":{}}}';
          if (method == 'textDocument/completion') {
            return pendingCompletion?.future ?? result;
          }
          return '{"result":null}';
      }
      return null;
    });
    messenger.setMockMethodCallHandler(const MethodChannel('flit/env'), (
      call,
    ) async {
      switch (call.method) {
        case 'bootstrapStatus':
          return {'prefix': '/does-not-exist', 'home': '/does-not-exist'};
        case 'exec':
          final cmd = (call.arguments as Map)['cmd'] as String;
          commands.add(cmd);
          if (failSave && cmd.contains('base64 -d')) {
            return {'exitCode': 1, 'output': 'write failed'};
          }
          if (cmd.contains('base64 -d')) {
            final encoded = RegExp(
              r"printf %s '([^']*)'",
            ).firstMatch(cmd)!.group(1)!;
            diskSource = utf8.decode(base64.decode(encoded));
          }
          if (cmd.contains('find .')) {
            return {'exitCode': 0, 'output': listing};
          }
          // 测试工程视为依赖已解析, 否则打开即自动起「获取依赖」会话
          if (cmd.contains('package_config.json')) {
            return {'exitCode': 0, 'output': 'RESOLVED'};
          }
          if (cmd.contains('base64 <')) {
            return {
              'exitCode': 0,
              'output': base64.encode(
                utf8.encode(
                  cmd.contains('other.dart')
                      ? 'otherFile'
                      : cmd.contains('readme.md')
                      ? mdSource
                      : diskSource,
                ),
              ),
            };
          }
          return {'exitCode': 0, 'output': 'SAVE_OK'};
      }
      return null;
    });
  });

  /// 没给工程就临时开一个(页面不再自建工程), 并在页面销毁时随之关闭——
  /// 与过去"页面销毁即关工程"的节奏一致, 自动保存等定时器不会越过测试边界。
  Future<void> open(WidgetTester tester, {ProjectSession? session}) async {
    final owned = session == null;
    final project =
        session ?? ProjectSession('/project', launcher: services.launcher);
    await tester.pumpWidget(
      AppScope(
        services: services,
        child: MaterialApp(
          theme: flitTheme(),
          navigatorObservers: [services.routeObserver],
          home: RepaintBoundary(
            key: boundary,
            child: _ProjectHost(
              project: project,
              closeOnDispose: owned,
              child: EditorPage(
                projectPath: '/project',
                projectName: 'flit_demo',
                session: project,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field() => find.descendant(
    of: find.byType(CodeField),
    matching: find.byType(TextField),
  );

  /// 关闭项目入口在抽屉底部(非顶栏)。关闭链里的 EventChannel 取消等真实
  /// 异步在 fake-clock 之外完成: 放行几次, 再等路由退出动画静止。
  Future<void> closeProject(WidgetTester tester) async {
    tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.text('关闭项目'));
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
    expect(find.byType(EditorPage), findsNothing, reason: '关闭项目后页面应退出');
  }

  testWidgets('opens main without waiting for project file listing', (
    tester,
  ) async {
    listing = '';
    await open(tester);
    expect(find.byType(CodeField), findsOneWidget);
    expect(tester.widget<TextField>(field()).controller!.text, source);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'opening project drawer refreshes files without a filter or manual refresh',
    (tester) async {
      await open(tester);
      listing = 'lib/main.dart\nlib/other.dart\ngenerated.txt';
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.text('generated.txt'), findsOneWidget);
      expect(find.widgetWithText(TextField, '筛选文件…'), findsNothing);
      tester.state<ScaffoldState>(find.byType(Scaffold).first).closeDrawer();
      await tester.pumpAndSettle();
      listing += '\nnew-file.txt';
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.text('new-file.txt'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('project retains buffers and target until explicitly closed', (
    tester,
  ) async {
    final project = await services.workspace.open('/project');
    await open(tester, session: project);
    await tester.enterText(field(), 'edited');
    project.runTarget = 'web';
    final document = project.documents.current!;
    final controller = document.controller;
    controller.selection = const TextSelection.collapsed(offset: 3);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(project.closed, false);
    expect(await services.workspace.open('/project'), same(project));
    await open(tester, session: project);
    expect(tester.widget<TextField>(field()).controller, same(controller));
    expect(controller.text, 'edited');
    expect(controller.selection.baseOffset, 3);
    expect(project.runTarget, 'web');
    await closeProject(tester);
    // EventChannel cancellation completes outside the widget fake-clock zone.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(project.closed, true);
    expect(services.workspace.active, isNull);
    expect(find.byType(CodeField), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'new typing discards old completion; file switch preserves unsaved buffers',
    (tester) async {
      await open(tester);
      pendingCompletion = Completer<String>();
      await tester.tap(field());
      await tester.enterText(field(), 'St');
      await tester.pump(const Duration(milliseconds: 230));
      await tester.enterText(field(), 'pri');
      pendingCompletion!.complete('{"result":[{"label":"StaleWidget"}]}');
      await tester.pump();
      final bar = tester.widget<CompletionPopup>(find.byType(CompletionPopup));
      expect(bar.items.any((c) => c.label == 'StaleWidget'), false);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      tester
          .widget<FileTreeDrawer>(
            find.byType(FileTreeDrawer, skipOffstage: false),
          )
          .onOpenFile('lib/other.dart');
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field()).controller!.text, 'otherFile');
      expect(find.byType(CompletionPopup), findsNothing);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      tester
          .widget<FileTreeDrawer>(
            find.byType(FileTreeDrawer, skipOffstage: false),
          )
          .onOpenFile('lib/main.dart');
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field()).controller!.text, 'pri');
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );

  testWidgets(
    'renaming the visible document retains editing state and changes the language path',
    (tester) async {
      final project = ProjectSession('/project', launcher: services.launcher);
      await open(tester, session: project);
      await tester.enterText(field(), 'renamed content');
      final controller = project.documents.current!.controller;
      await project.files.rename('/project/lib/main.dart', 'renamed.dart');
      await tester.pumpAndSettle();
      expect(project.documents.current!.path, 'lib/renamed.dart');
      expect(tester.widget<TextField>(field()).controller, same(controller));
      expect(controller.canUndo, true);
      // 标题是工程名, 文件名在 tab 上(只显示文件名)
      expect(find.text('renamed.dart'), findsOneWidget);
      expect(find.text('lib/renamed.dart'), findsNothing);
      expect(
        notifications.any(
          (n) =>
              n['method'] == 'textDocument/didClose' &&
              n['params'].toString().contains('main.dart'),
        ),
        true,
      );
      expect(
        notifications.any(
          (n) =>
              n['method'] == 'textDocument/didOpen' &&
              n['params'].toString().contains('renamed.dart'),
        ),
        true,
      );
      await tester.enterText(field(), 'after rename');
      await project.documents.saveAll();
      expect(
        commands.lastWhere((cmd) => cmd.contains('base64 -d')),
        contains('/project/lib/renamed.dart'),
      );
      await tester.pumpWidget(const SizedBox());
      final closing = project.close();
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await closing;
    },
  );

  testWidgets(
    'autosave failure remains visible and can be retried without losing text',
    (tester) async {
      final project = ProjectSession('/project', launcher: services.launcher);
      await open(tester, session: project);
      failSave = true;
      await tester.enterText(field(), 'unsaved');
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('保存失败 · 点击重试'), findsOneWidget);
      expect(project.documents.current!.dirty, true);
      failSave = false;
      await tester.tap(find.text('保存失败 · 点击重试'));
      await tester.pumpAndSettle();
      expect(find.text('保存失败 · 点击重试'), findsNothing);
      expect(project.documents.current!.controller.text, 'unsaved');
      expect(project.documents.current!.dirty, false);
      await tester.pumpWidget(const SizedBox());
      final closing = project.close();
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await closing;
    },
  );

  testWidgets('physical arrows/Tab accept candidates; Enter stays a newline', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(field());
    await tester.enterText(field(), 'St');
    await tester.pump(const Duration(milliseconds: 230));
    await tester.pumpAndSettle();
    final candidates = tester
        .widget<CompletionPopup>(find.byType(CompletionPopup))
        .items;
    expect(candidates.first.label, 'State', reason: methods.toString());
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      tester.widget<TextField>(field()).controller!.text,
      candidates[1].insert,
    );
    await tester.enterText(field(), 'St');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(tester.widget<TextField>(field()).controller!.text, 'St');
    // Android commits the newline through the text input client.
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'St\n',
        selection: TextSelection.collapsed(offset: 3),
      ),
    );
    await tester.testTextInput.receiveAction(TextInputAction.newline);
    await tester.pump();
    expect(tester.widget<TextField>(field()).controller!.text, 'St\n');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
    'language failure keeps local completion and typing does not rebuild the workbench',
    (tester) async {
      pendingCompletion = Completer<String>();
      await open(tester);
      await tester.tap(field());
      await tester.pumpAndSettle();
      final rebuilt = <Type>[];
      final previous = debugOnRebuildDirtyWidget;
      debugOnRebuildDirtyWidget = (element, builtOnce) {
        rebuilt.add(element.widget.runtimeType);
        previous?.call(element, builtOnce);
      };
      addTearDown(() => debugOnRebuildDirtyWidget = previous);
      await tester.enterText(field(), 'St');
      await tester.pump(const Duration(milliseconds: 230));
      pendingCompletion!.completeError(
        StateError('language server disconnected'),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<CompletionPopup>(find.byType(CompletionPopup)).items,
        isNotEmpty,
      );
      expect(rebuilt, isNot(contains(EditorPage)));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );

  testWidgets('phone preview switches in place and Back returns to code', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final project = ProjectSession('/project', launcher: services.launcher);
    project.runTarget = 'web';
    await open(tester, session: project);
    await tester.tap(find.text('预览'));
    await tester.pumpAndSettle();
    expect(find.text('运行 Web 后在这里预览'), findsOneWidget);
    expect(find.byType(CodeField), findsNothing);
    expect(find.byType(EditorPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(CodeField), findsOneWidget);
    expect(find.byType(EditorPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await closeProject(tester);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('phone layout, expansion and preview', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(tester);
    await tester.tap(field());
    await tester.enterText(field(), source);
    await tester.pump(const Duration(milliseconds: 230));
    await tester.pumpAndSettle();
    expect(find.byType(CompletionPopup), findsOneWidget);
    expect(find.byType(CompletionPopup), findsOneWidget);
    expect(tester.widget<TextField>(field()).focusNode!.hasFocus, true);
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('EDITOR_PREVIEW')) {
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          'build/editor-preview.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(GlobalTerminalPanel), findsNothing);
    await tester.tap(find.byTooltip('展开终端'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<GlobalTerminalPanel>(find.byType(GlobalTerminalPanel))
          .expanded,
      true,
    );
    expect(tester.widget<TextField>(field()).focusNode!.hasFocus, false);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    tester.view.resetViewInsets();
  });

  /// 关闭链里有 fake-clock 外的真实异步: 放行几次再等
  Future<void> closeSession(WidgetTester tester, ProjectSession project) async {
    await tester.pumpWidget(const SizedBox());
    final closing = project.close();
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await closing;
  }

  void openFromDrawer(WidgetTester tester, String path) => tester
      .widget<FileTreeDrawer>(find.byType(FileTreeDrawer, skipOffstage: false))
      .onOpenFile(path);

  testWidgets(
    'open files become tabs; tapping switches, closing picks the neighbour',
    (tester) async {
      final project = ProjectSession('/project', launcher: services.launcher);
      await open(tester, session: project);
      // 标题是工程名, 文件名只在 tab 上
      expect(find.text('flit_demo'), findsOneWidget);
      expect(find.text('main.dart'), findsOneWidget);
      expect(find.text('lib/main.dart'), findsNothing);
      final mainDoc = (project.tabs.current! as CodeTab).document;

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      openFromDrawer(tester, 'lib/other.dart');
      await tester.pumpAndSettle();
      expect(project.tabs.items.map((t) => t.path), [
        'lib/main.dart',
        'lib/other.dart',
      ]);
      expect(project.tabs.current!.path, 'lib/other.dart');
      expect(tester.widget<TextField>(field()).controller!.text, 'otherFile');

      await tester.tap(find.text('main.dart'));
      await tester.pumpAndSettle();
      expect(project.tabs.current!.path, 'lib/main.dart');
      expect(
        tester.widget<TextField>(field()).controller,
        same(mainDoc.controller),
      );

      // ✕ 只在当前项上; 关掉后选邻居, 缓冲一起释放
      expect(find.byTooltip('关闭 other.dart'), findsNothing);
      await tester.tap(find.byTooltip('关闭 main.dart'));
      await tester.pumpAndSettle();
      expect(project.tabs.items.map((t) => t.path), ['lib/other.dart']);
      expect(project.tabs.current!.path, 'lib/other.dart');
      expect(project.documents.contains(mainDoc), isFalse);
      expect(find.text('main.dart'), findsNothing);
      expect(tester.widget<TextField>(field()).controller!.text, 'otherFile');
      await closeSession(tester, project);
    },
  );

  testWidgets('markdown files toggle a rendered preview', (tester) async {
    listing = 'lib/main.dart\nreadme.md';
    final project = ProjectSession('/project', launcher: services.launcher);
    await open(tester, session: project);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    openFromDrawer(tester, 'readme.md');
    await tester.pumpAndSettle();
    expect(find.text('MD'), findsOneWidget);
    await tester.tap(find.text('MD'));
    await tester.pumpAndSettle();
    expect(find.text('Flit README'), findsOneWidget);
    expect(find.text('item one'), findsOneWidget);
    await tester.tap(find.text('代码'));
    await tester.pumpAndSettle();
    expect(find.byType(CodeField), findsOneWidget);
    await closeSession(tester, project);
  });
  testWidgets('binary files open as a file card instead of the editor', (
    tester,
  ) async {
    final project = ProjectSession('/project', launcher: services.launcher);
    await open(tester, session: project);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    openFromDrawer(tester, 'build/app/outputs/flutter-apk/app-debug.apk');
    await tester.pumpAndSettle();
    expect(
      project.tabs.current,
      isA<FileTab>().having((t) => t.kind, 'kind', FileKind.binary),
    );
    expect(field(), findsNothing);
    expect(find.text('安装到本机'), findsOneWidget);
    // APK 只保留安装语义: 不提供外部打开, 也不再支持以文本打开
    expect(find.text('用其他应用打开'), findsNothing);
    expect(find.text('分享'), findsOneWidget);
    expect(find.text('以文本打开'), findsNothing);
    // 卡片用 dart:io 读 stat(真实异步): 放行一次; 测试机上文件不存在 → 如实说明, 动作禁用
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
    expect(find.text('文件不存在'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '安装到本机'))
          .onPressed,
      isNull,
    );
    // 代码 tab 还在, 点回去编辑器回来
    await tester.tap(find.text('main.dart'));
    await tester.pumpAndSettle();
    expect(field(), findsOneWidget);
    expect(project.tabs.items.length, 2);
    await closeSession(tester, project);
  });
}

/// 测试里替代"页面自建工程": 临时工程随宿主销毁而关闭。
class _ProjectHost extends StatefulWidget {
  const _ProjectHost({
    required this.project,
    required this.closeOnDispose,
    required this.child,
  });

  final ProjectSession project;
  final bool closeOnDispose;
  final Widget child;

  @override
  State<_ProjectHost> createState() => _ProjectHostState();
}

class _ProjectHostState extends State<_ProjectHost> {
  @override
  void dispose() {
    if (widget.closeOnDispose) unawaited(widget.project.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
