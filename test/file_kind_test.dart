import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/editor/file_kind.dart';

void main() {
  test('known names: images preview, blacklist is binary, text opens as code', () {
    expect(fileKindByName('assets/logo.png'), FileKind.image);
    expect(fileKindByName('assets/PHOTO.JPG'), FileKind.image);
    expect(fileKindByName('build/app/outputs/flutter-apk/app-debug.apk'), FileKind.binary);
    expect(fileKindByName('libs/foo.jar'), FileKind.binary);
    expect(fileKindByName('fonts/Mono.ttf'), FileKind.binary);
    expect(fileKindByName('lib/main.dart'), FileKind.code);
    expect(fileKindByName('pubspec.yaml'), FileKind.code);
    // 曾被白名单误判成二进制而拒开的几类
    expect(fileKindByName('android/app/src/main/kotlin/MainActivity.kt'), FileKind.code);
    expect(fileKindByName('lib/l10n/app_en.arb'), FileKind.code);
    expect(fileKindByName('Cargo.toml'), FileKind.code);
    expect(fileKindByName('assets/icon.svg'), FileKind.code);
  });

  test('unknown or missing extension defers to sniffing', () {
    expect(fileKindByName('LICENSE'), isNull);
    expect(fileKindByName('Makefile'), isNull);
    expect(fileKindByName('data/blob.xyz'), isNull);
    // 目录名里的点不算后缀
    expect(fileKindByName('v1.2/README'), isNull);
  });

  test('sniff command reads only the head and its verdict parses', () {
    final cmd = sniffCommand("/p/it's/LICENSE");
    expect(cmd, startsWith("head -c 8192 -- '/p/it'\\''s/LICENSE' | od -An -c"));
    expect(cmd, contains("grep -qF '\\0'"));
    expect(fileKindFromSniff('binary\n'), FileKind.binary);
    expect(fileKindFromSniff('text\n'), FileKind.code);
    expect(fileKindFromSniff(''), FileKind.code);
  });

  test('card actions: share always first, apk swaps open for install', () {
    expect(cardActions('build/app/outputs/app-release.apk'), [
      FileCardAction.installApk,
      FileCardAction.share,
    ]);
    expect(cardActions('assets/images/logo.png'), [
      FileCardAction.share,
      FileCardAction.openExternal,
    ]);
    expect(cardActions('dist/data.sqlite'), [
      FileCardAction.share,
      FileCardAction.openExternal,
    ]);
  });

  test('renderable document formats are extension based', () {
    expect(renderableDocumentFormat('README.md'), 'md');
    expect(renderableDocumentFormat('docs/guide.markdown'), 'md');
    expect(renderableDocumentFormat('assets/logo.svg'), 'svg');
    expect(renderableDocumentFormat('lib/main.dart'), isNull);
    expect(renderableDocumentFormat('notes.txt'), isNull);
  });
}
