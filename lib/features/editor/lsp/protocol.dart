import 'dart:convert';

/// LSP 协议辅助: 坐标换算 / 补全条目 / 诊断解析。
/// LSP 的 character 以 UTF-16 码元计, 与 Dart 字符串索引一致, 无需换算编码。
class LspProtocol {
  LspProtocol._();

  /// LSP position(line, character) → 文本偏移
  static int positionToOffset(String text, int line, int character) {
    if (line < 0 || character < 0) {
      throw const FormatException('Invalid position');
    }
    var lineStart = 0;
    var l = 0;
    for (var i = 0; i < text.length && l < line; i++) {
      if (text.codeUnitAt(i) == 0x0A) {
        l++;
        lineStart = i + 1;
      }
    }
    if (l != line) throw const FormatException('Line outside document');
    final startOfLine = lineStart;
    var col = 0;
    var off = startOfLine;
    while (off < text.length && col < character) {
      final cu = text.codeUnitAt(off);
      if (cu == 0x0A) break;
      col++;
      off++;
    }
    if (col != character) throw const FormatException('Column outside line');
    return off;
  }

  /// 文本偏移 → LSP position
  static (int, int) offsetToPosition(String text, int offset) {
    offset = offset.clamp(0, text.length);
    var line = 0;
    var lineStart = 0;
    for (var i = 0; i < offset && i < text.length; i++) {
      if (text.codeUnitAt(i) == 0x0A) {
        line++;
        lineStart = i + 1;
      }
    }
    return (line, offset - lineStart);
  }

  static String fileUri(String path) => Uri.file(path).toString();

  static String pathOfUri(String uri) =>
      uri.startsWith('file://') ? Uri.parse(uri).toFilePath() : uri;

  static (int, int) positionFromJson(Object? value) {
    final map = value is Map ? value : const {};
    return (
      (map['line'] as num?)?.toInt() ?? 0,
      (map['character'] as num?)?.toInt() ?? 0,
    );
  }
}

class LspTextEdit {
  const LspTextEdit({
    required this.start,
    required this.end,
    required this.newText,
  });

  final int start;
  final int end;
  final String newText;
}

/// 补全候选(来自 LSP)
class LspCompletionItem {
  const LspCompletionItem({
    required this.label,
    this.insertText,
    this.detail,
    this.editText,
    this.editOffset,
    this.editLength,
    this.kind,
    this.sortText,
    this.filterText,
    this.additionalTextEdits = const [],
    this.raw = const {},
    this.documentation,
  });

  factory LspCompletionItem.fromJson(
    Map<String, dynamic> j, {
    String? document,
  }) {
    int? editOffset;
    int? editLength;
    String? editText;
    final edits = <LspTextEdit>[];
    final te = j['textEdit'];
    if (te is Map<String, dynamic>) {
      editText = (te['newText'] as String?) ?? j['insertText'] as String?;
      final range = (te['replace'] ?? te['range']) as Map<String, dynamic>?;
      if (range != null && range['start'] is Map && range['end'] is Map) {
        final start = LspProtocol.positionFromJson(range['start']);
        final end = LspProtocol.positionFromJson(range['end']);
        if (document != null) {
          editOffset = LspProtocol.positionToOffset(
            document,
            start.$1,
            start.$2,
          );
          editLength =
              LspProtocol.positionToOffset(document, end.$1, end.$2) -
              editOffset;
        }
      }
    }
    for (final raw in (j['additionalTextEdits'] as List? ?? const [])) {
      if (raw is! Map<String, dynamic> || document == null) continue;
      final range = raw['range'] as Map<String, dynamic>?;
      if (range == null) continue;
      final start = LspProtocol.positionFromJson(range['start']);
      final end = LspProtocol.positionFromJson(range['end']);
      final startOffset = LspProtocol.positionToOffset(
        document,
        start.$1,
        start.$2,
      );
      final endOffset = LspProtocol.positionToOffset(document, end.$1, end.$2);
      edits.add(
        LspTextEdit(
          start: startOffset,
          end: endOffset,
          newText: raw['newText'] as String? ?? '',
        ),
      );
    }
    return LspCompletionItem(
      label: (j['label'] as String?) ?? '',
      insertText: j['insertText'] as String?,
      detail: j['detail'] as String?,
      kind: j['kind'] as int?,
      sortText: j['sortText'] as String?,
      filterText: j['filterText'] as String?,
      raw: Map.unmodifiable(j),
      documentation: j['documentation'] is String
          ? j['documentation'] as String
          : (j['documentation'] is Map
                ? j['documentation']['value'] as String?
                : null),
      editText: editText,
      editOffset: editOffset,
      editLength: editLength,
      additionalTextEdits: edits,
    );
  }

  final Map<String, dynamic> raw;
  final String? documentation;
  final String label;
  final String? insertText;
  final String? detail;
  final String? editText;
  final int? editOffset;
  final int? editLength;
  final int? kind;
  final String? sortText;
  final String? filterText;
  final List<LspTextEdit> additionalTextEdits;

  String get insert =>
      editText ?? (insertText?.isNotEmpty == true ? insertText : null) ?? label;

