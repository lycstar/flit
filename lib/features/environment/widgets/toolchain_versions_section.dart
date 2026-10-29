import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../toolchain_catalog.dart';

/// 环境页的"版本目录"区块: 列出各构建仓 Releases 里的可下载版本,
/// 点版本即经 EnvironmentController 在临时会话里安装(输出实时回显终端)。
/// bootstrap 不提供(整包重装属于初始化管线, 走安装时间线)。
class ToolchainVersionsSection extends StatefulWidget {
  const ToolchainVersionsSection({
    super.key,
    required this.catalog,
    required this.onInstall,
    required this.installing,
    this.enabled = true,
  });

  final ToolchainCatalog catalog;

  /// 安装回调(应用侧经控制器在临时会话流式执行)
  final Future<void> Function(CatalogEntry entry) onInstall;

  /// 安装进行中(禁用列表)
  final bool installing;

  final bool enabled;

  @override
  State<ToolchainVersionsSection> createState() =>
      _ToolchainVersionsSectionState();
}

class _ToolchainVersionsSectionState extends State<ToolchainVersionsSection> {
  Map<String, List<CatalogEntry>>? _versions;
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // 上次成功列表若有缓存则先显示, 再静默刷新
    final cached = widget.catalog.lastGood;
    if (cached.isNotEmpty) _versions = cached;
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loading = true);
    final versions = await widget.catalog.collect();
    if (!mounted) return;
    setState(() {
      _versions = versions;
      _loading = false;
    });
  }

  void _refreshSoon() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      if (mounted) unawaited(_refresh());
    });
  }

  @override
  void didUpdateWidget(covariant ToolchainVersionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.installing && !widget.installing) {
      // 一次安装结束: 稍候刷新列表(发布时间排序可能变化)
      _refreshSoon();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final versions = _versions;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '版本目录',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: '刷新',
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _loading ? null : _refresh,
                ),
              ],
            ),
          ),
          if (versions == null || _loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (versions.values.every((l) => l.isEmpty))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                !widget.catalog.configured
                    ? '未配置版本目录仓库，当前使用内置发行清单。'
                    : widget.catalog.errors.isNotEmpty
                    ? '版本目录请求失败：${widget.catalog.errors.values.join('；')}'
                    : '仓库暂无匹配的工具链版本。',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            for (final id in versions.keys) _componentTile(id, versions[id]!),
        ],
      ),
    );
  }

  Widget _componentTile(String id, List<CatalogEntry> entries) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return ListTile(
      dense: true,
      leading: const Icon(Icons.inventory_2_outlined, size: 18),
      title: Text(
        _label(id),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${entries.length} 个版本 · 最新 ${entries.first.name}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.expand_more, size: 18),
      onTap: widget.installing ? null : () => _pickAndInstall(id, entries),
    );
  }

  Future<void> _pickAndInstall(String id, List<CatalogEntry> entries) async {
    final picked = await showModalBottomSheet<CatalogEntry>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final entry in entries)
              ListTile(
                dense: true,
                title: Text(entry.name, style: const TextStyle(fontSize: 13)),
                subtitle: Text(
                  '${_formatSize(entry.size)} · ${entry.tag}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: const Icon(Icons.download_outlined, size: 18),
                onTap: () => Navigator.pop(context, entry),
              ),
          ],
        ),
      ),
    );
    if (picked != null) await widget.onInstall(picked);
  }

  static String _label(String id) => switch (id) {
    'android-sdk' => 'Android SDK',
    'ndk' => 'Android NDK',
    'flutter-sdk' => 'Flutter SDK',
    _ => id,
  };

  static String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(0)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }
}
