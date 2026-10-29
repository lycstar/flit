import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../highlighting/highlighter.dart';
import '../lsp/protocol.dart';

/// 代码编辑控制器: 高亮 + 编辑辅助(自动缩进/括号配对/跨括号)。
///
/// 高亮在 [buildTextSpan] 内按需重算(文本未变直接复用缓存);
/// 编辑辅助通过 [CodeInputFormatter] 挂在 TextField 的 inputFormatters 上。
class CodeController extends TextEditingController {
  CodeController({super.text, String? language}) : _language = language;

  /// 高亮语言(dart/config/generic/markdown), null = 纯文本
  String? _language;
  String? get language => _language;
  set language(String? value) {
    if (_language == value) return;
    _language = value;
    _cachedText = null;
    _cachedStyle = null;
    notifyListeners();
  }

  // ---- 撤销/重做(时间窗合并: 连续快速小编辑并成一步, 与 IDE 手感一致) ----
  final List<TextEditingValue> _undo = [];
  final List<TextEditingValue> _redo = [];
  DateTime _lastEditAt = DateTime.now();
  bool _applyingHistory = false;
  static const _mergeWindow = Duration(milliseconds: 700);
  static const _historyCap = 100;

  bool editingLocked = false;
  bool get canUndo => !editingLocked && _undo.isNotEmpty;
  bool get canRedo => !editingLocked && _redo.isNotEmpty;

  @override
  set value(TextEditingValue newValue) {
    if (editingLocked && newValue.text != text) return;
    if (!_applyingHistory && newValue.text != text) {
      final now = DateTime.now();
      final coalesce =
          now.difference(_lastEditAt) < _mergeWindow && _undo.isNotEmpty;
      _lastEditAt = now;
      if (!coalesce) {
        _undo.add(value);
        if (_undo.length > _historyCap) _undo.removeAt(0);
      }
      // 新输入使重做分支作废
      _redo.clear();
    } else if (!_applyingHistory && newValue.selection != selection) {
      // Moving the caret starts a new edit group, without touching redo history.
      _lastEditAt = DateTime.now().subtract(_mergeWindow);
    }
    super.value = newValue;
  }

  void undo() => _travel(_undo, _redo);
  void redo() => _travel(_redo, _undo);

  void _travel(List<TextEditingValue> from, List<TextEditingValue> to) {
    if (editingLocked || from.isEmpty) return;
    _applyingHistory = true;
    to.add(value);
    final target = from.removeLast();
    final sel = target.selection;
    super.value = TextEditingValue(
      text: target.text,
      selection: TextSelection.collapsed(
        offset: sel.baseOffset.clamp(0, target.text.length),
      ),
      composing: TextRange.empty,
    );
    _applyingHistory = false;
    _lastEditAt = DateTime.now().subtract(_mergeWindow); // 历史/新编辑不合并
  }

