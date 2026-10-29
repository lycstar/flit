import '../../services/shell.dart';

/// 文件在编辑器里的打开方式: 代码(文本编辑器) / 图片(预览卡) / 二进制(文件卡)。
enum FileKind { code, image, binary }

const _imageExtensions = {'png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'};

/// 明确不是文本的: 只这一小张黑名单, 其余都按文本尝试(白名单漏得太多,
/// .kt/.toml/.arb 这类曾被当成二进制拒开)
const _binaryExtensions = {
  'apk', 'aab', 'jar', 'aar', 'so', 'a', 'o', 'dex', 'class', 'dill', //
  'snapshot', 'zip', '7z', 'rar', 'tar', 'gz', 'tgz', 'bz2', 'xz', 'zst',
  'ttf', 'otf', 'woff', 'woff2', 'pdf', 'mp3', 'mp4', 'm4a', 'aac', 'ogg',
  'wav', 'flac', 'mov', 'avi', 'mkv', 'webm', 'ico', 'icns', 'psd', 'ai',
  'bin', 'dat', 'db', 'sqlite', 'keystore', 'jks', 'der', 'p12', 'pfx',
  'exe', 'dll', 'dylib', 'wasm',
};

/// 常见文本后缀直接认, 省一次嗅探
const _textExtensions = {
  'dart', 'yaml', 'yml', 'txt', 'md', 'json', 'xml', 'kt', 'kts', 'gradle', //
  'properties', 'java', 'c', 'cc', 'cpp', 'h', 'hpp', 'html', 'htm', 'css',
  'js', 'ts', 'tsx', 'jsx', 'sh', 'bash', 'lock', 'toml', 'ini', 'cfg',
  'conf', 'env', 'csv', 'tsv', 'sql', 'arb', 'plist', 'pro', 'cmake', 'iml',
  'svg', 'swift', 'm', 'mm', 'py', 'rb', 'rs', 'go', 'vue', 'bat', 'ps1',
  'gitignore', 'gitattributes', 'editorconfig', 'metadata', 'log', 'pem',
};

String _extensionOf(String path) {
  final name = path.split('/').last;
  final dot = name.lastIndexOf('.');
  return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
}

/// 只凭名字能判定的类型; 未知后缀与无后缀返回 null, 要用 [sniffCommand] 嗅探
FileKind? fileKindByName(String path) {
  final ext = _extensionOf(path);
  if (_imageExtensions.contains(ext)) return FileKind.image;
  if (_binaryExtensions.contains(ext)) return FileKind.binary;
  if (_textExtensions.contains(ext)) return FileKind.code;
  return null;
}

/// 嗅探: 前 8KB 出现 NUL 字节即二进制。输出一行 binary 或 text。
/// od 把 NUL 打成 \0, grep 按定长串找(正则里 \0 是非法回引)
String sniffCommand(String absolutePath) =>
    'head -c 8192 -- ${shQuote(absolutePath)} | od -An -c '
    r"| grep -qF '\0' && echo binary || echo text";

/// 解析嗅探输出
FileKind fileKindFromSniff(String output) =>
    output.trim().endsWith('binary') ? FileKind.binary : FileKind.code;
