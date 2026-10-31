import 'dart:async';

import 'package:flit_device/flit_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/page_layout.dart';
import '../../core/theme.dart';
import '../../services/shell.dart';

/// 离线可读的通知配对教程，按 Flit 的实际流程改写 Shizuku 的使用说明。
/// 阅读不启动服务；明确开始后返回 true，由设备页先启动服务再打开系统设置。
/// 从系统设置返回时重新读取权限，不把厂商通知样式误判成可自动检测的权限。
class DevicePairingGuidePage extends StatefulWidget {
  const DevicePairingGuidePage({super.key, this.allowStart = true});
  final bool allowStart;

  @override
  State<DevicePairingGuidePage> createState() => _DevicePairingGuidePageState();
}

class _DevicePairingGuidePageState extends State<DevicePairingGuidePage>
    with WidgetsBindingObserver {
  bool? _supported;
  bool? _notifications;
  bool _checking = true;
  String? _error;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_check());
  }

  @override
  void dispose() {
    ++_revision;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _check() async {
    final revision = ++_revision;
    setState(() => _checking = true);
    try {
      final result = await FlitDevice.pairingReadiness();
      if (result['supported'] is! bool ||
          result['notificationsEnabled'] is! bool) {
        throw StateError('无法读取通知状态');
      }
      if (!mounted || revision != _revision) return;
      setState(() {
        _supported = result['supported'] as bool;
        _notifications = result['notificationsEnabled'] as bool;
        _error = null;
      });
    } catch (_) {
      if (!mounted || revision != _revision) return;
      setState(() {
        _supported = null;
        _notifications = null;
        _error = '无法读取通知状态，请重试';
      });
    } finally {
      if (mounted && revision == _revision) setState(() => _checking = false);
    }
  }

  Future<void> _open(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is PlatformException
            ? error.message ?? '无法打开系统设置'
            : '无法打开，请稍后重试',
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('无线配对指南')),
    body: PageList(
      children: [
        const PageIntro('在通知中输入配对码', 'Android 11 及以上 · 手机需连接 Wi-Fi'),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _checking
                    ? '正在检查通知权限…'
                    : _supported == false
                    ? '此系统不支持无线配对'
                    : _notifications == true
                    ? '配对通知已开启'
                    : _notifications == false
                    ? '请先允许 Flit 通知'
                    : '通知状态未知',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                _supported == false
                    ? '无线配对需要 Android 11 或以上，可返回使用电脑 USB 激活。'
                    : '允许 Flit 发布通知；若已有“无线调试配对”通知类别，也要开启。配对时从通知里输入代码。',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
              if (_checking) const LinearProgressIndicator(minHeight: 2),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => _open(FlitDevice.openNotificationSettings),
                    child: const Text('通知设置'),
                  ),
                  TextButton(
                    onPressed: _checking ? null : _check,
                    child: const Text('重新检查'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          StatusNotice(_error!, error: true),
        ],
        const SizedBox(height: 12),
        const StatusNotice(
          '小米 / POCO：部分 MIUI 需要把通知样式改为“原生样式”，否则可能无法输入配对码。具体路径见下方说明。',
        ),
        if (!widget.allowStart) ...[
          const SizedBox(height: 12),
          const StatusNotice('请先在设备页结束当前操作，或安装缺失的 ADB，再开始配对。'),
        ],
        const SizedBox(height: 20),
        _step(
          '1',
          '开始配对',
          '点击下方“开始配对”，Flit 会先启动配对通知，再打开开发者选项。首次使用请先开启开发者选项和 USB 调试。',
        ),
        _step(
          '2',
          '打开配对码窗口',
          '开启“无线调试”，点击这项的文字进入详情，再点“使用配对码配对设备”。保持显示 6 位代码的窗口打开。',
          note: '仅打开右侧开关还不够，需要进入无线调试详情页。',
        ),
        _step(
          '3',
          '下拉通知，输入 6 位码',
          '展开 Flit 的配对通知，点击“输入配对码”，填入系统窗口中的代码并发送。不要切回 Flit 填写，切换应用可能关闭配对窗口。',
          note: '找到配对端口后，通知才会出现“输入配对码”按钮。',
        ),
        _step(
          '4',
          '返回 Flit 连接',
          '通知提示配对成功后返回 Flit，会自动尝试连接本机。已配对时直接“扫描并连接”；重新开启无线调试后，连接端口可能改变。',
        ),
        SurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _help('通知里没有输入框 / 点输入就失败', [
                const Text('先展开通知，确认已显示“输入配对码”。若仍停留在“搜索端口”，请看下一项。'),
                const SizedBox(height: 10),
                const Text(
                  '小米、Redmi、POCO 的部分 MIUI：在系统设置 → 通知管理 → 通知显示设置，将通知样式切为“原生样式”，再重新配对。',
                ),
                const SizedBox(height: 10),
                const Text(
                  'HyperOS 或其他版本的入口、名称可能不同；如提供“Android”或“原生”通知样式，可尝试切换。Flit 无法自动检测或修改此设置。',
                ),
                const SizedBox(height: 10),
                const Text('找不到该选项时，可用分屏保留系统配对窗口，在“手动连接 / 其他设备”输入配对端口和配对码。'),
              ]),
              _help('一直搜索端口 / 切到设置后没反应', [
                const Text(
                  '确认 Wi-Fi 和无线调试已开启，并保持“使用配对码配对设备”窗口打开。配对端口只在这个窗口打开时广播。',
                ),
                const SizedBox(height: 10),
                const Text(
                  '部分系统会限制不可见应用的本地网络访问。允许 Flit 后台运行，并在系统的联网管理中允许 Wi-Fi / 本地网络访问（如提供）。',
                ),
                TextButton(
                  onPressed: () => _open(() async {
                    await FlitDevice.requestIgnoreBatteryOptimizations();
                  }),
                  child: const Text('允许后台运行'),
                ),
                const Text(
                  '仍无结果可重新开关无线调试后再试。Flit 最多搜索 3 分钟；超时后重新开始，也可改用电脑 USB 激活。',
                ),
              ]),
              _help('配对成功，但连接失败', [
                const Text('配对端口与连接端口不同。手动连接时，请使用无线调试主页显示的连接端口，不要使用配对码窗口的端口。'),
                const SizedBox(height: 10),
                const Text(
                  '返回设备页点“扫描并连接”。仍找不到端口时，可以手动输入连接端口，或使用电脑 USB 激活。配对记录不代表设备当前在线。',
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => _open(() async {
            if (!await Shell.instance.openUrl(
              'https://shizuku.rikka.app/zh-hans/guide/setup/',
            )) {
              throw StateError('无法打开参考页面');
            }
          }),
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('参考：Shizuku 使用指南'),
        ),
      ],
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed:
              widget.allowStart &&
                  !_checking &&
                  _supported == true &&
                  _notifications == true
              ? () => Navigator.pop(context, true)
              : null,
          icon: const Icon(Icons.notifications_active_outlined, size: 18),
          label: const Text('开始配对'),
        ),
      ),
    ),
  );

  Widget _step(String number, String title, String text, {String? note}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.accent.withValues(alpha: .12),
              child: Text(
                number,
                style: const TextStyle(color: AppColors.accent, fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (note != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      note,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget _help(String title, List<Widget> children) => ExpansionTile(
    title: Text(title, style: const TextStyle(fontSize: 13)),
    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    children: [
      DefaultTextStyle(
        style: const TextStyle(
          fontSize: 13,
          height: 1.6,
          color: AppColors.textSecondary,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    ],
  );
}
