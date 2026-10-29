import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

/// 脚本驱动的一键初始化编排。
/// bootstrap 由原生全量解压(MainActivity.deployBootstrap); 其后各阶段脚本
/// 由环境页写入环境专用终端执行, 输出实时可见、可 Ctrl+C。
class SetupRunner {
  SetupRunner({required this.home, required this.prefix});

  final String home;
  final String prefix;

  /// 与 flutter.ndkVersion 对齐(AGP 按目录名匹配); 同见 lib.sh 默认值
  static const ndkVersion = '28.2.13676358';

  static const _scriptNames = [
    'lib.sh',
    'check.sh',
    'android_jdk.sh',
    'android_sdk.sh',
    'android_ndk.sh',
    'android_gradle.sh',
    'flutter_sdk.sh',
    'flutter_tools.sh',
    'flutter_warmup.sh',
    'net_probe.sh',
  ];

  String get scriptsDir => '$home/.flit/scripts';
  String get tmpDir => '$prefix/tmp';

  /// 阶段脚本 + env.sh 写入 $HOME/.flit(每次覆盖, 随 app 更新)。
  Future<void> installScripts() async {
    final dir = Directory(scriptsDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    for (final name in _scriptNames) {
      final text = await rootBundle.loadString('assets/scripts/$name');
      File('$scriptsDir/$name').writeAsStringSync(text);
    }
    // env.sh 必须在 .flit/ 根下 —— lib.sh 按此路径 source(放 scripts/ 里找不到)
    File('$home/.flit/env.sh').writeAsStringSync(await _renderEnvSh());
  }

  /// 从 manifest 生成 env.sh(URL/sha256 唯一事实源)。
  Future<String> _renderEnvSh() async {
    final root =
        jsonDecode(
              await rootBundle.loadString('assets/toolchain_manifest.json'),
            )
            as Map<String, dynamic>;
    final pkg = (root['packages'] as Map).cast<String, dynamic>();
    Map<String, dynamic> p(String id) =>
        (pkg[id] as Map).cast<String, dynamic>();
    String urls(Map<String, dynamic> p) =>
        (p['urls'] as List? ?? const []).map((u) => "'$u'").join(' ');
    String sha(Map<String, dynamic> p, String key) => (p[key] as String?) ?? '';

    final sdk = p('android-sdk');
    final ndk = p('ndk');
    final flt = p('flutter-sdk');
    return '''
# 由 flit 从 toolchain_manifest.json 生成, 每次初始化覆盖; 勿手改
export ANDROID_HOME="\$HOME/android-sdk"
export JAVA_HOME="\$PREFIX/lib/jvm/java-17-openjdk"
# termux 版 JDK 把 java.io.tmpdir 烧死成 com.termux 前缀, 必须覆盖
export JDK_JAVA_OPTIONS="-Djava.io.tmpdir=\$PREFIX/tmp"
# libjvm.so 依赖同包 lib/ 下的 libandroid-shmem.so, dlopen 按 LD_LIBRARY_PATH 搜索
# 保持工具优先级；重复加载时去掉旧条目，避免 PATH/动态库路径越积越长。
_flit_prepend() {
  local name=\$1 entry=\$2 part rest=\${!1} result=\$2
  while [ -n "\$rest" ]; do
    part=\${rest%%:*}
    case "\$rest" in *:*) rest=\${rest#*:} ;; *) rest= ;; esac
    [ -z "\$part" ] || [ "\$part" = "\$entry" ] || result="\$result:\$part"
  done
  export "\$name=\$result"
}
export LD_LIBRARY_PATH="\${LD_LIBRARY_PATH:-}"
_flit_prepend LD_LIBRARY_PATH "\$JAVA_HOME/lib"
export GRADLE_USER_HOME="\$HOME/.gradle"
# PATH 必须在 JAVA_HOME 之后(flutter 需要它); platform-tools 提供 SDK 内 adb
_flit_prepend PATH "\$ANDROID_HOME/platform-tools"
_flit_prepend PATH "\$JAVA_HOME/bin"
_flit_prepend PATH "\$PREFIX/opt/flutter/bin"
unset -f _flit_prepend
export TMPDIR="\$PREFIX/tmp"
# flutter/dart 首次需要联网拉取工件与依赖, 走国内镜像(官方源直连不可达)
export PUB_HOSTED_URL="https://pub.flutter-io.cn"
export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
# termux-exec: #!/usr/bin/env 类解释器重写到本前缀(官方 Termux 同款)
for __f in "\$PREFIX/lib/libtermux-exec-ld-preload.so" "\$PREFIX/lib/libtermux-exec.so"; do
  [ -f "\$__f" ] && export LD_PRELOAD="\$__f" && break
done
unset __f
export NDK_VERSION="$ndkVersion"
SDK_URLS=(${urls(sdk)})
SDK_SHA256="${sha(sdk, 'sha256')}"
NDK_URLS=(${urls(ndk)})
NDK_SHA256="${sha(ndk, 'sha256')}"
FLUTTER_URLS=(${urls(flt)})
FLUTTER_SHA256="${sha(flt, 'sha256')}"
# APT 源由需要安装软件包的阶段脚本在安装动作开始时配置。
# source env.sh 只注入环境变量，避免打开终端、查看状态或运行 ADB 时改写系统配置。
export FLIT_APT_SOURCE='${(root['aptSource'] as String? ?? '').replaceAll("'", "'\\''")}'
''';
  }

  /// bootstrap 产物规格(manifest 唯一事实源; url/sha 来自 GitHub Release)
  Future<({String url, String sha256})> bootstrapSpec() async {
    final root =
        jsonDecode(
              await rootBundle.loadString('assets/toolchain_manifest.json'),
            )
            as Map<String, dynamic>;
    final b = ((root['packages'] as Map)['bootstrap'] as Map)
        .cast<String, dynamic>();
    // 下载地址和校验值由清单统一提供。
    return (
      url: (b['url'] as String?) ?? '',
      sha256: (b['sha256'] as String?) ?? '',
    );
  }
}
