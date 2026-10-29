import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flit_files/flit_files.dart';

import '../../../core/theme.dart';
import '../file_kind.dart';

/// 非文本文件的 tab 内容: 图片给预览, 其余给一张文件卡——图标、名字、路径、
/// 大小/时间, 以及动作清单(file_kind.cardActions 按格式分发, 分享永远在)。
/// 文件系统操作(改名/删除)不在这里, 在文件树的长按菜单。
class FileCard extends StatefulWidget {
  const FileCard({
    super.key,
    required this.projectRoot,
    required this.path,
    required this.kind,
  });

  final String projectRoot;

  /// 相对工程根
  final String path;
  final FileKind kind;

  @override
  State<FileCard> createState() => _FileCardState();
}

class _FileCardState extends State<FileCard> {
  FileStat? _stat;

  String get _absolute => '${widget.projectRoot}/${widget.path}';

  /// 动作清单唯一事实源在 file_kind.cardActions; 图标等展示随清单推导
  List<FileCardAction> get _actions => cardActions(widget.path);
  bool get _installable => _actions.contains(FileCardAction.installApk);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant FileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _load();
  }

  Future<void> _load() async {
    final stat = await File(_absolute).stat();
    if (mounted) setState(() => _stat = stat);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(Future<bool> Function() action, String failure) async {
    try {
      if (!await action()) _snack(failure);
    } catch (e) {
      _snack('$e');
    }
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final stat = _stat;
    final exists = stat != null && stat.type != FileSystemEntityType.notFound;
    final modified = stat?.modified;
    final meta = !exists
        ? (stat == null ? '' : '文件不存在')
        : '${formatBytes(stat.size)} · '
              '${modified!.year}-${_two(modified.month)}-${_two(modified.day)} '
              '${_two(modified.hour)}:${_two(modified.minute)}';
    final isImage = widget.kind == FileKind.image;
    return ColoredBox(
      color: AppColors.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isImage && exists)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_absolute),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              Icon(
                isImage
                    ? Icons.image_outlined
                    : _installable
                    ? Icons.android
                    : Icons.insert_drive_file_outlined,
                size: 64,
                color: AppColors.textSecondary,
              ),
            const SizedBox(height: 16),
            Text(
              widget.path.split('/').last,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              widget.path,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                meta,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (final action in cardActions(widget.path))
                  switch (action) {
                    FileCardAction.installApk => FilledButton.icon(
                      onPressed: !exists
                          ? null
                          : () => _run(
                              () => FlitFiles.installApk(_absolute),
                              '无法安装：请先在系统设置里授予 Flit“安装未知应用”权限',
                            ),
                      icon: const Icon(Icons.install_mobile_outlined, size: 18),
                      label: const Text('安装到本机'),
                    ),
                    FileCardAction.openExternal => OutlinedButton.icon(
                      onPressed: !exists
                          ? null
                          : () => _run(
                              () => FlitFiles.open(_absolute),
                              '没有能打开此文件的应用',
                            ),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('用其他应用打开'),
                    ),
                    FileCardAction.share => OutlinedButton.icon(
                      onPressed: !exists
                          ? null
                          : () => _run(
                              () => FlitFiles.share(_absolute),
                              '无法分享该文件',
                            ),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('分享'),
                    ),
                  },
              ],
            ),
          ],
        ),
      ),
    );
  }
}
