import 'package:flit/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../terminal/pty_session.dart';
import '../workspace/project_session.dart';
import '../../core/page_layout.dart';
import '../environment/environment_controller.dart';
import '../environment/widgets/stage_timeline.dart';
import '../environment/toolchain_catalog.dart';
import 'widgets/toolchain_components_section.dart';
import '../settings/settings_page.dart';
import '../terminal/terminal_host.dart';
import '../terminal/terminal_side_pane.dart';

/// 开发环境页: 一切执行与显示都走专用终端——
/// 进入即跑 check.sh(可见探测过程), 安装阶段在终端里实时执行;
/// 上方只保留状态摘要与阶段时间线, 不再有第二套日志视图。
class EnvironmentPage extends StatefulWidget {
  const EnvironmentPage({super.key});

  @override
  State<EnvironmentPage> createState() => _EnvironmentPageState();
}

class _EnvironmentPageState extends State<EnvironmentPage> {
  bool _termCollapsed = true;

  Future<bool> _prepareToolchainChange(BuildContext context) async {
    if (context.read<ProjectWorkspace>().active != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.strings.closeTheProjectBeforeChangingSdksOr),
        ),
      );
      return false;
    }
    await context.read<PtySession>().stop();
    return true;
  }

  @override
  void initState() {
    super.initState();
    // 任务属于应用（离开页面继续跑）；再次进入只复查本地状态。
    context.read<EnvironmentController>().refreshOnOpen();
  }

  @override
  Widget build(BuildContext context) {
    final env = context.watch<EnvironmentController>();
    return PopScope(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: context.strings.back,
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(context.strings.developmentEnvironment),
          // 工具条直出 icon button, 不藏菜单; 停止/清空属于终端会话, 由终端头部固定提供
          actions: [
            IconButton(
              tooltip: context.strings.checkAgain,
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: env.busy ? null : () => env.refreshStatus(),
            ),
            IconButton(
              tooltip: context.strings.networkCheck,
              icon: const Icon(Icons.network_check, size: 20),
              onPressed: env.busy ? null : () => env.probeNetwork(),
            ),
            IconButton(
              tooltip: context.strings.proxySettings,
              icon: const Icon(Icons.settings_outlined, size: 20),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, screen) {
            // 与其他页统一: 内容边距收到 ListView 一处, 卡片不再各自为政
            final checklist = PageList(
              children: [
                PageIntro(
                  context.strings.sdksAndToolchains,
                  context.strings.manageSdksAndBuildToolsViewInstallation,
                ),
                _summaryCard(env),
                const SizedBox(height: 12),
                if (env.allDone)
                  ExpansionTile(
                    key: const PageStorageKey('environment-setup-details'),
                    title: Text(
                      context.strings.setupDetails,
                      style: TextStyle(fontSize: 13),
                    ),
                    children: [
                      StageTimeline(stages: env.stages, busy: env.busy),
                    ],
                  )
                else
                  StageTimeline(stages: env.stages, busy: env.busy),
                const SizedBox(height: 12),
                ToolchainComponentsSection(
                  environment: env,
                  catalog: context.read<ToolchainCatalog>(),
                  onChange: (tool, {bool delete = false}) async {
                    if (!await _prepareToolchainChange(context)) return;
                    await env.changeInstalled(tool, delete: delete);
                  },
                  onInstall: (entry) async {
                    if (!await _prepareToolchainChange(context)) return;
                    await env.installFromCatalog(entry);
                  },
                ),
              ],
            );
            // 平板/横屏大屏: 清单与终端并排, 边装边看输出
            if (screen.maxWidth >= 840) {
              return Row(
                children: [
                  Expanded(child: checklist),
                  TerminalSidePane(session: env.console, running: env.busy),
                ],
              );
            }
            return TerminalHost(
              session: env.console,
              expanded: !_termCollapsed,
              onToggle: () => setState(() => _termCollapsed = !_termCollapsed),
              running: env.busy,
              preferredHeight: 340,
              hideContentWithKeyboard: true,
              child: checklist,
            );
          },
        ),
      ),
    );
  }

  Widget _summaryCard(EnvironmentController env) {
    // 计数按可见阶段聚合(如 Android 行 = jdk + android_sdk 两个组件全 DONE)
    final done = stageDefs
        .where(
          (s) => stageParts[s['id'] as String]!.every(
            (p) => env.stages[p]!.state == 'DONE',
          ),
        )
        .length;
    final failed = env.stages.values.where((s) => s.state == 'FAILED').length;
    final running = env.stages.values.firstWhere(
      (s) => s.state == 'RUNNING',
      orElse: () => StageState(),
    );
    final title = env.checking
        ? context.strings.checkingEnvironment
        : env.installing
        ? context.strings.managingToolchains
        : env.allDone
        ? context.strings.environmentReady
        : env.pipelineRunning
        ? context.strings.installingComponents
        : failed > 0
        ? context.strings.installationFailed
        : context.strings.environmentNotReady;
    final subtitle = env.checking
        ? context.strings.checkingLocalComponentsPleaseWait
        : env.installing
        ? context.strings.seeTerminalForDetails
        : env.allDone
        ? context.strings.componentsReadyYouCanCreateProjectsAnd
        : running.state == 'RUNNING'
        ? context.strings.seeTerminalForDetails
        : context.strings.pPReady(done, stageDefs.length);
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                env.allDone ? Icons.check_circle : Icons.tune,
                size: 20,
                color: env.allDone ? AppColors.success : AppColors.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (env.busy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (!env.busy)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: env.allDone
                    ? () => Navigator.of(context).pop()
                    : () async {
                        if (!await _prepareToolchainChange(context)) return;
                        await env.startPipeline();
                      },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(
                  env.allDone
                      ? context.strings.done
                      : done > 0
                      ? context.strings.resumeInstallation
                      : context.strings.startInstallation,
                ),
              ),
            ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: env.allDone ? 1 : done / stageDefs.length,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
          // 网络通路探测结果(菜单里手动触发, 有结果才显示)
          if (env.netPaths.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              context.strings.networkP(
                env.netPaths.entries
                    .map((e) {
                      final t = double.tryParse(e.value.detail.split('|').last);
                      return '${e.key} ${e.value.ok ? '✓ ${t?.toStringAsFixed(2) ?? "?"}s' : context.strings.requestFailed}';
                    })
                    .join(' · '),
              ),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
