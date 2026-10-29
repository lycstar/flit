import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// 查询已配置构建仓库的 GitHub Releases，失败时保留本次会话内的缓存。
class ToolchainCatalog {
  ToolchainCatalog({this.sources = components});

  final Map<String, CatalogSource> sources;

  /// 可注入测试
  Future<Object?> Function(String url) fetchJson = _fetchJsonDefault;

  final _cache = <String, List<CatalogEntry>>{};

  /// 每个组件的构建仓与资产匹配模式(组件注册表)。
  static const components = <String, CatalogSource>{
    'bootstrap': CatalogSource(
      repo: String.fromEnvironment('FLIT_BOOTSTRAP_REPO'),
      asset: 'bootstrap-aarch64.zip',
      install: r'$PREFIX (bootstrap 解压)',
    ),
    'android-sdk': CatalogSource(
      repo: String.fromEnvironment('FLIT_ANDROID_SDK_REPO'),
      asset: 'android-sdk-aarch64-linux-android.tar.xz',
      install: r'$HOME/android-sdk',
    ),
    'ndk': CatalogSource(
      repo: String.fromEnvironment('FLIT_NDK_REPO'),
      asset: 'android-ndk-*-aarch64-linux-android.tar.xz',
      install: r'$HOME/android-sdk/ndk/<Pkg.Revision>',
    ),
    'flutter-sdk': CatalogSource(
      repo: String.fromEnvironment('FLIT_FLUTTER_SDK_REPO'),
      asset: 'flutter-*-aarch64-linux-android.tar.xz',
      install: r'$PREFIX/opt/flutter',
    ),
  };

  /// 上次成功拉取的结果(API 不可达时的离线兜底)
  Map<String, List<CatalogEntry>> get lastGood => Map.unmodifiable(_cache);

  /// 拉取全部组件的可选版本。单个组件失败不影响其他组件,
  /// 失败的组件从 [lastGood] 回退, 全都失败时该组件返回空列表。
  Future<Map<String, List<CatalogEntry>>> collect() async {
    final result = <String, List<CatalogEntry>>{};
    for (final entry in sources.entries) {
      final id = entry.key;
      final cached = _cache[id] ?? const [];
      if (entry.value.repo.isEmpty) {
        result[id] = const [];
        continue;
      }
      try {
        final releases =
            await fetchJson(
                  'https://api.github.com/repos/${entry.value.repo}/releases?per_page=30',
                )
                as List? ??
            const [];
        final found = <CatalogEntry>[];
        for (final release in releases) {
          final tag = release['tag_name'] as String? ?? '';
          final assets = release['assets'] as List? ?? const [];
          for (final asset in assets) {
            final name = asset['name'] as String? ?? '';
            if (!matchesAsset(name, entry.value.asset)) continue;
            found.add(
              CatalogEntry(
                component: id,
                repo: entry.value.repo,
                tag: tag,
                name: name,
                url: asset['browser_download_url'] as String? ?? '',
                size: asset['size'] as int? ?? 0,
                sha256: (asset['digest'] as String?)?.split(':').last,
                publishedAt: DateTime.tryParse(
                  release['published_at'] as String? ?? '',
                ),
              ),
            );
          }
        }
        if (found.isEmpty && cached.isNotEmpty) {
          result[id] = cached;
          continue;
        }
        found.sort(
          (a, b) => (b.publishedAt ?? DateTime(0)).compareTo(
            a.publishedAt ?? DateTime(0),
          ),
        );
        result[id] = found;
        _cache[id] = found;
      } on Exception {
        result[id] = cached;
        if (cached.isEmpty) _cache.remove(id);
      }
    }
    return result;
  }

  /// 资产名通配符匹配(只支持 '*', 够用: 组件资产模式固定); 公开供测试
  static bool matchesAsset(String name, String pattern) {
    // 资产名通配符只支持 '*'(够用: 组件资产模式固定)
    final segments = pattern.split('*');
    var start = 0;
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      if (segment.isEmpty) continue;
      final found = name.indexOf(segment, start);
      if (found < 0) return false;
      start = found + segment.length;
    }
    if (segments.first.isNotEmpty && !name.startsWith(segments.first)) {
      return false;
    }
    if (segments.last.isNotEmpty && !name.endsWith(segments.last)) {
      return false;
    }
    return true;
  }

  static Future<Object?> _fetchJsonDefault(String url) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('Accept', 'application/vnd.github+json');
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
      }
      return jsonDecode(await response.transform(utf8.decoder).join());
    } finally {
      client.close();
    }
  }
}

/// 一个可下载的工具链产物
class CatalogEntry {
  const CatalogEntry({
    required this.component,
    required this.repo,
    required this.tag,
    required this.name,
    required this.url,
    required this.size,
    required this.sha256,
    this.publishedAt,
  });

  final String component;
  final String repo;
  final String tag;
  final String name;

  /// browser_download_url(匿名可下)
  final String url;
  final int size;

  /// GitHub 资产自带的 sha256(安装前校验); 旧资产可能没有
  final String? sha256;
  final DateTime? publishedAt;
}

/// 构建仓与资产匹配模式
class CatalogSource {
  const CatalogSource({
    required this.repo,
    required this.asset,
    required this.install,
  });
  final String repo;
  final String asset;
  final String install;
}
