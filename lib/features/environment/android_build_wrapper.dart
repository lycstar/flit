import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../services/shell.dart';
import '../terminal/run_sessions.dart';
import 'setup_runner.dart';
import 'toolchain_catalog.dart';

/// 精确的 SDK 包标识；version 是项目要求的版本，不是“可替代”的最新版。
class AndroidComponent {
  const AndroidComponent(this.id, [this.version = '']);
  final String id;
  final String version;
  String get key => '$id:$version';
  String get title =>
      '${const {'platforms': 'Android Platform', 'build-tools': 'Build Tools', 'ndk': 'NDK', 'cmake': 'CMake / Ninja', 'platform-tools': 'Platform Tools', 'cmdline-tools': 'Command-line Tools'}[id] ?? id}${version.isEmpty ? '' : ' $version'}';
}

/// UI 只展示请求和返回选择；下载地址、版本匹配和重试不进入 Widget。
class AndroidRepairRequest {
  const AndroidRepairRequest(
    this.components, {
    required this.afterFailure,
    this.error,
  });
  final List<AndroidComponent> components;
  final bool afterFailure;
  final String? error;
}

typedef ConfirmAndroidRepair =
    Future<bool> Function(AndroidRepairRequest request);
typedef AndroidLaunch =
    Future<RunSession> Function(
      RunConfiguration configuration,
      void Function(String)? onText,
    );

/// Android 构建的唯一补包入口，覆盖 APK 和设备 flutter run。
///
/// 前置检查只处理基础工具和字面量版本，不模拟执行 Gradle。动态版本、插件和
/// 多模块依赖交给真实构建诊断；只有明确的缺包错误才允许安装。一次启动最多
/// 做一次失败恢复，避免重试循环。关闭项目/会话或启动新任务后，旧回调失效。
class AndroidBuildWrapper {
  AndroidBuildWrapper({
    required this.executions,
    ToolchainCatalog? catalog,
    Future<Map<dynamic, dynamic>> Function(String)? probe,
    Future<List<AndroidComponent>> Function()? requirements,
  }) : catalog = catalog ?? ToolchainCatalog(),
       _probe =
           probe ??
           ((command) => Shell.instance.exec(command, timeoutMs: 60000)),
       _requirements = requirements;

  final RunSessions executions;
  final ToolchainCatalog catalog;
  final Future<Map<dynamic, dynamic>> Function(String) _probe;
  final Future<List<AndroidComponent>> Function()? _requirements;
  int _generation = 0;
  bool _closed = false;

  /// 与环境页共享安装互斥，防止两个入口同时覆盖 SDK 或同一 staging 目录。
  static final installationBusy = ValueNotifier(false);
  static bool get installing => installationBusy.value;
  static set installing(bool value) => installationBusy.value = value;

  void cancelPending() {
    _generation++;
  }

  void dispose() {
    _closed = true;
    _generation++;
  }

  Future<RunSession> start(
    RunConfiguration configuration, {
    required AndroidLaunch launch,
    required ConfirmAndroidRepair confirm,
    required Future<void> Function() save,
    bool device = false,
  }) async {
    final generation = ++_generation;
    bool current() => !_closed && generation == _generation;
    if (installing) throw StateError('工具链正在安装，请稍后重试');
    await save();
    final declared = await (_requirements?.call() ?? _readRequirements());
    final missing = await _check(declared, baseline: true, device: device);
    if (!current()) throw StateError('项目已关闭或任务已取消');
    if (missing.isNotEmpty &&
        !await _repair(missing, confirm, current, afterFailure: false)) {
      throw StateError('组件未补齐，构建未启动');
    }
    if (!current()) throw StateError('项目已关闭或任务已取消');
    final diagnostics = AndroidBuildDiagnostics();
    final session = await launch(configuration, diagnostics.add);
    // 返回首个会话，让控制台立即显示；后续流程的异常写回原控制台，不能成为
    // 未处理的异步异常。重试仍走 ProjectActions，成功产物只由真实构建报告。
    unawaited(
      _recover(session, configuration, diagnostics, launch, confirm, current),
    );
    return session;
  }

