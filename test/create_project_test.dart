import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/projects/clone_project_page.dart';
import 'package:flit/features/projects/create_project_page.dart';

void main() {
  const base = CreateProjectParams(
    type: 'flutter',
    name: 'my_app',
    org: 'com.example',
    platforms: ['android'],
    empty: false,
    androidLang: 'kotlin',
    description: '',
    projectRoot: '/home/projects',
  );

  test('默认参数', () {
    final cmd = buildFlutterCreateCommand(base);
    expect(cmd, contains('--platforms=android'));
    expect(cmd, contains("--org 'com.example'"));
    expect(cmd, contains("'my_app'"));
    expect(cmd, isNot(contains('echo')));
    expect(cmd, isNot(contains('--empty')));
    expect(cmd, isNot(contains('-a java')));
  });

  test('project creation commands use the chosen project root', () {
    const project = CreateProjectParams(
      type: 'dart',
      name: 'private_app',
      org: 'com.example',
      platforms: [],
      empty: false,
      androidLang: 'kotlin',
      description: '',
      projectRoot: '/data/app/home/projects',
    );
    expect(
      buildDartCreateCommand(project),
      contains("cd '/data/app/home/projects'"),
    );
    expect(
      buildFlutterCreateCommand(
        const CreateProjectParams(
          type: 'flutter',
          name: 'private_app',
          org: 'com.example',
          platforms: ['android'],
          empty: false,
          androidLang: 'kotlin',
          description: '',
          projectRoot: '/data/app/home/projects',
        ),
      ),
      contains("cd '/data/app/home/projects'"),
    );
  });

  test('空项目 + java + 多平台 + 描述单引号转义', () {
    final cmd = buildFlutterCreateCommand(
      const CreateProjectParams(
        type: 'flutter',
        name: 'demo',
        org: 'com.a.b',
        platforms: ['android', 'ios'],
        empty: true,
        androidLang: 'java',
        description: "it's fine",
        projectRoot: '/home/projects',
      ),
    );
    expect(cmd, contains('--empty'));
    expect(cmd, contains('-a java'));
    expect(cmd, contains('--platforms=android,ios'));
    expect(cmd, contains(r"'\''"));
    expect(cmd, contains('--description'));
  });

  group('buildGitCloneCommand', () {
    test('默认克隆', () {
      final cmd = buildGitCloneCommand(
        const CloneProjectParams(
          url: 'https://github.com/u/repo.git',
          dirName: 'repo',
          branch: '',
          shallow: false,
          targetDir: '/home/projects',
        ),
      );
      expect(cmd, contains("cd '/home/projects'"));
      expect(cmd, contains("git clone 'https://github.com/u/repo.git' 'repo'"));
      expect(cmd, isNot(contains('echo')));
      expect(cmd, isNot(contains('--depth')));
      expect(cmd, isNot(contains('--branch')));
    });

    test('分支 + 浅克隆', () {
      final cmd = buildGitCloneCommand(
        const CloneProjectParams(
          url: 'https://github.com/u/repo.git',
          dirName: 'repo',
          branch: 'dev',
          shallow: true,
          targetDir: '/home/projects',
        ),
      );
      expect(cmd, contains("--branch 'dev'"));
      expect(cmd, contains('--depth 1'));
    });

    test('repoNameFromUrl 三种形态', () {
      expect(repoNameFromUrl('https://github.com/u/repo.git'), 'repo');
      expect(repoNameFromUrl('git@github.com:u/repo.git'), 'repo');
      expect(repoNameFromUrl('https://github.com/u/repo/'), 'repo');
    });
  });
}
