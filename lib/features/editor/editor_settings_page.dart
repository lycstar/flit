import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/page_layout.dart';
import '../settings/appearance_preferences.dart';

/// 编辑器设置: 字体字号 / 主题(dark·light) / 换行策略。
/// 页面直接读写 AppearancePreferences, 它是唯一事实源(编辑器同样监听它)。
class EditorSettingsPage extends StatefulWidget {
  const EditorSettingsPage({super.key});

  @override
  State<EditorSettingsPage> createState() => _EditorSettingsPageState();
}

class _EditorSettingsPageState extends State<EditorSettingsPage> {
  /// 滑块拖动中的临时值; 松手写入偏好后清空
  double? _draggingSize;

  Future<void> _apply(
    Future<void> Function(AppearancePreferences) change,
  ) async {
    try {
      await change(context.read<AppearancePreferences>());
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('设置已应用，但保存失败：$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<AppearancePreferences>();
    return Scaffold(
      appBar: AppBar(title: const Text('编辑器设置')),
      body: PageList(
        children: [
          const PageIntro('编辑器选项', '设置自动保存并应用到编辑器。'),
          const SectionLabel('显示'),
          _card([
            SettingsSlider(
              title: '字号',
              value: _draggingSize ?? preferences.editorSize,
              min: 12,
              max: 20,
              onChanged: (value) => setState(() => _draggingSize = value),
              onChangeEnd: (value) {
                setState(() => _draggingSize = null);
                _apply((p) => p.update(editor: value));
              },
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text('字体'),
              subtitle: const Text(
                'JetBrains Mono',
                style: TextStyle(fontFamily: 'JetBrainsMono'),
              ),
              enabled: false,
              trailing: const Text(
                '内置',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ]),
          const SectionLabel('配色方案'),
          _card([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'dark', label: Text('深色')),
                    ButtonSegment(value: 'light', label: Text('浅色')),
                  ],
                  selected: {preferences.editorTheme},
                  onSelectionChanged: (s) =>
                      _apply((p) => p.update(theme: s.first)),
                ),
              ),
            ),
          ]),
          const SectionLabel('编辑行为'),
          _card([
            SwitchListTile(
              title: const Text('软换行'),
              subtitle: Text(
                preferences.editorWrap ? '长行自动折行显示，不插入换行符' : '长行横向滚动，行号保持可见',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              value: preferences.editorWrap,
              onChanged: (v) => _apply((p) => p.update(wrap: v)),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('代码键盘'),
              subtitle: Text(
                preferences.editorCodeKeys ? '使用内置代码键盘，不显示系统键盘' : '使用系统键盘',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              value: preferences.editorCodeKeys,
              onChanged: (v) => _apply((p) => p.update(codeKeys: v)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }
}
