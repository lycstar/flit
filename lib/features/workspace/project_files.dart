import 'package:flutter/foundation.dart';

import '../../services/file_ops.dart';
import '../../services/shell.dart';
import '../editor/file_kind.dart';
import 'project_documents.dart';

/// Coordinates project mutations with autosave and Git worktree changes, and
/// owns the project's file listing (what the tree shows). Notifies when the
/// listing changes.
class ProjectFiles extends ChangeNotifier {
  ProjectFiles(this.documents);
  final ProjectDocuments documents;
  FileOps get _ops => FileOps.instance;
  String get root => documents.projectPath;

  /// 工程文件清单: 相对路径, 目录带尾斜杠, 已排序; 排除 .dart_tool/build/.git
  List<String> get files => _files;
  List<String> _files = const [];

  Future<void> refresh() async {
    final res = await Shell.instance.exec(
      "cd ${shQuote(root)} && find . -mindepth 1 "
      r"\( -name .dart_tool -o -name build -o -name .git \) -prune -o "
      r"\( -type d -printf '%P/\n' -o -type f -printf '%P\n' \) | sort",
    );
    final out = (res['output'] as String? ?? '').trim();
    _files = List.unmodifiable(out.split('\n').where((l) => l.isNotEmpty));
    notifyListeners();
  }

  /// 文件类型: 按后缀能定的直接定; 未知后缀/无后缀嗅探前 8KB,
  /// 嗅探本身失败按文本处理(编辑器自己会报读不出)
  Future<FileKind> kindOf(String rel) async {
    final byName = fileKindByName(rel);
    if (byName != null) return byName;
    try {
      final res = await Shell.instance.exec(sniffCommand('$root/$rel'));
      return fileKindFromSniff(res['output'] as String? ?? '');
    } catch (_) {
      return FileKind.code;
    }
  }

  String _relative(String path) {
    if (!path.startsWith('$root/')) throw StateError('文件不在当前项目内');
    return path.substring(root.length + 1);
  }

  Future<void> _checked(Future<OpResult> operation) async {
    final result = await operation;
    if (!result.ok) throw StateError(result.msg);
  }

  Future<void> rename(String path, String name) => documents.renamePath(
    _relative(path),
    _relative('${path.substring(0, path.lastIndexOf('/'))}/$name'),
    apply: () => _checked(_ops.rename(path, name, allowedRoot: root)),
  );

  Future<void> delete(String path) => documents.deletePath(
    _relative(path),
    apply: () => _checked(_ops.delete(path, allowedRoot: root)),
  );

  Future<void> create(String parent, String name, {required bool directory}) =>
      documents.withFileChange(
        () => _checked(
          directory
              ? _ops.createDir(parent, name, allowedRoot: root)
              : _ops.createFile(parent, name, allowedRoot: root),
        ),
      );

  Future<void> paste(String target) async {
    final source = _ops.clipPath;
    if (source == null) throw StateError('没有可粘贴的文件');
    final cut = _ops.clipCut;
    if (cut) {
      if (_ops.clipRoot != root) throw StateError('只能在当前项目内移动文件，请使用复制');
      final destination = '$target/${source.split('/').last}';
      await documents.renamePath(
        _relative(source),
        _relative(destination),
        apply: () => _checked(
          _ops.moveInto(
            source,
            target,
            sourceRoot: root,
            destinationRoot: root,
          ),
        ),
      );
    } else {
      await documents.withFileChange(
        () => _checked(_ops.copyInto(source, target, destinationRoot: root)),
      );
    }
    if (cut && _ops.clipPath == source) _ops.clearClip();
  }
}