  /// Git replaced the disk version: old undo history must not resurrect it.
  void replaceFromDisk(String text) {
    _undo.clear();
    _redo.clear();
    _diagnostics = const [];
    super.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: selection.baseOffset.clamp(0, text.length),
      ),
    );
  }

  String? _cachedText;
  TextSpan? _cachedSpan;
  TextStyle? _cachedStyle;
  final _dartCache = DartHighlightCache();
  List<EditorDiagnostic> _diagnostics = const [];
  List<EditorDiagnostic> get diagnostics => _diagnostics;
  void setDiagnostics(List<EditorDiagnostic> items) {
    _diagnostics = items;
    notifyListeners();
  }

  /// 应用快速修复的文本编辑: 按当前文本换算偏移、倒序应用(高偏移先改,
  /// 低偏移不受影响); 选区收敛到第一个(最低偏移)编辑的末尾
  void applyLspEdits(List<LspRangeEdit> edits) {
    final current = this.text;
    final resolved = <(int, int, String)>[];
    for (final e in edits) {
      try {
        final start = LspProtocol.positionToOffset(
          current,
          e.startLine,
          e.startChar,
        );
        final end = LspProtocol.positionToOffset(current, e.endLine, e.endChar);
        if (end >= start) resolved.add((start, end, e.newText));
      } on FormatException {
        /* 编辑区间过期 */
      }
    }
    if (resolved.isEmpty) return;
    resolved.sort((a, b) => b.$1 - a.$1);
    var text = current;
    for (final (start, end, replacement) in resolved) {
      text = text.replaceRange(start, end, replacement);
    }
    final first = resolved.last;
    value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: first.$1 + first.$3.length),
      composing: TextRange.empty,
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (text != _cachedText || style != _cachedStyle) {
      _cachedText = text;
      _cachedStyle = style;
      _cachedSpan = CodeHighlighter.build(
        text,
        language,
        base: style,
        dartCache: _dartCache,
      );
    }
    final span = _cachedSpan ?? TextSpan(text: text, style: style);
    final composing = value.composing;
    final showComposing =
        withComposing &&
        composing.isValid &&
        !composing.isCollapsed &&
        composing.end <= text.length;
    final ranges = <(int, int, bool)>[];
    for (final diagnostic in _diagnostics) {
      try {
        final start = LspProtocol.positionToOffset(
          text,
          diagnostic.line,
          diagnostic.character,
        );
        final end = LspProtocol.positionToOffset(
          text,
          diagnostic.endLine,
          diagnostic.endCharacter,
        );
        if (end > start && diagnostic.severity <= 2) {
          ranges.add((start, end, diagnostic.severity == 1));
        }
      } on FormatException {
        /* A new edit can invalidate an old diagnostic. */
      }
    }
    if (!showComposing && ranges.isEmpty) return span;
    final children = <TextSpan>[];
    var offset = 0;
    void visit(TextSpan node, TextStyle inherited) {
      final effective = inherited.merge(node.style);
      final part = node.text ?? '';
      final end = offset + part.length;
      final cuts = <int>{offset, end};
      for (final range in ranges) {
        if (range.$1 > offset && range.$1 < end) cuts.add(range.$1);
        if (range.$2 > offset && range.$2 < end) cuts.add(range.$2);
      }
      if (showComposing) {
        if (composing.start > offset && composing.start < end) {
          cuts.add(composing.start);
        }
        if (composing.end > offset && composing.end < end) {
          cuts.add(composing.end);
        }
      }
      final sorted = cuts.toList()..sort();
      for (var i = 0; i + 1 < sorted.length; i++) {
        final start = sorted[i];
        var decorated = effective;
        final diagnostic = ranges
            .where((r) => r.$1 <= start && r.$2 > start)
            .firstOrNull;
        if (diagnostic != null) {
          decorated = decorated.copyWith(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.wavy,
            decorationColor: diagnostic.$3 ? Colors.redAccent : Colors.amber,
          );
        }
        if (showComposing &&
            composing.start <= start &&
            composing.end > start) {
          decorated = decorated.copyWith(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.solid,
            decorationColor: effective.color,
          );
        }
        children.add(
          TextSpan(
            text: part.substring(start - offset, sorted[i + 1] - offset),
            style: decorated,
          ),
        );
      }
      offset = end;
      for (final child in node.children ?? <InlineSpan>[]) {
        if (child is TextSpan) visit(child, effective);
      }
    }

    visit(span, const TextStyle());
    return TextSpan(style: span.style, children: children);
  }
}

/// 编辑辅助输入过滤器:
///   输入 ( [ { ' " `  → 自动补闭合符(光标落在中间; 下一字符就是闭合符时改为跨过)
///   输入 ) ] }        → 若下一字符就是同款闭合符, 跨过而不重复插入
///   输入换行          → 复制上一行缩进; 上一行以 { ( [ 结尾时多缩一层
class CodeInputFormatter extends TextInputFormatter {
  CodeInputFormatter({this.indentUnit = '  ', this.enableAutoIndent = true});

  /// 缩进单位(默认两空格)
  final String indentUnit;
  final bool enableAutoIndent;

