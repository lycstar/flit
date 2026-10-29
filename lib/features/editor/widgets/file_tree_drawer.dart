import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import 'file_dialogs.dart';
import '../../../services/file_ops.dart';
import '../../../services/shared_storage_access.dart';
import '../../workspace/editor_tabs.dart';
import '../../workspace/project_files.dart';
import '../../workspace/project_session.dart';

/// 抽屉位置模式
enum _Loc { project, storage }

/// 文件树节点(由 find 扁平列表构建)
class _Node {
  _Node(this.name, this.path, this.isDir);
  final String name;
  final String path; // 相对项目根
  final bool isDir;
  final List<_Node> children = [];
}

/// Project tree with bounded mutations; shared storage is a read-only import
/// browser. Toolchains and app internals are not exposed as editable projects.
class FileTreeDrawer extends StatefulWidget {
  const FileTreeDrawer({
    super.key,
    required this.searchCtrl,
    required this.onOpenFile,
    this.asContent = false,
  });

  /// 搜索框文本由页面持有, 抽屉反复开合时不丢
  final TextEditingController searchCtrl;
  final ValueChanged<String> onOpenFile;
  final bool asContent; // true = 只出内容(嵌 drawer 的 tab), 不包 Drawer 壳

  @override
  State<FileTreeDrawer> createState() => _FileTreeDrawerState();
}

class _FileTreeDrawerState extends State<FileTreeDrawer> {
  final Set<String> _expanded = {};
  _Loc _loc = _Loc.project;

  // 共享存储导入浏览器
  String _browseDir = '';
  List<FileSystemEntity> _entries = [];
  bool _browseLoading = false;
  int _browseRequest = 0;

  FileOps get _ops => FileOps.instance;

  /// 工程、文件清单与打开项都来自 ProjectScope
  late final ProjectSession _project = context.read<ProjectSession>();
  late final ProjectFiles _projectFiles = context.read<ProjectFiles>();
  List<String> get _files => _projectFiles.files;

  /// 当前打开项的相对路径(文件树据此高亮); 变了就展开它的祖先目录
  String? _openFile;

  @override
  void initState() {
    super.initState();
    _openFile = context.read<EditorTabs>().current?.path;
    _expandAncestorsOf(_openFile);
  }

  // ---------- 项目树(逻辑不变) ----------

  void _expandAncestorsOf(String? rel) {
    if (rel == null) return;
    final parts = rel.split('/')..removeLast();
    var acc = '';
    for (final p in parts) {
      acc = acc.isEmpty ? p : '$acc/$p';
      _expanded.add(acc);
    }
  }

