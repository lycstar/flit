/// 本地实际目录是已安装版本的事实来源，不额外保存一份版本配置。
class InstalledToolchain {
  const InstalledToolchain({
    required this.path,
    required this.sizeKb,
    required this.active,
    required this.complete,
    required this.revision,
  });

  final String path;
  final int sizeKb;
  final bool active;
  final bool complete;
  final String revision;
  bool get isFlutter => path.startsWith('flutter/');
  String get version => path.split('/').last;
  String get title =>
      '${switch (path.split('/').first) {
        'flutter' => 'Flutter',
        'ndk' => 'NDK',
        'cmake' => 'CMake',
        _ => switch (path.split('/')[1]) {
          'platforms' => 'Android Platform',
          'build-tools' => 'Build Tools',
          'cmdline-tools' => 'Command-line Tools',
          _ => 'Platform Tools',
        },
      }}${path == 'android-sdk/platform-tools' || path.startsWith('android-sdk/cmdline-tools/') ? (revision.isEmpty ? '' : ' $revision') : ' $version'}';
  String get size => sizeKb >= 1024 * 1024
      ? '${(sizeKb / 1024 / 1024).toStringAsFixed(1)} GB'
      : '${(sizeKb / 1024).toStringAsFixed(0)} MB';

  static InstalledToolchain? parse(String line) {
    if (!line.startsWith('__TOOL__')) return null;
    final fields = line.substring(8).trim().split('|');
    if (fields.length != 5 || int.tryParse(fields[1]) == null) return null;
    return InstalledToolchain(
      path: fields[0],
      sizeKb: int.parse(fields[1]),
      active: fields[2] == '1',
      complete: fields[3] == '1',
      revision: fields[4],
    );
  }
}
