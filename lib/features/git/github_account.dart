import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../services/shell.dart';
import '../terminal/console_session.dart';

enum GithubAuth { missing, signedOut, credentialsSaved }

/// gh 的探测结果(命令退出码 + 输出), 与 GitRepo 的 execute 形态一致, 便于测试注入。
typedef GithubProbe = Future<({int code, String out})> Function(String command);

/// GitHub 账户是全局的(gh 凭据存在 ~/.config/gh), 不属于某个工程。
/// 登录走 Device Flow: 对话框给授权码 → 浏览器里授权 → gh 轮询拿令牌 →
/// `gh auth setup-git` 接上 git 凭据助手, 之后私库克隆/推送都非交互完成。
/// 握手过程没有值得看的终端输出, 命令跑在一个不展示的临时会话里, 失败原因进 error。
class GithubAccount extends ChangeNotifier {
  GithubAccount({required ProcessLauncher launcher, GithubProbe? probe})
    : _launcher = launcher,
      _probe = probe ?? _shellProbe;

  final ProcessLauncher _launcher;
  final GithubProbe _probe;

  GithubAuth auth = GithubAuth.signedOut;
  bool busy = false;
  String? error;

  /// 登录中的一次性授权码; 非空时调用方弹对话框, 登录结束置空(对话框自动关)
  final deviceCode = ValueNotifier<String?>(null);
  ConsoleSession? _console;
  Future<void>? _refreshing;

  static const loginCommand =
      'LC_ALL=C gh auth login --hostname github.com --git-protocol https --web </dev/null '
      '&& gh auth setup-git --hostname github.com';
  static const logoutCommand =
      'gh auth logout --hostname github.com </dev/null';

  static Future<({int code, String out})> _shellProbe(String command) async {
    final result = await Shell.instance.exec(
      '$terminalEnvSource$command',
      timeoutMs: 15000,
    );
    return (
      code: result['exitCode'] as int? ?? -1,
      out: result['output'] as String? ?? '',
    );
  }

  bool get signedIn => auth == GithubAuth.credentialsSaved;

  Future<void> refresh() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<void> _refresh() async {
    try {
      final installed = await _probe('command -v gh >/dev/null 2>&1');
      if (installed.code != 0) {
        auth = GithubAuth.missing;
      } else {
        final token = await _probe(
          'gh auth token --hostname github.com >/dev/null 2>&1',
        );
        auth = token.code == 0
            ? GithubAuth.credentialsSaved
            : GithubAuth.signedOut;
      }
    } catch (_) {
      // 环境未就绪(还没有 bash)等情况保持上次状态
    }
    notifyListeners();
  }

  /// 发起 Device Flow 登录; 授权码出现在 [deviceCode], 完成后刷新状态。
  Future<bool> login() async {
    if (busy) return false;
    if (auth == GithubAuth.missing) {
      error = '尚未安装 gh，请先在开发环境页完成 Flutter 阶段安装';
      notifyListeners();
      return false;
    }
    busy = true;
    error = null;
    deviceCode.value = null;
    notifyListeners();
    final console = _console = ConsoleSession(
      title: 'GitHub 登录',
      launcher: _launcher,
    );
    var output = '';
    final watch = console.textStream.listen((chunk) {
      // 授权码可能被 ANSI 色码和数据块边界切开: 去色后在累计文本上匹配
      output = '$output$chunk'.replaceAll(
        RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'),
        '',
      );
      if (output.length > 8192) output = output.substring(output.length - 8192);
      final match = RegExp(
        r'one-time code:\s*([A-Z0-9]{4}-[A-Z0-9]{4})',
      ).firstMatch(output);
      if (match != null && deviceCode.value != match.group(1)) {
        deviceCode.value = match.group(1);
      }
    });
    try {
      // 授权码 15 分钟过期, gh 轮询到期自行退出; 超时兜底再长一点
      final code = await console.run(
        loginCommand,
        timeout: const Duration(minutes: 16),
      );
      if (code != 0) {
        final tail = output
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .lastOrNull;
        error = console.stopRequested
            ? '已取消登录'
            : '登录未完成（退出码 $code）${tail == null ? '' : '：$tail'}';
      }
      return code == 0;
    } catch (e) {
      error = '登录失败：$e';
      return false;
    } finally {
      await watch.cancel();
      deviceCode.value = null;
      _console = null;
      unawaited(console.close());
      busy = false;
      await _refresh();
    }
  }

  /// 对话框「取消登录」: 结束 gh 的轮询
  Future<void> cancelLogin() async => _console?.stop();

  Future<bool> logout() async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    final console = ConsoleSession(title: '退出 GitHub 登录', launcher: _launcher);
    try {
      final code = await console.run(
        logoutCommand,
        timeout: const Duration(seconds: 30),
      );
      if (code != 0) error = '退出 GitHub 登录未完成（退出码 $code）';
      return code == 0;
    } catch (e) {
      error = '退出 GitHub 登录失败：$e';
      return false;
    } finally {
      unawaited(console.close());
      busy = false;
      await _refresh();
    }
  }

  @override
  void dispose() {
    deviceCode.dispose();
    super.dispose();
  }
}
