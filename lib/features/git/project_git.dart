import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../services/git_repo.dart';
import '../terminal/run_sessions.dart';
import '../workspace/project_documents.dart';

/// One Git operation per project; its lifetime is independent of the sidebar.
/// GitHub 账户(登录/登出/状态)是全局的, 见 GithubAccount; 这里只管仓库操作。
class ProjectGit extends ChangeNotifier {
  ProjectGit({
    required this.documents,
    required this.executions,
    this.preparing,
    GitRepo? repository,
  }) : repo = repository ?? GitRepo(documents.projectPath);

  final ProjectDocuments documents;
  final RunSessions executions;
  final ValueListenable<String?>? preparing;
  bool get blocked =>
      !repo.supported ||
      busy ||
      loading ||
      executions.active != null ||
      executions.starting ||
      preparing?.value != null;
  final GitRepo repo;
  GitSnapshot snapshot = const GitSnapshot();
  String? error;
  bool loading = false, busy = false, _closed = false;
  int revision = 0;
  Future<void>? _refreshing;
  Future<void>? _operation;
  RunSession? _task;

  Future<void> refresh() {
    if (_closed || busy) return Future.value();
    return _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  }

  Future<void> _refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final state = await repo.snapshot();
      if (!_closed) snapshot = state;
    } catch (e) {
      if (!_closed) error = '$e';
    } finally {
      if (!_closed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _mutate(
    Future<void> Function() action, {
    bool changesFiles = false,
  }) {
    if (_closed) return Future.error(StateError('项目已关闭'));
    if (!repo.supported) {
      return Future.error(StateError('请打开 Git 仓库根目录后使用版本控制'));
    }
    if (blocked) return Future.error(StateError('当前有任务正在运行，请先结束后再执行 Git 操作'));
    busy = true;
    error = null;
    notifyListeners();
    return _operation = (() async {
      try {
        // Validate the selected directory before any mutation, including when
        // the caller has not opened or refreshed the Git panel yet.
        await repo.snapshot();
        if (changesFiles) {
          await documents.changeOnDisk(action);
        } else {
          if (!await documents.saveAll()) throw StateError('保存失败，已取消 Git 操作');
          if (_closed) return;
          await action();
        }
      } catch (e) {
        if (!_closed) error = '$e';
      } finally {
        if (!_closed) {
          final operationError = error;
          busy = false;
          revision++;
          notifyListeners();
          await _refresh();
          if (operationError != null) {
            error = operationError;
            notifyListeners();
          }
        }
      }
    })().whenComplete(() => _operation = null);
  }

  Future<void> _command(List<String> args, {String title = 'Git'}) =>
      _terminal(repo.command(args), title: title);

  Future<void> _terminal(String command, {required String title}) async {
    if (_closed) return;
    _task = await executions.start(
      RunConfiguration(id: 'git', title: title, command: command),
    );
    if (_closed) await _task!.stop();
    final code = await _task!.done;
    if (code != 0) throw StateError('$title 未完成（退出码 $code），请查看终端输出');
  }

  Future<void> initialize() =>
      _mutate(() => _command(['init'], title: '初始化仓库'));
  Future<void> stage(GitChange change) => _mutate(
    () => _command([
      'add',
      '--',
      if (change.x == 'R' || change.x == 'C') change.path else ...change.paths,
    ]),
  );
  Future<void> stageAll() => _mutate(() => _command(['add', '-A']));
  Future<void> unstage(GitChange change) => _mutate(
    () => _command(
      snapshot.unborn
          ? ['rm', '--cached', '-f', '--', ...change.paths]
          : ['restore', '--staged', '--', ...change.paths],
    ),
  );
  Future<void> commit(String message) => _mutate(() async {
    if (message.trim().isEmpty) throw StateError('请输入提交消息');
    final state = await repo.snapshot();
    if (state.hasConflicts) throw StateError('请先解决冲突并暂存文件');
    if (!state.changes.any((c) => c.staged)) throw StateError('请先暂存需要提交的文件');
    await _command(['commit', '-m', message.trim()], title: '提交');
  });
  Future<void> discard(GitChange change) => _mutate(() async {
    if (change.untracked || change.conflicted) throw StateError('当前文件状态不支持回滚');
    await _command([
      'restore',
      '--worktree',
      '--',
      change.path,
    ], title: '回滚未暂存的更改');
  }, changesFiles: true);
  Future<void> switchBranch(String branch, {bool create = false}) =>
      _mutate(() async {
        final state = await repo.snapshot();
        if (state.changes.isNotEmpty) throw StateError('请先提交或回滚当前更改，再切换分支');
        await _command(
          create ? ['switch', '-c', branch] : ['switch', branch],
          title: '切换分支',
        );
      }, changesFiles: true);
  Future<void> pull() => _mutate(() async {
    final state = await repo.snapshot();
    if (state.changes.isNotEmpty) throw StateError('请先提交或回滚当前更改，再拉取');
    if (state.upstream == null) throw StateError('当前分支未设置上游分支，请先推送并关联远程分支');
    await _command(['pull', '--ff-only'], title: '拉取');
  }, changesFiles: true);
  Future<void> push() => _mutate(() async {
    final state = await repo.snapshot();
    if (state.detached || state.unborn) throw StateError('请先切换到分支并创建提交');
    if (state.hasConflicts) throw StateError('请先解决冲突');
    if (state.upstream != null) {
      await _command(['push'], title: '推送');
    } else {
      final remotes = (await repo.checked([
        'remote',
      ])).split('\n').where((s) => s.isNotEmpty).toList();
      if (remotes.length != 1) {
        throw StateError('首次推送需要一个远程仓库，请在「远程仓库」中配置 origin');
      }
      await _command([
        'push',
        '--set-upstream',
        remotes.single,
        state.branch,
      ], title: '首次推送');
    }
  });
  Future<void> setRemote(String url) => _mutate(() async {
    if (!RegExp(r'^(https?://|ssh://|git@)\S+$').hasMatch(url)) {
      throw StateError('请输入有效的仓库地址');
    }
    final existing = await repo.run(['remote', 'get-url', 'origin']);
    await _command(
      existing.code == 0
          ? ['remote', 'set-url', 'origin', url]
          : ['remote', 'add', 'origin', url],
    );
  });
  Future<void> setIdentity(String name, String email) => _mutate(() async {
    if (name.trim().isEmpty || email.trim().isEmpty) {
      throw StateError('请填写提交者名称和邮箱');
    }
    await _command(['config', '--local', 'user.name', name.trim()]);
    await _command(['config', '--local', 'user.email', email.trim()]);
  });
  Future<void> close() async {
    _closed = true;
    await _task?.stop();
    await _operation;
    await _refreshing;
    super.dispose();
  }
}
