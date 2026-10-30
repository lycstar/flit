"""Exercise the JDK sub-task with fake package tools, without touching APT."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class JdkSetupTests(unittest.TestCase):
    def run_setup(self, *args, java_preinstalled=None, **flags):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            scripts = root / "scripts"
            scripts.mkdir()
            source = Path(__file__).resolve().parents[1] / "assets/scripts"
            for name in ("android_jdk.sh", "lib.sh", "component_checks.sh"):
                shutil.copyfile(source / name, scripts / name)
            tools = root / "bin"
            tools.mkdir()
            command = tools / "fake-tool"
            command.write_text("""#!/usr/bin/env python3
import os, pathlib, sys
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ['TEST_LOG'], 'a') as log:
    log.write(name + ' ' + ' '.join(args) + '\\n')
if 'update' in args and os.getenv('UPDATE_FAIL') == '1':
    print('E: Failed to fetch repository: HTTP 404')
    sys.exit(100)
if 'install' in args:
    if os.getenv('INSTALL_FAIL') == '1':
        print('E: openjdk-17 depends on missing-library but it is not installable')
        sys.exit(100)
    java = pathlib.Path(os.environ['JAVA_HOME']) / 'bin/java'
    java.parent.mkdir(parents=True, exist_ok=True)
    java.write_text('#!/bin/sh\\necho java-runtime-check\\nexit ' +
                    ('1' if os.getenv('JAVA_FAIL') == '1' else '0') + '\\n')
    java.chmod(0o755)
""")
            command.chmod(0o755)
            for name in ("apt-get", "apt-cache", "dpkg", "dpkg-query"):
                (tools / name).symlink_to(command)
            if java_preinstalled is not None:
                java = root / 'jdk/bin/java'
                java.parent.mkdir(parents=True)
                java.write_text(
                    '#!/bin/sh\necho \'openjdk version "17.0.20"\'\nexit %d\n'
                    % (0 if java_preinstalled else 3))
                java.chmod(0o755)
            log = root / "calls"
            log.touch()
            result = subprocess.run(
                ["bash", str(scripts / "android_jdk.sh"), *args], text=True,
                capture_output=True,
                env={**os.environ, "HOME": str(root), "PREFIX": str(root / 'usr'),
                     "JAVA_HOME": str(root / 'jdk'), "TMPDIR": str(root / 'tmp'),
                     "TEST_LOG": str(log),
                     "FLIT_APT_SOURCE": "https://example.invalid/apt ./",
                     "PATH": str(tools) + os.pathsep + os.environ['PATH'], **flags},
            )
            return result, log.read_text()

    def test_installs_jdk_without_touching_unrelated_packages(self):
        result, calls = self.run_setup()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn('dpkg --remove', calls)
        self.assertNotIn('apt-get check', calls)
        # 上次被打断的 dpkg 状态先修复, 再更新索引
        self.assertLess(calls.index('dpkg --configure -a'), calls.index('apt-get --error-on=any update'))
        self.assertEqual(result.stdout.count('java-runtime-check'), 1)
        self.assertIn('__STAGE__android_jdk:RUNNING', result.stdout)
        self.assertIn('__STAGE__android_jdk:DONE', result.stdout)

    def test_failed_update_is_visible_and_stops_installation(self):
        result, calls = self.run_setup(UPDATE_FAIL="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('HTTP 404', result.stdout)
        self.assertIn('软件源索引更新失败', result.stdout)
        self.assertNotIn('apt-get install', calls)

    def test_install_failure_preserves_real_error(self):
        result, _ = self.run_setup(INSTALL_FAIL="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('missing-library', result.stdout)
        self.assertNotIn('请检查网络', result.stdout)
        self.assertNotIn('__STAGE__android_jdk:DONE', result.stdout)

    def test_nonfunctional_java_is_not_marked_done(self):
        result, _ = self.run_setup(JAVA_FAIL="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Java 无法运行', result.stdout)
        self.assertIn('__STAGE__android_jdk:FAILED', result.stdout)
        self.assertNotIn('__STAGE__android_jdk:DONE', result.stdout)

    def test_broken_java_is_reinstalled_not_skipped(self):
        result, calls = self.run_setup(java_preinstalled=False)
        # 预装的坏 java 退出码 3 → 不能"已安装跳过", 要带 --reinstall 重装(桩会写出好 java)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('--reinstall', calls)
        self.assertIn('现有 Java 无法运行', result.stdout)
        self.assertIn('__STAGE__android_jdk:DONE', result.stdout)

    def test_check_mode_never_installs_and_reports_each_state(self):
        result, calls = self.run_setup('--check')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(calls, '')
        self.assertIn('__STAGE__android_jdk:PENDING', result.stdout)
        self.assertNotIn('RUNNING', result.stdout)
        result, calls = self.run_setup('--check', java_preinstalled=True)
        self.assertEqual(calls, '')
        self.assertIn('__STAGE__android_jdk:DONE', result.stdout)
        self.assertIn('__VER__android_jdk:17.0.20', result.stdout)
        # 装了一半、起不来的 java: 探测报 FAILED, 安装路径会把它重装
        result, calls = self.run_setup('--check', java_preinstalled=False)
        self.assertEqual(calls, '')
        self.assertIn('__STAGE__android_jdk:FAILED', result.stdout)
        self.assertNotIn('__STAGE__android_jdk:DONE', result.stdout)


if __name__ == '__main__':
    unittest.main()
