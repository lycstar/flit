import 'dart:async';

import 'package:flit/core/theme.dart';
import 'package:flit/features/environment/environment_controller.dart';
import 'package:flit/features/environment/installed_toolchain.dart';
import 'package:flit/features/environment/toolchain_catalog.dart';
import 'package:flit/features/environment/toolchain_component.dart';
import 'package:flit/features/environment/widgets/component_versions_sheet.dart';
import 'package:flit/features/environment/widgets/toolchain_components_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'toolchain_catalog_test.dart' show release;

void main() {
  late EnvironmentController env;
  late ToolchainCatalog catalog;
  late List<String> actions;
  var requests = 0;
  setUp(() {
    env = EnvironmentController(
      launcher:
          ({
            required command,
            required workingDirectory,
            required rows,
            required columns,
          }) async => throw StateError('unexpected process'),
    )..installedLoaded = true;
    env.stages['bootstrap']!.state = 'DONE';
    actions = [];
    requests = 0;
    catalog =
        ToolchainCatalog(
            sources: {
              'flutter-sdk': ToolchainCatalog.components['flutter-sdk']!,
            },
          )
          ..fetchJson = (_) async {
            requests++;
            return [
              for (final version in ['3.47.8', '3.47.7', '3.48.0'])
                release(
                  'flutter-$version',
                  '',
                  assets: [
                    {
                      'name': 'flutter-$version-aarch64-linux-android.tar.xz',
                      'size': 100,
                      'digest': 'aa',
                    },
                  ],
                ),
            ];
          };
  });
  tearDown(() => env.dispose());

  Widget section() => ToolchainComponentsSection(
    environment: env,
    catalog: catalog,
    onInstall: (e) async => actions.add('install:${e.tag}'),
    onChange: (t, {bool delete = false}) async =>
        actions.add('${t.path}:$delete'),
  );

  Future<void> render(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      theme: flitTheme(),
      home: Scaffold(
        body: ListView(
          children: [
            const SizedBox(height: 700),
            section(),
            const SizedBox(height: 700),
          ],
        ),
      ),
    ),
  );

  Future<void> openFlutter(WidgetTester tester) async {
    await tester.scrollUntilVisible(find.text('Flutter SDK'), 180);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flutter SDK'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'scroll and remount never fetch; reopen uses cache, manual refresh fetches once',
    (tester) async {
      await render(tester);
      await tester.scrollUntilVisible(find.text('Flutter SDK'), 180);
      await tester.pumpAndSettle();
      expect(requests, 0);
      await tester.drag(find.byType(ListView), const Offset(0, -1400));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 1400));
      await tester.pumpAndSettle();
      expect(requests, 0);
      await openFlutter(tester);
      expect(requests, 1);
      expect(find.text('3.48.0'), findsOneWidget);
      await tester.tap(find.byTooltip('关闭'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await render(tester);
      await openFlutter(tester);
      expect(requests, 1);
      await tester.tap(find.byTooltip('刷新可下载版本'));
      await tester.pumpAndSettle();
      expect(requests, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'local state excludes installed downloads and broken versions offer repair',
    (tester) async {
      env.installed = [
        InstalledToolchain.parse('__TOOL__flutter/3.47.8|1024|1|1|')!,
        InstalledToolchain.parse('__TOOL__flutter/3.47.7|1024|0|0|')!,
      ];
      await render(tester);
      await openFlutter(tester);
      expect(find.text('Flutter 3.47.8 · 当前'), findsOneWidget);
      expect(find.text('3.47.8'), findsNothing);
      expect(find.text('3.47.7'), findsNothing);
      expect(find.text('3.48.0'), findsOneWidget);
      await tester.tap(find.byTooltip('管理版本').at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('修复安装'));
      await tester.pumpAndSettle();
      expect(actions, ['install:flutter-3.47.7']);
      expect(find.byType(ComponentVersionsSheet), findsNothing);
    },
  );

  testWidgets('offline download failure leaves local switch available', (
    tester,
  ) async {
    catalog.fetchJson = (_) async {
      requests++;
      throw Exception('offline');
    };
    env.installed = [
      InstalledToolchain.parse('__TOOL__flutter/3.47.7|1024|0|1|')!,
    ];
    await render(tester);
    await openFlutter(tester);
    expect(find.textContaining('获取版本失败'), findsOneWidget);
    await tester.tap(find.byTooltip('管理版本'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('使用此版本'));
    await tester.pumpAndSettle();
    expect(actions, ['flutter/3.47.7:false']);
    await openFlutter(tester);
    expect(requests, 1);
  });

  testWidgets(
    'inventory failure is unknown, not missing, and disables writes',
    (tester) async {
      env.installedError = '组件检测失败';
      env.installedLoaded = false;
      await render(tester);
      await openFlutter(tester);
      expect(find.text('未安装'), findsNothing);
      expect(find.text('安装状态待确认'), findsWidgets);
      await tester.tap(find.text('3.48.0'));
      await tester.pumpAndSettle();
      expect(actions, isEmpty);
    },
  );

  testWidgets(
    'close while loading is safe and next sheet joins pending request',
    (tester) async {
      final pending = Completer<Object?>();
      catalog.fetchJson = (_) {
        requests++;
        return pending.future;
      };
      await render(tester);
      await tester.scrollUntilVisible(find.text('Flutter SDK'), 180);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Flutter SDK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byTooltip('关闭'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Flutter SDK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(requests, 1);
      pending.complete([]);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shared tool replacement is explicit and fits a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    catalog =
        ToolchainCatalog(
            sources: {
              'platform-tools': ToolchainCatalog.components['platform-tools']!,
            },
          )
          ..fetchJson = (_) async => [
            for (final version in ['35.0.0', '36.0.0'])
              release(
                'sdk-$version',
                '',
                assets: [
                  {
                    'name': 'platform-tools.tar.xz',
                    'size': 100,
                    'digest': 'aa',
                  },
                ],
              ),
          ];
    env.installed = [
      InstalledToolchain.parse(
        '__TOOL__android-sdk/platform-tools|10|0|1|35.0.2',
      )!,
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: flitTheme(),
        home: Scaffold(body: ListView(children: [section()])),
      ),
    );
    await tester.tap(find.text('Platform Tools'));
    await tester.pumpAndSettle();
    expect(find.text('Platform Tools 35.0.2'), findsOneWidget);
    expect(find.text('配套工具包 · sdk-35.0.0'), findsNothing);
    await tester.ensureVisible(find.text('配套工具包 · sdk-36.0.0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('配套工具包 · sdk-36.0.0'));
    await tester.pumpAndSettle();
    expect(actions, isEmpty);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(actions, isEmpty);
    await tester.tap(find.text('配套工具包 · sdk-36.0.0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('替换'));
    await tester.pumpAndSettle();
    expect(actions, ['install:sdk-36.0.0']);
    expect(tester.takeException(), isNull);
  });

  test(
    'bundles are not components; NDK matches digest, shared tools use default package only',
    () {
      expect(
        ToolchainComponent.all.map((c) => c.id),
        isNot(contains('android-sdk')),
      );
      final hash = 'a' * 64;
      final ndk = ToolchainComponent.all.firstWhere((c) => c.id == 'ndk');
      final tool = InstalledToolchain.parse(
        '__TOOL__ndk/28.2.13676358|10|0|1|28.2.13676358|$hash',
      )!;
      CatalogEntry entry(String id, String tag, String digest) => CatalogEntry(
        component: id,
        repo: 'test/repo',
        tag: tag,
        name: 'tool.tar.xz',
        url: 'https://example.test/tool',
        size: 1,
        sha256: digest,
      );
      expect(ndk.matches(tool, entry('ndk', 'ndk-r28c', hash)), isTrue);
      expect(ndk.matches(tool, entry('ndk', 'ndk-r28c', 'b' * 64)), isFalse);
      final adb = ToolchainComponent.all.firstWhere(
        (c) => c.id == 'platform-tools',
      );
      final available = adb.downloads(ToolchainCatalog(), {
        'platform-tools': [
          entry('platform-tools', 'sdk-35.0.0', hash),
          entry('platform-tools', 'sdk-36.0.0', hash),
        ],
      }, []);
      expect(available.single.tag, 'sdk-36.0.0');
      expect(adb.versionLabel(available.single), '配套工具包 · sdk-36.0.0');
    },
  );
}
