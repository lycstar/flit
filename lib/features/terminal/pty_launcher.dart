import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_pty/flutter_pty.dart';

import '../../services/auto_proxy.dart';
import '../../services/shell.dart';
import 'console_session.dart';
import 'session_environment.dart';

/// Starts the Termux bash every console runs in. This is the one production
/// [ProcessLauncher]: whatever owns consoles receives it from the composition
/// root, and tests substitute fakes through the very same parameter.
class PtyLauncher {
  PtyLauncher({required this.proxy});

  /// 代理地址在进程启动那一刻注入环境, 开关/地址变化只对之后的新会话生效。
  final AutoProxy proxy;

  Future<SessionProcess> call({
    required String? command,
    required String? workingDirectory,
    required int rows,
    required int columns,
  }) async {
    final status = await Shell.instance.bootstrapStatus();
    final prefix = status['prefix'] as String? ?? '';
    final home = status['home'] as String? ?? '';
    if (home.isEmpty || !File('$prefix/bin/bash').existsSync()) {
      throw StateError('开发环境未就绪，请先初始化环境');
    }
    return _PtyProcess(
      Pty.start(
        '$prefix/bin/bash',
        // flutter_pty 一收到退出码就关闭输出端口, 读线程尚未 post 的 PTY 尾部
        // 输出(脚本最后的 __STAGE__/__VER__ 行)会被丢弃(模拟器上必现)。
        // 退出前停 0.3s: 数据此时已在内核缓冲区, 读线程足以排空并先于退出码送达。
        arguments: command == null
            ? ['-i']
            : [
                '-c',
                '$terminalEnvSource$command; __rc=\$?; sleep 0.3; exit \$__rc',
              ],
        workingDirectory: workingDirectory ?? home,
        environment: sessionEnvironment(prefix, home, proxy: proxy.envVars()),
        rows: rows,
        columns: columns,
      ),
    );
  }
}

class _PtyProcess implements SessionProcess {
  _PtyProcess(this.pty);
  final Pty pty;

  @override
  Stream<List<int>> get output => pty.output;
  @override
  Future<int> get exitCode => pty.exitCode;
  @override
  void write(Uint8List data) => pty.write(data);
  @override
  void resize(int rows, int columns) => pty.resize(rows, columns);
  @override
  void kill() {
    // forkpty creates a new session/process group. Stop its children as well.
    Process.killPid(-pty.pid, ProcessSignal.sigkill);
    pty.kill(ProcessSignal.sigkill);
  }
}
