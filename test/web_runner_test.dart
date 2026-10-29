import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/run/web_runner.dart';
import 'package:flit/features/terminal/run_sessions.dart';

import 'support/fake_session_process.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RunSessions executions;
  late WebRunController web;
  late List<FakeProcess> processes;
  late List<String?> commands;
  int port = 20000;

  setUp(() {
    processes = [];
    commands = [];
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
    web = WebRunController(executions, allocatePort: () async => ++port);
  });
  tearDown(() async {
    web.dispose();
    await executions.closeAll();
  });

  Future<void> emit(Map<String, dynamic> message) async {
    processes.last.emit('${jsonEncode([message])}\r\n');
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> serve() async {
    await emit({
      'event': 'app.start',
      'params': {'appId': 'app-$port'},
    });
    await emit({
      'event': 'app.webLaunchUrl',
      'params': {'url': 'http://127.0.0.1:$port'},
    });
    await emit({
      'event': 'app.started',
      'params': {'appId': 'app-$port'},
    });
  }

  test(
    'switching to a device stops Web preview and disables its hot reload',
    () async {
      await web.start();
      await serve();
      web.setClientReady(true);
      final old = web.session!;
      expect(web.canReload, true);
      final device = await executions.start(
        const RunConfiguration(
          id: 'run:phone',
          title: 'Phone',
          command: 'flutter run',
          kind: SessionKind.run,
          target: 'phone',
        ),
      );
      expect(old.disposed, true);
      expect(web.state, WebRunState.stopped);
      expect(web.canReload, false);
      expect(executions.active, same(device));
      expect(executions.forConfiguration('run:web'), isNull);
    },
  );

  test(
    'only this execution startup events make the server ready; chunks may split',
    () async {
      await web.start();
      expect(web.state, WebRunState.starting);
      processes.last.emit('main.dart.js 200\r\n');
      // An old listener at another port cannot satisfy this run's readiness.
      await emit({
        'event': 'app.webLaunchUrl',
        'params': {'url': 'http://127.0.0.1:18321'},
      });
      await emit({'event': 'app.started', 'params': {}});
      expect(web.serving, false);
      final message = jsonEncode([
        {
          'event': 'app.start',
          'params': {'appId': 'app-$port'},
        },
      ]);
      processes.last.emit(message.substring(0, 13));
      processes.last.emit('${message.substring(13)}\r');
      processes.last.emit('\n');
      await emit({
        'event': 'app.webLaunchUrl',
        'params': {'url': 'http://127.0.0.1:$port'},
      });
      expect(web.serving, false);
      await emit({'event': 'app.started', 'params': {}});
      expect(web.serving, true);
      expect(web.canReload, false); // Browser still needs to render/connect.
      web.setClientReady(true);
      expect(web.canReload, true);
      expect(commands.single, contains('flutter run --machine'));
      await emit({
        'event': 'app.log',
        'params': {'log': 'hello from app'},
      });
      final text = web.session!.terminal.buffer.getText();
      expect(text, contains('hello from app'));
      expect(text, isNot(contains('app.started')));
    },
  );

  test(
    'reload waits for matching reply, rejects duplicates and keeps the running page on errors',
    () async {
      await web.start();
      await serve();
      web.setClientReady(true);
      final reload = web.reload();
      expect(web.reloading, true);
      expect(await web.reload(), false);
      final request =
          (jsonDecode(processes.last.writes.last) as List).single as Map;
      expect(request['method'], 'app.restart');
      expect(request['params']['fullRestart'], false);
      await emit({
        'id': 99999,
        'result': {'code': 0},
      });
      expect(web.reloading, true);
      await emit({
        'id': request['id'],
        'result': {'code': 1, 'message': 'Failed to recompile application.'},
      });
      expect(await reload, false);
      expect(web.error, contains('Failed to recompile'));
      expect(web.serving, true);
      expect(web.canReload, true);

      final restart = web.reload(fullRestart: true);
      final next =
          (jsonDecode(processes.last.writes.last) as List).single as Map;
      expect(next['params']['fullRestart'], true);
      await emit({
        'id': next['id'],
        'result': {'code': 0},
      });
      expect(await restart, true);
      expect(web.error, isNull);
      expect(web.reloading, false);
    },
  );

  test(
    'stopping during a reload completes pending request and disables updates',
    () async {
      await web.start();
      await serve();
      web.setClientReady(true);
      final updating = web.reload();
      await web.session!.stop();
      expect(await updating, false);
      expect(web.state, WebRunState.stopped);
      expect(web.canReload, false);
      expect(web.serving, false);
    },
  );

  test('rerun stops the previous execution and uses a new port', () async {
    final first = web.start();
    final duplicate = web.start();
    await Future.wait([first, duplicate]);
    expect(processes, hasLength(1));
    await serve();
    final firstPort = web.url!.port;
    final old = web.session!;
    await web.start();
    expect(old.alive, false);
    expect(processes, hasLength(2));
    expect(web.serving, false);
    expect(web.url, isNull);
    await serve();
    expect(web.url!.port, isNot(firstPort));
    expect(web.session, isNot(same(old)));
  });

  test(
    'startup failure preserves the actual error instead of reporting a network failure',
    () async {
      await web.start();
      await emit({
        'event': 'app.stop',
        'params': {'error': 'Undefined name: missingWidget'},
      });
      await processes.last.finish(1);
      await web.session!.done;
      expect(web.state, WebRunState.failed);
      expect(web.error, contains('Undefined name: missingWidget'));
      expect(web.error, isNot(contains('网络')));
    },
  );
}
