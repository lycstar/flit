import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/environment/environment_controller.dart';
import 'package:flit/features/environment/toolchain_catalog.dart';

void main() {
  test('prefixed release tags pass real versions to SDK installers', () async {
    final home = Directory.systemTemp.createTempSync('flit-release-tags-');
    addTearDown(() => home.deleteSync(recursive: true));
    final scripts = Directory('${home.path}/.flit/scripts')
      ..createSync(recursive: true);
    for (final item in [
      ('flutter-sdk', 'flutter-3.47.8', 'flutter_sdk.sh', '3.47.8'),
      ('cmake', 'cmake-3.31.6', 'android_cmake.sh', '3.31.6'),
    ]) {
      File(
        '${scripts.path}/${item.$3}',
      ).writeAsStringSync('printf "%s" "\$4" > "\$HOME/version"\n');
      final command = EnvironmentController.buildInstallCommand(
        CatalogEntry(
          component: item.$1,
          repo: 'example/tools',
          tag: item.$2,
          name: 'archive.tar.xz',
          url: 'https://example.invalid/archive',
          size: 0,
          sha256: 'a' * 64,
        ),
      );
      final result = await Process.run(
        'bash',
        ['-c', command],
        environment: {'HOME': home.path},
      );
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(File('${home.path}/version').readAsStringSync(), item.$4);
    }
  });

  test(
    'SDK catalog refreshes Gradle policy only after a successful install',
    () async {
      final home = Directory.systemTemp.createTempSync('flit-sdk-catalog-');
      addTearDown(() => home.deleteSync(recursive: true));
      final scripts = Directory('${home.path}/.flit/scripts')
        ..createSync(recursive: true);
      File('${scripts.path}/android_sdk.sh').writeAsStringSync(
        'echo sdk >> "\$HOME/calls"\nexit "\${SDK_EXIT:-0}"\n',
      );
      File(
        '${scripts.path}/android_gradle.sh',
      ).writeAsStringSync('echo gradle >> "\$HOME/calls"\n');
      final command = EnvironmentController.buildInstallCommand(
        CatalogEntry(
          component: 'android-sdk',
          repo: 'example/sdk',
          tag: '36',
          name: 'sdk.tar.xz',
          url: 'https://example.invalid/sdk',
          size: 0,
          sha256: 'a' * 64,
        ),
      );
      final failed = await Process.run(
        'bash',
        ['-c', command],
        environment: {'HOME': home.path, 'SDK_EXIT': '1'},
      );
      expect(failed.exitCode, 1);
      expect(File('${home.path}/calls').readAsStringSync(), 'sdk\n');
      File('${home.path}/calls').deleteSync();
      final success = await Process.run(
        'bash',
        ['-c', command],
        environment: {'HOME': home.path, 'SDK_EXIT': '0'},
      );
      expect(success.exitCode, 0, reason: success.stderr.toString());
      expect(File('${home.path}/calls').readAsStringSync(), 'sdk\ngradle\n');
    },
  );

  test('NDK catalog uses the same installer as initialization', () {
    final command = EnvironmentController.buildInstallCommand(
      CatalogEntry(
        component: 'ndk',
        repo: 'example/ndk',
        tag: 'ndk-r28c',
        name: 'ndk.tar.xz',
        url: 'https://example.invalid/ndk',
        size: 0,
        sha256: 'a' * 64,
      ),
    );
    expect(command, contains('android_ndk.sh" --release'));
    expect(command, isNot(contains('curl')));
  });
}
