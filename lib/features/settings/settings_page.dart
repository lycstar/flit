import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../git/github_account_tile.dart';
import '../../core/page_layout.dart';
import '../../core/theme.dart';
import '../../services/auto_proxy.dart';
import '../environment/environment_status.dart';
import '../device/device_connect_page.dart';
import '../editor/editor_settings_page.dart';
import '../environment/environment_page.dart';
import 'appearance_preferences.dart';
import 'env_vars_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _environment = '检测中…';
  bool _proxySaving = false;

  /// 滑块拖动中的临时值; 松手写入偏好后清空, 偏好仍是唯一事实源
  double? _draggingTerminalSize;

  @override
  void initState() {
    super.initState();
    _refresh();
    // 进页重探一次系统代理地址(开关状态随 AutoProxy 通知刷新)
    context.read<AutoProxy>().load().catchError(_showError);
  }

  void _showError(Object error) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('设置保存或读取失败：$error')));
    }
  }

  Future<void> _refresh() async {
    final status = await EnvironmentStatus.inspect();
    if (mounted) setState(() => _environment = status.label);
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted && page is EnvironmentPage) _refresh();
  }

  Future<void> _setProxy(bool value) async {
    setState(() => _proxySaving = true);
    try {
      await context.read<AutoProxy>().setEnabled(value);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('代理设置已更新，新终端和任务生效')));
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _proxySaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final proxy = context.watch<AutoProxy>();
    final preferences = context.watch<AppearancePreferences>();
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: PageList(
        children: [
          const PageIntro('IDE 设置', '配置开发环境、设备连接和编辑器选项。'),
          const SectionLabel('开发环境'),
          _card([
            _link(
              Icons.layers_outlined,
              '开发环境',
              _environment,
              const EnvironmentPage(),
            ),
            _link(
              Icons.data_object,
              '环境变量',
              '查看工具链路径与命令环境快照',
              const EnvVarsPage(),
            ),
            _link(
              Icons.phonelink_setup,
              '连接设备',
              '无线调试 · 配对与认证状态',
              const DeviceConnectPage(),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.swap_vert, color: AppColors.accent),
              title: const Text('跟随系统代理'),
              subtitle: Text(proxy.address ?? '未检测到系统代理；检测到后自动使用'),
              value: proxy.enabled,
              onChanged: _proxySaving ? null : _setProxy,
            ),
          ]),
          const SectionLabel('编辑器与终端'),
          _card([
            _link(
              Icons.code,
              '编辑器设置',
              '字体 · 配色方案 · 软换行 · 代码键盘',
              const EditorSettingsPage(),
            ),
            SettingsSlider(
              title: '终端字号',
              value: _draggingTerminalSize ?? preferences.terminalSize,
              min: 11,
              max: 20,
              onChanged: (value) =>
                  setState(() => _draggingTerminalSize = value),
              onChangeEnd: (value) {
                setState(() => _draggingTerminalSize = null);
                preferences.update(terminal: value).catchError(_showError);
              },
            ),
          ]),
          const SectionLabel('账户'),
          _card(const [GithubAccountTile()]),
          const SectionLabel('关于 Flit'),
          _card(const [
            ListTile(
              title: Text('构建提交'),
              subtitle: SelectableText(
                String.fromEnvironment(
                  'BUILD_SHA',
                  defaultValue: 'development',
                ),
                style: AppColors.mono,
              ),
            ),
            ListTile(
              title: Text('运行平台'),
              subtitle: Text('Android · arm64-v8a'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _link(IconData icon, String title, String subtitle, Widget page) =>
      ListTile(
        leading: Icon(icon, color: AppColors.accent),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textFaint),
        onTap: () => _open(page),
      );

  Widget _card(List<Widget> children) => SurfaceCard(
    padding: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
          children[i],
        ],
      ],
    ),
  );
}
