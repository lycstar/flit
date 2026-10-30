import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../services/adb_ops.dart';
import '../../services/shell.dart';
import '../run/web_runner.dart';
import '../environment/android_build_wrapper.dart';
import '../terminal/run_sessions.dart';
import 'project_documents.dart';

enum ProjectBuild {
  debugApk(
    RunConfiguration(
      id: 'build-apk',
      title: '构建 APK（调试版）',
      command:
          'bash "\$HOME/.flit/scripts/android_build.sh" flutter build apk --debug --target-platform android-arm64 2>&1',
      artifactPath: 'build/app/outputs/flutter-apk/app-debug.apk',
    ),
  ),
  releaseApk(
    RunConfiguration(
      id: 'build-apk-release',
      title: '构建 APK（发布版）',
      command:
          'bash "\$HOME/.flit/scripts/android_build.sh" flutter build apk --release --target-platform android-arm64 2>&1',
      artifactPath: 'build/app/outputs/flutter-apk/app-release.apk',
    ),
  ),
  web(
    RunConfiguration(
      id: 'build-web',
      title: '构建 Web（发布版）',
      command: 'flutter build web --release 2>&1',
    ),
  );

  const ProjectBuild(this.configuration);
  final RunConfiguration configuration;
}

/// 内置 Flutter/Dart 命令(AS Flutter 插件 Tools 菜单的对应)。
/// 改写源码的命令(dart format / dart fix)暂不内置: 要先解决打开中缓冲区的回读。
enum ProjectTool {
  pubGet('pub-get', '获取依赖'),
  pubUpgrade('pub-upgrade', '升级依赖'),
  pubOutdated('pub-outdated', '检查过期依赖'),
  clean('clean', '清理构建产物', exclusive: true),
  analyze('analyze', '静态分析'),
  test('test', '运行测试'),
  doctor('doctor', '环境诊断');

  const ProjectTool(this.id, this.title, {this.exclusive = false});
  final String id;
  final String title;

  /// clean 删除正在使用的 build/ 目录, 与一切互斥
  final bool exclusive;

  /// UI 与执行共用配置；analyze 禁止隐式 pub get，才可与打包并行。
  RunConfiguration configuration({required bool flutter}) {
    final cli = flutter ? 'flutter' : 'dart';
    final command = switch (this) {
      pubGet => '$cli pub get',
      pubUpgrade => '$cli pub upgrade',
      pubOutdated => '$cli pub outdated',
      clean => 'flutter clean',
      analyze => '$cli analyze${flutter ? ' --no-pub' : ''}',
      test => '$cli test',
      doctor => 'flutter doctor -v',
    };
    return RunConfiguration(
      id: id,
      title: title,
      command: '$command 2>&1',
      exclusive: exclusive,
      readOnly: this == analyze || this == doctor || this == pubOutdated,
    );
  }
}

/// Project commands own save/preflight/launch/completion; views only present them.
/// Notifies whenever [starting] changes so the tree can watch it as one object.
class ProjectActions extends ChangeNotifier {
  ProjectActions({
    required this.path,
    required this.documents,
    required this.executions,
    required this.web,
    Future<List<AdbDevice>> Function()? devices,
    bool Function()? gitBusy,
    this.android,
  }) : _devices = devices ?? AdbOps.devices,
       _gitBusy = gitBusy ?? _notBusy {
    starting.addListener(notifyListeners);
  }

  static bool _notBusy() => false;

  final String path;
  final ProjectDocuments documents;
  final RunSessions executions;
  final WebRunController web;
  final AndroidBuildWrapper? android;
  final Future<List<AdbDevice>> Function() _devices;
  final bool Function() _gitBusy;

  /// Identifier of the action currently preparing a managed session. This
  /// covers the short device lookup/save window before RunSessions has a tab.
  final starting = ValueNotifier<String?>(null);

  /// 构建成功产出的文件(相对工程根): 编辑器据此把产物开成文件卡 tab,
  /// 这就是"构建完显示个位置"的具象——名字/大小/安装/分享都在眼前
  final _artifacts = StreamController<String>.broadcast();
  Stream<String> get builtArtifacts => _artifacts.stream;
  final _starting = <String, Future<RunSession>>{};
  bool _closed = false;

  void _ensureOpen() {
    if (_closed) throw StateError('项目已关闭');
  }

  Future<void> _save() async {
    _ensureOpen();
    if (AndroidBuildWrapper.installing) throw StateError('开发环境正在安装或切换，请等待完成');
    if (_gitBusy()) throw StateError('Git 操作正在进行，请等待完成');
    if (!await documents.saveAll()) throw StateError('保存失败，请重试');
    _ensureOpen();
  }

  Future<RunSession> start(
    RunConfiguration configuration, {
    void Function(String)? onText,
  }) {
    _ensureOpen();
    if (!configuration.readOnly) android?.cancelPending();
    final existing = executions.forConfiguration(configuration.id);
    if (configuration.kind == SessionKind.temp && existing?.alive == true) {
      executions.select(existing!.id);
      return Future.value(existing);
    }
    return _starting[configuration.id] ??=
        _withStarting(
          configuration.id,
          () => _start(configuration, onText),
        ).whenComplete(() {
          _starting.remove(configuration.id);
        });
  }