  static List<LspCompletionItem> parseList(
    String responseJson, {
    String? document,
  }) {
    final j = jsonDecode(responseJson);
    final dynamic list = j is Map<String, dynamic>
        ? (j['result'] is Map<String, dynamic>
              ? j['result']['items']
              : j['result'])
        : null;
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .where((item) => item['insertTextFormat'] != 2)
        .map((item) => LspCompletionItem.fromJson(item, document: document))
        .toList();
  }
}

class EditorDiagnostic {
  const EditorDiagnostic({
    required this.line,
    required this.character,
    required this.endLine,
    required this.endCharacter,
    required this.severity,
    required this.message,
  });
  final int line, character, endLine, endCharacter, severity;
  final String message;
}

class DiagnosticsReport {
  const DiagnosticsReport({
    required this.path,
    required this.errors,
    required this.messages,
    this.version,
    this.items = const [],
  });
  final String path;
  final int errors;
  final int? version;
  final List<String> messages;
  final List<EditorDiagnostic> items;

  static DiagnosticsReport parse(String notifyJson) {
    final params = (jsonDecode(notifyJson) as Map)['params'] as Map;
    final items = <EditorDiagnostic>[];
    for (final d in (params['diagnostics'] as List? ?? [])) {
      if (d is! Map) continue;
      final range = d['range'] as Map? ?? {};
      final start = LspProtocol.positionFromJson(range['start']);
      final end = LspProtocol.positionFromJson(range['end']);
      items.add(
        EditorDiagnostic(
          line: start.$1,
          character: start.$2,
          endLine: end.$1,
          endCharacter: end.$2,
          severity: d['severity'] as int? ?? 3,
          message: d['message'] as String? ?? '',
        ),
      );
    }
    return DiagnosticsReport(
      path: LspProtocol.pathOfUri(params['uri'] as String? ?? ''),
      version: params['version'] as int?,
      errors: items.where((d) => d.severity == 1).length,
      messages: items.map((d) => d.message).toList(),
      items: items,
    );
  }
}

class SignatureHelp {
  const SignatureHelp(this.label, this.parameterStart, this.parameterEnd);
  final String label;
  final int? parameterStart, parameterEnd;
  static SignatureHelp? parse(Object? value) {
    if (value is! Map) return null;
    final signatures = value['signatures'] as List? ?? [];
    if (signatures.isEmpty) return null;
    final index = ((value['activeSignature'] as int?) ?? 0).clamp(
      0,
      signatures.length - 1,
    );
    final signature = signatures[index] as Map;
    final label = signature['label'] as String? ?? '';
    final params = signature['parameters'] as List? ?? [];
    final active =
        signature['activeParameter'] ?? value['activeParameter'] ?? 0;
    int? start, end;
    if (active is int && active >= 0 && active < params.length) {
      final param = (params[active] as Map)['label'];
      if (param is List && param.length == 2) {
        start = param[0] as int;
        end = param[1] as int;
      } else if (param is String) {
        start = label.indexOf(param);
        end = start + param.length;
      }
    }
    if (start == null ||
        end == null ||
        start < 0 ||
        end < start ||
        end > label.length) {
      start = null;
      end = null;
    }
    return SignatureHelp(label, start, end);
  }
}

/// LSP 文本编辑(range + newText), 作用于本文档
class LspRangeEdit {
  const LspRangeEdit(
    this.startLine,
    this.startChar,
    this.endLine,
    this.endChar,
    this.newText,
  );
  final int startLine, startChar, endLine, endChar;
  final String newText;

  static LspRangeEdit? parse(dynamic raw) {
    if (raw is! Map) return null;
    final range = raw['range'];
    final start = range is Map ? range['start'] : null;
    final end = range is Map ? range['end'] : null;
    final sl = start is Map ? start['line'] : null;
    final sc = start is Map ? start['character'] : null;
    final el = end is Map ? end['line'] : null;
    final ec = end is Map ? end['character'] : null;
    if (sl is! int || el is! int) return null;
    return LspRangeEdit(
      sl,
      sc is int ? sc : 0,
      el,
      ec is int ? ec : 0,
      (raw['newText'] ?? '').toString(),
    );
  }
}

/// 快速修复(codeAction): 只保留带文本编辑、且作用于当前文档的项
class LspCodeAction {
  const LspCodeAction({required this.title, required this.edits});
  final String title;
  final List<LspRangeEdit> edits;

  static List<LspCodeAction> parse(dynamic result, String docPath) {
    if (result is! List) return const [];
    final docUri = LspProtocol.fileUri(docPath);
    final actions = <LspCodeAction>[];
    for (final raw in result) {
      if (raw is! Map) continue;
      final edit = raw['edit'] as Map?;
      if (edit == null) continue; // command 型(执行命令而非改文本)不支持
      final edits = <LspRangeEdit>[];
      final changes = edit['changes'] as Map?;
      for (final e in (changes?[docUri] as List? ?? [])) {
        final parsed = LspRangeEdit.parse(e);
        if (parsed != null) edits.add(parsed);
      }
      for (final dc in (edit['documentChanges'] as List? ?? [])) {
        if (dc is! Map || dc['textDocument']?['uri'] != docUri) continue;
        for (final e in (dc['edits'] as List? ?? [])) {
          final parsed = LspRangeEdit.parse(e);
          if (parsed != null) edits.add(parsed);
        }
      }
      if (edits.isNotEmpty) {
        actions.add(
          LspCodeAction(title: (raw['title'] ?? '').toString(), edits: edits),
        );
      }
    }
    return actions;
  }
}
