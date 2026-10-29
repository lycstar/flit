import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../../../core/theme.dart';

/// Markdown 渲染预览:内容取自编辑缓冲(未保存的也所见即所得),输入防抖 250ms。
/// 相对路径图片按工程根解析,围栏代码块套编辑器配色;文本可选中。
class MarkdownPreview extends StatefulWidget {
  const MarkdownPreview({
    super.key,
    required this.controller,
    required this.projectRoot,
  });

  final TextEditingController controller;
  final String projectRoot;

  @override
  State<MarkdownPreview> createState() => _MarkdownPreviewState();
}

class _MarkdownPreviewState extends State<MarkdownPreview> {
  static const _debounce = Duration(milliseconds: 250);

  late String _text = widget.controller.text;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_schedule);
  }

  @override
  void didUpdateWidget(covariant MarkdownPreview old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_schedule);
      widget.controller.addListener(_schedule);
      _render();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_schedule);
    _timer?.cancel();
    super.dispose();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(_debounce, _render);
  }

  void _render() {
    if (mounted) setState(() => _text = widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      height: 1.55,
      color: AppColors.textPrimary,
    );
    final style = MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: base,
      listBullet: base,
      h1: base?.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
      h2: base?.copyWith(fontSize: 19, fontWeight: FontWeight.w700),
      h3: base?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      h4: base?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      blockquote: base?.copyWith(color: AppColors.textSecondary),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.border, width: 3)),
        color: AppColors.surface.withValues(alpha: .5),
      ),
      code: AppColors.mono.copyWith(
        fontSize: 12.5,
        backgroundColor: AppColors.surface,
      ),
      codeblockDecoration: BoxDecoration(
        color: CodeTheme.current.gutterBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      a: base?.copyWith(
        color: AppColors.accent,
        decoration: TextDecoration.underline,
      ),
      tableBorder: TableBorder.all(color: AppColors.border),
      tableHead: base?.copyWith(fontWeight: FontWeight.w600),
    );
    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MarkdownBody(
          data: _text,
          styleSheet: style,
          builders: {'pre': _FencedCodeBlock()},
          imageBuilder: _image,
        ),
      ),
    );
  }

  /// 相对路径按工程根解析, http(s)/file 绝对路径按原样
  Widget _image(Uri uri, String? title, String? alt) {
    final placeholder = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        alt?.isEmpty == false ? alt! : uri.toString(),
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
    final src = Uri.decodeFull(uri.toString());
    final path = switch (uri.scheme) {
      'http' || 'https' => null,
      'file' => uri.toFilePath(),
      _ => src.startsWith('/') ? src : '${widget.projectRoot}/$src',
    };
    if (path == null) {
      return Image.network(
        src,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    return Image.file(
      File(path),
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

/// 围栏代码块:注册在 'pre' 标签上(块级),内容横向滚动
class _FencedCodeBlock extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = element.textContent;
    if (code.trim().isEmpty) return null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CodeTheme.current.gutterBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          code.replaceFirst(RegExp(r'\n$'), ''),
          style: AppColors.mono.copyWith(height: 1.5),
        ),
      ),
    );
  }
}
