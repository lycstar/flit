import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/git/github_account.dart';
import 'package:flit/features/git/project_git.dart';
import 'package:flit/features/terminal/console_session.dart';
import 'package:flit/features/terminal/run_sessions.dart';
import 'package:flit/features/workspace/project_documents.dart';
import 'package:flit/services/git_repo.dart';

import 'git_repo_test.dart' show localGit;
import 'support/fake_session_process.dart';

class _LocalProcess implements SessionProcess {
  _LocalProcess(this.process);
  final Process process;
  @override
  Stream<List<int>> get output => process.stdout;
  @override
  Future<int> get exitCode => process.exitCode;
  @override
  void write(Uint8List data) => process.stdin.add(data);
  @override
  void resize(int rows, int columns) {}
  @override
  void kill() => process.kill();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'staged-only commit works; discard and branch switch refresh cached documents',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'flit-git-actions-',
      );
      final repo = GitRepo(temp.path, execute: localGit);
      final documents = ProjectDocuments(
        temp.path,
        read: (path) async =>
            File(path).existsSync() ? File(path).readAsString() : null,
        write: (path, text) async {
          await File(path).writeAsString(text);
          return true;
        },
      );
      final executions = RunSessions(
        projectPath: temp.path,
        launcher:
            ({
              required command,
              required workingDirectory,
              required rows,
              required columns,
            }) async => _LocalProcess(
              await Process.start(
                'bash',
                ['-c', 'exec 2>&1; $command'],
                workingDirectory: workingDirectory,
                environment: {
                  'GIT_CONFIG_NOSYSTEM': '1',
                  'GIT_CONFIG_GLOBAL': '/dev/null',
                },
              ),
            ),
      );
      final git = ProjectGit(
        documents: documents,
        executions: executions,
        repository: repo,
      );
      try {
        await repo.checked(['init', '--initial-branch=main', '--template=']);
        await repo.checked(['config', 'user.name', 'Test']);
        await repo.checked(['config', 'user.email', 'test@example.invalid']);
        await repo.checked(['config', 'commit.gpgsign', 'false']);
        await File('${temp.path}/main.dart').writeAsString('original');
        await documents.open('main.dart');
        await git.refresh();
        expect(git.snapshot.unborn, true);
        await git.stage(git.snapshot.changes.single);
        documents.current!.controller.text = 'edited after staging';
        await git.unstage(git.snapshot.changes.single);
        expect(git.error, isNull);
        expect(
          await File('${temp.path}/main.dart').readAsString(),
          'edited after staging',
        );
        documents.current!.controller.text = 'original';
        expect(git.snapshot.changes.single.untracked, true);
        await git.stageAll();
        documents.current!.controller.text = 'later edit';
        await git.commit("quoted ' message \$(not-a-command)");
        expect(git.error, isNull);
        expect(await repo.checked(['show', 'HEAD:main.dart']), 'original');
        expect(
          await File('${temp.path}/main.dart').readAsString(),
          'later edit',
        );
        expect(git.snapshot.changes.single.unstaged, true);
        await git.discard(git.snapshot.changes.single);
        expect(git.error, isNull);
        expect(documents.current!.controller.text, 'original');
        expect(documents.current!.controller.canUndo, false);
        expect(documents.current!.dirty, false);
        await repo.checked(['mv', 'main.dart', 'renamed.dart']);
        await File('${temp.path}/renamed.dart').writeAsString('rename edit');
        await git.refresh();
        await git.stage(git.snapshot.changes.single);
        expect(git.error, isNull);
        for (final change in git.snapshot.changes.toList()) {
          await git.unstage(change);
          expect(git.error, isNull);
        }
        await repo.checked(['restore', '--', 'main.dart']);
        await File('${temp.path}/renamed.dart').delete();
        await git.switchBranch('feature', create: true);
        documents.current!.controller.text = 'feature content';
        await git.stageAll();
        await git.commit('feature');
        await git.switchBranch('main');
        expect(git.error, isNull);
        expect(documents.current!.controller.text, 'original');
        expect(git.snapshot.branch, 'main');
        final remote = '${temp.path}/remote.git';
        await Directory(remote).create();
        await GitRepo(
          remote,
          execute: localGit,
        ).checked(['init', '--bare', '--template=']);
        await repo.checked(['remote', 'add', 'origin', remote]);
        await git.push();
        expect(git.error, isNull);
        expect(git.snapshot.upstream, 'origin/main');
        documents.current!.controller.text = 'dirty';
        await git.pull();
        expect(git.error, contains('先提交'));
        expect(documents.current!.controller.text, 'dirty');
      } finally {
        await git.close();
        await executions.closeAll();
        await documents.close();
        await temp.delete(recursive: true);
      }
    },
  );

  test(
    'GitHub auth watches split ANSI codes, does not auto-install, and reflects failed logout',
    () async {
      final processes = <FakeProcess>[];
      final commands = <String>[];
      bool signedIn = false;
      final account = GithubAccount(
        probe: (command) async => (
          code: command.startsWith('command -v') || signedIn ? 0 : 1,
          out: '',
        ),
        launcher:
            ({
              required command,
              required workingDirectory,
              required rows,
              required columns,
            }) async {
              commands.add(command!);
              final process = FakeProcess();
              processes.add(process);
              return process;
            },
      );
      try {
        await account.refresh();
        expect(account.auth, GithubAuth.signedOut);
        final login = account.login();
        await Future<void>.delayed(Duration.zero);
        expect(commands.single, isNot(contains('apt')));
        expect(
          commands.single,
          contains('&& gh auth setup-git --hostname github.com'),
        );
        processes.single.emit(
          '! First copy your one-time code: \x1b[1;32mABCD-',
        );
        processes.single.emit('EFGH\x1b[0m\r\n');
        await Future<void>.delayed(Duration.zero);
        expect(account.deviceCode.value, 'ABCD-EFGH');
        expect(account.busy, true);
        signedIn = true;
        await processes.single.finish();
        expect(await login, true);
        expect(account.auth, GithubAuth.credentialsSaved);
        expect(account.deviceCode.value, isNull);
        final logout = account.logout();
        await Future<void>.delayed(Duration.zero);
        await processes.last.finish(1);
        expect(await logout, false);
        expect(account.auth, GithubAuth.credentialsSaved);
        expect(account.error, contains('退出 GitHub 登录'));
      } finally {
        account.dispose();
      }
    },
  );

  test(
    'worktree mutation blocks edits/saves and removes deleted buffers',
    () async {
      final files = <String, String>{'/p/a.dart': 'old', '/p/b.dart': 'keep'};
      final documents = ProjectDocuments(
        '/p',
        read: (path) async => files[path],
        write: (path, text) async {
          files[path] = text;
          return true;
        },
      );
      await documents.open('a.dart');
      final code = documents.current!.controller;
      code.text = 'saved before operation';
      final ready = Completer<void>(), finished = Completer<void>();
      final changing = documents.changeOnDisk(() async {
        expect(files['/p/a.dart'], 'saved before operation');
        ready.complete();
        await finished.future;
        files['/p/a.dart'] = 'pulled';
      });
      await ready.future;
      code.text = 'must not overwrite';
      code.undo();
      expect(code.text, 'saved before operation');
      expect(await documents.saveAll(), false);
      expect(await documents.open('b.dart'), false);
      finished.complete();
      await changing;
      expect(code.text, 'pulled');
      expect(code.canUndo, false);
      expect(code.editingLocked, false);
      await documents.changeOnDisk(() async {
        files.remove('/p/a.dart');
      });
      expect(documents.current, isNull);
      expect(await documents.saveAll(), true);
      expect(files.containsKey('/p/a.dart'), false);
      await documents.close();
    },
  );
}
