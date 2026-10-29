import 'package:flit_files/flit_files.dart';
import 'package:flutter/material.dart';

import '../../../core/page_layout.dart';
import '../../../core/theme.dart';
import '../../../services/app_releases.dart';
import '../../../services/shell.dart';

/// App 更新页:当前构建对照最新发布(检查更新),
/// 下方列出全部历史版本与产物,APK 可下载安装。
class AppVersionsPage extends StatefulWidget {
  AppVersionsPage({super.key, AppReleases? releases})
    : releases = releases ?? _shared;
  static final _shared = AppReleases();

  final AppReleases releases;

  @override
  State<AppVersionsPage> createState() => _AppVersionsPageState();
}

class _AppVersionsPageState extends State<AppVersionsPage> {
  List<AppRelease>? _releases;
  Object? _error;
  String _home = '';

  /// 产物 url → 下载进度(0..1);在表中即下载中
  final _progress = <String, double>{};

  @override
  void initState() {
    super.initState();
    _refresh();
    _loadHome();
  }

  Future<void> _loadHome() async {
    try {
      final status = await Shell.instance.bootstrapStatus();
      if (mounted) {
        setState(() => _home = status['home'] as String? ?? '');
      }
    } catch (_) {
      /* home 拿不到时下载落系统临时目录, 安装照常 */
    }
  }

  Future<void> _refresh() async {
    try {
      final releases = await widget.releases.collect();
      if (mounted) {
        setState(() {
          _releases = releases;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  void _snackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _download(AppAsset asset) async {
    final url = asset.url;
    if (_progress.containsKey(url)) return;
    setState(() => _progress[url] = 0);
    try {
      final path = await widget.releases.download(
        asset,
        home: _home,
        onProgress: (value) {
          if (mounted) setState(() => _progress[url] = value);
        },
      );
      if (!mounted) return;
      setState(() => _progress.remove(url));
      if (asset.isApk) {
        // false = 需要先授权"安装未知应用"(插件已跳授权页), 授权后重试
        final ok = await FlitFiles.installApk(path);
        if (!ok) _snackbar('需要先授权“安装未知应用”，授权后重新点击安装');
      } else {
        final ok = await FlitFiles.share(path);
        if (!ok) _snackbar('下载完成:$path');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _progress.remove(url));
        _snackbar('下载失败:$error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App 更新')),
      body: PageList(
        children: [
          PageIntro('App 更新', '当前构建对照 GitHub 发布；历史版本的产物可下载安装。'),
          _currentCard(),
          const SizedBox(height: 16),
          if (_releases == null && _error == null)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null) ...[
            StatusNotice('发布列表请求失败：$_error', error: true),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _error = null);
                _refresh();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重试'),
            ),
          ] else ...[
            for (final (index, release) in _releases!.indexed) _releaseCard(
              release,
              expanded: index == 0,
            ),
          ],
        ],
      ),
    );
  }

  /// 检查更新:当前构建号是否出现在最新发布的产物里
  Widget _currentCard() {
    final releases = _releases;
    final latest = releases != null && releases.isNotEmpty
        ? releases.first
        : null;
    final buildSha = AppReleases.buildSha;
    final (label, color) = latest == null
        ? ('未知', AppColors.textSecondary)
        : buildSha.length < 7
        ? ('本地构建，不比对版本', AppColors.textSecondary)
        : AppReleases.shippedIn(latest)
        ? ('已是最新', AppColors.success)
        : ('有更新:${latest.tag}', AppColors.accent);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('当前构建', buildSha, mono: true),
          _row('最新发布', latest == null ? '—' : latest.tag),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                label == '已是最新' ? Icons.check_circle_outline : Icons.info_outline,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, style: TextStyle(fontSize: 13, color: color)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool mono = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: mono
                ? AppColors.mono.copyWith(fontSize: 12)
                : const TextStyle(fontSize: 13),
          ),
        ),
      ],
    ),
  );

  Widget _releaseCard(AppRelease release, {required bool expanded}) {
    final date = release.publishedAt == null
        ? ''
        : '${release.publishedAt!.year}-'
              '${release.publishedAt!.month.toString().padLeft(2, '0')}-'
              '${release.publishedAt!.day.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SurfaceCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: expanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          title: Text(
            release.tag,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '$date${release.prerelease ? ' · 预发布' : ''}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          children: [
            if (release.assets.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('无产物', style: TextStyle(fontSize: 12)),
              ),
            for (final asset in release.assets)
              ListTile(
                dense: true,
                title: Text(
                  asset.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppColors.mono.copyWith(fontSize: 12),
                ),
                subtitle: _progress.containsKey(asset.url)
                    ? LinearProgressIndicator(value: _progress[asset.url])
                    : Text(
                        _formatSize(asset.size),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                trailing: _progress.containsKey(asset.url)
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        tooltip: asset.isApk ? '下载并安装' : '下载',
                        icon: const Icon(Icons.download_outlined, size: 18),
                        onPressed: () => _download(asset),
                      ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(0)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }
}
