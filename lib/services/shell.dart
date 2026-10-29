import 'package:flit_env/flit_env.dart';

/// shell 单引号转义(拼终端命令用)
String shQuote(String s) => "'${s.replaceAll("'", r"'\''")}'";

/// 终端长命令统一前缀: 执行前先 source env.sh。
/// PTY bash 的环境在启动那一刻冻结, 装完工具链旧会话也拿不到新 PATH;
/// 命令自带 source 后, 任何年龄的会话都能用上最新环境；已有配置加载失败时保留诊断并停止命令。
const terminalEnvSource =
    r'if [ -f "$HOME/.flit/env.sh" ]; then . "$HOME/.flit/env.sh" || exit $?; fi; ';

/// Termux 环境操作与短命令: 无状态的进程边界门面, 原生薄方法在 flit_env 插件。
/// 交互终端与流式任务属于 ConsoleSession; 这里的 exec 只跑本地短命令(检测、
/// 列目录、读文件), 不走网络, 所以不需要知道代理。
class Shell {
  Shell._();
  static final Shell instance = Shell._();

  Future<Map<dynamic, dynamic>> bootstrapStatus() => FlitEnv.bootstrapStatus();

  /// 原生全量解压 bootstrap 到 $PREFIX；失败通过 PlatformException 传递原始错误。
  Future<bool> deployBootstrap(String zipPath) =>
      FlitEnv.deployBootstrap(zipPath);

  /// 一次性执行(不进交互会话), 返回 (exitCode, output)
  Future<Map<dynamic, dynamic>> exec(String cmd, {int timeoutMs = 120000}) =>
      FlitEnv.exec(cmd, timeoutMs: timeoutMs);

  /// 文件 sha256(原生分块计算, 产物校验用)
  Future<String> sha256OfFile(String path) => FlitEnv.sha256(path);

  /// 唤起系统浏览器(git 认证等场景; 终端进程无法自己打开 Intent)
  Future<bool> openUrl(String url) => FlitEnv.openUrl(url);

  /// 直达系统设置页(action 见 android.provider.Settings,
  /// 如 android.settings.APPLICATION_DEVELOPMENT_SETTINGS = 开发者选项)
  Future<bool> openSettings(String action) => FlitEnv.openSettings(action);
}
