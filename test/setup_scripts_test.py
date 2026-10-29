"""Run setup sub-task scripts with local archives and fake downloads, never real APT.

每个用例对应一类中断/重试场景: 断点续传、半截解压重装、合并落位不误删 NDK、
旧安装认领、清单升级重装、只补缺的工具、check 零副作用。
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
                    'TMPDIR': str(self.tmp), 'ANDROID_HOME': str(self.root / 'android-sdk'),
                    'JAVA_HOME': str(self.root / 'jdk'), 'GRADLE_USER_HOME': str(self.root / '.gradle'),
                    'PATH': str(self.tools) + ':' + os.environ['PATH']}
        if shutil.which('gsed'):
            (self.tools / 'sed').symlink_to(shutil.which('gsed'))
        self.write_exec(self.tools / 'git', '#!/bin/sh\necho git version 2.47\necho 2.47\n')
        self.write_exec(self.tools / 'dpkg', '#!/bin/sh\nexit 0\n')
        self.write_exec(self.tools / 'dpkg-query', '#!/bin/sh\nexit 1\n')
        self.curl_calls = []

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
echo 'Flutter 3.47.7 • channel stable'
echo 'engine diagnostic detail' >&2
exit %d
''' % exit_code, 0o755)])
        self.config.write_text(f"FLUTTER_URLS=('https://test/missing' 'https://test/sdk')\nFLUTTER_SHA256='{sha}'\n")
        self.install_fake_curl('missing')

    def test_flutter_sdk_falls_back_sources_and_writes_marker(self):
        self.flutter_archive()
        result = self.run_script('flutter_sdk.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        for text in ('https://test/missing', 'curl: HTTP 404',
                     '__STAGE__flutter_sdk:RUNNING', '__STAGE__flutter_sdk:DONE'):
            self.assertIn(text, result.stdout)
        self.assertEqual(self.marker(self.prefix / 'opt/flutter').read_text().strip(),
                         hashlib.sha256(Path(self.env['TEST_ARCHIVE']).read_bytes()).hexdigest())
        # 安装包在标记落盘后删除
        self.assertFalse((self.tmp / 'flutter-sdk.tar.xz').exists())

    def test_flutter_sdk_interrupted_extract_reinstalls_from_cache_without_download(self):
        self.flutter_archive()
        sha = hashlib.sha256(Path(self.env['TEST_ARCHIVE']).read_bytes()).hexdigest()
        # 半截解压现场: 目录在(bin/ 早于 packages/ 出现在归档序), 无标记; 缓存包在
        flutter = self.prefix / 'opt/flutter'
        (flutter / 'bin').mkdir(parents=True)
        self.write_exec(flutter / 'bin/flutter', '#!/bin/sh\nexit 0\n')
        shutil.copyfile(self.env['TEST_ARCHIVE'], self.tmp / 'flutter-sdk.tar.xz')
        result = self.run_script('flutter_sdk.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertNotIn('curl ', (self.root / 'curl-calls').read_text(), '有缓存包时不应重新下载')
        self.assertTrue(self.marker(flutter).exists())
        self.assertIn('__STAGE__flutter_sdk:DONE', result.stdout)

    def test_flutter_sdk_skips_when_marker_matches(self):
        self.flutter_archive()
        flutter = self.prefix / 'opt/flutter'
        (flutter / 'bin').mkdir(parents=True)
        self.write_exec(flutter / 'bin/flutter', '#!/bin/sh\nexit 0\n')
        self.marker(flutter).write_text(
            hashlib.sha256(Path(self.env['TEST_ARCHIVE']).read_bytes()).hexdigest() + '\n')
        result = self.run_script('flutter_sdk.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('跳过下载与解压', result.stdout)
        self.assertNotIn('curl ', (self.root / 'curl-calls').read_text())

    def test_flutter_sdk_reinstalls_when_manifest_sha_changes(self):
        self.flutter_archive()
        flutter = self.prefix / 'opt/flutter'
        (flutter / 'bin').mkdir(parents=True)
        self.write_exec(flutter / 'bin/flutter', '#!/bin/sh\nexit 0\n')
        (flutter / 'packages/flutter_tools').mkdir(parents=True)
        self.marker(flutter).write_text('0' * 64 + '\n')  # 旧清单的标记
        result = self.run_script('flutter_sdk.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        # 结构完整也不能认领: 标记 sha 不一致 = 清单升级, 必须重装并写入新标记
        self.assertIn('curl ', (self.root / 'curl-calls').read_text())
        self.assertEqual(self.marker(flutter).read_text().strip(),
                         hashlib.sha256(Path(self.env['TEST_ARCHIVE']).read_bytes()).hexdigest())

    def test_download_resumes_from_partial_part(self):
        """断点续传: .part 前半截 + stub 从既有偏移补齐 → 完整文件过校验, 不重下整包"""
        self.flutter_archive()
        sha = hashlib.sha256(Path(self.env['TEST_ARCHIVE']).read_bytes()).hexdigest()
        part = self.tmp / 'flutter-sdk.tar.xz.part'
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
        order = ['android_jdk', 'android_sdk', 'android_ndk', 'android_gradle',
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
        self.assertFalse((self.prefix / 'opt/flutter').exists())
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
        self.write_exec(self.prefix / 'opt/flutter/bin/flutter', '''#!/bin/sh
echo call >> "$HOME/flutter-calls"
echo 'Downloading Dart SDK...' >&2
echo 'Flutter 3.47.7 • channel stable'
echo 'engine diagnostic detail' >&2
exit %d
''' % exit_code)

    def test_flutter_warmup_runs_flutter_once_and_reports_version(self):
        self.installed_flutter_stub()
        result = self.run_script('flutter_warmup.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('engine diagnostic detail', result.stdout)
        self.assertIn('__VER__flutter_warmup:3.47.7', result.stdout)
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
        return self.archive([
            ('android-sdk/build-tools/36.1.0/aapt2', '#!/bin/sh\nexit 0\n', 0o755),
            ('android-sdk/platforms/android-36/android.jar', 'jar\n', 0o644),
        ])

    def test_sdk_merge_install_preserves_ndk_directory(self):
        sha = self.sdk_archive()
        self.config.write_text(f"SDK_URLS=('https://test/sdk')\nSDK_SHA256='{sha}'\n")
        self.install_fake_curl()
        ndk_dir = self.root / 'android-sdk/ndk/28.2.13676358'
        (ndk_dir).mkdir(parents=True)
        (ndk_dir / 'clang').write_text('ndk\n')
        result = self.run_script('android_sdk.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertTrue((self.root / 'android-sdk/build-tools/36.1.0/aapt2').exists())
        self.assertTrue((ndk_dir / 'clang').exists(), '重装 SDK 不得连带删掉 NDK')
        self.assertTrue(self.marker(self.root / 'android-sdk').exists())

    def test_catalog_sdk_uses_release_digest_and_keeps_default_manifest(self):
        sha = self.sdk_archive()
        original = "SDK_URLS=('https://test/default')\nSDK_SHA256='default-hash'\n"
        self.config.write_text(original)
        self.install_fake_curl()
        result = self.run_script('android_sdk.sh', '--release', 'https://test/selected', sha)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(self.marker(self.root / 'android-sdk').read_text().strip(), sha)
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
        result = self.run_script('flutter_sdk.sh', '--release', 'https://test/selected', sha)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(self.marker(self.prefix / 'opt/flutter').read_text().strip(), sha)
        self.assertEqual(self.config.read_text(), original)
        result = self.run_script('flutter_sdk.sh', '--check')
        self.assertIn('__STAGE__flutter_sdk:DONE', result.stdout)

    def test_sdk_old_install_is_adopted_without_download(self):
        self.sdk_archive()
        self.install_fake_curl()
        sdk = self.root / 'android-sdk'
        self.write_exec(sdk / 'build-tools/36.1.0/aapt2', '#!/bin/sh\nexit 0\n')
        result = self.run_script('android_sdk.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('旧安装补记完整性标记', result.stdout)
        self.assertTrue(self.marker(sdk).exists())
        self.assertEqual((self.root / 'curl-calls').read_text(), '')

    def test_sdk_interrupted_extract_leaves_no_marker_and_retries_clean(self):
        sha = self.sdk_archive()
        self.config.write_text(f"SDK_URLS=('https://test/sdk')\nSDK_SHA256='{sha}'\n")
        self.install_fake_curl()
        # 半截解压现场: 新脚本解压在暂存目录, 中断只留暂存残留, $ANDROID_HOME 不受污染
        residue = self.tmp / 'android-sdk.extract/android-sdk/build-tools/36.1.0'
        self.write_exec(residue / 'aapt2', '#!/bin/sh\nexit 0\n')
        sdk = self.root / 'android-sdk'
        result = self.run_script('android_sdk.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('curl ', (self.root / 'curl-calls').read_text())
        self.assertFalse((self.tmp / 'android-sdk.extract').exists(), '暂存残留应被清理')
        self.assertTrue((sdk / 'platforms/android-36/android.jar').exists())
        self.assertTrue(self.marker(sdk).exists())

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
        ndk = self.root / 'android-sdk/ndk/28.2.13676358'
        result = self.run_script('android_ndk.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertTrue((ndk / 'shader-tools/linux-x86_64/glslc').is_file())
        self.assertTrue((ndk / 'toolchains/llvm/prebuilt/linux-x86_64/bin/clang').is_file())
        self.assertTrue(self.marker(ndk).exists())
        self.assertIn('__VER__android_ndk:r28.2', result.stdout)
        downloads = (self.root / 'curl-calls').read_text()
        result = self.run_script('android_ndk.sh')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('已安装，跳过', result.stdout)
        self.assertEqual((self.root / 'curl-calls').read_text(), downloads, '第二次不应再下载')

    def test_ndk_tar_failure_stops_installation(self):
        sha = self.ndk_fixture()
        self.config.write_text(f"NDK_URLS=('https://test/ndk')\nNDK_SHA256='{sha}'\n")
        self.install_fake_curl()
        self.write_exec(self.tools / 'tar', '#!/bin/sh\necho "tar: No space left on device" >&2\nexit 2\n')
        ndk = self.root / 'android-sdk/ndk/28.2.13676358'
        result = self.run_script('android_ndk.sh')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('No space left on device', result.stdout)
        self.assertFalse(ndk.exists())
        self.assertIn('__STAGE__android_ndk:FAILED', result.stdout)
        self.assertNotIn('__STAGE__android_ndk:DONE', result.stdout)

    # ---- 2-4 Gradle 配置 ----

    def test_gradle_config_preserves_existing_settings_and_is_idempotent(self):
        self.sdk_archive()
        sdk = self.root / 'android-sdk'
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
        self.assertFalse((self.root / 'android-sdk/build-tools').exists())


if __name__ == '__main__':
    unittest.main()
