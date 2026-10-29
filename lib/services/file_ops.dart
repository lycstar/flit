import 'shell.dart';

/// File operation result.
typedef OpResult = ({bool ok, String msg});

/// Filesystem mutations with both a fast lexical check and a shell-side
/// realpath boundary. The shell check is authoritative, so symlinks cannot
/// redirect a project operation outside its selected root.
class FileOps {
  FileOps._();
  static final instance = FileOps._();

  /// Clipboard state is shared between the project tree and file browser.
  String? clipPath;
  bool clipCut = false;
  bool get hasClip => clipPath != null;
  String? clipRoot;
  String? get clipName =>
      clipPath?.split('/').where((part) => part.isNotEmpty).lastOrNull;

  void clearClip() {
    clipPath = null;
    clipRoot = null;
    clipCut = false;
  }

  OpResult ok(String msg) => (ok: true, msg: msg);
  OpResult fail(String msg) => (ok: false, msg: msg);

  /// Copy may read from a shared or user-selected source, but writes only
  /// inside [destinationRoot].
  Future<OpResult> copyInto(
    String src,
    String destDir, {
    required String destinationRoot,
  }) => _transfer(src, destDir, move: false, destinationRoot: destinationRoot);

  /// A move is destructive on both sides, so both paths must stay within
  /// their explicitly selected roots.
  Future<OpResult> moveInto(
    String src,
    String destDir, {
    required String sourceRoot,
    required String destinationRoot,
  }) => _transfer(
    src,
    destDir,
    move: true,
    sourceRoot: sourceRoot,
    destinationRoot: destinationRoot,
  );

  Future<OpResult> _transfer(
    String src,
    String destDir, {
    required bool move,
    String? sourceRoot,
    required String destinationRoot,
  }) async {
    final name = src.split('/').where((part) => part.isNotEmpty).lastOrNull;
    if (name == null) return fail('源路径无效');
    final target = _join(destDir, name);
    final fromRoot = sourceRoot ?? destinationRoot;
    final toRoot = destinationRoot;
    if (move &&
        (!_within(src, fromRoot) || _normalize(src) == _normalize(fromRoot))) {
      return fail('不能将文件移出它所属的项目目录');
    }
    if (!_within(destDir, toRoot) || !_within(target, toRoot)) {
      return fail('目标必须位于当前项目目录内');
    }
    if (_within(destDir, src)) {
      return fail('不能将目录复制或移动到它自己内部');
    }

    final gates = <(String, String)>[(destDir, toRoot), (target, toRoot)];
    if (move) gates.add((src, fromRoot));
    final command =
        "${_gate(gates)}"
        'source=\$(realpath -e -- ${shQuote(src)}) || exit 64; '
        'dest=\$(realpath -e -- ${shQuote(destDir)}) || exit 64; '
        r'case "$dest" in "$source"|"$source"/*) echo "不能复制或移动到自身内部" >&2; exit 64;; esac; '
        '${move ? _protectRoot(src, fromRoot) : ''}'
        "if [ -e ${shQuote(target)} ] || [ -L ${shQuote(target)} ]; then "
        "echo '同名文件或目录已存在，未覆盖' >&2; exit 65; fi; "
        "${move ? 'mv' : 'cp -a'} -- ${shQuote(src)} ${shQuote('$destDir/')} && echo OK";
    return _exec(command);
  }

  Future<OpResult> delete(String path, {required String allowedRoot}) async {
    final root = allowedRoot;
    if (!_within(path, root) || _normalize(path) == _normalize(root)) {
      return fail('只能删除当前项目目录中的条目');
    }
    return _exec(
      '${_gate([(path, root)])}${_protectRoot(path, root)}rm -rf -- ${shQuote(path)} && echo OK',
    );
  }

