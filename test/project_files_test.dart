import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/workspace/project_documents.dart';
import 'package:flit/features/workspace/project_files.dart';
import 'package:flit/services/file_ops.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final ops = FileOps.instance;
  late Directory sandbox;
  late String root;
  late ProjectDocuments documents;
  late ProjectFiles files;
  var failDecode = false;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('flit-files-');
    root = '${sandbox.path}/shared projects';
    await Directory('$root/lib').create(recursive: true);
    await File('$root/lib/main.dart').writeAsString('original');
    await File('$root/lib/other.dart').writeAsString('other');
    failDecode = false;
    ops.clearClip();
    messenger.setMockMethodCallHandler(const MethodChannel('flit/env'), (
      call,
    ) async {
      if (call.method != 'exec') return null;
      final command = (call.arguments as Map)['cmd'] as String;
      // Production uses Termux coreutils; macOS tests use Homebrew GNU tools.
      final result = await Process.run(
        'bash',
        ['-c', '${failDecode ? 'base64(){ return 42; }; ' : ''}$command'],
        environment: {
          'PATH':
              '/opt/homebrew/opt/coreutils/libexec/gnubin:${Platform.environment['PATH']}',
        },
      );
      return {
        'exitCode': result.exitCode,
        'output': '${result.stdout}${result.stderr}',
      };
    });
    documents = ProjectDocuments(root);
    files = ProjectFiles(documents);
  });

  tearDown(() async {
    await documents.close();
    ops.clearClip();
    messenger.setMockMethodCallHandler(const MethodChannel('flit/env'), null);
    await sandbox.delete(recursive: true);
  });

  test('failed listing preserves files and reports the read error', () async {
    messenger.setMockMethodCallHandler(
      const MethodChannel('flit/env'),
      (_) async => {'exitCode': 0, 'output': 'lib/main.dart\n'},
    );
    await files.refresh();
    messenger.setMockMethodCallHandler(
      const MethodChannel('flit/env'),
      (_) async => {'exitCode': 1, 'output': 'Permission denied'},
    );
    await expectLater(files.refresh(), throwsStateError);
    expect(files.files, ['lib/main.dart']);
  });

  test('an older directory scan cannot overwrite a newer listing', () async {
    final first = Completer<Map<String, Object>>();
    var calls = 0;
    messenger.setMockMethodCallHandler(const MethodChannel('flit/env'), (
      _,
    ) async {
      if (++calls == 1) return first.future;
      return {'exitCode': 0, 'output': 'new.dart\n'};
    });
    final oldScan = files.refresh();
    while (calls == 0) {
      await Future<void>.delayed(Duration.zero);
    }
    await files.refresh();
    first.complete({'exitCode': 0, 'output': ''});
    await oldScan;
    expect(files.files, ['new.dart']);
  });

  test(
    'shared project supports create, rename and delete without granting HOME access',
    () async {
      await files.create(root, "new ' folder", directory: true);
      await files.create("$root/new ' folder", '测试.dart', directory: false);
      await files.rename("$root/new ' folder/测试.dart", 'renamed.dart');
      expect(await File("$root/new ' folder/renamed.dart").exists(), true);
      await files.delete("$root/new ' folder");
      expect(await Directory("$root/new ' folder").exists(), false);
      expect(await File('$root/lib/main.dart').readAsString(), 'original');
    },
  );

  test(
    'rename folder preserves all buffers, undo and subsequent save destinations',
    () async {
      await documents.open('lib/main.dart');
      final main = documents.current!.controller;
      main.text = 'edited';
      await documents.open('lib/other.dart');
      final other = documents.current!.controller;
      other.text = 'other edited';
      await files.rename('$root/lib', 'src');
      expect(documents.current!.path, 'src/other.dart');
      expect(documents.current!.controller, same(other));
      expect(await Directory('$root/lib').exists(), false);
      await documents.open('src/main.dart');
      expect(documents.current!.controller, same(main));
      expect(main.canUndo, true);
      main.text = 'after rename';
      expect(await documents.saveAll(), true);
      expect(await File('$root/src/main.dart').readAsString(), 'after rename');
      expect(await File('$root/src/other.dart').readAsString(), 'other edited');
      expect(await Directory('$root/lib').exists(), false);
    },
  );

  test(
    'external edits are reloaded when clean and never overwritten when dirty',
    () async {
      await documents.open('lib/main.dart');
      final controller = documents.current!.controller;
      final file = File('$root/lib/main.dart');
      await file.writeAsString('changed in terminal');
      await documents.open('lib/main.dart');
      expect(documents.current!.controller, same(controller));
      expect(controller.text, 'changed in terminal');
      controller.text = 'editor changes';
      await file.writeAsString('another external change');
      expect(await documents.saveAll(), false);
      expect(await file.readAsString(), 'another external change');
      expect(controller.text, 'editor changes');
      expect(documents.conflictPath, 'lib/main.dart');
      await documents.reload('lib/main.dart');
      expect(controller.text, 'another external change');
      expect(documents.saveFailed, false);
      controller.text = 'edit before external deletion';
      await file.delete();
      expect(await documents.saveAll(), false);
      await documents.reload('lib/main.dart');
      expect(documents.current, isNull);
      expect(await documents.saveAll(), true);
      expect(await file.exists(), false);
    },
  );

  test(
    'deleting an open folder removes buffers and autosave cannot recreate files',
    () async {
      await documents.open('lib/main.dart');
      documents.current!.controller.text = 'edited';
      await documents.open('lib/other.dart');
      documents.current!.controller.text = 'other edited';
      await files.delete('$root/lib');
      expect(documents.current, isNull);
      expect(await documents.saveAll(), true);
      expect(await Directory('$root/lib').exists(), false);
      await expectLater(documents.open('lib/main.dart'), throwsStateError);
    },
  );

  test(
    'cut to the project root updates the open document and clears the clipboard',
    () async {
      await documents.open('lib/main.dart');
      documents.current!.controller.text = 'edited';
      ops.clipPath = '$root/lib/main.dart';
      ops.clipRoot = root;
      ops.clipCut = true;
      await files.paste(root);
      expect(documents.current!.path, 'main.dart');
      expect(ops.hasClip, false);
      expect(await File('$root/main.dart').readAsString(), 'edited');
      documents.current!.controller.text = 'new';
      await documents.saveAll();
      expect(await File('$root/lib/main.dart').exists(), false);
      expect(await File('$root/main.dart').readAsString(), 'new');
    },
  );

  test(
    'failed save aborts rename and retains dirty text; retry recovers',
    () async {
      await documents.open('lib/main.dart');
      documents.current!.controller.text = 'unsaved';
      failDecode = true;
      await expectLater(
        files.rename('$root/lib/main.dart', 'new.dart'),
        throwsStateError,
      );
      expect(documents.current!.path, 'lib/main.dart');
      expect(documents.current!.controller.text, 'unsaved');
      expect(documents.saveFailed, true);
      expect(await File('$root/lib/main.dart').readAsString(), 'original');
      expect(await File('$root/lib/new.dart').exists(), false);
      final leftovers = await Directory('$root/lib').list().toList();
      expect(leftovers.any((e) => e.path.contains('.flit-save.')), false);
      failDecode = false;
      await files.rename('$root/lib/main.dart', 'new.dart');
      expect(documents.saveFailed, false);
      expect(await File('$root/lib/new.dart').readAsString(), 'unsaved');
    },
  );

  test(
    'existing destinations including dangling links are never overwritten',
    () async {
      await Link('$root/lib/dangling.dart').create('${sandbox.path}/missing');
      for (final target in ['other.dart', 'dangling.dart']) {
        await expectLater(
          files.rename('$root/lib/main.dart', target),
          throwsStateError,
        );
      }
      await expectLater(
        files.create('$root/lib', 'other.dart', directory: false),
        throwsStateError,
      );
      ops.clipPath = '$root/lib/main.dart';
      ops.clipCut = false;
      await expectLater(files.paste('$root/lib'), throwsStateError);
      expect(await File('$root/lib/main.dart').readAsString(), 'original');
      expect(await File('$root/lib/other.dart').readAsString(), 'other');
      expect(
        await Link('$root/lib/dangling.dart').target(),
        '${sandbox.path}/missing',
      );
    },
  );

  test(
    'root, traversal and symlink escapes cannot mutate outside files',
    () async {
      final outside = Directory('${sandbox.path}/toolchain');
      await outside.create();
      final sdk = File('${outside.path}/sdk');
      await sdk.writeAsString('keep');
      await Link('$root/outside').create(outside.path);
      await Link('$root/root-link').create(root);
      for (final path in [
        root,
        '$root/../toolchain/sdk',
        '$root/outside/sdk',
        '$root/root-link',
      ]) {
        final result = await ops.delete(path, allowedRoot: root);
        expect(result.ok, false, reason: path);
      }
      expect(
        (await ops.createFile('$root/outside', 'new', allowedRoot: root)).ok,
        false,
      );
      expect(
        (await ops.moveInto(
          '$root/lib',
          '$root/lib',
          sourceRoot: root,
          destinationRoot: root,
        )).ok,
        false,
      );
      expect(
        (await ops.copyInto(root, '$root/lib', destinationRoot: root)).ok,
        false,
      );
      await expectLater(documents.open('../toolchain/sdk'), throwsStateError);
      await expectLater(documents.open('outside/sdk'), throwsStateError);
      expect(await sdk.readAsString(), 'keep');
      expect(await File('${outside.path}/new').exists(), false);
    },
  );

  test(
    'external imports copy only and cannot overwrite an edited file',
    () async {
      final external = File('${sandbox.path}/import.txt');
      await external.writeAsString('imported');
      ops.clipPath = external.path;
      ops.clipCut = false;
      await files.paste(root);
      expect(await File('$root/import.txt').readAsString(), 'imported');
      expect(await external.exists(), true);
      ops.clipCut = true;
      await expectLater(files.paste('$root/lib'), throwsStateError);
      expect(await external.exists(), true);
    },
  );

  test(
    'atomic save preserves executable bits and rejects a deleted file',
    () async {
      final script = File('$root/tool.sh');
      await script.writeAsString('old');
      await Process.run('chmod', ['755', script.path]);
      await documents.open('tool.sh');
      documents.current!.controller.text = 'new';
      expect(await documents.saveAll(), true);
      expect((await script.stat()).mode & 511, 493);
      await script.delete();
      documents.current!.controller.text = 'later';
      expect(await documents.saveAll(), false);
      expect(await script.exists(), false);
      expect(documents.current!.controller.text, 'later');
    },
  );

  test(
    'a pending save completes before rename and blocks concurrent mutations',
    () async {
      final pending = Completer<bool>();
      final entered = Completer<void>();
      final docs = ProjectDocuments(
        '/project',
        read: (_) async => 'old',
        write: (_, _) {
          if (!entered.isCompleted) entered.complete();
          return pending.future;
        },
      );
      await docs.open('a.dart');
      docs.current!.controller.text = 'new';
      var renamed = false;
      final renaming = docs.renamePath(
        'a.dart',
        'b.dart',
        apply: () async => renamed = true,
      );
      await entered.future;
      expect(renamed, false);
      expect(docs.current!.controller.editingLocked, true);
      await expectLater(
        docs.deletePath('a.dart', apply: () async {}),
        throwsStateError,
      );
      pending.complete(true);
      await renaming;
      expect(renamed, true);
      expect(docs.current!.path, 'b.dart');
      expect(docs.current!.controller.editingLocked, false);
      await docs.close();
    },
  );
}