  Future<T> _withStarting<T>(String id, Future<T> Function() action) async {
    _ensureOpen();
    if (_gitBusy()) throw StateError('Git 操作正在进行，请等待完成');
    final current = starting.value;
    if (current != null && current != id) {
      throw StateError('当前已有任务正在启动，请稍后重试');
    }
    final owner = current == null;
    if (owner) starting.value = id;
    try {
      return await action();
    } finally {
      if (!_closed && owner && starting.value == id) starting.value = null;
    }
  }

  Future<RunSession> _start(
    RunConfiguration configuration,
    void Function(String)? onText,
  ) async {
    await _save();
    final session = await executions.start(configuration, onText: onText);
    final artifact = configuration.artifactPath;
    if (artifact != null) {
      unawaited(
        session.done.then((code) {
          if (!_closed && code == 0 && !session.stopRequested) {
            _artifacts.add(artifact);
          }
        }),
      );
    }
    return session;
  }

  Future<void> run(String target, {ConfirmAndroidRepair? confirmRepair}) async {
    _ensureOpen();
    android?.cancelPending();
    await _withStarting('run:$target', () async {
      if (target == 'web') {
        await _save();
        await web.start();
        if (web.error != null) throw StateError(web.error!);
        return;
      }
      final devices = await _devices();
      _ensureOpen();
      final matches = devices.where((device) => device.$1 == target);
      if (matches.isEmpty) throw StateError('目标 $target 未连接');
      final device = matches.first;
      final configuration = RunConfiguration(
        id: 'run:$target',
        title: device.$2.isEmpty ? target : device.$2,
        command:
            'bash "\$HOME/.flit/scripts/android_build.sh" flutter run -d ${shQuote(target)} 2>&1',
        kind: SessionKind.run,
        hotReload: true,
        target: target,
      );
      if (android != null && confirmRepair != null) {
        await android!.start(
          configuration,
          launch: _start,
          confirm: confirmRepair,
          save: _save,
          device: true,
        );
      } else {
        await start(configuration);
      }
    });
  }

  /// 纯 Dart 工程: 平台只有终端, 运行即 console 模板的 dart run。
  Future<void> runDart() => start(
    const RunConfiguration(
      id: 'run:dart',
      title: 'Dart 运行',
      command: 'dart run 2>&1',
      kind: SessionKind.run,
      target: 'dart',
    ),
  );

  /// 纯 Dart 工程的构建 = dart compile exe(原生可执行)。
  /// console 模板入口固定为 bin/<包名>.dart, 包名 = 工程目录名; 产物放 build/。
  RunConfiguration get dartExeConfiguration {
    final name = path.split('/').last;
    return RunConfiguration(
      id: 'build-dart-exe',
      title: '编译可执行文件',
      command:
          'mkdir -p build && dart compile exe ${shQuote('bin/$name.dart')} '
          '-o ${shQuote('build/$name')} 2>&1',
    );
  }

  Future<RunSession> buildDartExe() => start(dartExeConfiguration);

  /// 内置命令都是临时会话: 只读输出, 只能关。pub/analyze/test 按工程类型
  /// 走 flutter 或 dart 前缀(flutter 工程的 pub 必须用 flutter pub)。
  Future<RunSession> tool(ProjectTool tool, {required bool flutter}) =>
      start(tool.configuration(flutter: flutter));

  Future<void> reload(String target, {required bool fullRestart}) async {
    final run = executions.forConfiguration('run:$target');
    if (run == null) return;
    if (executions.hasWritingTask || starting.value != null) {
      throw StateError('请等待构建或依赖更新完成后再热重载');
    }
    await _save();
    if (executions.hasWritingTask || starting.value != null) {
      throw StateError('请等待构建或依赖更新完成后再热重载');
    }
    // A rerun during save must not receive an action intended for the old process.
    if (!identical(run, executions.forConfiguration('run:$target'))) return;
    if (target == 'web') {
      if (!await web.reload(fullRestart: fullRestart) && web.error != null) {
        throw StateError(web.error!);
      }
    } else if (run.supportsReload) {
      run.write(fullRestart ? 'R' : 'r');
    }
  }

  Future<RunSession> build(
    ProjectBuild kind, {
    ConfirmAndroidRepair? confirmRepair,
  }) {
    if (kind == ProjectBuild.web || android == null || confirmRepair == null) {
      return start(kind.configuration);
    }
    final configuration = kind.configuration;
    final existing = executions.forConfiguration(configuration.id);
    if (existing?.alive == true) {
      executions.select(existing!.id);
      return Future.value(existing);
    }
    return _starting[configuration.id] ??= _withStarting(
      configuration.id,
      () => android!.start(
        configuration,
        launch: _start,
        confirm: confirmRepair,
        save: _save,
      ),
    ).whenComplete(() => _starting.remove(configuration.id));
  }

  @override
  void dispose() {
    if (_closed) return;
    _closed = true;
    android?.dispose();
    starting.removeListener(notifyListeners);
    starting.dispose();
    _artifacts.close();
    super.dispose();
  }
}
