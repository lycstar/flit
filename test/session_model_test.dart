import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flit/features/terminal/console_session.dart';
import 'package:flit/features/terminal/pty_session.dart';
import 'package:flit/features/terminal/run_sessions.dart';
import 'package:flit/features/workspace/project_documents.dart';

import 'support/fake_session_process.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'PTY byte streams decode UTF-8 characters split across chunks',
    () async {
      final process = FakeProcess();
      final console = ConsoleSession(
        title: 'terminal',
        launcher:
            ({
              required command,
              required workingDirectory,
              required rows,
              required columns,
            }) async => process,
      );
      final output = <String>[];
      console.textStream.listen(output.add);
      await console.start();
      expect(console.state, ExecutionState.running);
      final bytes = Uint8List.fromList(utf8.encode('终端已启动\n'));
      process.chunks.add(Uint8List.sublistView(bytes, 0, 1));
      process.chunks.add(Uint8List.sublistView(bytes, 1, 5));
      process.chunks.add(Uint8List.sublistView(bytes, 5));
      await process.finish();
      expect(await console.done, 0);
      expect(output.join(), '终端已启动\n');
      await console.close();
    },
  );

  test(
    'done waits for trailing output and preserves nonzero exit code',
    () async {
      final process = FakeProcess();
      final console = ConsoleSession(
        title: 'build',
        launcher:
            ({
              required command,
              required workingDirectory,
              required rows,
              required columns,
            }) async => process,
      );
      final output = <String>[];
      console.textStream.listen(output.add);
      await console.start(command: 'build');
      bool done = false;
      console.done.then((_) => done = true);
      process.exited.complete(42);
      await Future<void>.delayed(Duration.zero);
      expect(done, false);
      process.emit('last error\n');
      await process.chunks.close();
      expect(await console.done, 42);
      expect(output.join(), 'last error\n');
      expect(console.state, ExecutionState.failed);
      await console.close();
    },
  );

  test(
    'concurrent start deduplicates and rerun waits for previous process',
    () async {
      final processes = <FakeProcess>[];
      final commands = <String?>[];
      final registry = RunSessions(
        projectPath: '/one',
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
      const configuration = RunConfiguration(
        id: 'run:web',
        title: 'Web',
        command: 'run',
        kind: SessionKind.run,
        hotReload: true,
        target: 'web',
      );
      final first = registry.start(configuration);
      final concurrent = registry.start(configuration);
      expect(identical(await first, await concurrent), true);
      expect(processes.length, 1);
      final old = await first;
      processes.first.stopOnInterrupt = false;
      final rerun = registry.start(configuration);
      await Future<void>.delayed(Duration.zero);
      expect(processes.length, 1);
      expect(old.state, ExecutionState.stopping);
      await processes.first.finish(130);
      final current = await rerun;
      expect(current.id, isNot(old.id));
      expect(processes.length, 2);
      expect(current.supportsReload, true);
      registry.select(null);
      expect(registry.forConfiguration('run:web'), same(current));
      const build = RunConfiguration(
        id: 'build',
        title: 'Build',
        command: 'build',
        kind: SessionKind.temp,
        exclusive: true,
      );
      await expectLater(registry.start(build), throwsStateError);
      await current.stop();
      final buildSession = await registry.start(build);
      expect(buildSession.supportsReload, false);
      expect(await registry.start(build), same(buildSession));
      expect(registry.selected, same(buildSession));
      expect(commands, ['run', 'run', 'build']);
      await registry.closeAll();
      expect(processes.every((p) => p.exited.isCompleted), true);
    },
  );

  test(
    'close during startup stops only that project and rejects new starts',
    () async {
      final startup = Completer<SessionProcess>();
      final firstProcess = FakeProcess();
      final secondProcess = FakeProcess();
      final first = RunSessions(
        projectPath: '/one',
        launcher:
            ({
              required command,
              required workingDirectory,
              required rows,
              required columns,
            }) => startup.future,
      );
      final second = RunSessions(
        projectPath: '/two',
        launcher:
            ({
              required command,
              required workingDirectory,
              required rows,
              required columns,
            }) async => secondProcess,
      );
      const configuration = RunConfiguration(
        id: 'device',
        title: 'Device',
        command: 'run',
      );
      final launching = first.start(configuration);
      final other = await second.start(configuration);
      final closing = first.closeAll();
      startup.complete(firstProcess);
      await launching;
      await closing;
      expect(firstProcess.exited.isCompleted, true);
      expect(other.alive, true);
      await expectLater(first.start(configuration), throwsStateError);
      await second.closeAll();
    },
  );

  test(
    'one managed run switches targets and temporary tasks exclude runs',
    () async {
      final processes = <FakeProcess>[];
      final sessions = RunSessions(
        projectPath: '/project',
        launcher:
            ({
              required command,
              required workingDirectory,
              required rows,
              required columns,
            }) async {
              final process = FakeProcess();
              processes.add(process);
              return process;
            },
      );
      const web = RunConfiguration(
        id: 'run:web',
        title: 'Web',
        command: 'web',
        kind: SessionKind.run,
      );
      const phone = RunConfiguration(
        id: 'run:phone',
        title: 'Phone',
        command: 'phone',
        kind: SessionKind.run,
      );
      const build = RunConfiguration(
        id: 'build',
        title: 'Build',
        command: 'build',
        exclusive: true,
      );
      const clean = RunConfiguration(
        id: 'clean',
        title: 'Clean',
        command: 'clean',
        exclusive: true,
      );
      const pubGet = RunConfiguration(
        id: 'pub-get',
        title: '获取依赖',
        command: 'pub get',
      );
      try {
        final first = await sessions.start(web);
        final second = await sessions.start(phone);
        expect(first.stopRequested, true);
        expect(first.disposed, true);
        expect(sessions.forConfiguration('run:web'), isNull);
        expect(sessions.active, same(second));
        await expectLater(sessions.start(build), throwsStateError);
        await second.stop();
        final task = await sessions.start(build);
        sessions.select(null);
        expect(await sessions.start(build), same(task));
        expect(sessions.selected, same(task));
        await expectLater(sessions.start(clean), throwsStateError);
        await expectLater(sessions.start(web), throwsStateError);
        expect(processes, hasLength(3));
        await task.close();
        expect((await sessions.start(web)).alive, true);
        // run 活着时, 非独占工具任务(pub get)可以并存——hot reload 开发循环
        final run = await sessions.start(web);
        final tool = await sessions.start(pubGet);
        expect(tool.alive, true);
        await expectLater(sessions.start(build), throwsStateError);
        await run.stop();
        await tool.stop();
      } finally {
        await sessions.closeAll();
      }
    },
  );

  test(
    'save serializes snapshots edited during write and retains controller on switch',
    () async {
      final pending = Completer<bool>();
      final writes = <String>[];
      final disk = <String, String>{};
      final documents = ProjectDocuments(
        '/project',
        read: (path) async => disk[path] ?? 'original',
        write: (path, text) async {
          writes.add(text);
          final saved = writes.length == 1 ? await pending.future : true;
          if (saved) disk[path] = text;
          return saved;
        },
      );
      await documents.open('main.dart');
      final controller = documents.current!.controller;
      controller.text = 'first';
      final saving = documents.saveAll();
      controller.text = 'second';
      pending.complete(true);
      expect(await saving, true);
      expect(writes, ['first', 'second']);
      expect(documents.current!.dirty, false);
      await documents.open('other.dart');
      await documents.open('main.dart');
      expect(documents.current!.controller, same(controller));
      expect(controller.text, 'second');
      final dirtyStates = <bool>[];
      documents.addListener(() {
        final current = documents.current;
        if (current != null) dirtyStates.add(current.dirty);
      });
      controller.text = 'third';
      controller.text = 'second';
      expect(dirtyStates.last, false);
      await documents.close();
    },
  );

  testWidgets(
    'caret movement neither notifies the workspace nor postpones autosave',
    (tester) async {
      final writes = <String>[];
      final documents = ProjectDocuments(
        '/p',
        read: (_) async => 'old',
        write: (_, text) async {
          writes.add(text);
          return true;
        },
      );
      await documents.open('main.dart');
      final code = documents.current!.controller;
      var changes = 0;
      documents.addListener(() => changes++);
      code.text = 'new';
      expect(changes, 1);
      await tester.pump(const Duration(milliseconds: 800));
      code.selection = const TextSelection.collapsed(offset: 1);
      code.setDiagnostics(const []);
      expect(changes, 1);
      await tester.pump(const Duration(milliseconds: 250));
      expect(writes, ['new']);
      final closing = documents.close();
      await tester.pump();
      await closing;
    },
  );

  test('failed save leaves buffer dirty and retry writes it', () async {
    bool fail = true;
    final documents = ProjectDocuments(
      '/project',
      read: (_) async => 'old',
      write: (_, text) async => !fail,
    );
    await documents.open('main.dart');
    documents.current!.controller.text = 'new';
    expect(await documents.saveAll(), false);
    expect(documents.current!.dirty, true);
    expect(documents.saveFailed, true);
    documents.current!.controller.text = 'old';
    expect(documents.dirty, false);
    expect(documents.saveFailed, false);
    documents.current!.controller.text = 'new';
    fail = false;
    expect(await documents.saveAll(), true);
    expect(documents.current!.savedText, 'new');
    await documents.close();
  });

  test(
    'a non-process task is the session task: alive, stop flag, done',
    () async {
      final console = ConsoleSession(title: '环境配置', launcher: noProcess);
      expect(console.alive, false);
      console.beginTask();
      expect(console.alive, true);
      expect(console.state, ExecutionState.running);
      // 停止只置旗标并等任务收尾: 不 kill、不卡死
      final stopping = console.stop();
      expect(console.stopRequested, true);
      expect(console.state, ExecutionState.stopping);
      console.endTask(code: 1);
      await stopping;
      expect(console.alive, false);
      expect(console.state, ExecutionState.exited); // 用户主动停止不算失败
      expect(await console.done, 1);
      console.beginTask(); // 可继续登记下一任务
      console.endTask();
      expect(console.state, ExecutionState.exited);
      await console.close();
    },
  );

  test('session kinds: shell inputs, run stops, temp only closes', () async {
    // 默认 shell: 可输入, 永不"可停"(中断前台命令走 CTRL+C)
    final shell = PtySession(launcher: noProcess);
    expect(shell.kind, SessionKind.shell);
    expect(shell.interactive, true);
    expect(shell.stoppable, false);

    // run: 只读, 任务在跑时可停而不丢
    final run = ConsoleSession(
      title: 'run',
      kind: SessionKind.run,
      launcher: noProcess,
    );
    expect(run.interactive, false);
    run.beginTask();
    expect(run.stoppable, true);
    run.endTask();
    expect(run.stoppable, false);
    await run.close();

    // temp: 只读, 在跑也不给 ⏹, 只能 ✕
    final temp = ConsoleSession(title: 'temp', launcher: noProcess);
    expect(temp.kind, SessionKind.temp);
    expect(temp.interactive, false);
    temp.beginTask();
    expect(temp.stoppable, false);
    temp.endTask();
    await temp.close();
  });

  test('closing a temp session from its console prunes it', () async {
    final process = FakeProcess();
    final executions = RunSessions(
      projectPath: '/project',
      launcher:
          ({
            required command,
            required workingDirectory,
            required rows,
            required columns,
          }) async => process,
    );
    final session = await executions.start(
      const RunConfiguration(
        id: 'pub-get',
        title: '获取依赖',
        command: 'dart pub get',
      ),
    );
    expect(session.kind, SessionKind.temp);
    expect(executions.selectedId, session.id);
    await session.close(); // 控制台头部 ✕: 在跑则终止, 然后关闭
    expect(executions.all, isEmpty);
    expect(executions.selectedId, isNull);
    expect(executions.console, same(executions.shell));
    await executions.closeAll();
  });
}
