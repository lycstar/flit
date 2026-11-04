import 'package:flit/l10n/strings.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.strings.settingsAppliedButSavingFailedP(error),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<AppearancePreferences>();
    return Scaffold(
      appBar: AppBar(title: Text(context.strings.editorSettings)),
      body: PageList(
        children: [
          PageIntro(
            context.strings.editorOptions,
            context.strings.settingsSaveAutomaticallyPinchInTheCode,
          ),
          SectionLabel(context.strings.display),
          _card([
            SettingsSlider(
              title: context.strings.fontSize,
              value: _draggingSize ?? preferences.editorSize,
              min: AppearancePreferences.editorMinSize,
              max: AppearancePreferences.editorMaxSize,
              onChanged: (value) => setState(() => _draggingSize = value),
              onChangeEnd: (value) {
                setState(() => _draggingSize = null);
                _apply((p) => p.update(editor: value));
              },
            ),
            const Divider(height: 1),
            ListTile(
              title: Text(context.strings.font),
              subtitle: const Text(
                'JetBrains Mono',
                style: TextStyle(fontFamily: 'JetBrainsMono'),
              ),
              enabled: false,
              trailing: Text(
                context.strings.builtIn,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ]),
          SectionLabel(context.strings.colorScheme),
          _card([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'dark',
                      label: Text(context.strings.dark),
                    ),
                    ButtonSegment(
                      value: 'light',
                      label: Text(context.strings.light),
                    ),
                  ],
                  selected: {preferences.editorTheme},
                  onSelectionChanged: (s) =>
                      _apply((p) => p.update(theme: s.first)),
                ),
              ),
            ),
          ]),
          SectionLabel(context.strings.editing),
          _card([
            SwitchListTile(
              title: Text(context.strings.softWraps),
              subtitle: Text(
                preferences.editorWrap
                    ? context.strings.wrapLongLinesWithoutInsertingLineBreaks
                    : context
                          .strings
                          .scrollLongLinesHorizontallyLineNumbersStay,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              value: preferences.editorWrap,
              onChanged: (v) => _apply((p) => p.update(wrap: v)),
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
