import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/environment/environment_controller.dart';
import 'package:flit/features/environment/toolchain_catalog.dart';

void main() {
  test(
    'NDK catalog installation verifies, repairs links and records completion',
    () async {
      final root = Directory.systemTemp.createTempSync('flit-catalog-');
      addTearDown(() => root.deleteSync(recursive: true));
      final source = Directory('${root.path}/source/android-ndk-r28c');
      File('${source.path}/source.properties')
        ..createSync(recursive: true)
        ..writeAsStringSync('Pkg.Revision=28.2.13676358\n');
      final clang =
          File('${source.path}/toolchains/llvm/prebuilt/linux-arm64/bin/clang')
            ..createSync(recursive: true)
            ..writeAsStringSync('#!/bin/sh\nexit 0\n');
      expect((await Process.run('chmod', ['+x', clang.path])).exitCode, 0);
      Directory(
        '${source.path}/shader-tools/linux-arm64',
      ).createSync(recursive: true);
      final archive = File('${root.path}/ndk.tar.xz');
      expect(
        (await Process.run('tar', [
          '-cJf',
          archive.path,
          '-C',
          source.parent.path,
          source.uri.pathSegments.where((s) => s.isNotEmpty).last,
        ])).exitCode,
        0,
      );
      final entry = CatalogEntry(
        component: 'ndk',
        repo: 'example/ndk',
        tag: 'r28',
        name: 'ndk.tar.xz',
        url: archive.uri.toString(),
        size: archive.lengthSync(),
        sha256: (await Process.run('sha256sum', [
          archive.path,
        ])).stdout.toString().split(' ').first,
      );
      final home = Directory('${root.path}/home')..createSync();
      final command = EnvironmentController.buildInstallCommand(entry);
      final result = await Process.run(
        'bash',
        ['-c', command],
        environment: {'HOME': home.path},
      );
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      final installed = '${home.path}/android-sdk/ndk/28.2.13676358';
      expect(
        File('$installed/.flit-complete').readAsStringSync().trim(),
        entry.sha256,
      );
      expect(
        Link('$installed/toolchains/llvm/prebuilt/linux-x86_64').targetSync(),
        'linux-arm64',
      );

      // A damaged archive must not replace an already installed NDK or its marker.
      clang.deleteSync();
      expect(
        (await Process.run('tar', [
          '-cJf',
          archive.path,
          '-C',
          source.parent.path,
          'android-ndk-r28c',
        ])).exitCode,
        0,
      );
      final broken = CatalogEntry(
        component: 'ndk',
        repo: entry.repo,
        tag: entry.tag,
        name: entry.name,
        url: entry.url,
        size: archive.lengthSync(),
        sha256: (await Process.run('sha256sum', [
          archive.path,
        ])).stdout.toString().split(' ').first,
      );
      final failed = await Process.run(
        'bash',
        ['-c', EnvironmentController.buildInstallCommand(broken)],
        environment: {'HOME': home.path},
      );
      expect(failed.exitCode, isNot(0));
      expect(
        File('$installed/.flit-complete').readAsStringSync().trim(),
        entry.sha256,
      );
      expect(
        File(
          '$installed/toolchains/llvm/prebuilt/linux-arm64/bin/clang',
        ).existsSync(),
        isTrue,
      );
    },
  );
}
