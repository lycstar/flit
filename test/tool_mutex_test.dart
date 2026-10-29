
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/terminal/run_sessions.dart';

import 'support/fake_session_process.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('two different tools cannot run at the same time', () async {
    final processes = <FakeProcess>[];
    final executions = RunSessions(
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
    const pubGet = RunConfiguration(
      id: 'pub-get',
      title: '获取依赖',
      command: 'dart pub get',
    );
    const analyze = RunConfiguration(
      id: 'analyze',
      title: '静态分析',
      command: 'dart analyze',
    );
    try {
      final first = await executions.start(pubGet);
      expect(first.alive, true);
      // temp 与 temp 互斥: 并发写 package_config 是竞态
      await expectLater(executions.start(analyze), throwsStateError);
      expect(processes, hasLength(1));
      // 前一个结束后, 后一个可以跑(会话状态经微任务链收尾, 放行一拍)
      await processes.single.finish();
      await Future<void>.delayed(Duration.zero);
      final second = await executions.start(analyze);
      expect(second.alive, true);
      await processes.last.finish();
    } finally {
      await executions.closeAll();
    }
  });
}
