import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'console_session.dart';
import 'pty_session.dart';

export 'console_session.dart' show SessionKind;

/// What to launch. A device is a target, never the identity of an execution.
/// kind 只会是 run(可停而不丢) 或 temp(只能关); 热重载按钮只对 hotReload 的 run 出现。
class RunConfiguration {
  const RunConfiguration({
    required this.id,
    required this.title,
    required this.command,
    this.kind = SessionKind.temp,
    this.hotReload = false,
    this.exclusive = false,
    this.target,
    this.artifactPath,
    this.installAfterBuild = false,
  }) : assert(kind != SessionKind.shell, '任务不会是默认 shell');
  final String id;
  final String title;
  final String command;
  final SessionKind kind;
  final bool hotReload;

  /// 与任何存活会话互斥(占用同一构建树/产物: 构建、clean)。
  /// 普通工具任务(pub get/analyze/装包)允许与 run 并存——开发循环就是
  /// "run 活着 → 加依赖 → pub get → hot reload", 一刀切互斥会砍断它。
  final bool exclusive;
  final String? target;
  final String? artifactPath;
  final bool installAfterBuild;
}

class RunSession extends ConsoleSession {
  RunSession({
    required this.id,
    required this.projectPath,
    required this.configuration,
    required super.launcher,
  }) : super(title: configuration.title, kind: configuration.kind);

  final String id;
  final String projectPath;
  final RunConfiguration configuration;
  bool get supportsReload =>
      state == ExecutionState.running && configuration.hotReload;
}

/// Project-owned executions. Start/rerun of the same configuration is serialized;
/// browsing a console never changes the project's chosen run target.
class RunSessions extends ChangeNotifier {
  RunSessions({required this.projectPath, required ProcessLauncher launcher})
    : _launcher = launcher,
      shell = PtySession(workingDirectory: projectPath, launcher: launcher);

  final String projectPath;
  final ProcessLauncher _launcher;
  final PtySession shell;
  final _sessions = <String, RunSession>{};
  final _pending = <String, Future<RunSession>>{};
  int _nextId = 0;
  String? _selectedId;
  bool _closed = false;

  Map<String, RunSession> get sessions => UnmodifiableMapView(_sessions);
  Iterable<RunSession> get all => _sessions.values;
  String? get selectedId => _selectedId;
  RunSession? get selected => _sessions[_selectedId];
  ConsoleSession get console => selected ?? shell;
  RunSession? get active {
    for (final session in _sessions.values) {
      if (session.alive) return session;
    }
    return null;
  }

  bool isStarting(String configurationId) =>
      _pending.containsKey(configurationId);
  bool get starting => _pending.isNotEmpty;

  RunSession? forConfiguration(String id) {
    for (final session in _sessions.values) {
      if (session.configuration.id == id) return session;
    }
    return null;
  }

  Future<RunSession> start(
    RunConfiguration configuration, {
    void Function(String)? onText,
    String Function(String)? outputFormatter,
  }) {
    if (_closed) return Future.error(StateError('项目已关闭'));
    final pending = _pending[configuration.id];
    if (pending != null) return pending;
    if (_pending.isNotEmpty) {
      return Future.error(StateError('当前已有任务正在启动，请稍后重试'));
    }
    final existing = forConfiguration(configuration.id);
    // Repeated clicks on a running temporary task select its existing output.
    // Run sessions intentionally restart because the Run button means rerun.
    if (configuration.kind == SessionKind.temp && existing?.alive == true) {
      select(existing!.id);
      return Future.value(existing);
    }
    return _pending[configuration.id] =
        _start(configuration, onText, outputFormatter).whenComplete(() {
          _pending.remove(configuration.id);
          if (!_closed) notifyListeners();
        });
  }

  Future<RunSession> _start(
    RunConfiguration configuration,
    void Function(String)? onText,
    String Function(String)? outputFormatter,
  ) async {
    final active = _sessions.values.where((session) => session.alive).toList();
    if (configuration.exclusive && active.isNotEmpty) {
      throw StateError('构建期间不能并行其它任务，请先停止正在运行的项目');
    }
    if (configuration.kind == SessionKind.temp) {
      // 普通工具任务与 run 并存(开发循环); temp 之间一次一个:
      // 并发写 package_config/构建目录是真竞态
      if (active.any(
        (session) =>
            session.configuration.kind == SessionKind.temp ||
            session.configuration.exclusive,
      )) {
        throw StateError('当前已有工具任务正在运行，请稍后再试');
      }
    } else {
      if (active.any(
        (session) =>
            session.configuration.kind == SessionKind.temp ||
            session.configuration.exclusive,
      )) {
        throw StateError('当前已有工具任务正在运行，请稍后再运行项目');
      }
      // Only one managed run target is kept. Switching Web/device closes the
      // previous run and its tab before creating the new target session.
      for (final old
          in _sessions.values
              .where((session) => session.configuration.kind == SessionKind.run)
              .toList()) {
        await close(old.id, graceful: true);
      }
    }
    final old = forConfiguration(configuration.id);
    if (old != null) {
      await close(old.id, graceful: true);
    }
    if (_closed) throw StateError('项目已关闭');
    final session = RunSession(
      id: '$projectPath#${++_nextId}',
      projectPath: projectPath,
      configuration: configuration,
      launcher: _launcher,
    );
    _sessions[session.id] = session;
    _selectedId = session.id;
    session.addListener(_changed);
    notifyListeners();
    final subscription = onText == null
        ? null
        : session.textStream.listen(onText);
    await session.start(
      command: configuration.command,
      workingDirectory: projectPath,
      outputFormatter: outputFormatter,
    );
    if (subscription != null) {
      unawaited(session.done.then((_) => subscription.cancel()));
    }
    return session;
  }

  void _changed() {
    if (_closed) return;
    // 临时会话可从控制台头部 ✕ 自行 close(): 已释放的会话从列表摘除
    _sessions.removeWhere((id, session) {
      if (!session.disposed) return false;
      session.removeListener(_changed);
      if (_selectedId == id) _selectedId = null;
      return true;
    });
    notifyListeners();
  }

  void select(String? id) {
    if (_closed || (id != null && !_sessions.containsKey(id))) return;
    _selectedId = id;
    notifyListeners();
  }

  /// 关闭会话。UI 关闭(chip ✕/头部 ✕/关闭项目)用 hard kill 立即释放;
  /// 内部重跑/切目标传 graceful: 旧控制台保留到进程退出, 输出不丢。
  Future<void> close(String id, {bool graceful = false}) async {
    final session = _sessions[id];
    if (session == null) return;
    if (graceful) await session.stop();
    await session.close();
    if (identical(_sessions[id], session)) {
      _sessions.remove(id);
      if (_selectedId == id) _selectedId = null;
      session.removeListener(_changed);
      if (!_closed) notifyListeners();
    }
  }

  Future<void>? _closing;
  Future<void> closeAll() => _closing ??= _closeAll();
  Future<void> _closeAll() async {
    _closed = true;
    await Future.wait(
      _pending.values
          .map((future) => future.then<void>((_) {}, onError: (Object _) {}))
          .toList(),
    );
    await Future.wait(_sessions.keys.toList().map(close));
    await shell.close();
    super.dispose();
  }
}
