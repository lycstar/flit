import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'bootstrap_installer.dart';
import 'setup_runner.dart';
import '../../services/shell.dart';
import '../terminal/console_session.dart';
import 'toolchain_catalog.dart';

/// 安装步骤定义(展示顺序, 3 个可见阶段); OpenJDK 归入 Android 阶段作子项。
/// 各阶段实体仍是 assets/scripts/ 下的 .sh, 与组件 id 的映射见 stageScripts。
const stageDefs = [
  {'id': 'bootstrap', 'title': '基础环境', 'hint': 'Bash · 软件包管理器'},
  {
    'id': 'android_sdk',
    'title': 'Android 工具链',
    'hint': 'OpenJDK 17 · Android SDK · NDK · CMake · Gradle 配置',
  },
  {
    'id': 'flutter_sdk',
    'title': 'Flutter 工具链',
    'hint': 'Flutter SDK · Git 与 gh · 预热',
  },
];

/// 可见阶段 -> 子任务。子任务是管线的一等公民: 一个脚本 = 一个状态 = 一个可重试单位
/// = 卡片上一行; 脚本自带 probe(--check)/install, "算不算装好"与安装逻辑写在一处。
const stageParts = <String, List<String>>{
  'bootstrap': ['bootstrap'],
  'android_sdk': [
    'android_jdk',
    'android_sdk',
    'android_ndk',
    'android_cmake',
    'android_gradle',
  ],
  'flutter_sdk': ['flutter_tools', 'flutter_sdk', 'flutter_warmup'],
};

/// 可见阶段实际执行的脚本顺序(已 DONE 的子任务自动跳过, 重试从断点续)
const stageScripts = <String, List<String>>{
  'android_sdk': [
    'android_jdk',
    'android_sdk',
    'android_ndk',
    'android_cmake',
    'android_gradle',
  ],
  'flutter_sdk': ['flutter_tools', 'flutter_sdk', 'flutter_warmup'],
};

/// 安装就绪判据 = 全部子任务 DONE(bootstrap 由 bootstrapStatus 单独判)。
/// main.dart 的首页就绪探测从这里取 id, 不许自己再抄一份(改子任务必然漏改)。
final readyStageIds = [
  for (final parts in stageParts.values)
    for (final id in parts)
      if (id != 'bootstrap') id,
];

/// 子任务在卡片上的名字
const partNames = <String, String>{
  'android_jdk': 'OpenJDK 17',
  'android_sdk': 'Android SDK',
  'android_ndk': 'NDK',
  'android_cmake': 'CMake',
  'android_gradle': 'Gradle 配置',
  'flutter_tools': 'Git 与 gh',
  'flutter_sdk': 'Flutter SDK',
  'flutter_warmup': '预热',
};

/// 过程性步骤不上卡片(下载解压/预热是内部动作, 不是"装了什么组件")
const hiddenParts = {'bootstrap', 'flutter_warmup'};

