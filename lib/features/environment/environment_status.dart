import '../../services/shell.dart';
import 'environment_controller.dart'
    show parseStageMarker, readyStageIds, stripAnsi;

/// A read-only snapshot. All required components must report DONE in a successful
/// check; partial output must never unlock project creation or execution.
class EnvironmentStatus {
  const EnvironmentStatus({
    required this.bootstrapped,
    this.completed = 0,
    this.checkFailed = false,
  });

  final bool bootstrapped;
  final int completed;
  final bool checkFailed;

  bool get ready =>
      bootstrapped && !checkFailed && completed == readyStageIds.length;

  String get label {
    if (checkFailed) return '检测失败 · 进入开发环境查看';
    if (!bootstrapped) return '尚未安装 · 配置开发环境';
    if (ready) return '组件全部就绪';
    return '已就绪 $completed/${readyStageIds.length} 个组件';
  }

  factory EnvironmentStatus.fromCheck({
    required int exitCode,
    required String output,
  }) {
    final states = <String, String>{};
    for (final line in output.split(RegExp(r'[\r\n]'))) {
      final marker = parseStageMarker(stripAnsi(line));
      if (marker != null) states[marker.$1] = marker.$2;
    }
    return EnvironmentStatus(
      bootstrapped: true,
      completed: readyStageIds.where((id) => states[id] == 'DONE').length,
      checkFailed: exitCode != 0 || !readyStageIds.every(states.containsKey),
    );
  }

  static Future<EnvironmentStatus> inspect() async {
    try {
      final status = await Shell.instance.bootstrapStatus();
      if (status['bootstrapped'] != true) {
        return const EnvironmentStatus(bootstrapped: false);
      }
      final home = status['home'] as String? ?? '';
      if (home.isEmpty) {
        return const EnvironmentStatus(bootstrapped: true, checkFailed: true);
      }
      final result = await Shell.instance.exec(
        'bash ${shQuote('$home/.flit/scripts/check.sh')}',
        timeoutMs: 30000,
      );
      return EnvironmentStatus.fromCheck(
        exitCode: result['exitCode'] as int? ?? -1,
        output: result['output'] as String? ?? '',
      );
    } catch (_) {
      return const EnvironmentStatus(bootstrapped: false, checkFailed: true);
    }
  }
}
