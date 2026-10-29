import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/editor/controller/code_controller.dart';
import 'package:flit/features/editor/widgets/markdown_preview.dart';

void main() {
  testWidgets('md preview renders the buffer and follows edits after debounce', (
    tester,
  ) async {
    final controller = CodeController(text: '# Hello Flit\n');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownPreview(controller: controller, projectRoot: '/project'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Hello Flit'), findsOneWidget);

    // 防抖期内不重渲染, 250ms 后跟上
    controller.text = '- item one\n- item two\n';
    await tester.pump();
    expect(find.text('item one'), findsNothing);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('item one'), findsOneWidget);
    expect(find.text('item two'), findsOneWidget);
  });

  testWidgets('fenced code blocks render in a horizontal-scroll block', (
    tester,
  ) async {
    final controller = CodeController(text: '```dart\nvoid main() {}\n```\n');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownPreview(controller: controller, projectRoot: '/project'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('void main() {}'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
        skipOffstage: false,
      ),
      findsWidgets,
    );
  });
}