  Future<void> _recover(
    RunSession session,
    RunConfiguration configuration,
    AndroidBuildDiagnostics diagnostics,
    AndroidLaunch launch,
    ConfirmAndroidRepair confirm,
    bool Function() current,
  ) async {
    bool valid() =>
        current() &&
        !session.disposed &&
        !session.stopRequested &&
        identical(executions.forConfiguration(configuration.id), session) &&
        executions.conflictFor(configuration) == null &&
        !executions.starting;
    try {
      final code = await session.done;
      diagnostics.finish();
      if (code == 0 || !valid()) return;
      if (diagnostics.blocker != null) {
        await confirm(
          AndroidRepairRequest(
            diagnostics.components,
            afterFailure: true,
            error: diagnostics.blocker,
          ),
        );
        return;
      }
      if (diagnostics.components.isEmpty) return;
      final missing = diagnostics.components;
      if (!await _repair(missing, confirm, valid, afterFailure: true)) return;
      if (!valid()) return;
      // 不再包裹第二次启动：新缺失/其他错误保持原始输出，由用户决定下一步。
      await launch(configuration, null);
    } catch (error) {
      if (!session.disposed) session.log.err('组件修复未完成：$error');
    }
  }

  Future<List<AndroidComponent>> _readRequirements() async {
    final result = <AndroidComponent>[];
    // 常用入口的明确声明只是提前发现问题的优化；不递归扫描缓存和插件源码。
    for (final relative in [
      'build.gradle',
      'build.gradle.kts',
      'app/build.gradle',
      'app/build.gradle.kts',
      'android/build.gradle',
      'android/build.gradle.kts',
      'android/app/build.gradle',
      'android/app/build.gradle.kts',
    ]) {
      final file = File('${executions.projectPath}/$relative');
      if (await file.exists()) {
        result.addAll(declaredComponents(await file.readAsString()));
      }
    }
    return _unique(result);
  }

  Future<List<AndroidComponent>> _check(
    List<AndroidComponent> components, {
    bool baseline = false,
    bool device = false,
  }) async {
    final args = [
      if (baseline) '--baseline',
      if (device) '--device',
      for (final c in components) '${c.id}:${c.version}',
    ];
    final result = await _probe(
      'bash "\$HOME/.flit/scripts/android_components.sh" ${args.map(shQuote).join(' ')}',
    );
    if (result['exitCode'] != 0) {
      throw StateError(
        'Android 环境检查失败，请先在开发环境页完成初始化。\n${result['output'] ?? ''}',
      );
    }
    final missing = _unique([
      for (final line in (result['output'] as String? ?? '').split(
        RegExp(r'[\r\n]'),
      ))
        if (RegExp(r'^__MISSING__([a-z-]+):([0-9.]*)$').hasMatch(line))
          AndroidComponent(
            line.substring(11).split(':')[0],
            line.split(':').last,
          ),
    ]);
    // 已声明 Build Tools 时装该版本即可，它同时提供 AAPT2，无须再装默认版本。
    if (baseline &&
        components.any(
          (c) =>
              c.id == 'build-tools' && c.version != ToolchainCatalog.sdkVersion,
        ) &&
        !components.any(
          (c) =>
              c.id == 'build-tools' && c.version == ToolchainCatalog.sdkVersion,
        )) {
      missing.removeWhere(
        (c) =>
            c.id == 'build-tools' && c.version == ToolchainCatalog.sdkVersion,
      );
    }
    return missing;
  }

