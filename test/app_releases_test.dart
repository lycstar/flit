import 'package:flutter_test/flutter_test.dart';
import 'package:flit/services/app_releases.dart';

Map<String, dynamic> release(
  String tag, {
  bool prerelease = false,
  List<Map<String, dynamic>> assets = const [],
}) => {
  'tag_name': tag,
  'name': 'Flit $tag',
  'prerelease': prerelease,
  'published_at': '2026-10-29T11:17:00Z',
  'assets': [
    for (final a in assets)
      {
        'name': a['name'],
        'size': a['size'],
        'browser_download_url':
            'https://github.com/lycstar/flit/releases/download/$tag/${a['name']}',
      },
  ],
};

void main() {
  test('default catalog points at the Flit repository', () {
    expect(AppReleases().repo, 'lycstar/flit');
  });

  test('collect parses tags, prerelease flags and assets in order', () async {
    final catalog = AppReleases()
      ..fetchJson = (url) async {
        expect(url, contains('repos/lycstar/flit/releases?per_page=30'));
        return [
          release(
            'v1.0.0-preview.2',
            prerelease: true,
            assets: [
              {
                'name': 'flit-v1.0.0-preview.2-20261030-abcdef0.apk',
                'size': 987,
              },
            ],
          ),
          release('v1.0.0-preview.1'),
        ];
      };

    final releases = await catalog.collect();
    expect(releases, hasLength(2));
    expect(releases[0].tag, 'v1.0.0-preview.2');
    expect(releases[0].prerelease, isTrue);
    expect(releases[0].assets.single.name, contains('abcdef0'));
    expect(releases[0].assets.single.url, contains('/download/v1.0.0-preview.2/'));
    expect(releases[0].assets.single.isApk, isTrue);
    expect(releases[1].tag, 'v1.0.0-preview.1');
    expect(releases[1].assets, isEmpty);
  });

  test('build identity matches release assets by short sha', () {
    final latest = AppRelease(
      tag: 'v1',
      name: 'v1',
      prerelease: true,
      assets: [
        const AppAsset(
          name: 'flit-v1-20261030-1e99594.apk',
          size: 1,
          url: 'https://example/flit-v1-20261030-1e99594.apk',
        ),
      ],
    );
    expect(AppReleases.matchesBuild(latest, '1e99594abcdef0123456'), isTrue);
    expect(AppReleases.matchesBuild(latest, '0000000abcdef0123456'), isFalse);
    expect(AppReleases.matchesBuild(latest, 'dev'), isFalse);
    // 本地构建(development)不做比对
    expect(AppReleases.shippedIn(latest), isFalse);
  });
}
