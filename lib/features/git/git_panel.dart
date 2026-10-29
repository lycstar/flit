import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../services/git_repo.dart';
import '../editor/workbench_layout.dart';
import 'github_account_tile.dart';
import 'project_git.dart';

/// Repository tools sit beside the file tree, never inside its folder menus.
class GitPanel extends StatefulWidget {
  const GitPanel({super.key});
  @override
  State<GitPanel> createState() => _GitPanelState();
}

class _GitPanelState extends State<GitPanel> {
  /// 工程的版本控制状态来自 ProjectScope, 页面生命周期内不换对象
  late final ProjectGit git = context.read<ProjectGit>();
  bool get disabled => git.blocked;

  /// 面板在抽屉里: 看输出 = 关抽屉 + 展开终端
  void _showOutput() {
    Scaffold.maybeOf(context)?.closeDrawer();
    context.read<WorkbenchLayout>().showOutput();
  }

  @override
  void initState() {
    super.initState();
    // 刷新会立刻 notify; 面板可能与提供它的 ProjectScope 同帧挂载,
    // 挂载中通知祖先会触发框架断言, 所以推到首帧之后
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) git.refresh();
    });
  }

  Future<void> _act(
    Future<void> Function() action, {
    bool terminal = false,
  }) async {
    try {
      if (terminal) _showOutput();
      await action();
    } catch (error) {
      if (mounted) _message('$error');
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<String?> _input(
    String title,
    String label, {
    String initial = '',
    int lines = 1,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (_) => _GitTextPrompt(
        title: title,
        label: label,
        initial: initial,
        lines: lines,
      ),
    );
  }

  Future<bool> _confirm(String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确定'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _commit() async {
    final message = await _input('提交已暂存的更改', '提交消息', lines: 3);
    if (message != null && mounted) await _act(() => git.commit(message));
  }

  Future<void> _diff(GitChange change, bool staged) async {
    try {
      final text = await git.repo.diff(change, staged: staged);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * .8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    '${staged ? '已暂存' : '未暂存'} · ${change.path}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(text, style: AppColors.mono),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (error) {
      if (mounted) _message('$error');
    }
  }

  Future<void> _fileMenu(GitChange change) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  change.path,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (change.staged)
                ListTile(
                  leading: const Icon(Icons.difference_outlined),
                  title: const Text('显示已暂存的差异'),
                  onTap: () => Navigator.pop(ctx, 'stagedDiff'),
                ),
              if (!change.untracked && change.unstaged)
                ListTile(
                  leading: const Icon(Icons.difference_outlined),
                  title: const Text('显示未暂存的差异'),
                  onTap: () => Navigator.pop(ctx, 'diff'),
                ),
              if (change.unstaged || change.conflicted)
                ListTile(
                  leading: const Icon(Icons.add),
                  title: Text(change.conflicted ? '标记冲突已解决（暂存）' : '暂存文件'),
                  onTap: () => Navigator.pop(ctx, 'stage'),
                ),
              if (change.staged)
                ListTile(
                  leading: const Icon(Icons.remove),
                  title: const Text('取消暂存'),
                  onTap: () => Navigator.pop(ctx, 'unstage'),
                ),
              if (!change.untracked && !change.conflicted && change.unstaged)
                ListTile(
                  leading: const Icon(Icons.undo, color: AppColors.danger),
                  title: const Text('回滚未暂存的更改'),
                  onTap: () => Navigator.pop(ctx, 'discard'),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'stagedDiff':
        await _diff(change, true);
      case 'diff':
        await _diff(change, false);
      case 'stage':
        await _act(() => git.stage(change));
      case 'unstage':
        await _act(() => git.unstage(change));
      case 'discard':
        if (await _confirm(
              '回滚更改？',
              '将丢弃 ${change.path} 未暂存的更改，已暂存的内容保留。此操作无法撤销。',
            ) &&
            mounted) {
          await _act(() => git.discard(change));
        }
    }
  }

  Future<void> _branches() async {
    try {
      final branches = await git.repo.branches();
      if (!mounted) return;
      final selected = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('分支'),
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('新建并切换分支'),
              onTap: () => Navigator.pop(ctx, ''),
            ),
            for (final branch in branches)
              ListTile(
                title: Text(branch),
                trailing: branch == git.snapshot.branch
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(ctx, branch),
              ),
          ],
        ),
      );
      if (selected == null || !mounted) return;
      if (selected.isEmpty) {
        final name = await _input('新建分支', '分支名称');
        if (name != null && mounted) {
          await _act(() => git.switchBranch(name, create: true));
        }
      } else if (selected != git.snapshot.branch) {
        await _act(() => git.switchBranch(selected));
      }
    } catch (error) {
      if (mounted) _message('$error');
    }
  }

  Future<void> _settings(String action) async {
    if (action == 'log') {
      try {
        final text = await git.repo.checked(['log', '--oneline', '-15']);
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('提交历史'),
            content: SingleChildScrollView(
              child: SelectableText(text, style: AppColors.mono),
            ),
          ),
        );
      } catch (error) {
        if (mounted) _message('$error');
      }
    } else if (action == 'remote') {
      final result = await git.repo.run(['remote', 'get-url', 'origin']);
      if (!mounted) return;
      final url = await _input(
        '远程仓库 · origin',
        '仓库地址',
        initial: result.code == 0 ? result.out.trim() : '',
      );
      if (url != null && mounted) await _act(() => git.setRemote(url));
    } else if (action == 'identity') {
      final existingName = await git.repo.run(['config', 'user.name']);
      final existingEmail = await git.repo.run(['config', 'user.email']);
      if (!mounted) return;
      final name = await _input(
        '提交者信息（当前仓库）',
        '名称',
        initial: existingName.out.trim(),
      );
      if (name == null || !mounted) return;
      final email = await _input(
        '提交者信息（当前仓库）',
        '邮箱',
        initial: existingEmail.out.trim(),
      );
      if (email != null && mounted) {
        await _act(() => git.setIdentity(name, email));
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      git,
      git.executions,
      if (git.preparing != null) git.preparing!,
    ]),
    builder: (_, _) {
      final state = git.snapshot;
      final staged = state.changes.where((c) => c.staged).length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
            child: Row(
              children: [
                const Icon(
                  Icons.account_tree_outlined,
                  size: 18,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.exists
                        ? (state.detached ? '游离 HEAD' : state.branch)
                        : '版本控制',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: '刷新版本控制状态',
                  onPressed: disabled ? null : git.refresh,
                  icon: const Icon(Icons.refresh, size: 20),
                ),
                PopupMenuButton<String>(
                  enabled: !disabled && state.exists,
                  tooltip: '仓库设置',
                  onSelected: (value) => _act(() => _settings(value)),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'log', child: Text('提交历史')),
                    PopupMenuItem(value: 'remote', child: Text('远程仓库')),
                    PopupMenuItem(value: 'identity', child: Text('提交者信息')),
                  ],
                ),
              ],
            ),
          ),
          if (git.loading || git.busy)
            const LinearProgressIndicator(minHeight: 2),
          if (state.exists)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                spacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: disabled
                        ? null
                        : () => _act(git.pull, terminal: true),
                    icon: const Icon(Icons.download_outlined, size: 17),
                    label: const Text('拉取'),
                  ),
                  TextButton.icon(
                    onPressed: disabled
                        ? null
                        : () => _act(git.push, terminal: true),
                    icon: const Icon(Icons.upload_outlined, size: 17),
                    label: const Text('推送'),
                  ),
                  TextButton.icon(
                    onPressed: disabled ? null : _branches,
                    icon: const Icon(Icons.call_split, size: 17),
                    label: const Text('分支'),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (git.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      git.error!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (git.busy)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      '操作进行中，可在终端查看进度或停止。',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                if (!state.exists && !git.loading && git.error == null) ...[
                  const Text(
                    '此项目尚未创建 Git 仓库。',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: disabled ? null : () => _act(git.initialize),
                    icon: const Icon(Icons.add),
                    label: const Text('初始化仓库'),
                  ),
                ],
                if (state.exists &&
                    state.changes.isEmpty &&
                    git.error == null &&
                    !git.loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      '没有本地更改',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                if (state.hasConflicts)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      '存在冲突：编辑文件解决冲突后，逐个暂存。',
                      style: TextStyle(color: AppColors.warn, fontSize: 12),
                    ),
                  ),
                for (final change in state.changes)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Text(
                      change.conflicted
                          ? '冲突'
                          : change.untracked
                          ? '未跟踪'
                          : '${change.x}${change.y}',
                      style: TextStyle(
                        fontSize: 12,
                        color: change.conflicted
                            ? AppColors.danger
                            : AppColors.accent,
                      ),
                    ),
                    title: Text(
                      change.path,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    subtitle: change.staged
                        ? Text(
                            change.unstaged ? '已暂存，另有未暂存更改' : '已暂存',
                            style: const TextStyle(fontSize: 10),
                          )
                        : null,
                    trailing: const Icon(Icons.more_horiz, size: 18),
                    onTap: disabled ? null : () => _fileMenu(change),
                  ),
              ],
            ),
          ),
          if (state.exists && state.changes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextButton(
                    onPressed: disabled || state.hasConflicts
                        ? null
                        : () => _act(git.stageAll),
                    child: const Text('暂存所有更改'),
                  ),
                  FilledButton.icon(
                    onPressed: disabled || staged == 0 || state.hasConflicts
                        ? null
                        : _commit,
                    icon: const Icon(Icons.commit, size: 18),
                    label: Text('提交更改 · $staged'),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          // 账户是全局的: 与克隆页、设置页同一个 tile
          GithubAccountTile(dense: true, enabled: !disabled),
        ],
      );
    },
  );
}

class _GitTextPrompt extends StatefulWidget {
  const _GitTextPrompt({
    required this.title,
    required this.label,
    required this.initial,
    required this.lines,
  });
  final String title, label, initial;
  final int lines;
  @override
  State<_GitTextPrompt> createState() => _GitTextPromptState();
}

class _GitTextPromptState extends State<_GitTextPrompt> {
  late final controller = TextEditingController(text: widget.initial);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: controller,
      autofocus: true,
      maxLines: widget.lines,
      decoration: InputDecoration(labelText: widget.label),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () {
          final text = controller.text.trim();
          if (text.isNotEmpty) Navigator.pop(context, text);
        },
        child: const Text('确定'),
      ),
    ],
  );
}
