import 'package:flutter/material.dart';
import 'package:flit_device/flit_device.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../features/settings/appearance_preferences.dart';

/// 首次初始化前说明后台运行用途；每项设置都在对话框内直接发起。
/// 权限入口与设置页共用，拒绝后可在设置页再次调整。
class BackgroundAccess {
  static Future<void> explain(BuildContext context) async {
    final preferences = context.read<AppearancePreferences>();
    if (preferences.backgroundNoticeShown) return;

    await showDialog<void>(
      context: context,
      builder: (_) => const _BackgroundSetupDialog(),
    );
    try {
      await preferences.update(backgroundNoticeShown: true);
    } catch (_) {
      // 保存提示偏好失败不应阻止初始化。
    }
  }
}

/// 初始化前置说明：描边按钮就地发起，结果回显在按钮上，避免"点了没反应"。
class _BackgroundSetupDialog extends StatefulWidget {
  const _BackgroundSetupDialog();

  @override
  State<_BackgroundSetupDialog> createState() => _BackgroundSetupDialogState();
}

class _BackgroundSetupDialogState extends State<_BackgroundSetupDialog>
    with WidgetsBindingObserver {
  /// null = 未知(通道不可用或检测中)，按钮保持可点
  bool? _foregroundAllowed;
  bool? _batteryAllowed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 从系统通知设置开关后返回时刷新按钮状态
    if (state == AppLifecycleState.resumed) _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final notification = await Permission.notification.status;
      final battery = await FlitDevice.isIgnoringBatteryOptimizations();
      if (mounted) {
        setState(() {
          _foregroundAllowed = notification.isGranted;
          _batteryAllowed = battery;
        });
      }
    } catch (_) {
      /* 测试环境没有通道 mock，保持未知态 */
    }
  }

  Future<void> _openNotificationSettings() async {
    try {
      await FlitDevice.openNotificationSettings();
    } catch (_) {
      // 个别 ROM 不认通知设置直达 intent 时, 退回应用详情页
      try {
        await openAppSettings();
      } catch (_) {
        /* 两级都失败保持原状态, 用户仍可从系统应用信息进入 */
      }
    }
  }

  Future<void> _requestBattery() async {
    try {
      final allowed = await FlitDevice.requestIgnoreBatteryOptimizations();
      if (mounted) setState(() => _batteryAllowed = allowed);
    } catch (_) {
      /* 请求失败保持原状态，可再点 */
    }
  }

  @override
  Widget build(BuildContext context) {
    final caption = Theme.of(context).textTheme.bodySmall;
    return AlertDialog(
      title: const Text('后台运行与通知'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('初始化和构建可能耗时较长，建议开启：'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _foregroundAllowed == true
                      ? null
                      : _openNotificationSettings,
                  icon: Icon(
                    _foregroundAllowed == true ? Icons.check : Icons.task_alt,
                    size: 18,
                  ),
                  label: Text(_foregroundAllowed == true ? '已开启' : '前台服务'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _batteryAllowed == true ? null : _requestBattery,
                  icon: Icon(
                    _batteryAllowed == true
                        ? Icons.check
                        : Icons.battery_saver_outlined,
                    size: 18,
                  ),
                  label: Text(_batteryAllowed == true ? '已允许' : '后台运行'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('前台服务仅显示通用运行状态，开关在系统通知设置中，可稍后在「设置 → 后台与通知」里再调。', style: caption),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('继续'),
        ),
      ],
    );
  }
}
