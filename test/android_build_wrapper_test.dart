import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/environment/android_build_wrapper.dart';
import 'package:flit/features/environment/toolchain_catalog.dart';
import 'package:flit/features/terminal/run_sessions.dart';

import 'support/fake_session_process.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'diagnostics span PTY chunks, deduplicate and ignore ordinary mentions',
    () {
      final diagnostics = AndroidBuildDiagnostics();
      diagnostics.add(
        'compileSdk android-34\nNDK 27.1.12297006 is recommended\n',
      );
      diagnostics.add('\x1b[31mFailed to find Plat');
      diagnostics.add('form SDK with path: platforms;android-34\x1b[0m\r\n');
      diagnostics.add("Failed to find target with hash string 'android-34'\n");
      diagnostics.add('Failed to find Build Tools revision 35.0.0\n');
      diagnostics.add(
        'NDK at /sdk/ndk/28.2.13676358 did not have a source.properties file\n',
      );
      diagnostics.add(
        "CMake '3.22.1' was not found in SDK, PATH, or by cmake.dir property.",
      );
      diagnostics.finish();
      expect(diagnostics.components.map((c) => c.key), [
        'platforms:34',
        'build-tools:35.0.0',
        'ndk:28.2.13676358',
        'cmake:3.22.1',
      ]);
    },
  );

  test('multiline AGP errors and native executable paths identify exact versions', () {
    final diagnostics = AndroidBuildDiagnostics();
    diagnostics.add(
      "NDK not configured.\nDownload it with SDK manager. Preferred NDK version is '27.0.12077973'.\n",
    );
    diagnostics.add(
      'Failed to install the following SDK components:\n  cmake;3.22.1 CMake 3.22.1\n',
    );
    diagnostics.add(
      'Cannot run program "/sdk/cmake/3.31.6/bin/ninja": error=8, Exec format error\n',
    );
    diagnostics.add(
      "A problem occurred starting process 'command '/sdk/build-tools/35.0.0/aapt2''\n",
    );
    diagnostics.add(
      'Cannot run program "/sdk/ndk/28.2.13676358/toolchains/llvm/prebuilt/linux-x86_64/bin/clang": error=8\n',
    );
    diagnostics.finish();
    expect(diagnostics.components.map((c) => c.key), [
      'ndk:27.0.12077973',
      'cmake:3.22.1',
      'cmake:3.31.6',
      'build-tools:35.0.0',
      'ndk:28.2.13676358',
    ]);
    final ordinary = AndroidBuildDiagnostics()
      ..add('Installed packages:\n  ndk;27.0.12077973 NDK\n');
    ordinary.finish();
    expect(ordinary.components, isEmpty);
  });

  test(
    'literal declarations exclude comments, variables and computed versions',
    () {
      final found = AndroidBuildWrapper.declaredComponents('''
// ndkVersion = "99.0.123"
/* compileSdk = 99 */
compileSdk = 35
buildToolsVersion "35.0.0"
ndkVersion = flutter.ndkVersion
ndkVersion = "28.2.13676358"
compileSdk = 30 + 5
version = "9.9.9"
cmake {
  version = "3.22.1"
}
''');
      expect(found.map((c) => c.key), [
        'platforms:35',
        'build-tools:35.0.0',
        'ndk:28.2.13676358',
        'cmake:3.22.1',
      ]);
    },
  );

  test(
    'NDK revision chooses candidate r tag without a bundled version table',
    () {
      expect(AndroidBuildWrapper.ndkTag('27.0.12077973'), 'ndk-r27');
      expect(AndroidBuildWrapper.ndkTag('28.2.13676358'), 'ndk-r28c');
      expect(() => AndroidBuildWrapper.ndkTag('28.2.bad'), throwsStateError);
    },
  );

  test(
    'license and invalid configured paths are blockers, not download requests',
    () {
      final license = AndroidBuildDiagnostics()
        ..add(
          '> Failed to install the following Android SDK packages as some licences have not been accepted.\n'
          '> ndk;28.2.13676358 NDK\n',
        );
      license.finish();
      expect(license.blocker, contains('许可证'));
      final path = AndroidBuildDiagnostics()
        ..add('ndk.dir /old/ndk does not contain a valid NDK\n');
      path.finish();
      expect(path.blocker, contains('路径无效'));
    },
  );

  test(
    'preview and extension versions are never truncated into stable versions',
    () {
      final diagnostics = AndroidBuildDiagnostics()
        ..add(
          'Failed to find Build Tools revision 36.0.0-rc1\n'
          "Failed to find target with hash string 'android-36-ext15'\n"
          'No version of NDK matched the requested version 29.0.12345-beta1\n',
        );
      diagnostics.finish();
      expect(diagnostics.components, isEmpty);
      diagnostics.add(
        '> Failed to install the following SDK components:\n> cmake;3.22.1 CMake\n',
      );
      expect(diagnostics.components.single.key, 'cmake:3.22.1');
    },
  );

  late RunSessions executions;
  late AndroidBuildWrapper wrapper;
  late ToolchainCatalog catalog;
  final commands = <String>[];
  final processes = <FakeProcess>[];
  final requests = <AndroidRepairRequest>[];
  final probes = <String>[];
  var probeOutput = '';
  var probeCode = 0;
  var accept = true;
  var saves = 0;
  Completer<bool>? confirmation;
  const config = RunConfiguration(
    id: 'build',
    title: 'APK',
    command: 'build-apk',
    exclusive: true,
  );

  Future<void> flush() async {
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<RunSession> launch(
    RunConfiguration c,
    void Function(String)? onText,
  ) => executions.start(c, onText: onText);
  Future<bool> confirm(AndroidRepairRequest request) async {
    requests.add(request);
    return confirmation?.future ?? accept;
  }

  Future<RunSession> start() => wrapper.start(
    config,
    launch: launch,
    confirm: confirm,
    save: () async {
      saves++;
    },
  );

  setUp(() {
    commands.clear();
    processes.clear();
    requests.clear();
    probes.clear();
    probeOutput = '';
    probeCode = 0;
    accept = true;
    saves = 0;
    confirmation = null;
    AndroidBuildWrapper.installing = false;
    executions = RunSessions(
      projectPath: '/project',
      launcher:
          ({
            required command,
            required workingDirectory,
            required rows,
            required columns,
          }) async {
            commands.add(command!);
            final p = FakeProcess();
            processes.add(p);
            return p;
          },
    );
    catalog = ToolchainCatalog();
    catalog.fetchJson = (url) async {
      final tag = Uri.decodeComponent(Uri.parse(url).pathSegments.last);
      final asset = tag.startsWith('platform-')
          ? 'platforms.tar.xz'
          : tag.startsWith('ndk-')
          ? 'android-ndk-r28c-aarch64-linux-android.tar.xz'
          : 'build-tools.tar.xz';
      return {
        'tag_name': tag,
        'assets': [
          {
            'name': asset,
            'browser_download_url': 'https://example.test/$asset',
            'digest': 'sha256:${'a' * 64}',
          },
        ],
      };
    };
    wrapper = AndroidBuildWrapper(
      executions: executions,
      catalog: catalog,
      requirements: () async => [],
      probe: (command) async {
        probes.add(command);
        final result = probeOutput;
        probeOutput = '';
        return {'exitCode': probeCode, 'output': result};
      },
    );
  });
  tearDown(() async {
    wrapper.dispose();
    await executions.closeAll();
  });

  test(
    'preflight asks once, installs before build, and verifies SDK paths',
    () async {
      probeOutput = '__MISSING__ndk:28.2.13676358\n';
      final future = start();
      await flush();
      expect(requests.single.afterFailure, false);
      expect(commands.single, contains('android_ndk.sh'));
      expect(commands.single, endsWith("'28.2.13676358'"));
      expect(AndroidBuildWrapper.installing, true);
      await processes.single.finish();
      final session = await future;
      expect(commands.last, 'build-apk');
      expect(probes.last, contains('ndk:28.2.13676358'));
      expect(AndroidBuildWrapper.installing, false);
      expect(saves, 1);
      await processes.last.finish();
      await session.done;
    },
  );

  test('cancelling preflight never installs or builds', () async {
    probeOutput = '__MISSING__platforms:34\n';
    accept = false;
    await expectLater(start(), throwsStateError);
    expect(commands, isEmpty);
  });

  test('failed probe is not treated as healthy', () async {
    probeCode = 1;
    await expectLater(start(), throwsStateError);
    expect(commands, isEmpty);
    expect(requests, isEmpty);
  });

  test(
    'failed build installs exact component, retries once and then stops',
    () async {
      final session = await start();
      processes.first.emit('Failed to find Build Tools revision 35.0.0\n');
      await processes.first.finish(1);
      await session.done;
      await flush();
      expect(requests.single.afterFailure, true);
      expect(commands[1], contains("'35.0.0'"));
      await processes[1].finish();
      await flush();
      expect(commands, hasLength(3));
      expect(commands.last, 'build-apk');
      processes.last.emit('Failed to find Build Tools revision 34.0.0\n');
      await processes.last.finish(1);
      await flush();
      expect(commands, hasLength(3));
      expect(requests, hasLength(1));
    },
  );

  test('successful build and unrelated failures do not prompt', () async {
    final session = await start();
    processes.first.emit('compileSdk android-35\nNDK 28.2.13676358\n');
    await processes.first.finish(1);
    await session.done;
    await flush();
    expect(requests, isEmpty);
    expect(commands, ['build-apk']);
  });

  test(
    'missing release explains failure without using another version',
    () async {
      catalog.fetchJson = (_) async => throw const HttpException('HTTP 404');
      final session = await start();
      processes.first.emit('NDK 27.1.12297006 was not found\n');
      await processes.first.finish(1);
      await session.done;
      await flush();
      expect(requests.single.error, isNotNull);
      expect(commands, ['build-apk']);
    },
  );

  test('Platform alone may use Google on release 404', () async {
    catalog.fetchJson = (_) async => throw const HttpException('HTTP 404');
    final session = await start();
    processes.first.emit(
      "Failed to find target with hash string 'android-29'\n",
    );
    await processes.first.finish(1);
    await session.done;
    await flush();
    expect(commands[1], contains('android_platform.sh'));
    expect(commands[1], contains("'29'"));
    await processes[1].finish(1);
    await flush();
    expect(commands, hasLength(2));
  });

  test('network error never triggers official fallback', () async {
    catalog.fetchJson = (_) async => throw const HttpException('HTTP 403');
    probeOutput = '__MISSING__platforms:34\n';
    await expectLater(start(), throwsStateError);
    expect(requests.single.error, contains('HTTP 403'));
    expect(commands, isEmpty);
  });

  test('closing failed session during dialog prevents installation', () async {
    confirmation = Completer<bool>();
    final session = await start();
    processes.first.emit('Failed to find Build Tools revision 35.0.0\n');
    await processes.first.finish(1);
    await session.done;
    await flush();
    await executions.close(session.id);
    confirmation!.complete(true);
    await flush();
    expect(commands, ['build-apk']);
  });

  test('new user action invalidates an old repair prompt', () async {
    confirmation = Completer<bool>();
    final session = await start();
    processes.first.emit('Failed to find Build Tools revision 35.0.0\n');
    await processes.first.finish(1);
    await session.done;
    await flush();
    wrapper.cancelPending();
    confirmation!.complete(true);
    await flush();
    expect(commands, ['build-apk']);
  });

  test('project disposal while installing never rebuilds', () async {
    final session = await start();
    processes.first.emit('Failed to find Build Tools revision 35.0.0\n');
    await processes.first.finish(1);
    await session.done;
    await flush();
    wrapper.dispose();
    await processes.last.finish();
    await flush();
    expect(commands, hasLength(2));
    expect(AndroidBuildWrapper.installing, false);
  });

  test('closing installer cancels retry', () async {
    final session = await start();
    processes.first.emit('Failed to find Build Tools revision 35.0.0\n');
    await processes.first.finish(1);
    await session.done;
    await flush();
    await executions.close(
      executions.forConfiguration('android-components')!.id,
    );
    await flush();
    expect(commands, hasLength(2));
    expect(AndroidBuildWrapper.installing, false);
  });
  test(
    'license failure displays guidance without reinstalling an existing package',
    () async {
      final session = await start();
      processes.first.emit(
        'Failed to install the following SDK components because licenses have not been accepted\nndk;28.2.13676358 NDK\n',
      );
      await processes.first.finish(1);
      await session.done;
      await flush();
      expect(requests.single.error, contains('许可证'));
      expect(commands, ['build-apk']);
    },
  );
}
