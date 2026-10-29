import 'package:flutter/foundation.dart';

import '../editor/file_kind.dart';
import 'project_documents.dart';

/// 编辑器里的一个打开项(tab)。
sealed class OpenItem {
  String get path;
  String get name => path.split('/').last;
}

/// 代码文件: 直接引用缓冲, 文件改名/删除随缓冲走(路径不是身份)
final class CodeTab extends OpenItem {
  CodeTab(this.document);
  final EditorDocument document;
  @override
  String get path => document.path;
}

/// 非文本文件: 只记路径, 不建缓冲, 不进自动保存
final class FileTab extends OpenItem {
  FileTab(this.path, this.kind);
  @override
  final String path;
  final FileKind kind; // image | binary
}

/// 打开项列表 + 当前项, 是"编辑器正显示什么"的唯一事实源;
/// ProjectDocuments.current 只跟随当前代码 tab。缓冲被外部拿掉(删除/git)时
/// 对应 tab 自动消失。
class EditorTabs extends ChangeNotifier {
  EditorTabs(this.documents) {
    documents.addListener(_prune);
  }

  final ProjectDocuments documents;
  final _items = <OpenItem>[];
  OpenItem? current;

  List<OpenItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  /// 已打开的缓冲进列表并选中(已有则只选中); [at] 指定插入位置(替换文件卡用)
  void showDocument(EditorDocument document, {int? at}) {
    var tab = _codeTabOf(document);
    if (tab == null) {
      tab = CodeTab(document);
      _items.insert(at == null ? _items.length : at.clamp(0, _items.length), tab);
    }
    current = tab;
    notifyListeners();
  }

  void showFile(String path, FileKind kind) {
    var tab = _fileTabOf(path);
    if (tab == null || tab.kind != kind) {
      final index = tab == null ? _items.length : _items.indexOf(tab);
      if (tab != null) _items.removeAt(index);
      tab = FileTab(path, kind);
      _items.insert(index, tab);
    }
    current = tab;
    notifyListeners();
  }

  void select(OpenItem item) {
    if (!_items.contains(item) || identical(current, item)) return;
    current = item;
    notifyListeners();
  }

  /// 移除一项; 关掉的是当前项时选左邻(关第一个则选右邻)。返回新的当前项
  OpenItem? close(OpenItem item) {
    final index = _items.indexOf(item);
    if (index < 0) return current;
    _items.removeAt(index);
    if (identical(current, item)) {
      current = _items.isEmpty ? null : _items[index == 0 ? 0 : index - 1];
    }
    notifyListeners();
    return current;
  }

  /// 只留 [keep]; 返回被移除的项(代码项的缓冲由调用方释放)
  List<OpenItem> closeOthers(OpenItem keep) {
    if (!_items.contains(keep)) return const [];
    final removed = _items.where((item) => !identical(item, keep)).toList();
    _items
      ..clear()
      ..add(keep);
    current = keep;
    notifyListeners();
    return removed;
  }

  int indexOf(OpenItem item) => _items.indexOf(item);

  CodeTab? _codeTabOf(EditorDocument document) {
    for (final item in _items) {
      if (item is CodeTab && identical(item.document, document)) return item;
    }
    return null;
  }

  FileTab? _fileTabOf(String path) {
    for (final item in _items) {
      if (item is FileTab && item.path == path) return item;
    }
    return null;
  }

  /// 缓冲没了(文件被删/git 检出丢失) → tab 一起走
  void _prune() {
    final stale = _items
        .where((item) => item is CodeTab && !documents.contains(item.document))
        .toList();
    if (stale.isEmpty) return;
    for (final item in stale) {
      final index = _items.indexOf(item);
      _items.removeAt(index);
      if (identical(current, item)) {
        current = _items.isEmpty ? null : _items[index == 0 ? 0 : index - 1];
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    documents.removeListener(_prune);
    super.dispose();
  }
}
