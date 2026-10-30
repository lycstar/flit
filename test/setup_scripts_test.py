"""Run setup sub-task scripts with local archives and fake downloads, never real APT.

每个用例对应一类中断/重试场景: 断点续传、半截解压重装、合并落位不误删 NDK、
多版本共存、安全删除、只补缺的工具、check 零副作用。
"""
import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import threading
import io
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import tempfile
import unittest

SCRIPTS = Path(__file__).resolve().parents[1] / 'assets/scripts'


class SetupScriptsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.prefix = self.root / 'usr'
        self.tools = self.prefix / 'bin'
        self.tools.mkdir(parents=True)
        self.tmp = self.prefix / 'tmp'
        self.tmp.mkdir()
        self.config = self.root / '.flit/env.sh'
        self.config.parent.mkdir()
        self.config.write_text('true\n')
        self.env = {**os.environ, 'HOME': str(self.root), 'PREFIX': str(self.prefix),
                    'FLIT_APT_SOURCE': 'https://example.invalid/apt ./',
                    'SDK_VERSION': '36.1.0', 'SDK_PLATFORM_VERSION': '36',
                    'TMPDIR': str(self.tmp), 'ANDROID_HOME': str(self.root / 'toolchains/android-sdk'),
                    'JAVA_HOME': str(self.root / 'jdk'), 'GRADLE_USER_HOME': str(self.root / '.gradle'),
                    'PATH': str(self.tools) + ':' + os.environ['PATH']}
        if shutil.which('gsed'):
            (self.tools / 'sed').symlink_to(shutil.which('gsed'))
        self.write_exec(self.tools / 'git', '#!/bin/sh\necho git version 2.47\necho 2.47\n')
        self.write_exec(self.tools / 'dpkg', '#!/bin/sh\nexit 0\n')
        self.write_exec(self.tools / 'dpkg-query', '#!/bin/sh\nexit 1\n')
        self.curl_calls = []
        for command in ('mv',):
            gnu = shutil.which('g' + command)
            if gnu:
                (self.tools / command).symlink_to(gnu)
        (self.root / 'toolchains/flutter/3.47.8').mkdir(parents=True)
        (self.root / 'toolchains/flutter/current').symlink_to('3.47.8')

    def write_exec(self, path, body):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body)
        path.chmod(0o755)

    def install_fake_curl(self, fail_url_substring=None, append_resume=False):
        """curl 桩: 拷贝本地档案当下载; 可指定失败 URL 片段。"""
        self.write_exec(self.tools / 'curl', '''#!/usr/bin/env python3
import os, pathlib, shutil, sys
args = sys.argv[1:]
with open(os.environ['CURL_LOG'], 'a') as log:
    log.write('curl ' + ' '.join(args) + '\\n')
if os.environ.get('CURL_FAIL') and os.environ['CURL_FAIL'] in args[-1]:
    print('curl: HTTP 404', file=sys.stderr)
    sys.exit(22)
out = args[args.index('-o') + 1]
with open(os.environ['TEST_ARCHIVE'], 'rb') as f:
    payload = f.read()
existing = b''
if os.environ.get('CURL_RESUME') == '1' and os.path.exists(out):
    with open(out, 'rb') as f:
        existing = f.read()
# 服务器从既有偏移给剩余字节, 追加到既有内容之后(同源文件)
existing_len = len(existing)
with open(out, 'r+b' if existing else 'wb') as f:
    f.seek(existing_len)
    f.write(payload[existing_len:])
''')
        if append_resume:
            self.env['CURL_RESUME'] = '1'
        self.env['CURL_LOG'] = str(self.root / 'curl-calls')
        (self.root / 'curl-calls').touch()
        if fail_url_substring:
            self.env['CURL_FAIL'] = fail_url_substring

    def archive(self, files):
        path = self.root / 'archive.tar.xz'
        with tarfile.open(path, 'w:xz') as archive:
            for name, contents, mode in files:
                entry = tarfile.TarInfo(name)
                entry.mode = mode
                if mode == 0o777:
                    entry.type = tarfile.SYMTYPE
                    entry.linkname = contents
                    archive.addfile(entry)
                else:
                    data = contents.encode()
                    entry.size = len(data)
                    archive.addfile(entry, io.BytesIO(data))
        self.env['TEST_ARCHIVE'] = str(path)
        return hashlib.sha256(path.read_bytes()).hexdigest()

    def run_script(self, name, *args):
        return subprocess.run(['bash', str(SCRIPTS / name), *args], env=self.env,
                              text=True, errors='replace',
                              stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

    def marker(self, directory):
        return (Path(directory) / '.flit-complete')

    # ---- 3-1 Flutter SDK ----

    def flutter_archive(self, exit_code=0):
        sha = self.archive([('flutter/bin/flutter', '''#!/bin/sh
echo call >> "$HOME/flutter-calls"
echo 'Downloading Dart SDK...' >&2
echo 'Flutter 3.47.8 • channel stable'
echo 'engine diagnostic detail' >&2
exit %d
''' % exit_code, 0o755), ('flutter/bin/cache/dart-sdk/bin/dart', '#!/bin/sh\nexit 0\n', 0o755)])
        self.config.write_text(f"FLUTTER_URLS=('https://test/missing' 'https://test/sdk')\nFLUTTER_SHA256='{sha}'\n")
        self.install_fake_curl('missing')

    def test_flutter_sdk_falls_back_sources_and_writes_marker(self):
        self.flutter_archive()
        result = self.run_script('flutter_sdk.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        for text in ('https://test/missing', 'curl: HTTP 404',
                     '__STAGE__flutter_sdk:RUNNING', '__STAGE__flutter_sdk:DONE'):
            self.assertIn(text, result.stdout)
        self.assertEqual(self.marker(self.root / 'toolchains/flutter/current').read_text().strip(),
                         hashlib.sha256(Path(self.env['TEST_ARCHIVE']).read_bytes()).hexdigest())
        # 安装包在标记落盘后删除
        self.assertFalse((self.tmp / 'flutter-sdk.tar.xz').exists())

    def test_flutter_sdk_interrupted_extract_reinstalls_from_cache_without_download(self):
        self.flutter_archive()
        sha = hashlib.sha256(Path(self.env['TEST_ARCHIVE']).read_bytes()).hexdigest()
        # 半截解压现场: 目录在(bin/ 早于 packages/ 出现在归档序), 无标记; 缓存包在
        flutter = self.root / 'toolchains/flutter/current'
        (flutter / 'bin').mkdir(parents=True)
        self.write_exec(flutter / 'bin/flutter', '#!/bin/sh\nexit 0\n')
        self.write_exec(flutter / 'bin/cache/dart-sdk/bin/dart', '#!/bin/sh\nexit 0\n')
        cache = self.tmp / f'toolchain-downloads/{sha}.tar.xz'
        cache.parent.mkdir()
        shutil.copyfile(self.env['TEST_ARCHIVE'], cache)
        result = self.run_script('flutter_sdk.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertNotIn('curl ', (self.root / 'curl-calls').read_text(), '有缓存包时不应重新下载')
        self.assertTrue(self.marker(flutter).exists())
        self.assertIn('__STAGE__flutter_sdk:DONE', result.stdout)

    def test_flutter_sdk_skips_when_marker_matches(self):
        self.flutter_archive()
        flutter = self.root / 'toolchains/flutter/current'
        (flutter / 'bin').mkdir(parents=True)
        self.write_exec(flutter / 'bin/flutter', '#!/bin/sh\nexit 0\n')
        self.write_exec(flutter / 'bin/cache/dart-sdk/bin/dart', '#!/bin/sh\nexit 0\n')
        self.marker(flutter).write_text(
            hashlib.sha256(Path(self.env['TEST_ARCHIVE']).read_bytes()).hexdigest() + '\n')
        result = self.run_script('flutter_sdk.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('跳过下载与解压', result.stdout)
        self.assertNotIn('curl ', (self.root / 'curl-calls').read_text())

    def test_flutter_sdk_default_keeps_selected_version_when_manifest_changes(self):
        self.flutter_archive()
        flutter = self.root / 'toolchains/flutter/current'
        self.write_exec(flutter / 'bin/flutter', '#!/bin/sh\nexit 0\n')
        self.write_exec(flutter / 'bin/cache/dart-sdk/bin/dart', '#!/bin/sh\nexit 0\n')
        self.marker(flutter).write_text('0' * 64 + '\n')
        result = self.run_script('flutter_sdk.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertNotIn('curl ', (self.root / 'curl-calls').read_text())
        self.assertEqual(self.marker(flutter).read_text().strip(), '0' * 64)

    def test_flutter_versions_coexist_and_switch_without_redownload(self):
        self.flutter_archive()
        sha = hashlib.sha256(Path(self.env['TEST_ARCHIVE']).read_bytes()).hexdigest()
        for version in ('3.47.8', '3.48.0'):
            result = self.run_script('flutter_sdk.sh', '--release', 'https://test/sdk', sha, version)
            self.assertEqual(result.returncode, 0, result.stdout)
            self.assertTrue(self.marker(self.root / f'toolchains/flutter/{version}').exists())
        calls = (self.root / 'curl-calls').read_text()
        result = self.run_script('flutter_sdk.sh', '--release', 'https://test/sdk', sha, '3.47.8')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual((self.root / 'toolchains/flutter/current').readlink(), Path('3.47.8'))
        self.assertEqual((self.root / 'curl-calls').read_text(), calls)

    def test_failed_flutter_install_preserves_current_sdk(self):
        self.flutter_archive()
        result = self.run_script('flutter_sdk.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        marker = self.marker(self.root / 'toolchains/flutter/current').read_text()
        result = self.run_script('flutter_sdk.sh', '--release', 'https://test/sdk', '0' * 64, '3.48.0')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((self.root / 'toolchains/flutter/current').readlink(), Path('3.47.8'))
        self.assertEqual(self.marker(self.root / 'toolchains/flutter/current').read_text(), marker)

    def test_download_resumes_from_partial_part(self):
        """断点续传: .part 前半截 + stub 从既有偏移补齐 → 完整文件过校验, 不重下整包"""
        self.flutter_archive()
        sha = hashlib.sha256(Path(self.env['TEST_ARCHIVE']).read_bytes()).hexdigest()
        part = self.tmp / f'toolchain-downloads/{sha}.tar.xz.part'
        part.parent.mkdir()
        data = Path(self.env['TEST_ARCHIVE']).read_bytes()
        part.write_bytes(data[:len(data) // 2])  # 半截真字节(同源前缀)
        result = self.run_script('flutter_sdk.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('从断点续传', result.stdout)
        self.assertIn('__STAGE__flutter_sdk:DONE', result.stdout)
        # 成功后 .part 已被 mv 走(校验通过的前提), 重新解压用的是补齐后的完整包
        self.assertFalse(part.exists())

    def test_check_emits_markers_in_pipeline_order(self):
        result = self.run_script('check.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        order = ['android_jdk', 'android_sdk', 'android_ndk', 'android_cmake', 'android_gradle',
                 'flutter_tools', 'flutter_sdk', 'flutter_warmup']
        positions = [result.stdout.find(f'__STAGE__{sid}:') for sid in order]
        self.assertTrue(all(p >= 0 for p in positions), result.stdout)
        self.assertEqual(positions, sorted(positions))

    def test_download_checksum_failure_does_not_install(self):
        self.flutter_archive()
        with self.config.open('a') as config:
            config.write("FLUTTER_SHA256='" + '0' * 64 + "'\n")
        result = self.run_script('flutter_sdk.sh')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('FAILED', result.stdout)
        self.assertFalse(self.marker(self.root / 'toolchains/flutter/current').exists())
        self.assertFalse((self.tmp / 'flutter-sdk.tar.xz.part').exists())

    def test_real_curl_follows_release_redirect_before_checksum(self):
        payload = b'archive bytes behind a release redirect'

        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                if self.path == '/release':
                    self.send_response(302)
                    self.send_header('Location', '/asset')
                    self.end_headers()
                else:
                    self.send_response(200)
                    self.send_header('Content-Length', str(len(payload)))
                    self.end_headers()
                    self.wfile.write(payload)

            def log_message(self, *_):
                pass

        server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            destination = self.tmp / 'download'
            result = subprocess.run(
                ['bash', '-c', '. "$1"; dl "$2" "$3" "$4"', 'test',
                 str(SCRIPTS / 'lib.sh'), hashlib.sha256(payload).hexdigest(),
                 str(destination), f'http://127.0.0.1:{server.server_port}/release'],
                env={**self.env, 'NO_PROXY': '127.0.0.1', 'no_proxy': '127.0.0.1'},
                text=True, capture_output=True,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(destination.read_bytes(), payload)
        finally:
            server.shutdown()
            server.server_close()
            thread.join()

    def test_checksum_mismatch_retries_same_url_without_partial_bytes(self):
        self.flutter_archive()
        self.config.write_text(self.config.read_text().replace("'https://test/missing' ", ''))
        fake = self.tools / 'curl'
        body = fake.read_text()
        body = body.replace("out = args[args.index('-o') + 1]", """out = args[args.index('-o') + 1]
count = pathlib.Path(os.environ['HOME']) / 'download-attempts'
if not count.exists():
    count.touch()
    pathlib.Path(out).write_bytes(b'not the archive')
    sys.exit(0)
assert not pathlib.Path(out).exists(), 'corrupt partial must be removed'
""")
        fake.write_text(body)
        result = self.run_script('flutter_sdk.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('从头重试同一地址', result.stdout)
        self.assertIn('SHA-256 实际', result.stdout)
        self.assertEqual(len((self.root / 'curl-calls').read_text().splitlines()), 2)
        self.assertIn('__STAGE__flutter_sdk:DONE', result.stdout)

    # ---- 3-3 预热 ----

    def installed_flutter_stub(self, exit_code=0):
        """3-1 的产物: 已落位的 SDK(与 flutter_archive 同一份桩)。"""
        self.write_exec(self.root / 'toolchains/flutter/current/bin/flutter', '''#!/bin/sh
echo call >> "$HOME/flutter-calls"
echo 'Downloading Dart SDK...' >&2
echo 'Flutter 3.47.8 • channel stable'
echo 'engine diagnostic detail' >&2
exit %d
''' % exit_code)

    def test_flutter_warmup_runs_flutter_once_and_reports_version(self):
        self.installed_flutter_stub()
        result = self.run_script('flutter_warmup.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('engine diagnostic detail', result.stdout)
        self.assertIn('__VER__flutter_warmup:3.47.8', result.stdout)
        self.assertIn('__STAGE__flutter_warmup:DONE', result.stdout)
        self.assertEqual((self.root / 'flutter-calls').read_text(), 'call\n')

    def test_flutter_warmup_failure_is_not_hidden_by_tee(self):
        self.installed_flutter_stub(9)
        result = self.run_script('flutter_warmup.sh')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('engine diagnostic detail', result.stdout)
        self.assertIn('\x1b[1;31m', result.stdout)
        self.assertIn('__STAGE__flutter_warmup:FAILED', result.stdout)
        self.assertNotIn('__STAGE__flutter_warmup:DONE', result.stdout)

    def test_flutter_warmup_check_is_structural_and_never_executes_flutter(self):
        self.installed_flutter_stub()
        result = self.run_script('flutter_warmup.sh', '--check')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('__STAGE__flutter_warmup:PENDING', result.stdout)
        self.assertFalse((self.root / 'flutter-calls').exists(), 'check 不得执行 flutter')

    # ---- 2-2 SDK 合并落位 ----

    def sdk_archive(self):
        files = [
            ('android-sdk/platform-tools/adb', '#!/bin/sh\nexit 0\n', 0o755),
            ('android-sdk/cmdline-tools/latest/bin/sdkmanager', '#!/bin/sh\nexit 0\n', 0o755),
            ('android-sdk/cmdline-tools/latest/lib/tool.jar', 'jar', 0o644),
            ('android-sdk/build-tools/36.1.0/source.properties', 'Pkg.Revision=36.1.0', 0o644),
            ('android-sdk/build-tools/36.1.0/lib/d8.jar', 'jar', 0o644),
            ('android-sdk/platforms/android-36/android.jar', 'jar', 0o644),
            ('android-sdk/platforms/android-36/source.properties', 'Pkg.Revision=1', 0o644),
        ]
        files += [(f'android-sdk/build-tools/36.1.0/{name}', '#!/bin/sh\nexit 0\n', 0o755)
                  for name in ('aapt', 'aapt2', 'aidl', 'zipalign', 'd8', 'apksigner')]
        return self.archive(files)

    def test_sdk_merge_install_preserves_ndk_directory(self):
        sha = self.sdk_archive()
        self.config.write_text(f"SDK_URLS=('https://test/sdk')\nSDK_SHA256='{sha}'\n")
        self.install_fake_curl()
        ndk_dir = self.root / 'toolchains/ndk/28.2.13676358'
        (ndk_dir).mkdir(parents=True)
        (ndk_dir / 'clang').write_text('ndk\n')
        result = self.run_script('android_sdk.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertTrue((self.root / 'toolchains/android-sdk/build-tools/36.1.0/aapt2').exists())
        self.assertTrue((ndk_dir / 'clang').exists(), '重装 SDK 不得连带删掉 NDK')
        self.assertTrue(self.marker(self.root / 'toolchains/android-sdk/build-tools/36.1.0').exists())

    def test_sdk_rejects_unusable_tools_before_replacing_installed_version(self):
        sdk = self.root / 'toolchains/android-sdk'
        aapt2 = sdk / 'build-tools/36.1.0/aapt2'
        original = '#!/bin/sh\nexit 0\n'
        self.write_exec(aapt2, original)
        sha = self.archive([
            ('android-sdk/build-tools/36.1.0/aapt2', '#!/bin/sh\nexit 126\n', 0o755),
        ])
        self.install_fake_curl()
        result = self.run_script('android_sdk.sh', '--release', 'https://test/sdk', sha)
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertEqual(aapt2.read_text(), original)
        self.assertFalse(self.marker(sdk).exists())

    def test_catalog_sdk_uses_release_digest_and_keeps_default_manifest(self):
        sha = self.sdk_archive()
        original = "SDK_URLS=('https://test/default')\nSDK_SHA256='default-hash'\n"
        self.config.write_text(original)
        self.install_fake_curl()
        result = self.run_script('android_sdk.sh', '--release', 'https://test/selected', sha)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(self.marker(self.root / 'toolchains/android-sdk/build-tools/36.1.0').read_text().strip(), sha)
        self.assertEqual(self.config.read_text(), original)
        result = self.run_script('android_sdk.sh', '--check')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('__STAGE__android_sdk:DONE', result.stdout)
        self.assertNotIn('https://test/default', (self.root / 'curl-calls').read_text())

    def test_catalog_flutter_uses_shared_install_and_completion_marker(self):
        self.flutter_archive()
        sha = hashlib.sha256(Path(self.env['TEST_ARCHIVE']).read_bytes()).hexdigest()
        original = "FLUTTER_URLS=('https://test/default')\nFLUTTER_SHA256='default-hash'\n"
        self.config.write_text(original)
        result = self.run_script('flutter_sdk.sh', '--release', 'https://test/selected', sha, '3.47.8')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(self.marker(self.root / 'toolchains/flutter/current').read_text().strip(), sha)
        self.assertEqual(self.config.read_text(), original)
        result = self.run_script('flutter_sdk.sh', '--check')
        self.assertIn('__STAGE__flutter_sdk:DONE', result.stdout)

    def test_sdk_versions_coexist_and_refresh_gradle_config(self):
        sha = self.sdk_archive()
        self.install_fake_curl()
        sdk = self.root / 'toolchains/android-sdk'
        self.write_exec(sdk / 'build-tools/35.0.0/aapt2', '#!/bin/sh\nexit 0\n')
        (sdk / 'platforms/android-35').mkdir(parents=True)
        (sdk / 'platforms/android-35/android.jar').write_text('older API')
        result = self.run_script('android_sdk.sh', '--release', 'https://test/sdk', sha)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertTrue((sdk / 'build-tools/35.0.0/aapt2').exists())
        self.assertTrue((sdk / 'platforms/android-35/android.jar').exists())
        result = self.run_script('android_gradle.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        props = (self.root / '.gradle/gradle.properties').read_text()
        self.assertIn('build-tools/36.1.0/aapt2', props)
        self.assertIn('android.builder.sdkDownload=false', props)

    def test_sdk_interrupted_extract_leaves_no_marker_and_retries_clean(self):
        sha = self.sdk_archive()
        self.config.write_text(f"SDK_URLS=('https://test/sdk')\nSDK_SHA256='{sha}'\n")
        self.install_fake_curl()
        # 半截解压现场: 新脚本解压在暂存目录, 中断只留暂存残留, $ANDROID_HOME 不受污染
        residue = self.root / 'toolchains/.staging/android-sdk/android-sdk/build-tools/36.1.0'
        self.write_exec(residue / 'aapt2', '#!/bin/sh\nexit 0\n')
        sdk = self.root / 'toolchains/android-sdk'
        result = self.run_script('android_sdk.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('curl ', (self.root / 'curl-calls').read_text())
        self.assertFalse((self.root / 'toolchains/.staging/android-sdk').exists(), '暂存残留应被清理')
        self.assertTrue((sdk / 'platforms/android-36/android.jar').exists())
        self.assertTrue(self.marker(sdk / 'platforms/android-36').exists())

    def test_platform_part_installs_without_build_tools_and_keeps_other_platforms(self):
        sdk = self.root / 'toolchains/android-sdk'
        (sdk / 'platforms/android-35').mkdir(parents=True)
        (sdk / 'platforms/android-35/android.jar').write_text('old API')
        sha = self.archive([
            ('android-sdk/platforms/android-36.1/android.jar', 'new API', 0o644),
            ('android-sdk/platforms/android-36.1/source.properties', 'Pkg.Revision=1', 0o644),
        ])
        self.install_fake_curl()
        result = self.run_script('android_sdk.sh', '--release', 'https://test/platform', sha, 'platforms', '36.1')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertTrue(self.marker(sdk / 'platforms/android-36.1').exists())
        self.assertEqual((sdk / 'platforms/android-35/android.jar').read_text(), 'old API')
        removed = self.run_script('toolchain_manager.sh', '--delete', 'android-sdk/platforms/android-36.1')
        self.assertEqual(removed.returncode, 0, removed.stdout)

    def test_build_tools_part_installs_without_platform_and_rejects_wrong_version(self):
        files = [('android-sdk/build-tools/35.0.0/source.properties', 'Pkg.Revision=35.0.0', 0o644), ('android-sdk/build-tools/35.0.0/lib/d8.jar', 'jar', 0o644)]
        files += [(f'android-sdk/build-tools/35.0.0/{name}', '#!/bin/sh\nexit 0\n', 0o755)
                  for name in ('aapt', 'aapt2', 'aidl', 'zipalign', 'd8', 'apksigner')]
        sha = self.archive(files)
        self.install_fake_curl()
        wrong = self.run_script('android_sdk.sh', '--release', 'https://test/tools', sha, 'build-tools', '36.0.0')
        self.assertNotEqual(wrong.returncode, 0, wrong.stdout)
        sdk = self.root / 'toolchains/android-sdk'
        self.assertFalse((sdk / 'build-tools/35.0.0').exists())
        result = self.run_script('android_sdk.sh', '--release', 'https://test/tools', sha, 'build-tools', '35.0.0')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertTrue(self.marker(sdk / 'build-tools/35.0.0').exists())
        self.assertFalse((sdk / 'platforms').exists())

    def test_shared_tool_parts_can_explicitly_replace_and_restore_versions(self):
        for component, executable in [('platform-tools', 'adb'), ('cmdline-tools', 'latest/bin/sdkmanager')]:
            with self.subTest(component=component):
                archive_path = f'android-sdk/{component}/{executable}'
                libs = [('android-sdk/cmdline-tools/latest/lib/tool.jar', 'jar', 0o644)] if component == 'cmdline-tools' else []
                first_sha = self.archive(libs + [(archive_path, '#!/bin/sh\necho first\n', 0o755)])
                first_bytes = Path(self.env['TEST_ARCHIVE']).read_bytes()
                self.install_fake_curl()
                result = self.run_script('android_sdk.sh', '--release', 'https://test/first', first_sha, component, '35.0.0')
                self.assertEqual(result.returncode, 0, result.stdout)
                second_sha = self.archive(libs + [(archive_path, '#!/bin/sh\necho second\n', 0o755)])
                result = self.run_script('android_sdk.sh', '--release', 'https://test/second', second_sha, component, '36.0.0')
                self.assertEqual(result.returncode, 0, result.stdout)
                installed = self.root / 'toolchains' / archive_path
                self.assertIn('second', installed.read_text())
                Path(self.env['TEST_ARCHIVE']).write_bytes(first_bytes)
                result = self.run_script('android_sdk.sh', '--release', 'https://test/first', first_sha, component, '35.0.0')
                self.assertEqual(result.returncode, 0, result.stdout)
                self.assertIn('first', installed.read_text())

    def test_gradle_keeps_working_aapt2_when_another_build_tools_is_added(self):
        sdk = self.root / 'toolchains/android-sdk'
        for version in ('35.0.0', '36.0.0'):
            self.write_exec(sdk / f'build-tools/{version}/aapt2', '#!/bin/sh\nexit 0\n')
        props = self.root / '.gradle/gradle.properties'
        props.parent.mkdir()
        props.write_text(f'android.aapt2FromMavenOverride={sdk}/build-tools/35.0.0/aapt2\n')
        result = self.run_script('android_gradle.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('build-tools/35.0.0/aapt2', props.read_text())
        self.assertIn('android.builder.sdkDownload=false', props.read_text())

    def platform_manager_stub(self):
        manager = self.root / 'toolchains/android-sdk/cmdline-tools/latest/bin/sdkmanager'
        self.write_exec(manager, '''#!/bin/bash
printf '%s\n' "$@" >> "$HOME/sdkmanager-calls"
[ "${MANAGER_FAIL:-0}" = 0 ] || exit 9
api=${!#}
api=${api#platforms;android-}
mkdir -p "$ANDROID_HOME/platforms/android-$api"
echo jar > "$ANDROID_HOME/platforms/android-$api/android.jar"
echo Pkg.Revision=1 > "$ANDROID_HOME/platforms/android-$api/source.properties"
''')

    def test_sdk_repair_does_not_trust_receipt_for_non_runnable_aapt2(self):
        sha = self.sdk_archive()
        self.config.write_text(f"SDK_URLS=('https://test/sdk')\nSDK_SHA256='{sha}'\n")
        self.install_fake_curl()
        result = self.run_script('android_sdk.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        aapt = self.root / 'toolchains/android-sdk/build-tools/36.1.0/aapt2'
        self.write_exec(aapt, '#!/bin/sh\nexit 126\n')
        result = self.run_script('android_sdk.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('exit 0', aapt.read_text())
        result = self.run_script('android_components.sh', 'build-tools:36.1.0')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertNotIn('__MISSING__', result.stdout)

    def test_managed_build_keeps_exit_code_without_silent_download_or_retry(self):
        self.platform_manager_stub()
        self.write_exec(self.root / 'toolchains/android-sdk/build-tools/36.0.0/aapt2',
                        '#!/bin/sh\nexit 0\n')
        self.write_exec(self.tools / 'fake-build', """#!/bin/bash
echo build >> "$HOME/build-calls"
echo "Failed to find Platform SDK with path: platforms;android-34"
exit 8
""")
        result = self.run_script('android_build.sh', 'fake-build')
        self.assertEqual(result.returncode, 8, result.stdout)
        self.assertEqual((self.root / 'build-calls').read_text(), 'build\n')
        self.assertFalse((self.root / 'sdkmanager-calls').exists())
        self.assertIn('android.builder.sdkDownload=false',
                      (self.root / '.gradle/gradle.properties').read_text())

    def test_managed_build_does_not_launch_without_working_aapt2(self):
        self.write_exec(self.tools / 'fake-build', '#!/bin/sh\ntouch "$HOME/launched"\n')
        result = self.run_script('android_build.sh', 'fake-build')
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertFalse((self.root / 'launched').exists())

    def test_explicit_platform_installer_only_requests_one_platform(self):
        self.platform_manager_stub()
        result = self.run_script('android_platform.sh', '34')
        self.assertEqual(result.returncode, 0, result.stdout)
        calls = (self.root / 'sdkmanager-calls').read_text()
        self.assertIn('platforms;android-34', calls)
        self.assertNotIn('build-tools;', calls)
        self.assertTrue(self.marker(self.root / 'toolchains/android-sdk/platforms/android-34').exists())

    def test_failed_platform_download_has_no_success_marker(self):
        self.platform_manager_stub()
        self.env['MANAGER_FAIL'] = '1'
        result = self.run_script('android_platform.sh', '34')
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertFalse(self.marker(self.root / 'toolchains/android-sdk/platforms/android-34').exists())

    def test_component_probe_is_read_only_and_covers_native_tools(self):
        self.write_exec(self.root / 'jdk/bin/java', '#!/bin/sh\nexit 0\n')
        result = self.run_script('android_components.sh', '--baseline', '--device',
                                 'platforms:34', 'ndk:28.2.13676358', 'cmake:3.22.1', 'cmdline-tools:')
        self.assertEqual(result.returncode, 0, result.stdout)
        for missing in ('build-tools:36.1.0', 'platform-tools:', 'platforms:34',
                        'ndk:28.2.13676358', 'cmake:3.22.1', 'cmdline-tools:'):
            self.assertIn('__MISSING__' + missing, result.stdout)
        self.assertFalse((self.root / 'toolchains/android-sdk').exists())

    def test_component_probe_rejects_non_runnable_binary_and_wrong_cmake_version(self):
        sdk = self.root / 'toolchains/android-sdk'
        self.write_exec(sdk / 'platform-tools/adb', '#!/bin/sh\nexit 126\n')
        self.write_exec(sdk / 'cmake/3.22.1/bin/cmake', '#!/bin/sh\necho "cmake version 3.31.6"\n')
        self.write_exec(sdk / 'cmake/3.22.1/bin/ninja', '#!/bin/sh\nexit 0\n')
        (sdk / 'cmake/3.22.1/source.properties').write_text('Pkg.Revision=3.22.1')
        result = self.run_script('android_components.sh', 'platform-tools:', 'cmake:3.22.1')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('__MISSING__platform-tools:', result.stdout)
        self.assertIn('__MISSING__cmake:3.22.1', result.stdout)

    def test_ndk_requested_full_revision_is_verified_before_publish(self):
        sha = self.ndk_fixture()
        self.install_fake_curl()
        result = self.run_script('android_ndk.sh', '--release', 'https://test/ndk', sha, '28.2.99999999')
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn('产物实际为 28.2.13676358', result.stdout)
        self.assertFalse((self.root / 'toolchains/ndk/28.2.13676358').exists())
        result = self.run_script('android_ndk.sh', '--release', 'https://test/ndk', sha, '28.2.13676358')
        self.assertEqual(result.returncode, 0, result.stdout)
        # 相同摘要的快速路径也不得绕过完整版本校验。
        result = self.run_script('android_ndk.sh', '--release', 'https://test/ndk', sha, '28.2.99999999')
        self.assertNotEqual(result.returncode, 0, result.stdout)

    def test_sdk_install_rejects_archive_that_would_fail_the_shared_probe(self):
        files = [('android-sdk/build-tools/35.0.0/source.properties', 'Pkg.Revision=35.0.0', 0o644)]
        files += [(f'android-sdk/build-tools/35.0.0/{name}', '#!/bin/sh\nexit 0\n', 0o755)
                  for name in ('aapt', 'aapt2', 'aidl', 'zipalign', 'd8', 'apksigner')]
        sha = self.archive(files)  # 缺 d8.jar，不能先标记成功再让检测判失败。
        self.install_fake_curl()
        result = self.run_script('android_sdk.sh', '--release', 'https://test/tools', sha, 'build-tools', '35.0.0')
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertFalse((self.root / 'toolchains/android-sdk/build-tools/35.0.0').exists())

    def test_installed_list_and_gradle_probe_reject_non_runnable_binary(self):
        sdk = self.root / 'toolchains/android-sdk'
        aapt = sdk / 'build-tools/36.0.0/aapt2'
        self.write_exec(aapt, '#!/bin/sh\nexit 0\n')
        self.marker(aapt.parent).write_text('fixture')
        self.assertEqual(self.run_script('android_gradle.sh').returncode, 0)
        self.write_exec(aapt, '#!/bin/sh\nexit 126\n')
        result = self.run_script('android_gradle.sh', '--check')
        self.assertIn('__STAGE__android_gradle:PENDING', result.stdout)
        listed = self.run_script('toolchain_manager.sh', '--list')
        line = next(l for l in listed.stdout.splitlines() if 'build-tools/36.0.0|' in l)
        self.assertEqual(line.split('|')[3], '0')

    def test_flutter_switch_rejects_unrunnable_dart_and_protects_absolute_current(self):
        base = self.root / 'toolchains/flutter'
        for version in ('3.47.8', '3.48.0'):
            self.write_exec(base / version / 'bin/flutter', '#!/bin/sh\nexit 0\n')
            self.write_exec(base / version / 'bin/cache/dart-sdk/bin/dart', '#!/bin/sh\nexit 0\n')
            self.marker(base / version).write_text('fixture')
        self.write_exec(base / '3.48.0/bin/cache/dart-sdk/bin/dart', '#!/bin/sh\nexit 126\n')
        result = self.run_script('toolchain_manager.sh', '--select', '3.48.0')
        self.assertNotEqual(result.returncode, 0, result.stdout)
        (base / 'current').unlink()
        (base / 'current').symlink_to(base / '3.47.8')
        result = self.run_script('toolchain_manager.sh', '--delete', 'flutter/3.47.8')
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertTrue((base / '3.47.8').exists())
        listed = self.run_script('toolchain_manager.sh', '--list')
        line = next(l for l in listed.stdout.splitlines() if '__TOOL__flutter/3.47.8|' in l)
        self.assertEqual(line.split('|')[2:4], ['1', '1'])

    def test_nonstandard_tool_directory_is_rejected_without_migration(self):
        old = self.root / 'toolchains/android-sdk/ndk/28.2.13676358'
        old.mkdir(parents=True)
        (old / 'keep').write_text('preserved')
        result = subprocess.run(['bash', '-c', '. "$1"; link_android_tools', '_', str(SCRIPTS / 'lib.sh')],
                                env=self.env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertFalse((self.root / 'toolchains/android-sdk/ndk').is_symlink())
        self.assertEqual((old / 'keep').read_text(), 'preserved')
        self.assertFalse((self.root / 'toolchains/ndk/ndk').exists())

    def test_publish_recovers_backup_when_previous_run_was_interrupted(self):
        backup = self.root / 'target.replaced'
        backup.mkdir()
        (backup / 'old').write_text('keep')
        (self.root / 'stage').mkdir()
        result = subprocess.run(['bash', '-c',
            '. "$1"; mv() { if [ "$1" = "$HOME/stage" ]; then return 1; fi; command mv "$@"; }; publish_directory "$HOME/stage" "$HOME/target"',
            '_', str(SCRIPTS / 'lib.sh')], env=self.env, text=True,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertEqual((self.root / 'target/old').read_text(), 'keep')

    def test_check_propagates_probe_failure_and_overrides_stale_done(self):
        scripts = self.root / 'scripts'
        scripts.mkdir()
        shutil.copyfile(SCRIPTS / 'check.sh', scripts / 'check.sh')
        names = ('android_jdk', 'android_sdk', 'android_ndk', 'android_cmake', 'android_gradle',
                 'flutter_tools', 'flutter_sdk', 'flutter_warmup')
        for name in names:
            self.write_exec(scripts / (name + '.sh'), f'#!/bin/sh\necho __STAGE__{name}:DONE\nexit {7 if name == "android_ndk" else 0}\n')
        result = subprocess.run(['bash', str(scripts / 'check.sh')], text=True, stdout=subprocess.PIPE)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('__STAGE__android_ndk:FAILED', result.stdout)
        self.assertIn('__STAGE__flutter_warmup:DONE', result.stdout)

    # ---- 2-3 NDK ----

    def ndk_fixture(self):
        return self.archive([
            ('ndk/source.properties', 'Pkg.Revision=28.2.13676358\n', 0o644),
            ('ndk/toolchains/llvm/prebuilt/linux-arm64/bin/clang', '#!/bin/sh\n', 0o755),
            ('ndk/toolchains/llvm/prebuilt/linux-x86_64', 'linux-arm64', 0o777),
            ('ndk/shader-tools/linux-arm64/glslc', '#!/bin/sh\n', 0o755),
            ('ndk/shader-tools/linux-x86_64', 'linux-arm64', 0o777),
        ])

    def test_ndk_links_survive_and_second_run_skips(self):
        sha = self.ndk_fixture()
        self.config.write_text(f"NDK_URLS=('https://test/ndk')\nNDK_SHA256='{sha}'\n")
        self.install_fake_curl()
        ndk = self.root / 'toolchains/android-sdk/ndk/28.2.13676358'
        result = self.run_script('android_ndk.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertTrue((ndk / 'shader-tools/linux-x86_64/glslc').is_file())
        self.assertTrue((ndk / 'toolchains/llvm/prebuilt/linux-x86_64/bin/clang').is_file())
        self.assertTrue(self.marker(ndk).exists())
        self.assertIn('__VER__android_ndk:28.2.13676358', result.stdout)
        downloads = (self.root / 'curl-calls').read_text()
        result = self.run_script('android_ndk.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('已安装，跳过', result.stdout)
        self.assertEqual((self.root / 'curl-calls').read_text(), downloads, '第二次不应再下载')

    def test_cmake_installs_to_versioned_dir_and_skips_reinstall(self):
        # AGP 默认请求 cmake;3.22.1(flutter_pty 等原生插件); 包内顶层即 3.22.1/
        sha = self.archive([
            ('3.22.1/bin/cmake', '#!/bin/sh\necho "cmake version 3.22.1"\n', 0o755),
            ('3.22.1/bin/ninja', '#!/bin/sh\necho "1.12.1"\n', 0o755),
        ])
        self.config.write_text(
            f"CMAKE_URLS=('https://test/cmake')\nCMAKE_SHA256='{sha}'\n")
        self.install_fake_curl()

        result = self.run_script('android_cmake.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        cmake = self.root / 'toolchains/android-sdk/cmake/3.22.1'
        self.assertTrue((cmake / 'bin/cmake').exists())
        self.assertTrue((cmake / 'bin/ninja').exists())
        self.assertTrue(self.marker(cmake).exists())
        self.assertIn('__VER__android_cmake:3.22.1', result.stdout)
        downloads = (self.root / 'curl-calls').read_text()
        (cmake / 'source.properties').unlink()
        result = self.run_script('android_cmake.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('已安装，跳过', result.stdout)
        self.assertEqual((cmake / 'source.properties').read_text(), 'Pkg.Revision=3.22.1\n')
        self.assertEqual((self.root / 'curl-calls').read_text(), downloads,
                         '第二次不应再下载')

    def test_cmake_accepts_android_patch_dirty_suffix(self):
        sha = self.archive([
            ('3.22.1/bin/cmake', '#!/bin/sh\necho "cmake version 3.22.1-dirty"\n', 0o755),
            ('3.22.1/bin/ninja', '#!/bin/sh\necho "1.12.1"\n', 0o755),
        ])
        self.install_fake_curl()
        result = self.run_script('android_cmake.sh', '--release', 'https://test/cmake', sha, '3.22.1')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('cmake version 3.22.1-dirty', result.stdout)
        self.assertIn('1.12.1', result.stdout)
        directory = self.root / 'toolchains/android-sdk/cmake/3.22.1'
        self.assertEqual((directory / 'source.properties').read_text(), 'Pkg.Revision=3.22.1\n')
        self.config.write_text(f"CMAKE_SHA256='{sha}'\n")
        result = self.run_script('android_cmake.sh', '--check')
        self.assertIn('__STAGE__android_cmake:DONE', result.stdout)

    def test_cmake_reports_actual_version_or_execution_error(self):
        self.install_fake_curl()
        for cmake, ninja, error in [
            ('echo "cmake version 3.22.0"', 'exit 0', '实际 3.22.0'),
            ('echo "cmake version 3.22.1-rc1"', 'exit 0', '实际 3.22.1-rc1'),
            ('echo "CMake loader error" >&2; exit 126', 'exit 0', 'CMake loader error'),
            ('echo "cmake version 3.22.1-dirty"', 'echo "Ninja loader error" >&2; exit 127', 'Ninja loader error'),
        ]:
            with self.subTest(error=error):
                sha = self.archive([
                    ('3.22.1/bin/cmake', f'#!/bin/sh\n{cmake}\n', 0o755),
                    ('3.22.1/bin/ninja', f'#!/bin/sh\n{ninja}\n', 0o755),
                ])
                result = self.run_script('android_cmake.sh', '--release', 'https://test/cmake', sha, '3.22.1')
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertIn(error, result.stdout)
                self.assertFalse(self.marker(self.root / 'toolchains/android-sdk/cmake/3.22.1').exists())

    def test_cmake_catalog_versions_coexist_with_real_revision_metadata(self):
        self.install_fake_curl()
        for version in ('3.22.1', '3.31.6'):
            sha = self.archive([
                (f'{version}/bin/cmake', f'#!/bin/sh\necho "cmake version {version}"\n', 0o755),
                (f'{version}/bin/ninja', '#!/bin/sh\necho "1.12.1"\n', 0o755),
            ])
            result = self.run_script('android_cmake.sh', '--release', 'https://test/cmake', sha, version)
            self.assertEqual(result.returncode, 0, result.stdout)
            directory = self.root / f'toolchains/android-sdk/cmake/{version}'
            self.assertEqual((directory / 'source.properties').read_text(), f'Pkg.Revision={version}\n')
        self.assertTrue((self.root / 'toolchains/android-sdk/cmake/3.22.1/bin/cmake').exists())
        self.assertTrue((self.root / 'toolchains/android-sdk/cmake/3.31.6/bin/cmake').exists())

    def test_ndk_tar_failure_stops_installation(self):
        sha = self.ndk_fixture()
        self.config.write_text(f"NDK_URLS=('https://test/ndk')\nNDK_SHA256='{sha}'\n")
        self.install_fake_curl()
        self.write_exec(self.tools / 'tar', '#!/bin/sh\necho "tar: No space left on device" >&2\nexit 2\n')
        ndk = self.root / 'toolchains/android-sdk/ndk/28.2.13676358'
        result = self.run_script('android_ndk.sh')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('No space left on device', result.stdout)
        self.assertFalse(ndk.exists())
        self.assertIn('__STAGE__android_ndk:FAILED', result.stdout)
        self.assertNotIn('__STAGE__android_ndk:DONE', result.stdout)

    def test_toolchain_manager_lists_switches_and_deletes_offline(self):
        self.flutter_archive()
        sha = hashlib.sha256(Path(self.env['TEST_ARCHIVE']).read_bytes()).hexdigest()
        for version in ('3.47.8', '3.48.0'):
            result = self.run_script('flutter_sdk.sh', '--release', 'https://test/sdk', sha, version)
            self.assertEqual(result.returncode, 0, result.stdout)
        calls = (self.root / 'curl-calls').read_text()
        result = self.run_script('toolchain_manager.sh', '--list')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('__TOOL__flutter/3.48.0|', result.stdout)
        self.assertNotIn('__TOOL__flutter/current|', result.stdout)
        active = self.run_script('toolchain_manager.sh', '--delete', 'flutter/3.48.0')
        self.assertNotEqual(active.returncode, 0, active.stdout)
        switched = self.run_script('toolchain_manager.sh', '--select', '3.47.8')
        self.assertEqual(switched.returncode, 0, switched.stdout)
        removed = self.run_script('toolchain_manager.sh', '--delete', 'flutter/3.48.0')
        self.assertEqual(removed.returncode, 0, removed.stdout)
        self.assertFalse((self.root / 'toolchains/flutter/3.48.0').exists())
        self.assertEqual((self.root / 'toolchains/flutter/current').readlink(), Path('3.47.8'))
        self.assertEqual((self.root / 'curl-calls').read_text(), calls)
        missing = self.run_script('toolchain_manager.sh', '--select', '3.48.0')
        self.assertNotEqual(missing.returncode, 0)
        escaped = self.run_script('toolchain_manager.sh', '--delete', 'flutter/../../3.47.8')
        self.assertNotEqual(escaped.returncode, 0)

    def test_sdk_receipt_reuses_bundle_and_reinstalls_deleted_component(self):
        sha = self.sdk_archive()
        self.config.write_text(f"SDK_URLS=('https://test/sdk')\nSDK_SHA256='{sha}'\n")
        self.install_fake_curl()
        result = self.run_script('android_sdk.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        calls = (self.root / 'curl-calls').read_text()
        second = self.run_script('android_sdk.sh')
        self.assertEqual(second.returncode, 0, second.stdout)
        self.assertEqual((self.root / 'curl-calls').read_text(), calls)
        deleted = self.run_script('toolchain_manager.sh', '--delete', 'android-sdk/platforms/android-36')
        self.assertEqual(deleted.returncode, 0, deleted.stdout)
        check = self.run_script('android_sdk.sh', '--check')
        self.assertIn('__STAGE__android_sdk:PENDING', check.stdout)
        retried = self.run_script('android_sdk.sh')
        self.assertEqual(retried.returncode, 0, retried.stdout)
        self.assertTrue((self.root / 'toolchains/android-sdk/platforms/android-36/android.jar').exists())
        self.assertNotEqual((self.root / 'curl-calls').read_text(), calls)

    def test_sdk_bundle_cannot_replace_managed_ndk_and_cmake_links(self):
        files = [
            ('android-sdk/build-tools/36.1.0/source.properties', 'Pkg.Revision=36.1.0', 0o644),
            ('android-sdk/build-tools/36.1.0/lib/d8.jar', 'jar', 0o644),
            ('android-sdk/platforms/android-36/android.jar', 'jar', 0o644),
            ('android-sdk/platforms/android-36/source.properties', 'Pkg.Revision=1', 0o644),
            ('android-sdk/ndk/99/tool', 'unwanted', 0o644),
            ('android-sdk/cmake/99/tool', 'unwanted', 0o644),
            ('android-sdk/cmdline-tools/bin/sdkmanager', '#!/bin/sh\nexit 0\n', 0o755),
            ('android-sdk/cmdline-tools/lib/tool.jar', 'jar', 0o644),
        ]
        files += [(f'android-sdk/build-tools/36.1.0/{name}', '#!/bin/sh\nexit 0\n', 0o755)
                  for name in ('aapt', 'aapt2', 'aidl', 'zipalign', 'd8', 'apksigner')]
        sha = self.archive(files)
        self.install_fake_curl()
        result = self.run_script('android_sdk.sh', '--release', 'https://test/sdk', sha)
        self.assertEqual(result.returncode, 0, result.stdout)
        sdk = self.root / 'toolchains/android-sdk'
        self.assertEqual((sdk / 'ndk').readlink(), Path('../ndk'))
        self.assertEqual((sdk / 'cmake').readlink(), Path('../cmake'))
        self.assertFalse((sdk / 'ndk/99').exists())
        self.assertFalse((sdk / 'cmake/99').exists())
        self.assertTrue((sdk / 'cmdline-tools/latest/bin/sdkmanager').exists())

    def test_valid_same_version_is_never_implicitly_overwritten(self):
        sha = self.archive([
            ('3.22.1/bin/cmake', '#!/bin/sh\necho "cmake version 3.22.1"\n', 0o755),
            ('3.22.1/bin/ninja', '#!/bin/sh\necho 1.12.1\n', 0o755),
        ])
        self.install_fake_curl()
        result = self.run_script('android_cmake.sh', '--release', 'https://test/cmake', sha, '3.22.1')
        self.assertEqual(result.returncode, 0, result.stdout)
        calls = (self.root / 'curl-calls').read_text()
        # A new digest for the same version must not silently replace it.
        second = self.run_script('android_cmake.sh', '--release', 'https://test/broken', '0' * 64, '3.22.1')
        self.assertEqual(second.returncode, 0, second.stdout)
        self.assertEqual((self.root / 'curl-calls').read_text(), calls)
        self.assertEqual(self.marker(self.root / 'toolchains/cmake/3.22.1').read_text().strip(), sha)

    def test_failed_ndk_and_cmake_archives_preserve_previous_versions(self):
        self.install_fake_curl()
        for stage, directory, version in [('android_ndk', 'ndk', '28.2.13676358'),
                                           ('android_cmake', 'cmake', '3.22.1')]:
            with self.subTest(stage=stage):
                if directory == 'ndk':
                    sha = self.ndk_fixture()
                    args = []
                else:
                    sha = self.archive([
                        ('3.22.1/bin/cmake', '#!/bin/sh\necho "cmake version 3.22.1"\n', 0o755),
                        ('3.22.1/bin/ninja', '#!/bin/sh\necho 1.12.1\n', 0o755),
                    ])
                    args = [version]
                installed = self.run_script(stage + '.sh', '--release', 'https://test/sdk', sha, *args)
                self.assertEqual(installed.returncode, 0, installed.stdout)
                target = self.root / f'toolchains/{directory}/{version}'
                marker = self.marker(target).read_text()
                # A broken different version must leave the installed version untouched.
                broken = self.archive([('bad/README', 'incomplete', 0o644)])
                failed = self.run_script(stage + '.sh', '--release', 'https://test/sdk', broken,
                                         *(['3.31.6'] if directory == 'cmake' else []))
                self.assertNotEqual(failed.returncode, 0, failed.stdout)
                self.assertEqual(self.marker(target).read_text(), marker)

    def test_delete_build_tools_reconfigures_aapt2_without_enabling_download(self):
        sdk = self.root / 'toolchains/android-sdk'
        for version in ('35.0.0', '36.0.0'):
            self.write_exec(sdk / f'build-tools/{version}/aapt2', '#!/bin/sh\nexit 0\n')
        initial = self.run_script('android_gradle.sh')
        self.assertEqual(initial.returncode, 0, initial.stdout)
        result = self.run_script('toolchain_manager.sh', '--delete', 'android-sdk/build-tools/36.0.0')
        self.assertEqual(result.returncode, 0, result.stdout)
        props = self.root / '.gradle/gradle.properties'
        self.assertIn('build-tools/35.0.0/aapt2', props.read_text())
        self.assertIn('android.builder.sdkDownload=false', props.read_text())
        result = self.run_script('toolchain_manager.sh', '--delete', 'android-sdk/build-tools/35.0.0')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertNotIn('android.aapt2FromMavenOverride=', props.read_text())
        self.assertIn('android.builder.sdkDownload=false', props.read_text())

    def test_flutter_marker_without_launcher_does_not_skip_repair(self):
        self.flutter_archive()
        self.marker(self.root / 'toolchains/flutter/current').write_text('a' * 64)
        check = self.run_script('flutter_sdk.sh', '--check')
        self.assertIn('__STAGE__flutter_sdk:PENDING', check.stdout)
        repaired = self.run_script('flutter_sdk.sh')
        self.assertEqual(repaired.returncode, 0, repaired.stdout)
        check = self.run_script('flutter_sdk.sh', '--check')
        self.assertIn('__STAGE__flutter_sdk:DONE', check.stdout)

    # ---- 2-4 Gradle 配置 ----

    def test_gradle_config_preserves_existing_settings_and_is_idempotent(self):
        self.sdk_archive()
        sdk = self.root / 'toolchains/android-sdk'
        self.write_exec(sdk / 'build-tools/36.1.0/aapt2', '#!/bin/sh\nexit 0\n')
        gradle = self.root / '.gradle'
        gradle.mkdir()
        (gradle / 'gradle.properties').write_text('org.gradle.jvmargs=-Xmx1g\ncustom.setting=keep\n')
        for _ in range(2):
            result = self.run_script('android_gradle.sh')
            self.assertEqual(result.returncode, 0, result.stdout)
        props = (gradle / 'gradle.properties').read_text()
        self.assertIn('org.gradle.jvmargs=-Xmx1g', props, '用户已有的 jvmargs 不覆盖')
        self.assertIn('custom.setting=keep\n', props)
        self.assertEqual(props.count('android.aapt2FromMavenOverride='), 1)
        self.assertIn('build-tools/36.1.0/aapt2', props)

    def test_gradle_rejects_broken_aapt2_and_keeps_working_version(self):
        sdk = self.root / 'toolchains/android-sdk'
        self.write_exec(sdk / 'build-tools/35.0.0/aapt2', '#!/bin/sh\nexit 0\n')
        self.write_exec(sdk / 'build-tools/36.0.0/aapt2', '#!/bin/sh\nexit 126\n')
        result = self.run_script('android_gradle.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        props = self.root / '.gradle/gradle.properties'
        self.assertIn('build-tools/35.0.0/aapt2', props.read_text())
        (sdk / 'build-tools/35.0.0/aapt2').unlink()
        original = props.read_text()
        result = self.run_script('android_gradle.sh')
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertEqual(props.read_text(), original)

    @unittest.skipUnless(os.environ.get('FLIT_TEST_GRADLE'), 'requires local Gradle')
    def test_gradle_guard_rejects_unsafe_overrides_before_loading_project(self):
        self.write_exec(self.root / 'toolchains/android-sdk/build-tools/36.1.0/aapt2',
                        '#!/bin/sh\nexit 0\n')
        result = self.run_script('android_gradle.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        project = self.root / 'project'
        project.mkdir()
        (project / 'settings.gradle').write_text("rootProject.name = 'guard-test'\n")
        (project / 'gradle.properties').write_text(
            'android.builder.sdkDownload=true\nandroid.aapt2FromMavenOverride=/wrong/project\n')
        (project / 'build.gradle').write_text("""
assert providers.gradleProperty('android.builder.sdkDownload').get() == 'false'
assert providers.gradleProperty('android.aapt2FromMavenOverride').get().endsWith('/36.1.0/aapt2')
tasks.register('verifyGuard')
""")
        env = dict(self.env)
        # 用宿主 Java 运行 Gradle，待测脚本的 Android JAVA_HOME 不适用于 macOS。
        env.pop('JAVA_HOME', None)
        result = subprocess.run([
            os.environ['FLIT_TEST_GRADLE'], '--offline', '--no-daemon',
            '-p', str(project), 'verifyGuard',
        ], env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=90)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('BUILD SUCCESSFUL', result.stdout)
        # -P 优先级高于用户级配置，必须在加载项目之前拒绝，不能假装已覆盖。
        (project / 'settings.gradle').write_text("throw new GradleException('PROJECT_LOADED')")
        for override in ('android.builder.sdkDownload=true',
                         'android.aapt2FromMavenOverride=/wrong/cli'):
            result = subprocess.run([
                os.environ['FLIT_TEST_GRADLE'], '--offline', '--no-daemon',
                '-p', str(project), '-P' + override, 'verifyGuard',
            ], env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=90)
            self.assertNotEqual(result.returncode, 0, result.stdout)
            self.assertIn('unsafe Android toolchain override', result.stdout)
            self.assertNotIn('PROJECT_LOADED', result.stdout)


    def test_gradle_requires_sdk(self):
        result = self.run_script('android_gradle.sh')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('请先完成 2-2', result.stdout)
        self.assertIn('__STAGE__android_gradle:FAILED', result.stdout)

    # ---- 3-2 Git 与 gh ----

    def write_fake_apt(self, installed=()):
        """apt-get 桩: install 时把包名建成可执行(git 版本行/gh 版本行)。"""
        self.write_exec(self.tools / 'apt-get', f'''#!{sys.executable}
import os, pathlib, sys
args = sys.argv[1:]
with open(os.environ['APT_LOG'], 'a') as log:
    log.write('apt-get ' + ' '.join(args) + '\\n')
if 'update' in args:
    sys.exit(0)
if 'install' in args:
    for pkg in [a for a in args if not a.startswith('-')]:
        tool = pathlib.Path(os.environ['TOOL_BIN']) / pkg
        tool.write_text('#!/bin/sh\\necho %s version 9.9\\necho 9.9\\n' % pkg)
        tool.chmod(0o755)
    sys.exit(0)
sys.exit(0)
''')
        self.env['APT_LOG'] = str(self.root / 'apt-calls')
        self.env['TOOL_BIN'] = str(self.tools)
        # CI 的 /usr/bin 也可能有 gh；保留基础命令，但排除被测试的宿主工具。
        host_tools = self.root / 'host-bin'
        host_tools.mkdir()
        for directory in (Path('/usr/bin'), Path('/bin')):
            for tool in directory.iterdir():
                target = host_tools / tool.name
                if tool.name not in {'git', 'gh', 'clang'} and not target.exists() and tool.is_file():
                    target.symlink_to(tool)
        self.env['PATH'] = f"{self.tools}:{host_tools}"
        (self.root / 'apt-calls').touch()
        for name in installed:
            self.write_exec(self.tools / name, f'#!/bin/sh\necho {name} version 9.9\necho 9.9\n')

    def test_flutter_tools_installs_only_the_missing_tool(self):
        self.write_fake_apt(installed=['git'])  # git 已在, 只缺 gh
        result = self.run_script('flutter_tools.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        calls = (self.root / 'apt-calls').read_text()
        self.assertIn('gh', calls.split('install', 1)[1])
        self.assertNotIn(' git', calls.split('install', 1)[1].splitlines()[0])
        self.assertIn('__STAGE__flutter_tools:DONE', result.stdout)

    def test_flutter_tools_skips_when_both_present(self):
        self.write_fake_apt(installed=['git', 'gh'])
        result = self.run_script('flutter_tools.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('已安装，跳过', result.stdout)
        self.assertNotIn('install', (self.root / 'apt-calls').read_text())

    # ---- check.sh 循环 ----

    def test_package_configuration_failure_is_visible_and_stops_installation(self):
        self.write_exec(self.tools / 'dpkg', '#!/bin/sh\necho configuration-failed >&2\nexit 1\n')
        result = subprocess.run(['bash', '-c', '. "$1"; apt_repair', 'test',
                                 str(SCRIPTS / 'lib.sh')], env=self.env,
                                text=True, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('configuration-failed', result.stderr)
        self.assertIn('软件包配置失败', result.stdout)

    def test_check_loops_every_subtask_without_side_effects(self):
        self.flutter_archive()
        self.sdk_archive()
        self.write_fake_apt(installed=['git', 'gh'])
        result = self.run_script('check.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        for sid in ('android_jdk', 'android_sdk', 'android_ndk', 'android_gradle',
                    'flutter_sdk', 'flutter_tools', 'flutter_warmup'):
            self.assertIn(f'__STAGE__{sid}:', result.stdout)
        # check 零副作用: 没有下载、没有安装动作、SDK 目录不被创建
        self.assertEqual((self.root / 'curl-calls').read_text(), '')
        self.assertEqual((self.root / 'apt-calls').read_text(), '')
        self.assertFalse((self.root / 'toolchains/android-sdk/build-tools').exists())


if __name__ == '__main__':
    unittest.main()
