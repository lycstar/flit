import 'package:flutter/material.dart';
import 'package:flit_device/flit_device.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../features/settings/appearance_preferences.dart';

/// 首次初始化前说明后台运行用途；每项设置由用户分别打开。
class BackgroundAccess {
  static Future<void> explain(BuildContext context) async {
    final preferences = context.read<AppearancePreferences>();
    if (preferences.backgroundNoticeShown) return;
    Future<void> configure(Future<dynamic> Function() action) async {
      try {
        await action();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('无法打开设置，可稍后在系统应用设置中调整')));
        }
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('后台运行与通知'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('初始化、终端和构建可能需要较长时间。以下设置均为可选，暂不设置也可继续使用。'),
              const SizedBox(height: 16),
              const Text('任务通知仅显示通用运行状态，不展示项目名、代码、终端输出或登录凭据。'),
              // targetSdk 28 的通知弹窗时机由系统控制，使用系统设置入口。
              TextButton(
                onPressed: () => configure(openAppSettings),
                child: const Text('设置通知'),
              ),
              const SizedBox(height: 8),
              const Text('允许后台运行可减少切到后台后任务被中断，可能增加耗电。仅点击下方按钮后申请不受电池优化限制。'),
              TextButton(
                onPressed: () =>
                    configure(FlitDevice.requestIgnoreBatteryOptimizations),
                child: const Text('设置后台运行'),
              ),
              const SizedBox(height: 8),
              const Text('可稍后在系统应用设置中调整；文件访问权限会在使用相关功能时另行说明。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('暂不设置'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('继续初始化'),
          ),
        ],
      ),
    );
    try {
      await preferences.update(backgroundNoticeShown: true);
    } catch (_) {
      // 保存提示偏好失败不应阻止初始化。
    }
  }
}
