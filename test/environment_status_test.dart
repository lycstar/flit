import 'package:flit/features/environment/environment_controller.dart';
import 'package:flit/features/environment/environment_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String complete() =>
      readyStageIds.map((id) => '__STAGE__$id:DONE').join('\n');

  test('only a successful complete check unlocks the workspace', () {
    expect(
      EnvironmentStatus.fromCheck(exitCode: 0, output: complete()).ready,
      isTrue,
    );
    expect(
      EnvironmentStatus.fromCheck(exitCode: 1, output: complete()).ready,
      isFalse,
    );
    final missing = complete().split('\n')..removeLast();
    final partial = EnvironmentStatus.fromCheck(
      exitCode: 0,
      output: missing.join('\n'),
    );
    expect(partial.ready, isFalse);
    expect(partial.checkFailed, isTrue);
  });

  test(
    'latest marker wins and a failed required component blocks readiness',
    () {
      final status = EnvironmentStatus.fromCheck(
        exitCode: 0,
        output: '${complete()}\n\x1b[31m__STAGE__android_jdk:FAILED\x1b[0m\n',
      );
      expect(status.ready, isFalse);
      expect(status.completed, readyStageIds.length - 1);
      expect(status.checkFailed, isFalse);
      expect(
        status.label,
        contains('${readyStageIds.length - 1}/${readyStageIds.length}'),
      );
    },
  );

  test('unrelated and repeated markers cannot impersonate complete setup', () {
    final repeated = List.filled(
      readyStageIds.length,
      '__STAGE__android_jdk:DONE',
    ).join('\n');
    final status = EnvironmentStatus.fromCheck(
      exitCode: 0,
      output: '$repeated\n__STAGE__unknown:DONE',
    );
    expect(status.ready, isFalse);
    expect(status.completed, 1);
  });
}
