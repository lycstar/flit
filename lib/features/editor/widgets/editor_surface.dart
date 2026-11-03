import 'package:flit/l10n/strings.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../core/pinch_zoom.dart';
import '../../settings/appearance_preferences.dart';
import '../completion/completion_engine.dart';
import '../controller/code_controller.dart';
import '../controller/editor_intelligence.dart';
import '../lsp/lsp_client.dart';
import '../lsp/protocol.dart' show SignatureHelp;
import 'code_field.dart';
import 'completion_popup.dart';

/// Owns editing UI only; documents and the language server belong to the project.
class EditorSurface extends StatefulWidget {
  const EditorSurface({
    super.key,
    required this.controller,
    required this.path,
    required this.focusNode,
  });
  final CodeController controller;
  final String path;
  final FocusNode focusNode;

  @override
  State<EditorSurface> createState() => _EditorSurfaceState();
}

class _EditorSurfaceState extends State<EditorSurface> {
  /// 语言服务属于工程(ProjectScope), 页面生命周期内不换对象
  late final LspClient _language = context.read<LspClient>();
  late final EditorIntelligence _intelligence;
  Rect? _caretRect;
  double? _zoomSize;
  double _zoomStartSize = 14;
  int _zoomGeneration = 0;

  void _zoomStart() {
    _zoomGeneration++;
    _zoomStartSize =
        _zoomSize ?? context.read<AppearancePreferences>().editorSize;
    _dismissSuggestions();
  }

  void _zoom(double scale) {
    final size = (_zoomStartSize * scale).clamp(
      AppearancePreferences.editorMinSize,
      AppearancePreferences.editorMaxSize,
    );
    if (size.isFinite) setState(() => _zoomSize = size);
  }

  Future<void> _saveZoom() async {
    if (_zoomSize == null) return;
    final generation = _zoomGeneration;
    final size = (_zoomSize! * 2).round() / 2;
    try {
      await context.read<AppearancePreferences>().update(editor: size);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.strings.fontSizeAppliedButSavingFailedP(error),
            ),
          ),
        );
      }
    } finally {
      if (mounted && generation == _zoomGeneration) {
        setState(() => _zoomSize = null);
      }
    }
  }

  CodeController get _codeCtrl => widget.controller;
  FocusNode get _editorFocus => widget.focusNode;

  @override
  void initState() {
    super.initState();
    _intelligence = EditorIntelligence(
      path: widget.path,
      code: _codeCtrl,
      language: _language,
    );
    _editorFocus.addListener(_onFocusChanged);
    _onFocusChanged();
  }

  void _onFocusChanged() => _intelligence.setFocused(_editorFocus.hasFocus);
  void _dismissSuggestions() => _intelligence.dismiss();

  Future<void> _applyCompletion(CompletionItem item) async {
    try {
      if (await _intelligence.apply(item) && mounted) {
        _editorFocus.requestFocus();
      }
    } on FormatException {
      if (!mounted) return;
      _intelligence.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.strings.completionItemExpiredTypeAgain)),
      );
    }
  }

  /// 桌面式补全浮层的定位: 锚定光标, 优先显示在光标上方, 放不下落到下方
  Positioned? _buildCompletionPopup(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final caret = _caretRect;
    if (caret == null || _intelligence.suggestions.isEmpty) return null;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return null;
    const rowHeight = 40.0;
    const width = 300.0;
    final h = _intelligence.suggestions.length.clamp(1, 5) * rowHeight;
    final topLeft = box.globalToLocal(caret.topLeft);
    final left = (topLeft.dx - 12).clamp(
      8.0,
      (constraints.maxWidth - width - 8).clamp(8.0, double.infinity),
    );
    final caretBottom = box.globalToLocal(caret.bottomLeft).dy;
    var top = topLeft.dy - h - 6;
    if (top < 4) top = caretBottom + 6;
    top = top.clamp(
      4.0,
      (constraints.maxHeight - h - 4).clamp(4.0, double.infinity),
    );
    return Positioned(
      left: left,
      top: top,
      child: CompletionPopup(
        items: _intelligence.suggestions,
        selectedIndex: _intelligence.selected,
        onSelected: _applyCompletion,
        onDismiss: _dismissSuggestions,
      ),
    );
  }

  KeyEventResult _onEditorKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!_intelligence.canSuggest || _intelligence.suggestions.isEmpty) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _dismissSuggestions();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      _applyCompletion(_intelligence.suggestions[_intelligence.selected]);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final delta = event.logicalKey == LogicalKeyboardKey.arrowDown ? 1 : -1;
      _intelligence.moveSelection(delta);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _signatureView(SignatureHelp signature) {
    final start = signature.parameterStart;
    final end = signature.parameterEnd;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: AppColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text.rich(
          TextSpan(
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            children: start == null || end == null
                ? [TextSpan(text: signature.label)]
                : [
                    TextSpan(text: signature.label.substring(0, start)),
                    TextSpan(
                      text: signature.label.substring(start, end),
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: signature.label.substring(end)),
                  ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _editorFocus.removeListener(_onFocusChanged);
    _intelligence.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<AppearancePreferences>();
    return ListenableBuilder(
      listenable: _intelligence,
      builder: (context, _) => Focus(
        onKeyEvent: _onEditorKey,
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            children: [
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: PinchZoom(
                        onStart: _zoomStart,
                        onScale: _zoom,
                        onEnd: () => unawaited(_saveZoom()),
                        child: CodeField(
                          controller: _codeCtrl,
                          focusNode: _editorFocus,
                          language: _language,
                          filePath: widget.path,
                          onCaretChanged: (rect) {
                            if (mounted && rect != _caretRect) {
                              setState(() => _caretRect = rect);
                            }
                          },
                          fontSize: _zoomSize ?? preferences.editorSize,
                          wrap: preferences.editorWrap,
                        ),
                      ),
                    ),
                    if (_buildCompletionPopup(context, constraints)
                        case final popup?)
                      popup,
                  ],
                ),
              ),
              if (_intelligence.signature != null &&
                  constraints.maxHeight > 180)
                _signatureView(_intelligence.signature!),
            ],
          ),
        ),
      ),
    );
  }
}
