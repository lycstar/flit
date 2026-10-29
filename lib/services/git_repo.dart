import 'shell.dart';

typedef GitResult = ({int code, String out});
typedef GitExecute = Future<GitResult> Function(String command);

class GitChange {
  const GitChange(this.x, this.y, this.path, {this.originalPath});
  final String x, y, path;
  final String? originalPath;
  bool get untracked => x == '?' && y == '?';
  bool get conflicted =>
      x == 'U' || y == 'U' || '$x$y' == 'AA' || '$x$y' == 'DD';
  bool get staged => !untracked && x != ' ' && !conflicted;
  bool get unstaged => untracked || y != ' ';
  List<String> get paths => [path, if (originalPath != null) originalPath!];
}

class GitSnapshot {
  const GitSnapshot({
    this.exists = false,
    this.branch = '',
    this.upstream,
    this.detached = false,
    this.unborn = false,
    this.changes = const [],
  });
  final bool exists, detached, unborn;
  final String branch;
  final String? upstream;
  final List<GitChange> changes;
  bool get hasConflicts => changes.any((c) => c.conflicted);
}

/// All arguments are quoted individually. Machine output is never trimmed.
class GitRepo {
  GitRepo(this.root, {GitExecute? execute}) : _execute = execute ?? _shell;
  final String root;
  final GitExecute _execute;
  bool supported = true;

  static Future<GitResult> _shell(String command) async {
    final result = await Shell.instance.exec(command, timeoutMs: 60000);
    return (
      code: result['exitCode'] as int? ?? -1,
      out: result['output'] as String? ?? '',
    );
  }

  String command(List<String> args) =>
      'LC_ALL=C GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND=${shQuote('ssh -o BatchMode=yes -o StrictHostKeyChecking=yes')} git --no-pager --literal-pathspecs -c core.quotepath=false -c color.ui=false -C ${shQuote(root)} ${args.map(shQuote).join(' ')}';
  Future<GitResult> run(List<String> args) => _execute(command(args));
  Future<String> checked(List<String> args) async {
    final result = await run(args);
    if (result.code != 0) {
      throw StateError(
        result.out.trim().isEmpty
            ? 'Git 执行失败（${result.code}）'
            : result.out.trim(),
      );
    }
    return result.out;
  }

  Future<GitSnapshot> snapshot() async {
    final location = await run(['rev-parse', '--show-toplevel']);
    if (location.code != 0) {
      if (location.code == 128 &&
          location.out.contains('not a git repository')) {
        return const GitSnapshot();
      }
      throw StateError(
        location.out.trim().isEmpty ? 'Git 不可用，请检查开发环境' : location.out.trim(),
      );
    }
    // Android exposes shared storage through several aliases (/sdcard and
    // /storage/emulated/0). Compare canonical paths rather than their spelling.
    final selectedRoot = await checked(['rev-parse', '--show-prefix']);
    if (selectedRoot.trim().isNotEmpty) {
      supported = false;
      throw StateError('当前项目位于上级 Git 仓库中，请打开仓库根目录后使用版本控制');
    }
    supported = true;
    return parseStatus(
      await checked([
        'status',
        '--porcelain=v1',
        '-z',
        '-b',
        '--untracked-files=all',
      ]),
    );
  }

  static GitSnapshot parseStatus(String output) {
    final records = output.split('\x00');
    final changes = <GitChange>[];
    var branch = '', detached = false, unborn = false;
    String? upstream;
    for (var i = 0; i < records.length; i++) {
      final record = records[i];
      if (record.startsWith('## ')) {
        var head = record.substring(3).trimRight();
        for (final prefix in ['No commits yet on ', 'Initial commit on ']) {
          if (head.startsWith(prefix)) {
            unborn = true;
            head = head.substring(prefix.length);
            break;
          }
        }
        detached = head.startsWith('HEAD ');
        final split = head.indexOf('...');
        branch = split < 0 ? head : head.substring(0, split);
        if (split >= 0) upstream = head.substring(split + 3).split(' ').first;
        continue;
      }
      if (record.length < 4 || record[2] != ' ') continue;
      final x = record[0], y = record[1];
      String? original;
      if ((x == 'R' || x == 'C' || y == 'R' || y == 'C') &&
          i + 1 < records.length) {
        original = records[++i];
      }
      changes.add(GitChange(x, y, record.substring(3), originalPath: original));
    }
    return GitSnapshot(
      exists: true,
      branch: branch,
      upstream: upstream,
      detached: detached,
      unborn: unborn,
      changes: changes,
    );
  }

  Future<List<String>> branches() async => (await checked([
    'branch',
    '--format=%(refname:short)',
  ])).split('\n').where((line) => line.isNotEmpty).toList();

  Future<String> diff(GitChange change, {required bool staged}) async {
    if (change.untracked) return '此文件尚未跟踪，暂存后可查看完整差异。';
    final output = await checked([
      'diff',
      '--no-ext-diff',
      '--no-textconv',
      if (staged) '--cached',
      '--',
      ...change.paths,
    ]);
    return output.isEmpty ? '没有文本差异（可能是二进制文件或文件模式变化）。' : output;
  }
}
