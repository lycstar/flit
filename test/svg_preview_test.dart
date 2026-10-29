import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/editor/controller/code_controller.dart';
import 'package:flit/features/editor/widgets/svg_preview.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  testWidgets('svg preview renders the buffer and follows edits', (
    tester,
  ) async {
    const svg = '<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48">'
        '<rect width="48" height="48" fill="#3FB950"/></svg>';
    final controller = CodeController(text: svg);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SvgPreview(controller: controller),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(SvgPicture), findsOneWidget);

    // 防抖后跟随编辑: 非法内容显示错误而不是崩溃
    controller.text = 'not a svg';
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('无法渲染'), findsOneWidget);
  });

  testWidgets('empty buffer shows a placeholder', (tester) async {
    final controller = CodeController(text: '  \n');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SvgPreview(controller: controller),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('空文件'), findsOneWidget);
  });
}
