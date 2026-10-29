import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/environment/environment_controller.dart';
import 'package:flit/features/environment/widgets/stage_timeline.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, StageState> fixture() {
    final stages = {
      for (final parts in stageParts.values)
        for (final part in parts) part: StageState(),
    };
    stages['bootstrap']!
      ..state = 'DONE'
      ..size = '239 MB';
    stages['android_jdk']!
      ..state = 'DONE'
      ..version = '17.0.20'
      ..size = '215 MB';
    stages['android_sdk']!
      ..state = 'DONE'
      ..version = 'API 36'
      ..size = '217 MB';
    stages['android_ndk']!.state = 'DONE';
    stages['android_gradle']!.state = 'DONE';
    stages['flutter_tools']!.state = 'DONE';
    stages['flutter_sdk']!.state = 'RUNNING';
    return stages;
  }

  testWidgets('timeline shows component rows without numbering or process steps',
      (tester) async {
    final stages = fixture();
    stages['flutter_tools']!.version = 'git 2.47 · gh 2.63';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StageTimeline(stages: stages, busy: false),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    // 组件行: 名称(+版本)(+大小)
    expect(find.text('OpenJDK 17 · 17.0.20 · 215 MB'), findsOneWidget);
    expect(find.text('Android SDK · API 36 · 217 MB'), findsOneWidget);
    expect(find.text('NDK'), findsOneWidget);
    expect(find.text('Gradle 配置'), findsOneWidget);
    expect(find.text('Git 与 gh · git 2.47 · gh 2.63'), findsOneWidget);
    expect(find.text('Flutter SDK · 安装中'), findsOneWidget);
    // 过程性步骤与编号不上卡片
    expect(find.text('1-1 下载与解压'), findsNothing);
    expect(find.text('预热'), findsNothing);
    expect(find.textContaining('已就绪'), findsNothing);
    expect(find.textContaining('aapt2'), findsNothing);
  });

  testWidgets('failed stage keeps its red state label', (tester) async {
    final stages = fixture();
    stages['android_ndk']!.state = 'FAILED';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StageTimeline(stages: stages, busy: false)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('NDK · 失败'), findsOneWidget);
  });

  test('readyStageIds covers every scripted sub-task except bootstrap', () {
    expect(readyStageIds, hasLength(7));
    expect(readyStageIds, isNot(contains('bootstrap')));
    expect(readyStageIds, containsAll([
      'android_jdk',
      'android_sdk',
      'android_ndk',
      'android_gradle',
      'flutter_tools',
      'flutter_sdk',
      'flutter_warmup',
    ]));
  });

  test('markers are recognized even when glued to progress fragments', () {
    // dl 采样的 \r 进度残片与脚本输出同行时, 标记仍在行中任意位置可识别
    final stage = parseStageMarker('已下载 445 MB__STAGE__flutter_sdk:DONE');
    expect(stage, isNotNull);
    expect(stage!.$1, 'flutter_sdk');
    expect(stage.$2, 'DONE');

    final ver = parseVersionMarker('已下载 5 MB__VER__flutter_tools:git 2.47');
    expect(ver, isNotNull);
    expect(ver!.$1, 'flutter_tools');
    expect(ver.$2, 'git 2.47');

    final net = parseNetMarker('下载 3 MB__NET__github:200|1.2s');
    expect(net, isNotNull);
    expect(net!.$1, 'github');
    expect(net.$3, '200|1.2s');

    // 普通输出不误判
    expect(parseStageMarker('[flutter] 解压完成'), isNull);
    expect(parseVersionMarker('[flutter] 解压完成'), isNull);
  });
}
