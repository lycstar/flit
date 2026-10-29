import 'package:flit_device/flit_device.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
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
import 'app_versions_page.dart';
import 'env_vars_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  String _environment = '检测中…';
  bool _proxySaving = false;
  PermissionStatus _notificationStatus = PermissionStatus.denied;
  bool? _ignoringBattery;

  /// 滑块拖动中的临时值; 松手写入偏好后清空, 偏好仍是唯一事实源
  double? _draggingTerminalSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _refreshPermissions();
    // 进页重探一次系统代理地址(开关状态随 AutoProxy 通知刷新)
    context.read<AutoProxy>().load().catchError(_showError);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 从系统设置授权返回时刷新权限状态
    if (state == AppLifecycleState.resumed) _refreshPermissions();
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

  /// 通知与电池优化状态来自方法通道; 测试环境没有 mock, 失败时静默保持占位
  Future<void> _refreshPermissions() async {
    try {
      final notification = await Permission.notification.status;
      final battery = await FlitDevice.isIgnoringBatteryOptimizations();
      if (mounted) {
        setState(() {
          _notificationStatus = notification;
          _ignoringBattery = battery;
        });
      }
    } catch (_) {
      /* 状态读取失败保持占位, 点按操作仍可用 */
    }
  }

  Future<void> _requestNotifications() async {
    // targetSdk 28 下系统不为通知权限的运行时请求弹授权框, 只能去系统通知设置开关
    try {
      await FlitDevice.openNotificationSettings();
    } catch (_) {
      // 个别 ROM 不认直达 intent 时退回应用详情页
      try {
        await openAppSettings();
      } catch (_) {
        _permissionError();
        return;
      }
    }
    await _refreshPermissions();
  }

  Future<void> _requestBattery() async {
    try {
      await FlitDevice.requestIgnoreBatteryOptimizations();
    } catch (_) {
      _permissionError();
      return;
    }
    await _refreshPermissions();
  }

  void _permissionError() {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法请求系统权限，可稍后在系统应用设置中调整')));
    }
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
          const SectionLabel('账户'),
          _card(const [GithubAccountTile()]),
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
          const SectionLabel('后台与通知'),
          _card([
            ListTile(
              leading: const Icon(Icons.task_alt, color: AppColors.accent),
              title: const Text('前台服务'),
              subtitle: const Text('常驻通知展示构建与任务的运行状态'),
              trailing: _notificationLabel(),
              onTap: _requestNotifications,
            ),
            ListTile(
              leading: const Icon(
                Icons.battery_saver_outlined,
                color: AppColors.accent,
              ),
              title: const Text('后台运行'),
              subtitle: const Text('忽略电池优化，减少切到后台后任务被中断'),
              trailing: _batteryLabel(),
              onTap: _requestBattery,
            ),
          ]),
          const SectionLabel('编辑器与终端'),
          _card([
            _link(
              Icons.code,
              '编辑器设置',
              '字体 · 配色方案 · 软换行',
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
          const SectionLabel('关于 Flit'),
          _card([
            ListTile(
              leading: const Icon(
                Icons.system_update_alt,
                color: AppColors.accent,
              ),
              title: const Text('App 更新'),
              subtitle: const Text('检查更新 · 下载安装历史版本'),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textFaint),
              onTap: () => _open(AppVersionsPage()),
            ),
            ListTile(
              title: const Text('构建提交'),
              subtitle: SelectableText(
                String.fromEnvironment(
                  'BUILD_SHA',
                  defaultValue: 'development',
                ),
                style: AppColors.mono,
              ),
            ),
            const ListTile(
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

  Widget _notificationLabel() => switch (_notificationStatus) {
    PermissionStatus.granted => _stateLabel('已开启', ok: true),
    PermissionStatus.permanentlyDenied => _stateLabel('已拒绝'),
    _ => _stateLabel('未开启'),
  };

  Widget _batteryLabel() => switch (_ignoringBattery) {
    true => _stateLabel('已允许', ok: true),
    false => _stateLabel('未设置'),
    _ => _stateLabel('检测中…'),
  };

  Widget _stateLabel(String text, {bool ok = false}) => Text(
    text,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: ok ? AppColors.accent : AppColors.textFaint,
    ),
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
