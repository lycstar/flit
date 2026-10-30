import 'dart:io';

/// PTY 进程的启动环境。[proxy] 是启动那一刻的代理变量(由 PtyLauncher 注入),
/// 这里不认识任何开关, 只负责把工具链的路径按"此刻是否已装"拼出来。
Map<String, String> sessionEnvironment(
  String prefix,
  String home, {
  Map<String, String> proxy = const {},
}) {
  final env = <String, String>{
    'HOME': home,
    'PREFIX': prefix,
    'FLIT_TOOLCHAINS': '$home/toolchains',
    'PATH':
        '$prefix/bin:$prefix/bin/applets:$home/toolchains/android-sdk/platform-tools:/system/bin:/system/xbin',
    'ANDROID_ROOT': '/system',
    'ANDROID_DATA': '/data',
    'EXTERNAL_STORAGE': '/sdcard',
    'TMPDIR': '$prefix/tmp',
    'LD_LIBRARY_PATH': '$prefix/lib',
    'LANG': 'en_US.UTF-8',
    'TERM': 'xterm-256color',
    'COLORTERM': 'truecolor',
  }..addAll(proxy);
  // termux-exec: #!/usr/bin/env 类解释器重写(官方 Termux 同款); 新旧包名都认
  for (final so in [
    '$prefix/lib/libtermux-exec-ld-preload.so',
    '$prefix/lib/libtermux-exec.so',
  ]) {
    if (File(so).existsSync()) {
      env['LD_PRELOAD'] = so;
      break;
    }
  }
  // 工具链就绪的组件才注入(与安装阶段检测一致)
  if (File('$home/toolchains/flutter/current/bin/flutter').existsSync()) {
    env['FLUTTER_ROOT'] = '$home/toolchains/flutter/current';
    env['PATH'] = '$home/toolchains/flutter/current/bin:${env['PATH']}';
  }
  final jdk = '$prefix/lib/jvm/java-17-openjdk';
  if (File('$jdk/bin/java').existsSync()) {
    env['JAVA_HOME'] = jdk;
    env['PATH'] = '$jdk/bin:${env['PATH']}';
    // libjvm.so(lib/server/) 依赖同包 lib/ 下的 libandroid-shmem.so
    env['LD_LIBRARY_PATH'] = '$jdk/lib:${env['LD_LIBRARY_PATH']}';
    // termux 版 JDK 把 java.io.tmpdir 烧死成 com.termux 前缀(无视 TMPDIR 环境变量),
    // 必须显式覆盖, 否则 gradle 起不来("tmpdir is set to a directory that doesn't exist")
    env['JDK_JAVA_OPTIONS'] = '-Djava.io.tmpdir=$prefix/tmp';
  }
  final sdk = '$home/toolchains/android-sdk';
  if (Directory('$sdk/build-tools').existsSync()) env['ANDROID_HOME'] = sdk;
  env['GRADLE_USER_HOME'] = '$home/.gradle';
  if (File('$prefix/libexec/git-core/git').existsSync()) {
    env['GIT_EXEC_PATH'] = '$prefix/libexec/git-core';
    // git tarball 编译期前缀是 com.termux, 系统配置/模板指回本前缀
    env['GIT_CONFIG_SYSTEM'] = '$prefix/etc/gitconfig';
    env['GIT_TEMPLATE_DIR'] = '$prefix/share/git-core/templates';
  }
  return env;
}
