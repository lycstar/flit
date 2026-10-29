import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme.dart';

/// SVG 渲染预览:内容取自编辑缓冲(未保存即所见),输入防抖 250ms。
/// 解析失败原样提示,不崩溃;画布定高避免在滚动视图里无界扩张。
class SvgPreview extends StatefulWidget {
  const SvgPreview({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<SvgPreview> createState() => _SvgPreviewState();
}

class _SvgPreviewState extends State<SvgPreview> {
  static const _debounce = Duration(milliseconds: 250);

  late String _text = widget.controller.text;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_schedule);
  }

  @override
  void didUpdateWidget(covariant SvgPreview old) {
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            height: 320,
            width: double.infinity,
            child: _picture(),
          ),
          const SizedBox(height: 12),
          Text(
            'SVG 预览(内容来自编辑缓冲)',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _picture() {
    if (_text.trim().isEmpty) {
      return const Center(
        child: Text('空文件', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    // flutter_svg 对非法输入是宽松解析(渲染成空白), 前置一道明显非法的哨兵
    if (!_text.contains('<svg')) {
      return const Center(
        child: Text(
          '无法渲染该 SVG：内容不是有效的 SVG',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.danger),
        ),
      );
    }
    try {
      return SvgPicture.string(_text, fit: BoxFit.contain);
    } catch (error) {
      return Center(
        child: Text(
          '无法渲染该 SVG：$error',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.danger),
        ),
      );
    }
  }
}
