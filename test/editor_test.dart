import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/core/theme.dart';
import 'package:flit/features/editor/completion/completion_engine.dart';
import 'package:flit/features/editor/controller/code_controller.dart';
import 'package:flit/features/editor/highlighting/highlighter.dart';
import 'package:flit/features/editor/lsp/protocol.dart';

void main() {
  test(
    'cursor movement preserves redo and separates edits at different positions',
    () {
      final code = CodeController(text: 'ab');
      code.selection = const TextSelection.collapsed(offset: 2);
      expect(code.canUndo, false);
      code.value = const TextEditingValue(
        text: 'abc',
        selection: TextSelection.collapsed(offset: 3),
      );
      code.selection = const TextSelection.collapsed(offset: 0);
      code.value = const TextEditingValue(
        text: 'Xabc',
        selection: TextSelection.collapsed(offset: 1),
      );
      code.undo();
      expect(code.text, 'abc');
      code.selection = const TextSelection.collapsed(offset: 2);
      expect(code.canRedo, true);
      code.redo();
      expect(code.text, 'Xabc');
      code.undo();
      code.undo();
      expect(code.text, 'ab');
      code.dispose();
    },
  );

  group('CodeHighlighter', () {
    test('spans 拼接后还原原文', () {
      const src = '// 注释\nvoid main() {\n  print("hi");\n}\n';
      final span = CodeHighlighter.build(src, 'dart');
      expect(_flatten(span), src);
    });

    test('关键字/注释/字符串分别着色', () {
      const src = '// c\nvoid f() => "s";';
      final span = CodeHighlighter.build(src, 'dart');
      final colored = <String, Color?>{};
      _walk(span, colored);
      expect(colored['// c'], CodeTheme.current.comment);
      expect(colored['void'], CodeTheme.current.keyword);
      expect(colored['"s"'], CodeTheme.current.string);
    });

    test('大文件仍保留高亮及原文', () {
      final src = 'final value = 1;\n' * 8000;
      final span = CodeHighlighter.build(src, 'dart');
      expect(_flatten(span), src);
      expect(span.children, isNotEmpty);
    });

    test('未知语言返回纯文本', () {
      final span = CodeHighlighter.build('abc', null);
      expect(span.text, 'abc');
    });
  });

  group('CompletionEngine', () {
    test('前缀 <2 字符不触发', () {
      expect(CompletionEngine.complete('a', 1), isEmpty);
    });

    test('本地标识符子串命中且优先于符号', () {
      const doc = 'myStatefulThing\nst';
      final items = CompletionEngine.complete(doc, doc.length);
      expect(items, isNotEmpty);
      expect(items.first.insert, 'myStatefulThing'); // 本文档标识符排最前
      expect(items.any((i) => i.insert == 'static'), isTrue);
    });

    test('apply 用候选替换词前缀并移动光标', () {
      const doc = 'final x = pri';
      final (text, offset) = CompletionEngine.apply(
        doc,
        doc.length,
        const CompletionItem(insert: 'print', label: 'print', kind: '符号'),
      );
      expect(text, 'final x = print');
      expect(offset, text.length);
    });
  });

  group('CodeInputFormatter', () {
    final fmt = CodeInputFormatter();

    test('输入 ( 自动补全并落在中间', () {
      const old = TextEditingValue(text: 'a');
      const mid = TextEditingValue(
        text: 'a(',
        selection: TextSelection.collapsed(offset: 2),
      );
      final out = fmt.formatEditUpdate(old, mid);
      expect(out.text, 'a()');
      expect(out.selection.baseOffset, 2);
    });

    test('下一字符是闭合符时跨过而不重复插入', () {
      const old = TextEditingValue(
        text: 'a()',
        selection: TextSelection.collapsed(offset: 2),
      );
      // 原始输入: 用户多打了一个 ), 过滤器负责丢弃并跨过
      const mid = TextEditingValue(
        text: 'a())',
        selection: TextSelection.collapsed(offset: 3),
      );
      final out = fmt.formatEditUpdate(old, mid);
      expect(out.text, 'a()');
      expect(out.selection.baseOffset, 3);
    });

    test('换行继承缩进, { 结尾多缩一层', () {
      const old = TextEditingValue(text: 'void f() {');
      const mid = TextEditingValue(
        text: 'void f() {\n',
        selection: TextSelection.collapsed(offset: 11),
      );
      final out = fmt.formatEditUpdate(old, mid);
      expect(out.text, 'void f() {\n  ');
      expect(out.selection.baseOffset, 13);
    });

    test('{} 之间回车: 补缩进行, } 独占下一行', () {
      const old = TextEditingValue(text: 'void f() {}');
      const mid = TextEditingValue(
        text: 'void f() {\n}',
        selection: TextSelection.collapsed(offset: 11),
      );
      final out = fmt.formatEditUpdate(old, mid);
      expect(out.text, 'void f() {\n  \n}');
      expect(out.selection.baseOffset, 13);
    });
  });

  group('LspProtocol', () {
    test('position 与 offset 互转', () {
      const text = 'void a() {\n  int x = 1;\n}\n';
      final off = LspProtocol.positionToOffset(text, 1, 2);
      expect(off, text.indexOf('int'));
      final (line, character) = LspProtocol.offsetToPosition(text, off);
      expect(line, 1);
      expect(character, 2);
    });

    test('fileUri 生成', () {
      expect(
        LspProtocol.fileUri('/data/x/files/home/demo'),
        startsWith('file://'),
      );
    });
  });

  group('LspCompletionItem', () {
    test('解析 result.list', () {
      const json = '{"result":[{"label":"greet()","kind":2},{"label":"name"}]}';
      final items = LspCompletionItem.parseList(json);
      expect(items.length, 2);
      expect(items.first.insert, 'greet()');
    });

    test('解析 result.items 结构', () {
      const json =
          '{"result":{"isIncomplete":false,"items":[{"label":"foo","insertText":"fooBar"}]}}';
      final items = LspCompletionItem.parseList(json);
      expect(items.single.insert, 'fooBar');
    });
  });
}

String _flatten(TextSpan span) {
  final sb = StringBuffer();
  void walk(TextSpan s) {
    if (s.text != null) sb.write(s.text!);
    s.children?.forEach((c) => walk(c as TextSpan));
  }

  walk(span);
  return sb.toString();
}

void _walk(TextSpan span, Map<String, Color?> out) {
  if (span.text != null) out[span.text!] = span.style?.color;
  span.children?.forEach((c) => _walk(c as TextSpan, out));
}