  Future<OpResult> rename(
    String path,
    String newName, {
    required String allowedRoot,
  }) async {
    if (!_validName(newName)) return fail('名称无效');
    final root = allowedRoot;
    final parent = path.substring(0, path.lastIndexOf('/'));
    final target = _join(parent, newName);
    if (!_within(path, root) ||
        !_within(target, root) ||
        _normalize(path) == _normalize(root)) {
      return fail('只能在当前项目目录内重命名');
    }
    final command =
        "${_gate([(path, root), (target, root)])}${_protectRoot(path, root)}"
        "if [ -e ${shQuote(target)} ] || [ -L ${shQuote(target)} ]; then "
        "echo '同名文件或目录已存在' >&2; exit 65; fi; "
        "mv -- ${shQuote(path)} ${shQuote(target)} && echo OK";
    return _exec(command);
  }

  Future<OpResult> createDir(
    String parent,
    String name, {
    required String allowedRoot,
  }) => _create(parent, name, dir: true, allowedRoot: allowedRoot);

  Future<OpResult> createFile(
    String parent,
    String name, {
    required String allowedRoot,
  }) => _create(parent, name, dir: false, allowedRoot: allowedRoot);

  Future<OpResult> _create(
    String parent,
    String name, {
    required bool dir,
    required String allowedRoot,
  }) async {
    if (!_validName(name)) return fail('名称无效');
    final root = allowedRoot;
    final target = _join(parent, name);
    if (!_within(parent, root) || !_within(target, root)) {
      return fail('只能在当前项目目录中创建文件或目录');
    }
    final command =
        "${_gate([(parent, root), (target, root)])}"
        "if [ -e ${shQuote(target)} ] || [ -L ${shQuote(target)} ]; then "
        "echo '同名文件或目录已存在' >&2; exit 65; fi; "
        "${dir ? 'mkdir' : 'touch'} -- ${shQuote(target)} && echo OK";
    return _exec(command);
  }

  bool _validName(String name) =>
      name.isNotEmpty &&
      name != '.' &&
      name != '..' &&
      !name.contains('/') &&
      !name.contains('\\') &&
      !name.contains('\x00') &&
      !name.contains('\n');

  String _join(String parent, String name) =>
      '${parent.endsWith('/') ? parent.substring(0, parent.length - 1) : parent}/$name';

  bool _within(String path, String root) {
    final normalizedPath = _normalize(path);
    final normalizedRoot = _normalize(root);
    if (normalizedPath == null ||
        normalizedRoot == null ||
        normalizedRoot == '/') {
      return false;
    }
    return normalizedPath == normalizedRoot ||
        normalizedPath.startsWith('$normalizedRoot/');
  }

  String? _normalize(String path) {
    if (!path.startsWith('/')) return null;
    final parts = <String>[];
    for (final part in path.split('/')) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') {
        if (parts.isEmpty) return null;
        parts.removeLast();
      } else {
        parts.add(part);
      }
    }
    return '/${parts.join('/')}';
  }

  String _protectRoot(String path, String root) =>
      'r=\$(realpath -e -- ${shQuote(root)}) || exit 64; '
      'p=\$(realpath -m -- ${shQuote(path)}) || exit 64; '
      r'[ "$p" != "$r" ] || { echo "不能修改项目根目录" >&2; exit 64; }; ';

  String _gate(List<(String, String)> paths) {
    final checks = paths.map((entry) {
      final (path, root) = entry;
      return '__inside ${shQuote(root)} ${shQuote(path)} || exit 64; ';
    }).join();
    return r'__inside(){ r=$(realpath -e -- "$1") || return 1; '
        r'p=$(realpath -m -- "$2") || return 1; '
        r'case "$p" in "$r"|"$r"/*) return 0;; *) '
        r'echo "拒绝操作项目根目录外路径: $p" >&2; return 1;; esac; }; '
        '$checks';
  }

  Future<OpResult> _exec(String command) async {
    try {
      final result = await Shell.instance.exec(command, timeoutMs: 600000);
      final code = result['exitCode'] as int? ?? -1;
      if (code == 0) return ok('完成');
      final output = (result['output'] as String? ?? '').trim();
      return fail(output.isEmpty ? '操作失败（退出码 $code）' : output);
    } catch (error) {
      return fail('操作失败：$error');
    }
  }
}

extension on Iterable<String> {
  String? get lastOrNull => isEmpty ? null : last;
}