  Future<bool> _repair(
    List<AndroidComponent> missing,
    ConfirmAndroidRepair confirm,
    bool Function() current, {
    required bool afterFailure,
  }) async {
    // 普通打包可与 run 并存，但修复会替换共用工具链，仍需停止使用它的任务。
    if (executions.active != null) {
      if (current()) {
        await confirm(
          AndroidRepairRequest(
            missing,
            afterFailure: afterFailure,
            error: '安装组件需要修改共用开发环境。请先结束正在运行的任务，再重试。',
          ),
        );
      }
      return false;
    }
    final commands = <String>[];
    final requested = [...missing];
    var managerPlanned = false;
    try {
      for (final component in missing) {
        try {
          commands.add(await _installCommand(component));
        } on HttpException catch (error) {
          // 仅 Platform 可回退到 Google，且只有明确的 404；网络故障不能伪装成缺包。
          if (component.id != 'platforms' || error.message != 'HTTP 404') {
            rethrow;
          }
          final manager = await _check([
            const AndroidComponent('cmdline-tools'),
          ]);
          if (manager.isNotEmpty && !managerPlanned) {
            managerPlanned = true;
            requested.addAll(manager);
            commands.add(await _installCommand(manager.single));
          }
          commands.add(
            'bash "\$HOME/.flit/scripts/android_platform.sh" ${shQuote(component.version)}',
          );
        }
      }
    } catch (error) {
      if (current()) {
        await confirm(
          AndroidRepairRequest(
            _unique(requested),
            afterFailure: afterFailure,
            error: '未找到可安装的对应版本或无法获取下载信息：$error',
          ),
        );
      }
      return false;
    }
    if (!current() ||
        !await confirm(
          AndroidRepairRequest(_unique(requested), afterFailure: afterFailure),
        ) ||
        !current()) {
      return false;
    }
    if (installing || executions.active != null || executions.starting) {
      throw StateError('已有任务正在运行，请结束后重试');
    }
    installing = true;
    try {
      final repair = await executions.start(
        RunConfiguration(
          id: 'android-components',
          title: '安装 Android 构建组件',
          command: commands.join(' && '),
          exclusive: true,
        ),
      );
      final code = await repair.done;
      if (code != 0 || repair.stopRequested || repair.disposed || !current()) {
        return false;
      }
      // 安装器验证包内版本和二进制；再从 SDK 路径复查，防止软链接或残包误报成功。
      final remaining = await _check(missing);
      if (remaining.isNotEmpty) {
        throw StateError('安装后仍不可用：${remaining.map((c) => c.title).join('、')}');
      }
      return current();
    } finally {
      installing = false;
    }
  }

  Future<String> _installCommand(AndroidComponent component) async {
    final version = component.version;
    final tag = switch (component.id) {
      'platforms' => 'platform-$version',
      'build-tools' => 'sdk-$version',
      'cmake' => 'cmake-$version',
      'ndk' => ndkTag(version),
      'platform-tools' || 'cmdline-tools' => null,
      _ => throw StateError('不支持自动安装 ${component.title}'),
    };
    final entry = await catalog.resolve(component.id, tag: tag);
    final command = SetupRunner.installCommand(entry);
    // r28c 只能定位候选产物，完整 Pkg.Revision 必须由安装器在发布目录前验证。
    return component.id == 'ndk' ? '$command ${shQuote(version)}' : command;
  }

