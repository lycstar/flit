import 'installed_toolchain.dart';
import 'toolchain_catalog.dart';

/// 管理对象是安装目录里的组件，而非 Release 里的压缩包。
/// SDK 整包仅用于初始化；ADB 和 sdkmanager 共用固定目录，不伪装成多版本组件。
class ToolchainComponent {
  const ToolchainComponent(
    this.id,
    this.title,
    this.description, {
    this.shared = false,
  });

  final String id;
  final String title;
  final String description;
  final bool shared;

  static const all = [
    ToolchainComponent(
      'flutter-sdk',
      'Flutter SDK',
      '可安装多个版本，选择当前使用的版本。安装新版本后会自动切换。',
    ),
    ToolchainComponent(
      'platforms',
      'Android Platforms',
      '对应项目的 compileSdk，可同时保留多个 API 版本。',
    ),
    ToolchainComponent(
      'build-tools',
      'Build Tools',
      'Android 打包工具，按项目需要安装并保留多个版本。',
    ),
    ToolchainComponent('ndk', 'Android NDK', '原生代码编译工具，由项目指定版本，可同时安装多个版本。'),
    ToolchainComponent('cmake', 'CMake / Ninja', '原生构建工具，由项目指定版本，可同时安装多个版本。'),
    ToolchainComponent(
      'platform-tools',
      'Platform Tools',
      'ADB 等设备工具，所有项目共用。只提供基础环境配套包，安装会替换现有工具。',
      shared: true,
    ),
    ToolchainComponent(
      'cmdline-tools',
      'Command-line Tools',
      'sdkmanager 等 SDK 管理工具，所有项目共用。只提供基础环境配套包，安装会替换现有工具。',
      shared: true,
    ),
  ];

  List<InstalledToolchain> installed(List<InstalledToolchain> tools) =>
      tools.where((tool) => tool.component == id).toList();

  String versionLabel(CatalogEntry entry) => switch (id) {
    'platforms' => 'API ${entry.tag.replaceFirst('platform-', '')}',
    'build-tools' => entry.tag.replaceFirst('sdk-', ''),
    'flutter-sdk' => entry.tag.replaceFirst('flutter-', ''),
    'ndk' => entry.tag.replaceFirst('ndk-', ''),
    'cmake' => entry.tag.replaceFirst('cmake-', ''),
    _ => '配套工具包 · ${entry.tag}',
  };

  /// tag 只描述发布族。特别是 sdk-36.0.0 不能当作 ADB/sdkmanager 的版本，
  /// NDK 的 r 标签也不能用于项目要求的完整 Pkg.Revision 验证。
  String? releaseTag(InstalledToolchain tool) => switch (id) {
    'platforms' => 'platform-${tool.version.replaceFirst('android-', '')}',
    'build-tools' => 'sdk-${tool.version}',
    'flutter-sdk' => 'flutter-${tool.version}',
    'cmake' => 'cmake-${tool.version}',
    // NDK 目录使用完整 revision，展示层不凭 r 标签猜测两个安装包相同。
    _ => null,
  };

  List<CatalogEntry> downloads(
    ToolchainCatalog catalog,
    Map<String, List<CatalogEntry>> versions,
    List<InstalledToolchain> local,
  ) {
    final entries = versions[id] ?? const [];
    if (shared) {
      return entries
          .where(
            (e) =>
                e.tag == catalog.sources[id]?.defaultTag &&
                !local.any((t) => matches(t, e)),
          )
          .toList();
    }
    return entries.where((e) => !local.any((t) => matches(t, e))).toList();
  }

  bool matches(InstalledToolchain tool, CatalogEntry entry) =>
      releaseTag(tool) == entry.tag ||
      (tool.archiveSha256 != null && tool.archiveSha256 == entry.sha256);
}
