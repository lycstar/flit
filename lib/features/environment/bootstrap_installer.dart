import 'package:flit/l10n/strings.dart';
import 'dart:io';

import '../../services/shell.dart';

/// bootstrap 阶段: 从 GitHub Release 下载明文 ZIP → 校验完整性 → 全量解压。
/// 输出下载地址、进度、校验结果和原生解压错误。
/// 基础环境必须与应用前缀一致，地址与校验值在安装时从 GitHub Release API 获取。
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
        strings.baseEnvironmentDownloadConfigurationIsIncompleteUpdate,
      );
    }

    final tmp = File('$workDir/bootstrap-flit.zip');
    if (tmp.existsSync()) tmp.deleteSync();

    log(strings.downloadingBaseEnvironment);
    log(strings.downloadUrlP(url));
    final client = HttpClient();
    try {
      final req = await client.getUrl(Uri.parse(url));
      final resp = await req.close();
      if (resp.statusCode != 200) {
        throw StateError(
          strings.downloadFailedHttpPCheckTheUrl(resp.statusCode),
        );
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
              strings.downloadedPPMb(
                received * 100 ~/ total,
                (received / 1048576).toStringAsFixed(0),
              ),
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
    log(
      strings.downloadCompletePMb(
        (tmp.lengthSync() / 1048576).toStringAsFixed(1),
      ),
    );

    log(strings.verifyingShaP(sha256));
    final got = await Shell.instance.sha256OfFile(tmp.path);
    if (got != sha256) {
      throw StateError(
        strings.baseEnvironmentChecksumMismatchExpectedPActual(sha256, got),
      );
    }

    log(strings.shaVerified);
    log(strings.installingBaseEnvironmentExtractingAndConfiguring);
    final result = await Shell.instance.deployBootstrap(tmp.path);
    if (result != true) {
      throw StateError(strings.nativeInstallerDidNotConfirmASuccessful);
    }
    tmp.deleteSync();
    log(strings.baseEnvironmentReady);
  }
}
