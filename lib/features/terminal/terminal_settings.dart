import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/page_layout.dart';
import '../../core/theme.dart';
import '../settings/appearance_preferences.dart';
import 'terminal_theme.dart';

class TerminalSettingsPage extends StatelessWidget {
  const TerminalSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('终端设置')),
    body: const PageList(
      children: [
        PageIntro('终端外观', '所有终端共用设置，自动保存。也可在终端内容区双指缩放。'),
        TerminalAppearanceSettings(),
      ],
    ),
  );
}

/// 设置页、编辑器设置与终端快捷面板复用同一表单；拖动只更新预览，松手保存。
class TerminalAppearanceSettings extends StatefulWidget {
  const TerminalAppearanceSettings({super.key});
  @override
  State<TerminalAppearanceSettings> createState() =>
      _TerminalAppearanceSettingsState();
}

class _TerminalAppearanceSettingsState
    extends State<TerminalAppearanceSettings> {
  double? _size;
  double? _height;

  Future<void> _apply({double? size, double? height, String? font}) async {
    try {
      await context.read<AppearancePreferences>().update(
        terminal: size,
        terminalLineHeight: height,
        terminalFont: font,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('设置已应用，但保存失败：$error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _size = null;
          _height = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<AppearancePreferences>();
    final size = _size ?? preferences.terminalSize;
    final height = _height ?? preferences.terminalLineHeight;
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                const Expanded(child: Text('终端字号')),
                IconButton(
                  tooltip: '缩小终端字号',
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: size <= AppearancePreferences.terminalMinSize
                      ? null
                      : () => _apply(size: size - 1),
                ),
                Text(
                  size.toStringAsFixed(size == size.roundToDouble() ? 0 : 1),
                ),
                IconButton(
                  tooltip: '放大终端字号',
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: size >= AppearancePreferences.terminalMaxSize
                      ? null
                      : () => _apply(size: size + 1),
                ),
              ],
            ),
          ),
          Slider(
            value: size,
            min: AppearancePreferences.terminalMinSize,
            max: AppearancePreferences.terminalMaxSize,
            divisions: 38,
            onChanged: (v) => setState(() => _size = v),
            onChangeEnd: (v) => _apply(size: v),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              key: ValueKey(preferences.terminalFont),
              isExpanded: true,
              initialValue: preferences.terminalFont,
              decoration: const InputDecoration(labelText: '等宽字体'),
              items: [
                for (final font in AppearancePreferences.terminalFonts.entries)
                  DropdownMenuItem(
                    value: font.key,
                    child: Text(
                      font.value,
                      style: TextStyle(fontFamily: font.key),
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) _apply(font: value);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(child: Text('行高')),
                Text('${height.toStringAsFixed(1)} 倍'),
              ],
            ),
          ),
          Slider(
            value: height,
            min: 1,
            max: 2,
            divisions: 10,
            onChanged: (v) => setState(() => _height = v),
            onChangeEnd: (v) => _apply(height: v),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: flitTerminalTheme.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                'flit ~ \$ flutter build apk\n✓ 构建完成  Build complete\n0123456789  []{} <> !=',
                style: flitTerminalStyle
                    .copyWith(
                      fontSize: size,
                      height: height,
                      fontFamily: preferences.terminalFont,
                    )
                    .toTextStyle(color: flitTerminalTheme.foreground),
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                _apply(size: 13, height: 1.2, font: 'JetBrainsMono'),
            child: const Text('恢复终端默认外观'),
          ),
        ],
      ),
    );
  }
}
