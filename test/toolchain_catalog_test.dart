import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/environment/toolchain_catalog.dart';

Map<String, dynamic> release(
  String tag,
  String published, {
  required List<Map<String, dynamic>> assets,
}) => {
  'tag_name': tag,
  'published_at': published,
  'assets': [
    for (final a in assets)
      {
        'name': a['name'],
        'size': a['size'],
        'browser_download_url':
            'https://github.com/example/toolchain/releases/download/$tag/${a['name']}',
        'digest': 'sha256:${a['digest']}',
      },
  ],
};

void main() {
  late ToolchainCatalog exampleCatalog;
  setUp(() {
    exampleCatalog = ToolchainCatalog(
      sources: {
        for (final entry in ToolchainCatalog.components.entries)
          entry.key: CatalogSource(
            repo:
                'example/${const {'bootstrap': 'bootstrap', 'android-sdk': 'android-sdk-custom', 'ndk': 'android-ndk-custom', 'flutter-sdk': 'flutter-sdk-custom'}[entry.key]}',
            asset: entry.value.asset,
            install: entry.value.install,
          ),
      },
    );
  });
  test('unconfigured repositories do not make network requests', () async {
    final catalog = ToolchainCatalog()
      ..fetchJson = (_) async => throw StateError('Unexpected request');
    expect(
      (await catalog.collect()).values.every((entries) => entries.isEmpty),
      isTrue,
    );
  });

  test('asset matching: plain name and star patterns', () {
    expect(
      ToolchainCatalog.matchesAsset(
        'android-ndk-r28c-aarch64-linux-android.tar.xz',
        'android-ndk-*-aarch64-linux-android.tar.xz',
      ),
      isTrue,
    );
    expect(
      ToolchainCatalog.matchesAsset(
        'android-sdk-aarch64-linux-android.tar.xz',
        'android-sdk-aarch64-linux-android.tar.xz',
      ),
      isTrue,
    );
    // 通配符段也不许缺席
    expect(
      ToolchainCatalog.matchesAsset(
        'android-ndk-aarch64-linux-android.tar.xz',
        'android-ndk-*-aarch64-linux-android.tar.xz',
      ),
      isFalse,
    );
    expect(
      ToolchainCatalog.matchesAsset(
        'bootstrap-aarch64.zip.other',
        'bootstrap-aarch64.zip',
      ),
      isFalse,
    );
  });

  test('collect gathers matching assets per component, newest first', () async {
    final catalog = exampleCatalog
      ..fetchJson = (url) async {
        if (url.contains('android-ndk-custom')) {
          return [
            release(
              'r27',
              '2026-10-01T00:00:00Z',
              assets: [
                {
                  'name': 'android-ndk-r27d-aarch64-linux-android.tar.xz',
                  'size': 129,
                  'digest': 'aa',
                },
              ],
            ),
          ];
        }
        if (url.contains('android-sdk-custom')) {
          return [
            release(
              '36.0.1',
              '2026-10-02T00:00:00Z',
              assets: [
                {
                  'name': 'android-sdk-aarch64-linux-android.tar.xz',
                  'size': 156,
                  'digest': 'bb',
                },
              ],
            ),
          ];
        }
        if (url.contains('flutter-sdk-custom')) {
          return [
            release(
              '3.47.7',
              '2026-10-03T00:00:00Z',
              assets: [
                {
                  'name': 'flutter-3.47.7-aarch64-linux-android.tar.xz',
                  'size': 590,
                  'digest': 'cc',
                },
              ],
            ),
          ];
        }
        return [
          release(
            'bootstrap-2026.10.16-r1+apt.android-7',
            '2026-10-04T00:00:00Z',
            assets: [
              {'name': 'bootstrap-aarch64.zip', 'size': 31, 'digest': 'dd'},
            ],
          ),
        ];
      };

    final result = await catalog.collect();
    expect(
      result.keys,
      containsAll(['bootstrap', 'android-sdk', 'ndk', 'flutter-sdk']),
    );
    final ndk = result['ndk']!;
    expect(ndk, hasLength(1));
    expect(ndk.single.tag, 'r27');
    expect(ndk.single.sha256, 'aa');
    expect(ndk.single.url, contains('releases/download/r27/'));
    expect(result['flutter-sdk']!.single.size, 590);
  });

  test(
    'one component failing falls back to its cache, others stay fresh',
    () async {
      final catalog = exampleCatalog;
      catalog.fetchJson = (url) async => [
        release(
          '36.0.1',
          '2026-10-02T00:00:00Z',
          assets: [
            {
              'name': 'android-sdk-aarch64-linux-android.tar.xz',
              'size': 156,
              'digest': 'bb',
            },
          ],
        ),
      ];
      final first = await catalog.collect();
      expect(first['android-sdk']!, isNotEmpty);

      // 之后 SDK 仓持续 500, NDK 恢复: SDK 用上次成功结果, NDK 拿到新数据
      catalog.fetchJson = (url) async {
        if (url.contains('android-sdk-custom')) {
          throw const HttpExceptionWithCode('HTTP 503');
        }
        return [
          release(
            'r28',
            '2026-10-05T00:00:00Z',
            assets: [
              {
                'name': 'android-ndk-r28c-aarch64-linux-android.tar.xz',
                'size': 130,
                'digest': 'ee',
              },
            ],
          ),
        ];
      };
      final second = await catalog.collect();
      expect(second['android-sdk']!.single.sha256, 'bb'); // lastGood 回退
      expect(second['ndk']!.single.tag, 'r28');
    },
  );
}

class HttpExceptionWithCode implements Exception {
  const HttpExceptionWithCode(this.message);
  final String message;
  @override
  String toString() => message;
}
