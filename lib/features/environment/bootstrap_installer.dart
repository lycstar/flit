import 'dart:io';

import '../../services/shell.dart';

/// bootstrap 阶段: 从 GitHub Release 下载明文 ZIP → 校验完整性 → 全量解压。
/// 输出下载地址、进度、校验结果和原生解压错误。
/// 基础环境必须与应用前缀一致，地址与校验值由清单提供。
class BootstrapInstaller {
  static Future<void> install({
    required String url,
    required String sha256,
    required String workDir,
    required void Function(String) log,
    void Function(String)? progress,
  }) async {
    if (url.isEmpty || sha256.isEmpty) {
      throw StateError(
        '基础环境的下载配置不完整，'
        '请更新应用后重试',
      );
    }

    final tmp = File('$workDir/bootstrap-flit.zip');
    if (tmp.existsSync()) tmp.deleteSync();

    log('正在下载基础环境…');
    log('下载地址：$url');
    final client = HttpClient();
    try {
      final req = await client.getUrl(Uri.parse(url));
      final resp = await req.close();
      if (resp.statusCode != 200) {
        throw StateError('下载失败：HTTP ${resp.statusCode}，请检查下载地址和网络后重试');
      }
      final total = resp.contentLength;
      final sink = tmp.openWrite();
      var received = 0;
      var nextPct = 10;
      try {
        await for (final chunk in resp) {
          received += chunk.length;
          sink.add(chunk);
          if (total > 0 && received * 100 >= nextPct * total) {
            // 进度走独立回调: 调用方用 \r 原地刷新, 不产生满屏行
            progress?.call(
              '下载 ${received * 100 ~/ total}%（${(received / 1048576).toStringAsFixed(0)} MB）',
            );
            nextPct = (received * 100 ~/ total ~/ 10 + 1) * 10;
          }
        }
      } finally {
        await sink.close();
      }
    } finally {
      client.close();
    }
    log('下载完成（${(tmp.lengthSync() / 1048576).toStringAsFixed(1)} MB）');

    log('正在校验 SHA-256：$sha256');
    final got = await Shell.instance.sha256OfFile(tmp.path);
    if (got != sha256) {
      throw StateError('基础环境安装包校验失败：\n期望：$sha256\n实际：$got');
    }

    log('SHA-256 校验通过');
    log('正在安装基础环境（解压与配置）…');
    final result = await Shell.instance.deployBootstrap(tmp.path);
    if (result != true) {
      throw StateError('原生安装器未确认基础环境安装成功');
    }
    tmp.deleteSync();
    log('基础环境已就绪');
  }
}