  static const _pairs = {'(': ')', '[': ']', '{': '}'};
  static const _closers = {')', ']', '}'};
  static const _quotes = {"'", '"', '`'};

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.selection.isValid ||
        (newValue.composing.isValid && !newValue.composing.isCollapsed) ||
        (oldValue.composing.isValid && !oldValue.composing.isCollapsed)) {
      return newValue;
    }
    final selection = oldValue.selection;
    if (selection.isValid &&
        !selection.isCollapsed &&
        newValue.selection.isCollapsed) {
      final insertedLength =
          newValue.text.length -
          oldValue.text.length +
          selection.end -
          selection.start;
      if (insertedLength == 1 &&
          newValue.text.substring(0, selection.start) ==
              oldValue.text.substring(0, selection.start) &&
          newValue.text.substring(selection.start + 1) ==
              oldValue.text.substring(selection.end)) {
        final opener = newValue.text[selection.start];
        if (_pairs.containsKey(opener) || _quotes.contains(opener)) {
          return _wrapSelection(oldValue, opener, _pairs[opener] ?? opener);
        }
      }
      return newValue;
    }
    final ins = _insertedText(oldValue.text, newValue.text);
    if (ins == null) return newValue;

    // —— 换行: 自动缩进 ——
    if (enableAutoIndent && ins == '\n') {
      return _autoIndent(oldValue, newValue);
    }

    // —— 闭合符跨过: 下一字符就是同款闭合符时丢弃多输入的字符, 光标跨过 ——
    if (_closers.contains(ins) || _quotes.contains(ins)) {
      final sel = newValue.selection;
      if (sel.baseOffset == sel.extentOffset &&
          sel.baseOffset < newValue.text.length &&
          newValue.text[sel.baseOffset] == ins) {
        return TextEditingValue(
          text: oldValue.text,
          selection: TextSelection.collapsed(
            offset: oldValue.selection.baseOffset + 1,
          ),
          composing: TextRange.empty,
        );
      }
    }

    // —— 开括号/引号配对 ——
    final closer = _pairs[ins];
    final isQuote = _quotes.contains(ins);
    if (closer == null && !isQuote) return newValue;

    final sel = newValue.selection;
    if (!sel.isCollapsed) {
      // 有选区: 用配对包裹选区
      return _wrapSelection(newValue, ins, closer ?? ins);
    }
    final next = sel.baseOffset < newValue.text.length
        ? newValue.text[sel.baseOffset]
        : '';
    final canPair = closer != null
        ? next.isEmpty || _wordBreak(next)
        : next.isEmpty || _wordBreak(next) || closer == next;
    if (!canPair) return newValue;

    final offset = sel.baseOffset;
    final text = newValue.text.replaceRange(offset, offset, closer ?? ins);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
      composing: TextRange.empty,
    );
  }

  bool _wordBreak(String ch) => ch.contains(RegExp(r'[\s)\]}",;.]'));

  TextEditingValue _wrapSelection(
    TextEditingValue value,
    String opener,
    String closer,
  ) {
    final sel = value.selection;
    final start = sel.start.clamp(0, value.text.length);
    final end = sel.end.clamp(0, value.text.length);
    final text = value.text
        .replaceRange(end, end, closer)
        .replaceRange(start, start, opener);
    return TextEditingValue(
      text: text,
      selection: TextSelection(baseOffset: start + 1, extentOffset: end + 1),
      composing: TextRange.empty,
    );
  }

  TextEditingValue _autoIndent(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final sel = newValue.selection;
    if (!sel.isCollapsed) return newValue;
    final off = sel.baseOffset;
    final text = newValue.text;

    // 光标前一行
    final lineStart = text.lastIndexOf('\n', off - 2) + 1;
    final prevLine = text.substring(lineStart, (off - 1).clamp(0, text.length));
    final indent = RegExp(r'^[ \t]*').firstMatch(prevLine)![0]!;
    final extra = RegExp(r'[({\[]$').hasMatch(prevLine.trimRight())
        ? indentUnit
        : '';

    // 经典 {} 之间回车: 输入值已含换行, 这里补缩进并让 } 独占下一行
    if (off < text.length &&
        text[off] == '}' &&
        prevLine.trimRight().endsWith('{')) {
      final insert = '$indent$indentUnit\n$indent';
      final newText = text.replaceRange(off, off, insert);
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: off + indent.length + indentUnit.length,
        ),
        composing: TextRange.empty,
      );
    }

    if (indent.isEmpty && extra.isEmpty) return newValue;
    final insert = '$indent$extra';
    final newText = text.replaceRange(off, off, insert);
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: off + insert.length),
      composing: TextRange.empty,
    );
  }

  /// 计算这次编辑插入的文本(仅处理纯插入; 删除/替换返回 null)
  String? _insertedText(String oldText, String newText) {
    if (newText.length <= oldText.length) return null;
    var p = 0;
    final minLen = oldText.length;
    while (p < minLen && oldText[p] == newText[p]) {
      p++;
    }
    final insLen = newText.length - oldText.length;
    final inserted = newText.substring(p, p + insLen);
    // 确认是纯插入(尾部未变动)
    return oldText.substring(p) == newText.substring(p + insLen)
        ? inserted
        : null;
  }
}
