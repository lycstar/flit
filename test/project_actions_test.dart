import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/run/web_runner.dart';
import 'package:flit/features/environment/android_build_wrapper.dart';
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

  test('build blocks another writer and a new run', () async {
    final build = await actions.build(ProjectBuild.debugApk);
    await expectLater(
      actions.tool(ProjectTool.pubGet, flutter: true),
      throwsStateError,
    );
    await expectLater(actions.run('phone'), throwsStateError);
    expect(commands, [
      'bash "\$HOME/.flit/scripts/android_build.sh" flutter build apk --debug --target-platform android-arm64 2>&1',
    ]);
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
    expect(commands, [
      'bash "\$HOME/.flit/scripts/android_build.sh" flutter build apk --debug --target-platform android-arm64 2>&1',
    ]);
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
  test(
    'APK build uses its own session while device run remains connected',
    () async {
      await actions.run('phone');
      final run = executions.forConfiguration('run:phone')!;
      final deviceProcess = processes.single;
      final build = await actions.build(ProjectBuild.releaseApk);
      expect(build, isNot(same(run)));
      expect(run.alive, true);
      expect(deviceProcess.writes, isEmpty);
      expect(executions.selected, same(build));
      expect(await actions.build(ProjectBuild.releaseApk), same(build));
      expect(processes, hasLength(2));
      await expectLater(
        actions.reload('phone', fullRestart: false),
        throwsStateError,
      );
      await expectLater(
        actions.tool(ProjectTool.clean, flutter: true),
        throwsStateError,
      );
      await expectLater(actions.build(ProjectBuild.debugApk), throwsStateError);
      await processes.last.finish();
      await build.done;
      await actions.reload('phone', fullRestart: false);
      expect(deviceProcess.writes, ['r']);
      expect(run.alive, true);
    },
  );

  test('read-only tools can start before or during run and build', () async {
    final analysis = await actions.tool(ProjectTool.analyze, flutter: true);
    expect(commands.single, 'flutter analyze --no-pub 2>&1');
    await actions.run('phone');
    final run = executions.forConfiguration('run:phone')!;
    final build = await actions.build(ProjectBuild.debugApk);
    final doctor = await actions.tool(ProjectTool.doctor, flutter: true);
    expect([analysis, run, build, doctor].every((s) => s.alive), true);
    expect(processes, hasLength(4));
    await executions.close(build.id);
    expect(analysis.alive && run.alive && doctor.alive, true);
  });

  test(
    'clean is actually exclusive even when invoked outside the menu',
    () async {
      final clean = await actions.tool(ProjectTool.clean, flutter: true);
      expect(clean.configuration.exclusive, true);
      await expectLater(actions.run('phone'), throwsStateError);
      await expectLater(
        actions.tool(ProjectTool.doctor, flutter: true),
        throwsStateError,
      );
      await expectLater(actions.build(ProjectBuild.debugApk), throwsStateError);
    },
  );
  test('environment installation blocks new tools, builds and runs', () async {
    AndroidBuildWrapper.installing = true;
    try {
      await expectLater(
        actions.tool(ProjectTool.analyze, flutter: true),
        throwsStateError,
      );
      await expectLater(actions.run('phone'), throwsStateError);
      await expectLater(actions.build(ProjectBuild.debugApk), throwsStateError);
      expect(processes, isEmpty);
    } finally {
      AndroidBuildWrapper.installing = false;
    }
  });
}