  static String ndkTag(String version) {
    final parts = version.split('.');
    if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version)) {
      throw StateError('无效的 NDK 版本');
    }
    final minor = int.parse(parts[1]);
    if (minor > 25) throw StateError('无法定位 NDK $version');
    return 'ndk-r${parts[0]}${minor == 0 ? '' : String.fromCharCode(97 + minor)}';
  }

  static List<AndroidComponent> _unique(Iterable<AndroidComponent> values) =>
      {for (final c in values) c.key: c}.values.toList();

  /// 仅接受完整的一行字面量声明；flutter.ndkVersion、变量、函数交由失败诊断。
  static List<AndroidComponent> declaredComponents(String source) {
    final text = source.replaceAll(RegExp(r'/\*[\s\S]*?\*/|//[^\r\n]*'), '');
    final result = <AndroidComponent>[];
    for (final pair in [
      ('compileSdk(?:Version)?', 'platforms'),
      ('buildToolsVersion', 'build-tools'),
      ('ndkVersion', 'ndk'),
    ]) {
      final pattern = RegExp(
        '^\\s*${pair.$1}\\s*(?:=\\s*|\\(\\s*|\\s+)["\']?(?:android-)?([0-9]+(?:\\.[0-9]+)*)["\']?\\s*\\)?\\s*;?\\s*\$',
        multiLine: true,
      );
      for (final match in pattern.allMatches(text)) {
        final version = match[1]!;
        if (RegExp(
          pair.$2 == 'platforms' ? r'^\d+(?:\.\d+)?$' : r'^\d+\.\d+\.\d+$',
        ).hasMatch(version)) {
          result.add(AndroidComponent(pair.$2, version));
        }
      }
    }
    // 仅识别 cmake 块内、独占一行的字面量 version，避免把项目 version 当 CMake。
    for (final block in RegExp(r'\bcmake\s*\{([^{}]*)\}').allMatches(text)) {
      final match = RegExp(
        r'''^\s*version\s*(?:=\s*|\s+)["'](\d+\.\d+\.\d+)["']\s*;?\s*$''',
        multiLine: true,
      ).firstMatch(block[1]!);
      if (match != null) result.add(AndroidComponent('cmake', match[1]!));
    }
    return _unique(result);
  }
}

/// 按完整行解析 PTY 输出（ANSI 和 UTF-8 可以跨块）；只接受明确诊断，绝不把
/// 普通的版本提及、编译失败、网络错误当成缺包。限制行长，长日志不会无限占内存。
class AndroidBuildDiagnostics {
  String _pending = '';
  int _ndkContext = 0;
  int _packageContext = 0;
  final _found = <String, AndroidComponent>{};
  String? blocker;
  List<AndroidComponent> get components => _found.values.toList();
  void add(String chunk) {
    final lines = ('$_pending$chunk').split(RegExp(r'[\r\n]'));
    _pending = lines.removeLast();
    if (_pending.length > 32768) {
      _pending = _pending.substring(_pending.length - 32768);
    }
    for (final line in lines) {
      _line(line);
    }
  }

  void finish() {
    _line(_pending);
    _pending = '';
  }

  void _record(String id, String version) {
    if (!RegExp(
      id == 'platforms' ? r'^\d+(?:\.\d+)?$' : r'^\d+\.\d+\.\d+$',
    ).hasMatch(version)) {
      return;
    }
    final component = AndroidComponent(id, version);
    _found[component.key] = component;
  }

