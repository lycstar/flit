import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/editor/widgets/editor_run_controls.dart';
import 'package:flit/features/terminal/console_session.dart';
import 'package:flit/features/workspace/project_actions.dart';
import 'package:flit/features/workspace/project_session.dart';

import 'support/fake_session_process.dart';
import 'support/project_scope.dart';
import 'support/flit_plugins.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late ProjectSession project;
  final processes = <FakeProcess>[];
  Completer<SessionProcess>? pendingLaunch;

  setUp(() {
    processes.clear();
    pendingLaunch = null;
    // 工程关闭要 dispose 语言服务(flit/lsp), 会话启动要保活(flit/work)
    mockFlitPlugins(binding.defaultBinaryMessenger);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flit/env'),
      (call) async {
        if (call.method == 'exec') {
          final command = (call.arguments as Map)['cmd'] as String;
          if (command.contains("'rev-parse'")) {
            return {
              'exitCode': 0,
              'output': command.contains("'--show-prefix'") ? '' : '/project\n',
            };
          }
          if (command.contains("'status'")) {
            return {'exitCode': 0, 'output': '## main\x00'};
          }
          return {
            'exitCode': 0,
            'output':
                'List of devices attached\nphone device model:Phone\ntablet device model:Tablet\n',
          };
        }
        return true;
      },
    );
    project = ProjectSession(
      '/project',
      launcher:
          ({
            required command,
            required workingDirectory,
            required rows,
            required columns,
          }) async {
            final process = FakeProcess();
            processes.add(process);
            return pendingLaunch?.future ?? process;
          },
    );
    project.runTarget = 'phone';
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      scopedProject(
        session: project,
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(actions: const [EditorRunControls()]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    final closing = project.close();
    for (var i = 0; i < 8; i++) {
      await tester.pump();
    }
    expect(await closing, true);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flit/env'),
      null,
    );
  }

  IconButton button(WidgetTester tester, String tooltip) =>
      tester.widget<IconButton>(
        find.byWidgetPredicate(
          (widget) => widget is IconButton && widget.tooltip == tooltip,
        ),
      );
  ListTile task(WidgetTester tester, String title) => tester.widget<ListTile>(
    find.ancestor(of: find.text(title), matching: find.byType(ListTile)),
  );

  testWidgets(
    'run controls bind to target during startup, shell browsing and stop',
    (tester) async {
      pendingLaunch = Completer<SessionProcess>();
      await open(tester);
      await tester.tap(find.byTooltip('运行'));
      await tester.pump();
      expect(button(tester, '正在启动').onPressed, isNull);
      pendingLaunch!.complete(processes.single);
      await tester.pumpAndSettle();
      project.executions.select(null);
      await tester.pump();
      expect(button(tester, '重新运行').onPressed, isNotNull);
      await tester.tap(find.byTooltip('热重载'));
      await tester.pump();
      expect(processes.single.writes, contains('r'));
      await tester.tap(find.byTooltip('停止运行'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('热重载'), findsNothing);
      expect(find.byTooltip('停止运行'), findsNothing);
      expect(button(tester, '运行').onPressed, isNotNull);
      await close(tester);
    },
  );

  testWidgets(
    'task menu disables conflicts, selects existing output and updates on completion',
    (tester) async {
      await open(tester);
      final running = await project.actions.tool(
        ProjectTool.analyze,
        flutter: true,
      );
      project.executions.select(null);
      await tester.pump();
      // analyze 与 run 并存(按冲突面互斥), 运行按钮保持可用
      expect(button(tester, '运行').onPressed, isNotNull);
      await tester.tap(find.byTooltip('任务'));
      await tester.pumpAndSettle();
      expect(task(tester, '清理构建产物').onTap, isNull);
      expect(task(tester, '静态分析').onTap, isNotNull);
      await processes.single.finish();
      await tester.pumpAndSettle();
      expect(task(tester, '清理构建产物').onTap, isNotNull);
      Navigator.of(tester.element(find.text('任务').last)).pop();
      await tester.pumpAndSettle();
      expect(running.alive, false);
      expect(button(tester, '运行').onPressed, isNotNull);
      await close(tester);
    },
  );

  testWidgets(
    'switching an active device requires confirmation and replaces its session',
    (tester) async {
      await open(tester);
      await tester.tap(find.byTooltip('运行'));
      await tester.pumpAndSettle();
      final first = project.executions.active!;
      await tester.tap(find.text('Phone'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tablet'));
      await tester.pumpAndSettle();
      expect(find.text('切换运行目标？'), findsOneWidget);
      expect(first.alive, true);
      await tester.tap(find.text('切换并运行'));
      await tester.pumpAndSettle();
      expect(first.disposed, true);
      expect(project.runTarget, 'tablet');
      expect(
        project.executions.all.where((session) => session.alive),
        hasLength(1),
      );
      expect(project.executions.active!.configuration.target, 'tablet');
      await close(tester);
    },
  );

  testWidgets('Git and run share the busy state through completion', (
    tester,
  ) async {
    await open(tester);
    final staging = project.git.stageAll();
    await tester.pumpAndSettle();
    expect(project.git.busy, true);
    expect(button(tester, '运行').onPressed, isNull);
    await expectLater(project.actions.run('phone'), throwsStateError);
    await processes.single.finish();
    await tester.pumpAndSettle();
    await staging;
    expect(project.git.busy, false);
    expect(button(tester, '运行').onPressed, isNotNull);
    await tester.tap(find.byTooltip('运行'));
    await tester.pumpAndSettle();
    await expectLater(project.git.stageAll(), throwsStateError);
    expect(processes, hasLength(2));
    await close(tester);
  });
}