  _Node _buildTree() {
    final root = _Node('', '', true);
    for (final rel in _files) {
      final directory = rel.endsWith('/');
      final parts = rel.split('/').where((part) => part.isNotEmpty).toList();
      _Node cur = root;
      var acc = '';
      for (var i = 0; i < parts.length; i++) {
        acc = acc.isEmpty ? parts[i] : '$acc/${parts[i]}';
        final isDir = i < parts.length - 1 || directory;
        _Node? next;
        for (final c in cur.children) {
          if (c.name == parts[i] && c.isDir == isDir) {
            next = c;
            break;
          }
        }
        if (next == null) {
          next = _Node(parts[i], acc, isDir);
          cur.children.add(next);
        }
        cur = next;
      }
    }
    void sort(_Node n) {
      n.children.sort((a, b) {
        if (a.isDir != b.isDir) return a.isDir ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      for (final c in n.children) {
        sort(c);
      }
    }

    sort(root);
    return root;
  }

  List<(_Node, int)> _visible(_Node root) {
    final out = <(_Node, int)>[];
    void walk(_Node n, int depth) {
      for (final c in n.children) {
        out.add((c, depth));
        if (c.isDir && _expanded.contains(c.path)) walk(c, depth + 1);
      }
    }

    walk(root, 0);
    return out;
  }

  void _toggle(_Node n) {
    setState(() {
      if (_expanded.contains(n.path)) {
        _expanded.remove(n.path);
      } else {
        _expanded.add(n.path);
      }
    });
  }

  // ---------- 位置切换 + 浏览器 ----------

  Future<void> _switchLoc(_Loc loc) async {
    if (loc == _Loc.project) {
      ++_browseRequest;
      setState(() => _loc = loc);
      return;
    }
    final granted = await SharedStorageAccess.request(
      context,
      purpose: '浏览共享存储，选择需要复制到当前项目的文件。此浏览器仅用于导入文件。',
    );
    if (!mounted || !granted) return;
    setState(() {
      _loc = loc;
      _browseDir = '/storage/emulated/0';
    });
    await _reloadEntries();
  }

  Future<void> _reloadEntries() async {
    final request = ++_browseRequest;
    final path = _browseDir;
    final dir = Directory(path);
    setState(() => _browseLoading = true);
    try {
      final list = await dir.list().toList();
      list.sort((a, b) {
        final aDir = a is Directory;
        final bDir = b is Directory;
        if (aDir != bDir) return aDir ? -1 : 1;
        return a.path
            .split('/')
            .last
            .toLowerCase()
            .compareTo(b.path.split('/').last.toLowerCase());
      });
      if (!mounted || request != _browseRequest) return;
      setState(() {
        _entries = list;
        _browseLoading = false;
      });
    } catch (e) {
      if (!mounted || request != _browseRequest) return;
      setState(() => _browseLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('无法读取目录： $e')));
    }
  }

  void _descend(Directory d) {
    setState(() => _browseDir = d.path);
    _reloadEntries();
  }

  void _ascend() {
    if (_browseDir == '/storage/emulated/0') return;
    final parent = _browseDir.substring(0, _browseDir.lastIndexOf('/'));
    if (parent.isEmpty || !_browseDir.contains('/')) return;
    setState(() => _browseDir = parent);
    _reloadEntries();
  }

  // ---------- 文件操作 ----------

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _runOp(Future<void> Function() operation) async {
    try {
      await operation();
      if (!mounted) return;
      _snack('完成');
      _projectFiles.refresh();
      setState(() {});
    } catch (error) {
      _snack('$error');
    }
  }

  Future<void> _pasteInto(String dir) => _runOp(() => _projectFiles.paste(dir));

  Future<void> _confirmDelete(String abs, String name) async {
    if (!await confirmDeleteDialog(context, name) || !mounted) return;
    await _runOp(() => _projectFiles.delete(abs));
  }

  Future<void> _renameDialog(String abs, String oldName) async {
    final name = await renameDialog(context, oldName);
    if (!mounted || name == null || name.isEmpty || name == oldName) return;
    await _runOp(() => _projectFiles.rename(abs, name));
  }

  Future<void> _createDialog(String parent, {required bool dir}) async {
    final name = await createDialog(context, dir: dir);
    if (!mounted || name == null || name.isEmpty) return;
    await _runOp(() => _projectFiles.create(parent, name, directory: dir));
  }

  /// 项目树节点 → 绝对路径
  String _abs(_Node n) => '${_project.path}/${n.path}';

  void _nodeMenu(_Node n) {
    final abs = _abs(n);
    showActionMenu(context, [
      if (n.isDir && _ops.hasClip)
        ('paste', Icons.content_paste, '粘贴到此处', () => _pasteInto(abs)),
      if (n.isDir)
        (
          'newfile',
          Icons.post_add,
          '新建文件',
          () => _createDialog(abs, dir: false),
        ),
      if (n.isDir)
        (
          'newdir',
          Icons.create_new_folder,
          '新建目录',
          () => _createDialog(abs, dir: true),
        ),
      (
        'copy',
        Icons.copy_all_outlined,
        '复制',
        () {
          _ops.clipPath = abs;
          _ops.clipRoot = _project.path;
          _ops.clipCut = false;
          setState(() {});
          _snack('已复制 ${n.name}，长按目标目录可粘贴');
        },
      ),
      (
        'cut',
        Icons.content_cut,
        '剪切',
        () {
          _ops.clipPath = abs;
          _ops.clipRoot = _project.path;
          _ops.clipCut = true;
          setState(() {});
          _snack('已剪切 ${n.name}，长按目标目录可粘贴');
        },
      ),
      (
        'rename',
        Icons.drive_file_rename_outline,
        '重命名',
        () => _renameDialog(abs, n.name),
      ),
      ('delete', Icons.delete_outline, '删除', () => _confirmDelete(abs, n.name)),
    ]);
  }

  void _browseMenu(FileSystemEntity e) {
    final name = e.path.split('/').last;
    showActionMenu(context, [
      (
        'copy',
        Icons.copy_all_outlined,
        '复制',
        () {
          _ops.clipPath = e.path;
          _ops.clipRoot = null;
          _ops.clipCut = false;
          setState(() {});
          _snack('已复制 $name，返回项目后长按目标目录可粘贴');
        },
      ),
    ]);
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    context.watch<ProjectFiles>();
    final open = context.watch<EditorTabs>().current?.path;
    if (open != _openFile) {
      _openFile = open;
      _expandAncestorsOf(open);
    }
    final query = widget.searchCtrl.text.toLowerCase();
    final searching = query.isNotEmpty;
    final tree = _buildTree();
    final rows = _visible(tree);
    final inBrowser = _loc != _Loc.project;

    final content = SafeArea(
      child: Column(
        children: [
          _header(),
          if (!inBrowser) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                controller: widget.searchCtrl,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  hintText: '筛选文件…',
                  isDense: true,
                  prefixIcon: Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (_ops.hasClip) _clipBar(),
          Expanded(
            child: _loc == _Loc.project
                ? (searching
                      ? ListView.builder(
                          itemCount: _files.length,
                          itemBuilder: (_, i) {
                            final f = _files[i];
                            if (f.endsWith('/') ||
                                !f.toLowerCase().contains(query)) {
                              return const SizedBox.shrink();
                            }
                            return _fileTile(f);
                          },
                        )
                      : ListView.builder(
                          itemCount: rows.length,
                          itemBuilder: (_, i) {
                            final (n, depth) = rows[i];
                            return n.isDir
                                ? _dirRow(n, depth)
                                : _fileRow(n, depth);
                          },
                        ))
                : _browserList(),
          ),
        ],
      ),
    );
    // 作为 drawer 的 tab 内容时只出内容, 不包 Drawer 壳
    return widget.asContent
        ? content
        : Drawer(backgroundColor: AppColors.bg, child: content);
  }

  Widget _header() {
    final label = switch (_loc) {
      _Loc.project => '项目',
      _Loc.storage => '共享存储（仅导入）',
    };
    final title = _loc == _Loc.project
        ? _project.name
        : _browseDir.split('/').where((s) => s.isNotEmpty).last;
    return ListTile(
      dense: true,
      leading: Icon(
        _loc == _Loc.project ? Icons.folder : Icons.folder_shared,
        color: AppColors.accent,
      ),
      title: Text(
        title,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
      subtitle: Text(
        label,
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_loc == _Loc.project)
            PopupMenuButton<bool>(
              tooltip: '新建',
              icon: const Icon(Icons.add, size: 18),
              onSelected: (dir) => _createDialog(_project.path, dir: dir),
              itemBuilder: (_) => const [
                PopupMenuItem(value: false, child: Text('新建文件')),
                PopupMenuItem(value: true, child: Text('新建目录')),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: _loc == _Loc.project
                ? _projectFiles.refresh
                : _reloadEntries,
          ),
          PopupMenuButton<_Loc>(
            tooltip: '切换位置',
            icon: const Icon(Icons.drive_file_move_outline, size: 18),
            onSelected: _switchLoc,
            itemBuilder: (_) => const [
              PopupMenuItem(value: _Loc.project, child: Text('项目')),
              PopupMenuItem(value: _Loc.storage, child: Text('从共享存储复制…')),
            ],
          ),
        ],
      ),
    );
  }

  /// 剪贴板条: 快捷粘贴到项目根目录 + 取消
  Widget _clipBar() {
    final ops = _ops;
    final target = _loc == _Loc.project ? _project.path : null;
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            ops.clipCut ? Icons.content_cut : Icons.copy_all_outlined,
            size: 14,
            color: AppColors.accent,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${ops.clipCut ? '剪切' : '复制'}：${ops.clipName}',
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (target != null)
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => _pasteInto(target),
              child: const Text('粘贴', style: TextStyle(fontSize: 12)),
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 14),
            onPressed: () => setState(ops.clearClip),
          ),
        ],
      ),
    );
  }

  // ---------- 浏览器列表 ----------

  Widget _browserList() {
    return Column(
      children: [
        InkWell(
          onTap: _browseDir == '/storage/emulated/0' ? null : _ascend,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            width: double.infinity,
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_upward,
                  size: 14,
                  color: AppColors.textFaint,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _browseDir,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: AppColors.textFaint,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFF21262D)),
        Expanded(
          child: _browseLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : ListView.builder(
                  itemCount: _entries.length,
                  itemBuilder: (_, i) {
                    final e = _entries[i];
                    final isDir = e is Directory;
                    final name = e.path.split('/').last;
                    if (name.startsWith('.')) return const SizedBox.shrink();
                    return ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      leading: Icon(
                        isDir ? Icons.folder : Icons.description_outlined,
                        size: 16,
                        color: isDir ? AppColors.accent : Colors.grey,
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: isDir ? () => _descend(e) : () {},
                      onLongPress: () => _browseMenu(e),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------- 项目树行 ----------

  Widget _dirRow(_Node n, int depth) {
    final open = _expanded.contains(n.path);
    return InkWell(
      onTap: () => _toggle(n),
      onLongPress: () => _nodeMenu(n),
      child: Container(
        height: 34,
        padding: EdgeInsets.fromLTRB(10.0 + depth * 14.0, 0, 8, 0),
        child: Row(
          children: [
            AnimatedRotation(
              turns: open ? 0.25 : 0,
              duration: const Duration(milliseconds: 150),
              child: const Icon(
                Icons.chevron_right,
                size: 14,
                color: AppColors.textFaint,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              open ? Icons.folder_open : Icons.folder,
              size: 15,
              color: AppColors.accent,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                n.name,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fileRow(_Node n, int depth) {
    final selected = n.path == _openFile;
    return InkWell(
      onTap: () => widget.onOpenFile(n.path),
      onLongPress: () => _nodeMenu(n),
      child: Container(
        height: 34,
        padding: EdgeInsets.fromLTRB(26.0 + depth * 14.0, 0, 8, 0),
        color: selected ? AppColors.accent.withValues(alpha: 0.15) : null,
        child: Row(
          children: [
            Icon(_iconFor(n.path), size: 15, color: _colorFor(n.path)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                n.name,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: selected ? AppColors.accent : AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fileTile(String f) {
    final selected = f == _openFile;
    final abs = '${_project.path}/$f';
    final name = f.split('/').last;
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(_iconFor(f), size: 16, color: _colorFor(f)),
      title: Text(
        f,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: selected ? AppColors.accent : AppColors.textPrimary,
        ),
      ),
      selected: selected,
      onTap: () => widget.onOpenFile(f),
      onLongPress: () => showActionMenu(context, [
        (
          'copy',
          Icons.copy_all_outlined,
          '复制',
          () {
            _ops.clipPath = abs;
            _ops.clipCut = false;
            _snack('已复制 $name');
          },
        ),
        (
          'cut',
          Icons.content_cut,
          '剪切',
          () {
            _ops.clipPath = abs;
            _ops.clipCut = true;
            _snack('已剪切 $name');
          },
        ),
        (
          'rename',
          Icons.drive_file_rename_outline,
          '重命名',
          () => _renameDialog(abs, name),
        ),
        ('delete', Icons.delete_outline, '删除', () => _confirmDelete(abs, name)),
      ]),
    );
  }

  IconData _iconFor(String path) {
    if (path.endsWith('.dart')) return Icons.flutter_dash;
    if (path.endsWith('.yaml') || path.endsWith('.lock')) {
      return Icons.settings;
    }
    if (path.endsWith('.png') ||
        path.endsWith('.jpg') ||
        path.endsWith('.webp')) {
      return Icons.image;
    }
    return Icons.description_outlined;
  }

  Color _colorFor(String path) {
    if (path.endsWith('.dart')) return AppColors.accent;
    if (path.endsWith('.yaml') || path.endsWith('.lock')) return AppColors.warn;
    return Colors.grey;
  }
}
