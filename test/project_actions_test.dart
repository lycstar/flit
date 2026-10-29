import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/run/web_runner.dart';
import 'package:flit/features/terminal/run_sessions.dart';
import 'package:flit/features/workspace/project_actions.dart';
import 'package:flit/features/workspace/project_documents.dart';

import 'support/fake_session_process.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProjectDocuments documents;
  late RunSessions executions;
  late WebRunController web;
  late ProjectActions actions;
  final processes = <FakeProcess>[];
  final commands = <String?>[];
  bool saveSucceeds = true;
  List<(String, String)> onlineDevices = [('phone', 'Phone')];
  Completer<bool>? pendingSave;
  Completer<List<(String, String)>>? pendingDevices;

  setUp(() async {
    processes.clear();
    commands.clear();
    saveSucceeds = true;
    onlineDevices = [('phone', 'Phone')];
    pendingSave = null;
    pendingDevices = null;
    documents = ProjectDocuments(
      '/project',
      read: (_) async => 'old',
      write: (_, _) async => pendingSave?.future ?? saveSucceeds,
    );
    executions = RunSessions(
      projectPath: '/project',
      launcher:
          ({
            required command,
            required workingDirectory,
            required rows,
            required columns,
          }) async {
            commands.add(command);
            final process = FakeProcess();
            processes.add(process);
            return process;
          },
    );
    web = WebRunController(executions, allocatePort: () async => 12345);
    actions = ProjectActions(
      path: '/project',
      documents: documents,
      executions: executions,
      web: web,
      devices: () async => pendingDevices?.future ?? onlineDevices,
    );
    await documents.open('main.dart');
    documents.current!.controller.text = 'edited';
  });

  tearDown(() async {
    actions.dispose();
    web.dispose();
    await executions.closeAll();
    await documents.close();
  });

  test('failed save prevents both native and Web launches', () async {
    saveSucceeds = false;
    await expectLater(actions.run('phone'), throwsStateError);
    await expectLater(actions.run('web'), throwsStateError);
    expect(processes, isEmpty);
    expect(web.state, WebRunState.idle);
    expect(documents.current!.dirty, true);
  });

  test('close while checking devices prevents a later launch', () async {
    pendingDevices = Completer<List<(String, String)>>();
    final running = actions.run('phone');
    final assertion = expectLater(running, throwsStateError);
    actions.dispose();
    pendingDevices!.complete([('phone', 'Phone')]);
    await assertion;
    expect(processes, isEmpty);
  });

  test('build is exclusive: tools and runs cannot start beside it', () async {
    final build = await actions.build(ProjectBuild.debugApk);
    await expectLater(
      actions.tool(ProjectTool.pubGet, flutter: true),
      throwsStateError,
    );
    await expectLater(actions.run('phone'), throwsStateError);
    expect(commands, ['flutter build apk --debug --target-platform android-arm64 2>&1']);
    await processes.single.finish();
    await build.done;
  });

  test('build completion only reports; installing is a manual step', () async {
    final artifacts = <String>[];
    final watch = actions.builtArtifacts.listen(artifacts.add);
    final build = await actions.build(ProjectBuild.debugApk);
    await processes.single.finish();
    await build.done;
    await Future<void>.delayed(Duration.zero);
    // 没有自动安装: 只有构建本身这一条命令; 产物位置通过流报给编辑器开文件卡
    expect(commands, ['flutter build apk --debug --target-platform android-arm64 2>&1']);
    expect(artifacts, ['build/app/outputs/flutter-apk/app-debug.apk']);
    await watch.cancel();
  });

  test('a failed or stopped build reports no artifact', () async {
    final artifacts = <String>[];
    final watch = actions.builtArtifacts.listen(artifacts.add);
    final build = await actions.build(ProjectBuild.releaseApk);
    await processes.single.finish(1);
    await build.done;
    await Future<void>.delayed(Duration.zero);
    expect(artifacts, isEmpty);
    await watch.cancel();
  });

  test(
    'reload keeps its original execution if rerun happens during save',
    () async {
      await actions.run('phone');
      final old = processes.single;
      documents.current!.controller.text = 'new';
      pendingSave = Completer<bool>();
      final reload = actions.reload('phone', fullRestart: false);
      final config = executions.forConfiguration('run:phone')!.configuration;
      await executions.start(config);
      pendingSave!.complete(true);
      await reload;
      expect(old.writes, isNot(contains('r')));
      expect(processes.last.writes, isNot(contains('r')));
    },
  );
}
