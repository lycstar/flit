import 'package:flit/core/theme.dart';
import 'package:flit/features/environment/environment_controller.dart';
import 'package:flit/features/environment/installed_toolchain.dart';
import 'package:flit/features/environment/widgets/installed_toolchain_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('installation excludes checks and other task launches', () async {
    final env = EnvironmentController(
      launcher:
          ({
            required command,
            required workingDirectory,
            required rows,
            required columns,
          }) async => throw StateError('must not launch another process'),
    );
    addTearDown(env.dispose);
    env.installing = true;
    expect(env.busy, isTrue);
    await env.refreshStatus();
    await env.probeNetwork();
    await env.startPipeline();
    expect(env.checking, isFalse);
    expect(env.pipelineRunning, isFalse);
    expect(env.console, isNull);
  });

  testWidgets(
    'installed versions switch offline and require deletion confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final actions = <String>[];
      final tools = [
        InstalledToolchain.parse('__TOOL__flutter/3.47.8|1024|1|1|')!,
        InstalledToolchain.parse('__TOOL__flutter/3.47.7|2048|0|1|')!,
        InstalledToolchain.parse(
          '__TOOL__ndk/28.2.13676358|4096|0|1|28.2.13676358',
        )!,
      ];
      Future<void> render({bool busy = false}) => tester.pumpWidget(
        MaterialApp(
          theme: flitTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  for (final tool in tools)
                    InstalledToolchainTile(
                      tool: tool,
                      busy: busy,
                      onChange: (tool, {bool delete = false}) async =>
                          actions.add('${tool.path}:$delete'),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await render();
      expect(find.text('Flutter 3.47.8 · 当前'), findsOneWidget);
      await tester.tap(find.byTooltip('管理版本').at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('使用此版本'));
      await tester.pumpAndSettle();
      expect(actions, ['flutter/3.47.7:false']);
      await tester.tap(find.byTooltip('管理版本').at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除版本'));
      await tester.pumpAndSettle();
      expect(actions, hasLength(1));
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(actions, hasLength(1));
      await tester.tap(find.byTooltip('管理版本').at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除版本'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      expect(actions.last, 'ndk/28.2.13676358:true');
      await render(busy: true);
      await tester.tap(find.byTooltip('管理版本').first);
      await tester.pumpAndSettle();
      expect(find.text('先切换版本再删除'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
