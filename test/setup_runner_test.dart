import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/environment/setup_runner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'sourcing generated environment is idempotent and never rewrites APT',
    () async {
      final root = Directory.systemTemp.createTempSync('flit-env-');
      addTearDown(() => root.deleteSync(recursive: true));
      final home = Directory('${root.path}/home')..createSync();
      final prefix = Directory('${root.path}/usr')..createSync();
      final source = File('${prefix.path}/etc/apt/sources.list');
      source.parent.createSync(recursive: true);
      source.writeAsStringSync('keep this configuration\n');
      await SetupRunner(home: home.path, prefix: prefix.path).installScripts();
      final result = await Process.run(
        'bash',
        [
          '-eu',
          '-c',
          r'''
. "$HOME/.flit/env.sh"
first_path=$PATH
first_lib=$LD_LIBRARY_PATH
. "$HOME/.flit/env.sh"
[ "$PATH" = "$first_path" ]
[ "$LD_LIBRARY_PATH" = "$first_lib" ]
[ "$FLUTTER_VERSION" = "3.47.8" ]
[ "${PATH%%:*}" = "$HOME/toolchains/flutter/current/bin" ]
case ":$PATH:" in *":$ANDROID_HOME/platform-tools:$PREFIX/bin:"*) ;; *) exit 2 ;; esac
printf '%s\n' "$PATH" "$LD_LIBRARY_PATH"
''',
        ],
        environment: {
          'HOME': home.path,
          'PREFIX': prefix.path,
          'PATH':
              '${prefix.path}/bin:${home.path}/toolchains/android-sdk/platform-tools:/usr/bin:/bin',
          'LD_LIBRARY_PATH': '${prefix.path}/lib',
        },
      );
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(source.readAsStringSync(), 'keep this configuration\n');
      expect(
        Directory('${prefix.path}/etc/apt/sources.list.d').existsSync(),
        isFalse,
      );
    },
  );
}
