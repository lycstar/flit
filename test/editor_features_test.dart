import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/core/theme.dart';
import 'package:flit/features/editor/completion/completion_engine.dart';
import 'package:flit/features/editor/controller/code_controller.dart';
import 'package:flit/features/editor/highlighting/highlighter.dart';
import 'package:flit/features/editor/lsp/protocol.dart';
import 'package:flit/features/editor/widgets/code_field.dart';
import 'package:flit/features/editor/widgets/completion_popup.dart';

List<(String, Color?)> tokens(TextSpan span, [Color? inherited]) => [
  if (span.text != null) (span.text!, span.style?.color ?? inherited),
  for (final child in span.children ?? <InlineSpan>[])
    ...tokens(child as TextSpan, span.style?.color ?? inherited),
];

void main() {
  test(
    'textEdit replaces complete token and imports shift cursor in UTF-16',
    () {
      const source = '// 😀\nvoid main() { WidSuffix; }';
      final start = source.indexOf('WidSuffix');
      final position = LspProtocol.offsetToPosition(source, start);
      final end = LspProtocol.offsetToPosition(source, start + 9);
      final item = LspCompletionItem.fromJson({
        'label': 'Widget',
        'insertText': 'wrong',
        'textEdit': {
          'newText': 'Widget',
          'range': {
            'start': {'line': position.$1, 'character': position.$2},
            'end': {'line': end.$1, 'character': end.$2},
          },
        },
        'additionalTextEdits': [
          {
            'newText': "import 'widgets.dart';\n",
            'range': {
              'start': {'line': 0, 'character': 0},
              'end': {'line': 0, 'character': 0},
            },
          },
        ],
      }, document: source);
      final (result, cursor) = CompletionEngine.apply(
        source,
        start + 3,
        CompletionItem.fromLsp(item),
      );
      expect(result, "import 'widgets.dart';\n// 😀\nvoid main() { Widget; }");
      expect(result.substring(cursor - 6, cursor), 'Widget');
      expect(LspProtocol.offsetToPosition('😀abc', 2), (0, 2));
    },
  );

  test('insert/replace edit uses replacement range', () {
    final item = LspCompletionItem.fromJson({
      'label': 'print',
      'textEdit': {
        'newText': 'print',
        'insert': {
          'start': {'line': 0, 'character': 0},
          'end': {'line': 0, 'character': 2},
        },
        'replace': {
          'start': {'line': 0, 'character': 0},
          'end': {'line': 0, 'character': 5},
        },
      },
    }, document: 'prOld');
    expect(CompletionEngine.apply('prOld', 2, CompletionItem.fromLsp(item)), (
      'print',
      5,
    ));
  });

  test(
    'overlapping/out of bounds edits cannot partially modify the document',
    () {
      const item = LspCompletionItem(
        label: 'x',
        editOffset: 1,
        editLength: 3,
        additionalTextEdits: [LspTextEdit(start: 2, end: 2, newText: 'import')],
      );
      expect(
        () => CompletionEngine.apply('hello', 3, CompletionItem.fromLsp(item)),
        throwsFormatException,
      );
      expect(
        () => LspProtocol.positionToOffset('abc', 4, 0),
        throwsFormatException,
      );
      expect(
        () => LspProtocol.positionToOffset('abc', 0, 8),
        throwsFormatException,
      );
      expect(CompletionEngine.prefixOf('abc', -1), '');
      expect(CompletionEngine.complete('st', 2, language: 'json'), isEmpty);
    },
  );

  test(
    'nested comments, raw/multiline/unfinished strings and interpolation',
    () {
      const source =
          '/* outer /* nested */ still */\n'
          'final a = r"\$raw";\n'
          'final b = "hi \${foo({1: "inner"})} end";\n'
          "final c = '''multi\nline''';\n"
          'final d = "unfinished';
      final parts = tokens(CodeHighlighter.build(source, 'dart'));
      expect(parts.map((t) => t.$1).join(), source);
      expect(parts.first, (
        '/* outer /* nested */ still */',
        CodeTheme.current.comment,
      ));
      expect(parts, contains(('r"\$raw"', CodeTheme.current.string)));
      expect(parts, contains(('foo', CodeTheme.current.plain)));
      expect(parts, contains(('"inner"', CodeTheme.current.string)));
      expect(parts, contains((' end"', CodeTheme.current.string)));
      expect(parts.last, ('"unfinished', CodeTheme.current.string));
    },
  );

  test(
    'incremental lexer propagates changed multiline state to following lines',
    () {
      final cache = DartHighlightCache();
      const source = '/* comment\nfinal a = 1;\n*/\nreturn a;';
      CodeHighlighter.build(source, 'dart', dartCache: cache);
      final changed = source.replaceFirst('/* comment', '// comment');
      final cached = tokens(
        CodeHighlighter.build(changed, 'dart', dartCache: cache),
      );
      expect(cached, tokens(CodeHighlighter.build(changed, 'dart')));
      expect(cached, contains(('final', CodeTheme.current.keyword)));
      final removed = source.replaceFirst('*/', '');
      expect(
        tokens(CodeHighlighter.build(removed, 'dart', dartCache: cache)),
        tokens(CodeHighlighter.build(removed, 'dart')),
      );
    },
  );

  test(
    'JSON URL fragments are strings; YAML comments and XML attributes differ',
    () {
      expect(
        tokens(
          CodeHighlighter.build('{"url":"https://a/#b","ok":true}', 'json'),
        ),
        contains(('true', CodeTheme.current.keyword)),
      );
      expect(
        tokens(CodeHighlighter.build('name: hello # comment', 'yaml')),
        contains((' # comment', CodeTheme.current.comment)),
      );
      expect(
        tokens(CodeHighlighter.build('<item name="one"/>', 'xml')),
        contains(('name', CodeTheme.current.string)),
      );
    },
  );

  test('IME composition and selection wrapping preserve typed content', () {
    final formatter = CodeInputFormatter();
    const composing = TextEditingValue(
      text: '(',
      selection: TextSelection.collapsed(offset: 1),
      composing: TextRange(start: 0, end: 1),
    );
    expect(
      formatter.formatEditUpdate(TextEditingValue.empty, composing),
      composing,
    );
    const old = TextEditingValue(
      text: 'hello',
      selection: TextSelection(baseOffset: 0, extentOffset: 5),
    );
    const next = TextEditingValue(
      text: '(',
      selection: TextSelection.collapsed(offset: 1),
    );
    final wrapped = formatter.formatEditUpdate(old, next);
    expect(wrapped.text, '(hello)');
    expect(
      wrapped.selection,
      const TextSelection(baseOffset: 1, extentOffset: 6),
    );
  });

  test('signature active parameter and diagnostics preserve ranges/version', () {
    final signature = SignatureHelp.parse({
      'signatures': [
        {
          'label': 'f(int x, String y)',
          'parameters': [
            {
              'label': [2, 7],
            },
            {
              'label': [9, 17],
            },
          ],
        },
      ],
      'activeParameter': 1,
    });
    expect(
      signature!.label.substring(
        signature.parameterStart!,
        signature.parameterEnd!,
      ),
      'String y',
    );
    final diagnostic = DiagnosticsReport.parse(
      '{"params":{"uri":"file:///p/a.dart","version":3,"diagnostics":[{"severity":1,"message":"bad","range":{"start":{"line":1,"character":2},"end":{"line":1,"character":4}}}]}}',
    );
    expect(diagnostic.version, 3);
    expect(diagnostic.errors, 1);
    expect(diagnostic.items.single.character, 2);
    expect(diagnostic.items.single.endCharacter, 4);
  });

  testWidgets(
    'font changes invalidate spans and composing underline survives syntax color',
    (tester) async {
      final controller = CodeController(text: 'final x', language: 'dart');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CodeField(controller: controller)),
        ),
      );
      final context = tester.element(find.byType(CodeField));
      final a = controller.buildTextSpan(
        context: context,
        style: const TextStyle(fontSize: 12),
        withComposing: true,
      );
      final b = controller.buildTextSpan(
        context: context,
        style: const TextStyle(fontSize: 20),
        withComposing: true,
      );
      expect(a.style!.fontSize, 12);
      expect(b.style!.fontSize, 20);
      controller.value = controller.value.copyWith(
        composing: const TextRange(start: 0, end: 5),
      );
      final composing = controller.buildTextSpan(
        context: context,
        style: const TextStyle(fontSize: 20),
        withComposing: true,
      );
      final keyword = composing.children!.first as TextSpan;
      expect(keyword.text, 'final');
      expect(keyword.style!.decoration, TextDecoration.underline);
      expect(keyword.style!.color, CodeTheme.current.keyword);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );

  testWidgets(
    'cursor does not trigger text change; switching controller rebinds listeners',
    (tester) async {
      final first = CodeController(text: 'first');
      final second = CodeController(text: 'second');
      var changes = 0, selections = 0;
      Widget view(CodeController c) => MaterialApp(
        home: Scaffold(
          body: CodeField(
            controller: c,
            onChanged: () => changes++,
            onSelectionChanged: () => selections++,
          ),
        ),
      );
      await tester.pumpWidget(view(first));
      first.selection = const TextSelection.collapsed(offset: 2);
      expect(changes, 0);
      expect(selections, 1);
      await tester.pumpWidget(view(second));
      first.text = 'detached';
      expect(changes, 0);
      second.text = 'changed';
      expect(changes, 1);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      first.dispose();
      second.dispose();
    },
  );

  testWidgets('wrapped long lines and narrow candidate panel remain usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = CodeController(
      text: '${'longVariable ' * 40}\nfinal x = 1;',
      language: 'dart',
    );
    var selected = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(child: CodeField(controller: controller)),
              CompletionPopup(
                items: const [
                  CompletionItem(
                    insert: 'Widget',
                    label: 'AReallyLongWidgetNameThatWillBeTruncated',
                    kind: '类型',
                    detail: 'Widget(BuildContext context)',
                  ),
                ],
                selectedIndex: 0,
                onDismiss: () {},
                onSelected: (_) => selected = true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('AReallyLongWidgetNameThatWillBeTruncated'));
    expect(selected, isTrue);
    await tester.drag(find.byType(TextField), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