  void _line(String raw) {
    final line = raw
        .replaceAll(RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'), '')
        .replaceFirst(RegExp(r'^\s*(?:>\s*)+'), '');
    // 缺许可证、显式路径错误不能靠重复安装同版本解决，不把它们伪装成缺包。
    if (RegExp(
      r'licen[cs]es?.*(?:not accepted|not been accepted|not been agreed|not accepted)',
      caseSensitive: false,
    ).hasMatch(line)) {
      blocker =
          r'Android SDK 许可证尚未接受。请在开发环境终端运行 $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses，接受所需许可证后重试。';
    }
    if (RegExp(
      r'(?:sdk\.dir|ndk\.dir|ndkPath|cmake\.dir).*(?:does not exist|not a valid|invalid|does not contain)',
      caseSensitive: false,
    ).hasMatch(line)) {
      blocker =
          '项目配置的 SDK/NDK/CMake 路径无效。请检查 local.properties 或 Gradle 中的路径；安装到默认目录不会修复自定义路径。';
    }
    // AGP 的部分错误把包 ID/完整 NDK 版本放在下一行；只在明确失败标题
    // 后的短窗口内解析，普通 SDK 安装列表或 Flutter 版本建议不会触发补包。
    if (_ndkContext > 0) {
      _ndkContext--;
      final match = RegExp(
        r'''Preferred NDK version is ['"](\d+\.\d+\.\d+)['"]''',
      ).firstMatch(line);
      if (match != null) _record('ndk', match[1]!);
    }
    if (line.contains('NDK not configured')) _ndkContext = 3;
    if (_packageContext > 0) {
      _packageContext--;
      final match = RegExp(
        r'^\s*(platforms;android-|build-tools;|ndk;|cmake;)([0-9]+(?:\.[0-9]+)*)\s',
      ).firstMatch('$line ');
      if (match != null) {
        final id = switch (match[1]) {
          'platforms;android-' => 'platforms',
          'build-tools;' => 'build-tools',
          'ndk;' => 'ndk',
          _ => 'cmake',
        };
        _record(id, match[2]!);
      }
    }
    if (RegExp(
      r'Failed to install the following (?:Android )?SDK (?:components|packages)',
      caseSensitive: false,
    ).hasMatch(line)) {
      _packageContext = 12;
    }
    if (RegExp(
      r'Cannot run program|A problem occurred starting process|Exec format error|No such file or directory',
      caseSensitive: false,
    ).hasMatch(line)) {
      for (final id in ['build-tools', 'ndk', 'cmake']) {
        final match = RegExp(
          '/$id/'
          r'''(\d+\.\d+\.\d+)/(?:[^\r\n"']*/)?(?:aapt2?|aidl|zipalign|clang(?:\+\+)?|cmake|ninja)(?:["'\s]|$)''',
        ).firstMatch(line);
        if (match != null) _record(id, match[1]!);
      }
    }
    for (final (needle, component) in [
      (
        'Flit: AAPT2 unavailable.',
        const AndroidComponent('build-tools', ToolchainCatalog.sdkVersion),
      ),
      ('Unable to locate adb', const AndroidComponent('platform-tools')),
    ]) {
      if (line.contains(needle)) _found[component.key] = component;
    }
    final rules = <(String, RegExp)>[
      (
        'platforms',
        RegExp(
          r'''Failed to find (?:target|Platform SDK) with (?:hash string|path):?\s*["']?(?:platforms;)?android-(\d+(?:\.\d+)?)(?![\w+-]|\.\d)''',
          caseSensitive: false,
        ),
      ),
      (
        'build-tools',
        RegExp(
          r'Failed to find Build Tools revision (\d+\.\d+\.\d+)(?![\w+-]|\.\d)',
          caseSensitive: false,
        ),
      ),
      (
        'build-tools',
        RegExp(
          r'Installed Build Tools revision (\d+\.\d+\.\d+) is corrupted',
          caseSensitive: false,
        ),
      ),
      (
        'ndk',
        RegExp(
          r'NDK (\d+\.\d+\.\d+) (?:was not found|not found|is not installed|not installed)',
          caseSensitive: false,
        ),
      ),
      (
        'ndk',
        RegExp(
          r'No version of NDK matched the requested version (\d+\.\d+\.\d+)(?![\w+-]|\.\d)',
          caseSensitive: false,
        ),
      ),
      (
        'ndk',
        RegExp(
          r'NDK at .*[/\\]ndk[/\\](\d+\.\d+\.\d+) did not have a source.properties file',
          caseSensitive: false,
        ),
      ),
      (
        'ndk',
        RegExp(
          r'''NDK not configured.*version (?:is )?['"]?(\d+\.\d+\.\d+)(?![\w+-]|\.\d)''',
          caseSensitive: false,
        ),
      ),
      (
        'cmake',
        RegExp(
          r'''CMake (?:version )?['"]?(\d+\.\d+\.\d+)['"]? (?:was not found|not found|is not installed|not installed)''',
          caseSensitive: false,
        ),
      ),
    ];
    for (final (id, pattern) in rules) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        _record(id, match[1]!);
      }
    }
  }
}