/// 各子任务安装体积(du), 口径互斥不重叠:
/// bootstrap = PREFIX 扣掉 jdk/flutter(它们装在前缀里, 直接 du 会重复计数);
/// SDK 扣掉 NDK(NDK 装在 SDK 目录内); Gradle 名下记构建缓存(随构建增长);
/// Flutter SDK 名下记 pub 包缓存(随 pub get 增长)。行上只显示 名称+版本+体积。
const _sizeProbeCmd = r'''
P=$(du -sk "$PREFIX" 2>/dev/null | cut -f1)
J=$(du -sk "$PREFIX/lib/jvm/java-17-openjdk" 2>/dev/null | cut -f1)
F=$(du -sk "$PREFIX/opt/flutter" 2>/dev/null | cut -f1)
U=$(du -sk "$HOME/.pub-cache" 2>/dev/null | cut -f1)
S=$(du -sk "$HOME/android-sdk" 2>/dev/null | cut -f1)
G=$(du -sk "$HOME/.gradle" 2>/dev/null | cut -f1)
N=$(du -sk "$HOME/android-sdk/ndk" 2>/dev/null | cut -f1)
M=$(du -sk "$HOME/android-sdk/cmake" 2>/dev/null | cut -f1)
B=$(du -sk "$PREFIX/bin" 2>/dev/null | cut -f1)
L=$(du -sk "$PREFIX/lib" 2>/dev/null | cut -f1)
D=$(du -sk "$PREFIX/var/lib/dpkg" 2>/dev/null | cut -f1)
K=$(dpkg -l 2>/dev/null | grep -c '^ii')
echo bootstrap:$(( ${P:-0} - ${J:-0} - ${F:-0} ))
echo android_jdk:${J:-0}
echo android_sdk:$(( ${S:-0} - ${N:-0} - ${M:-0} ))
echo android_ndk:${N:-0}
echo android_cmake:${M:-0}
echo android_gradle:${G:-0}
echo flutter_sdk:$(( ${F:-0} + ${U:-0} ))
''';

/// 在完整行上清洗 ANSI，避免 PTY 分块把颜色转义序列截断。
String stripAnsi(String s) =>
    s.replaceAll(RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'), '');

/// `__STAGE__<id>:<STATE>` → (id, state)。
/// 标记允许粘在其它输出之后(dl 采样的进度残片与脚本输出同行)。
(String, String)? parseStageMarker(String line) {
  final i = line.indexOf('__STAGE__');
  if (i < 0) return null;
  final body = line.substring(i + '__STAGE__'.length);
  final c = body.indexOf(':');
  if (c <= 0) return null;
  return (body.substring(0, c), body.substring(c + 1).trim());
}

/// `__VER__<id>:<文本>` → (id, 版本文本)
(String, String)? parseVersionMarker(String line) {
  final i = line.indexOf('__VER__');
  if (i < 0) return null;
  final body = line.substring(i + '__VER__'.length);
  final c = body.indexOf(':');
  if (c <= 0) return null;
  return (body.substring(0, c), body.substring(c + 1).trim());
}

/// `__NET__<目标>:<HTTP码>|<详情>` → (目标, HTTP码, 详情)
(String, String, String)? parseNetMarker(String line) {
  final i = line.indexOf('__NET__');
  if (i < 0) return null;
  final body = line.substring(i + '__NET__'.length);
  final c = body.indexOf(':');
  if (c <= 0) return null;
  final name = body.substring(0, c);
  final rest = body.substring(c + 1).trim();
  return (name, rest.split('|').first.trim(), rest);
}

/// 步骤状态(state) + 就绪后的版本号/安装体积
class StageState {
  String state = 'PENDING'; // DONE / PENDING / RUNNING / FAILED / BLOCKED
  String? version;
  String? size;
}

/// App-owned installation task; navigation never changes its process lifetime.
class EnvironmentController extends ChangeNotifier {
  EnvironmentController({required ProcessLauncher launcher})
    : _launcher = launcher;

  final ProcessLauncher _launcher;

  /// 当前任务的控制台: 安装=run(能停能删), 检测/探测=temp(只能删)。
  /// 没任务或被 ✕ 关掉后为 null, 面板回落到默认 bash——会话只在任务跑起来时才有。
  ConsoleSession? console;
  Future<void>? _initializing;
  bool checking = false;

  /// 版本目录的安装进行中(临时会话流式输出)
  bool installing = false;
  bool get busy => pipelineRunning || checking;
  // 状态按子任务维护(bootstrap + 7 个脚本), 展示层按 stageParts 聚合成 3 行
  final Map<String, StageState> stages = {
    for (final parts in stageParts.values)
      for (final part in parts) part: StageState(),
  };
  bool pipelineRunning = false;
  bool allDone = false;

  String? home;
  String? prefix;
  SetupRunner? _runner;

  final StringBuffer _lineBuf = StringBuffer();

  /// 网络通路探测结果(最近一次): 目标 -> (通, "HTTP码|耗时秒")
  final Map<String, ({bool ok, String detail})> netPaths = {};

  /// 版本目录: 下载并安装指定产物(临时会话流式输出)。
  /// ndk 安装到 ndk/`<Pkg.Revision>`(AGP 按 ndkVersion 检索); sdk 合并进
  /// 单棵树; flutter 按版本并存，通过 current 切换。
  Future<void> installFromCatalog(CatalogEntry entry) async {
    if (busy || installing || _runner == null) {
      _term('当前有任务进行中，请等待完成后再安装版本', color: _cWarn);
      return;
    }
    if (stages['bootstrap']!.state != 'DONE') {
      _term('请先安装基础环境，再安装其他版本', color: _cWarn);
      return;
    }
    if (ToolchainCatalog.parseSha256('sha256:${entry.sha256}') == null) {
      _term('该产物缺少校验值，已拒绝安装', color: _cErr);
      return;
    }
    installing = true;
    notifyListeners();
    final c = _openConsole('安装 ${entry.name}', SessionKind.temp);
    try {
      final code = await _runInTerminal(
        c,
        buildInstallCommand(entry),
        timeout: const Duration(minutes: 45),
      );
      if (code == 0) {
        _line(c, '✓ ${entry.name} 安装完成', _cOk);
        await refreshStatus();
      } else {
        _line(c, '安装失败，退出码 $code（详细输出见上）', _cErr);
      }
    } finally {
      installing = false;
      notifyListeners();
    }
  }

  @visibleForTesting
  static String buildInstallCommand(CatalogEntry entry) {
    final sha = entry.sha256!;
    final script = switch (entry.component) {
      'android-sdk' => 'android_sdk.sh',
      'flutter-sdk' => 'flutter_sdk.sh',
      _ => null,
    };
    if (script != null) {
      return 'bash "\$HOME/.flit/scripts/$script" --release '
          '${shQuote(entry.url)} ${shQuote(sha)}'
          '${entry.component == 'flutter-sdk' ? ' ${shQuote(entry.tag)}' : ''}';
    }
    final url = shQuote(entry.url);
    final shaCheck =
        'echo ${shQuote('$sha  ')}"\$tmp/pkg" '
        '| sha256sum -c - || { rm -rf "\$tmp"; exit 1; }\n';
    final body = switch (entry.component) {
      'ndk' =>
        'tar -xJf "\$tmp/pkg" -C "\$tmp" '
            "--exclude='*/shader-tools/linux-x86_64*' "
            "--exclude='*/toolchains/llvm/prebuilt/linux-x86_64*'\n"
            'set -- "\$tmp"/android-ndk-*; ndk=\$1\n'
            '[ -d "\$ndk" ] || exit 1\n'
            'rev=\$(sed -n \'s/^Pkg\\.Revision[[:space:]]*=[[:space:]]*//p\' "\$ndk/source.properties" '
            '| head -n1 | tr -d \' \\r\')\n'
            '[ -n "\$rev" ] || { echo \'无法读取 Pkg.Revision\'; rm -rf "\$tmp"; exit 1; }\n'
            'mkdir -p "\$HOME/android-sdk/ndk"\n'
            'ln -sfn linux-arm64 "\$ndk/shader-tools/linux-x86_64"\n'
            'ln -sfn linux-arm64 "\$ndk/toolchains/llvm/prebuilt/linux-x86_64"\n'
            'test -x "\$ndk/toolchains/llvm/prebuilt/linux-arm64/bin/clang" || exit 1\n'
            'rm -rf "\$HOME/android-sdk/ndk/\$rev"\n'
            'mv "\$ndk" "\$HOME/android-sdk/ndk/\$rev"\n'
            'printf "%s\\n" ${shQuote(sha)} > "\$HOME/android-sdk/ndk/\$rev/.flit-complete"\n'
            'rm -rf "\$tmp"\n'
            'echo "已安装 NDK \$rev"',
      _ => throw StateError('组件不支持版本安装: ${entry.component}'),
    };
    return 'set -e\n'
        'tmp=\$(mktemp -d) || exit 1\n'
        "trap 'rm -rf \"\$tmp\"' EXIT\n"
        'curl -fL --retry 3 -o "\$tmp/pkg" $url || { rm -rf "\$tmp"; exit 1; }\n'
        '$shaCheck'
        '$body';
  }

  Future<void> probeNetwork() async {
    if (busy || _runner == null) return;
    if (stages['bootstrap']!.state != 'DONE') {
      _term('请先安装基础环境，再执行网络检测', color: _cWarn);
      return;
    }
    checking = true;
    netPaths.clear();
    notifyListeners();
    try {
      await _runInTerminal(
        _openConsole('网络检测', SessionKind.temp),
        'bash ${shQuote('${_runner!.scriptsDir}/net_probe.sh')}',
        timeout: const Duration(minutes: 2),
      );
    } finally {
      checking = false;
      notifyListeners();
    }
  }

  Future<void> init() => _initializing ??= _init();
  Future<void> _init() async {
    try {
      final st = await Shell.instance.bootstrapStatus();
      home = st['home'] as String?;
      prefix = st['prefix'] as String?;
      if (home != null && prefix != null) {
        final runner = SetupRunner(home: home!, prefix: prefix!);
        await runner.installScripts();
        _runner = runner;
      }
    } catch (e) {
      _term('环境检测失败：$e', color: _cErr);
    }
    await refreshStatus();
  }

  static const _cOk = '\x1b[1;32m'; // 成功绿
  static const _cErr = '\x1b[1;31m'; // 失败红
  static const _cWarn = '\x1b[1;33m'; // 警示黄

  /// 新任务开一个新控制台(环境页只有一个终端位, 替换上一个);
  /// 被 ✕ 关掉后自动置空, 面板回落默认 bash。
  ConsoleSession _openConsole(String title, SessionKind kind) {
    final previous = console;
    final session = ConsoleSession(
      title: title,
      kind: kind,
      launcher: _launcher,
    );
    session.textStream.listen(_onPtyText);
    session.addListener(() {
      if (session.disposed && identical(console, session)) {
        console = null;
        notifyListeners();
      }
    });
    console = session;
    notifyListeners();
    unawaited(previous?.close());
    return session;
  }

  /// 不隶属某个任务的消息(初始化失败/前置条件提示): 写到当前控制台,
  /// 没有就开一个「环境检测」
  void _term(String msg, {String color = ''}) =>
      _line(console ?? _openConsole('环境检测', SessionKind.temp), msg, color);

  /// 任务内消息: 写到任务自己的控制台; 用户已 ✕ 关掉就不再弹新的
  void _line(ConsoleSession c, String msg, [String color = '']) {
    if (c.disposed) return;
    c.log.line(color.isEmpty ? msg : '$color$msg\x1b[0m');
    notifyListeners();
  }

  /// PTY 文本流: 行缓冲 → ANSI 清洗 → 标记解析(阶段状态/检查完成)。
  void _onPtyText(String chunk) {
    _lineBuf.write(chunk);
    final text = _lineBuf.toString();
    final lines = text.split(RegExp(r'[\r\n]'));
    _lineBuf
      ..clear()
      ..write(lines.removeLast()); // 末段可能是不完整行, 留给下一块
    for (final rawLine in lines) {
      final line = stripAnsi(rawLine).trim();
      // 网络通路标记: __NET__<目标>:<HTTP码>|<耗时秒>(000 = 不通)
      final net = parseNetMarker(line);
      if (net != null) {
        netPaths[net.$1] = (
          ok: net.$3.isNotEmpty && net.$3 != '000',
          detail: net.$3,
        );
        notifyListeners();
        continue;
      }
      final m = parseStageMarker(line);
      if (m == null) {
        // 终端已原样显示输出；这里只解析版本标记
        final v = parseVersionMarker(line);
        if (v != null && stages.containsKey(v.$1)) {
          stages[v.$1]!.version = v.$2;
          notifyListeners();
        }
        continue;
      }
      final id = m.$1;
      final state = m.$2;
      if (stages.containsKey(id)) {
        stages[id]!.state = state;
        if (state != 'DONE') stages[id]!.version = null;
        _updateAllDone();
        notifyListeners();
      }
    }
  }

  void _updateAllDone() {
    allDone = stages.values.every((s) => s.state == 'DONE');
  }

  /// 已装状态重算: 在终端内可见地跑 check.sh(幂等, 供重启后续装)。
  Future<void> refreshStatus() async {
    if (busy) return;
    checking = true;
    notifyListeners();
    try {
      final bootstrapped =
          (await Shell.instance.bootstrapStatus())['bootstrapped'] == true;
      stages['bootstrap']!.state = bootstrapped ? 'DONE' : 'PENDING';
      for (final id in stages.keys.where((k) => k != 'bootstrap')) {
        stages[id]!.state = 'PENDING';
        stages[id]!.version = null;
      }
      if (bootstrapped && _runner != null) {
        final c = _openConsole('环境检测', SessionKind.temp);
        final code = await _runInTerminal(
          c,
          'bash ${shQuote('${_runner!.scriptsDir}/check.sh')}',
          timeout: const Duration(minutes: 2),
        );
        if (code != 0) _line(c, '环境检查未完成，退出码 $code', _cErr);
        await _loadSizes();
      }
      _updateAllDone();
    } finally {
      checking = false;
      notifyListeners();
    }
  }

  Future<int> _runInTerminal(
    ConsoleSession c,
    String command, {
    Duration timeout = const Duration(minutes: 45),
  }) async {
    if (c.disposed) return -1;
    _lineBuf.clear();
    final code = await c.run(command, timeout: timeout);
    if (_lineBuf.isNotEmpty) _onPtyText('\n');
    return code;
  }

  /// 就绪组件的安装体积 + 展开子项(du), 失败静默——纯展示信息。
  Future<void> _loadSizes() async {
    try {
      final res = await Shell.instance.exec(_sizeProbeCmd, timeoutMs: 60000);
      for (final line in (res['output'] as String? ?? '').split('\n')) {
        final i = line.indexOf(':');
        if (i <= 0) continue;
        final id = line.substring(0, i);
        final kb = int.tryParse(line.substring(i + 1).trim());
        if (stages.containsKey(id) && kb != null && kb > 0) {
          stages[id]!.size = _humanSize(kb);
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  static String _humanSize(int kb) {
    if (kb >= 1024 * 1024) return '${(kb / 1024 / 1024).toStringAsFixed(1)} GB';
    if (kb >= 1024) return '${(kb / 1024).toStringAsFixed(0)} MB';
    return '$kb KB';
  }

  // ---------- 流水线 ----------

  /// 一键安装: bootstrap(Dart 下载/解压, 进度进终端) → 其余阶段脚本
  /// 顺序在真终端里执行(失败即停, 后续 BLOCKED)。
  /// 停止旗标只有会话这一份(终端头部的停止按钮直接 stop 会话), 每步做完看一眼。
  Future<void> startPipeline() async {
    if (busy || _runner == null) return;
    pipelineRunning = true;
    // 整个安装共用一个 run 控制台: 能停(⏹, 输出留着,「继续安装」重跑)能删(✕)
    final c = _openConsole('安装环境', SessionKind.run);
    try {
      // ① bootstrap: 下载自建产物(校验) → 原生全量解压(bash/软链/权限)
      if (stages['bootstrap']!.state != 'DONE') {
        stages['bootstrap']!.state = 'RUNNING';
        notifyListeners();
        // 这一步在 Dart 侧原生完成、没有 PTY 进程; 登记为会话任务, 终端头部
        // 才有"运行中"和停止按钮。下载打不断, 停止 = 本步结束后不再继续
        c.beginTask();
        try {
          final spec = await _runner!.bootstrapSpec();
          await BootstrapInstaller.install(
            url: spec.url,
            sha256: spec.sha256,
            workDir: File(prefix!).parent.path, // files/(勿放 $PREFIX, 解压会先清空它)
            log: (message) => _line(c, message, '\x1b[36m'),
            progress: (message) => _progress(c, message),
          );
          // 装完就是装完: 用户停止只决定"不再继续下一阶段", 不丢弃成果
          stages['bootstrap']!.state = 'DONE';
          notifyListeners();
          if (_stopped(c)) return;
        } catch (e) {
          _line(c, '✗ 基础环境安装失败：$e', _cErr);
          stages['bootstrap']!.state = 'FAILED';
          _blockAfter('bootstrap');
          return;
        } finally {
          c.endTask(code: stages['bootstrap']!.state == 'DONE' ? 0 : 1);
        }
      }

      // ②~③ 可见阶段在真终端里顺序执行; 阶段内逐组件跑, 已完成自动跳过
      for (final s in stageDefs.skip(1)) {
        final id = s['id'] as String;
        final title = s['title'] as String;
        for (final part in stageScripts[id]!) {
          if (stages[part]!.state == 'DONE') continue;
          stages[part]!.state = 'RUNNING';
          notifyListeners();
          await _runStageInTerminal(c, part);
          if (_stopped(c)) return;
          if (stages[part]!.state != 'DONE') {
            _line(c, '✗ $title 安装失败，已跳过后续步骤', _cErr);
            _blockAfter(id);
            return;
          }
        }
        _line(c, '✓ $title 完成', _cOk);
      }

      _line(c, '✓ 安装完成，开发环境已就绪', _cOk);
    } finally {
      await _loadSizes();
      pipelineRunning = false;
      for (final stage in stages.values) {
        if (stage.state == 'RUNNING') {
          stage.state = c.stopRequested ? 'PENDING' : 'FAILED';
        }
      }
      _updateAllDone();
      notifyListeners();
    }
  }

  /// 用户停止: 不判失败、已完成的阶段保留, 点「继续安装」从断点续装
  bool _stopped(ConsoleSession c) {
    if (!c.stopRequested) return false;
    _line(c, '已停止，可随时继续安装', _cWarn);
    return true;
  }

  /// 进度: \r 原地刷新单行(wget 风格), 不产生满屏行
  void _progress(ConsoleSession c, String msg) {
    if (c.disposed) return;
    c.log.progress(msg);
    notifyListeners();
  }

  Future<void> _runStageInTerminal(ConsoleSession c, String id) async {
    final code = await _runInTerminal(
      c,
      'bash ${shQuote('${_runner!.scriptsDir}/$id.sh')}',
    );
    if (c.stopRequested) {
      stages[id]!.state = 'PENDING';
    } else if (code == 0) {
      // 退出码是唯一成功判据(脚本任何错误都 die 非零); __STAGE__ DONE 标记
      // 只做过程展示, 不能反过来否决一次成功的安装
      stages[id]!.state = 'DONE';
    } else {
      stages[id]!.state = 'FAILED';
    }
    _updateAllDone();
    notifyListeners();
  }

  void _blockAfter(String id) {
    // id = 失败的可见阶段; 其后的可见阶段整体拉黑(已完成组件除外)
    var blocked = false;
    for (final s in stageDefs) {
      final sid = s['id'] as String;
      if (sid == id) {
        blocked = true;
        continue;
      }
      if (blocked) {
        for (final part in stageParts[sid]!) {
          if (stages[part]!.state != 'DONE') {
            stages[part]!.state = 'BLOCKED';
          }
        }
      }
    }
    notifyListeners();
  }
}
