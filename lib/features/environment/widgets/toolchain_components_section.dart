import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../environment_controller.dart';
import '../installed_toolchain.dart';
import '../toolchain_catalog.dart';
import '../toolchain_component.dart';
import 'component_versions_sheet.dart';

/// 固定的组件入口只读取本地状态；滚动、重建、进入环境页均不请求版本目录。
class ToolchainComponentsSection extends StatelessWidget {
  const ToolchainComponentsSection({
    super.key,
    required this.environment,
    required this.catalog,
    required this.onInstall,
    required this.onChange,
  });

  final EnvironmentController environment;
  final ToolchainCatalog catalog;
  final Future<void> Function(CatalogEntry entry) onInstall;
  final Future<void> Function(InstalledToolchain tool, {bool delete}) onChange;

  @override
  Widget build(BuildContext context) {
    final env = environment;
    final initialized = env.stages['bootstrap']?.state == 'DONE';
    final known = env.installedLoaded && env.installedError == null;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '组件管理',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              env.installedError ??
                  (initialized
                      ? '按组件管理本地版本、下载与修复。SDK 整包仅用于初始化。'
                      : '先完成基础环境初始化，再按项目需要管理组件。'),
              style: TextStyle(
                fontSize: 12,
                color: env.installedError == null
                    ? AppColors.textSecondary
                    : AppColors.danger,
              ),
            ),
          ),
          for (final component in ToolchainComponent.all)
            Builder(
              builder: (context) {
                final local = component.installed(env.installed);
                final damaged = local.where((t) => !t.complete).length;
                final active = local.where((t) => t.active).firstOrNull;
                final installedSummary = local.length == 1
                    ? '${damaged == 0 ? '已安装' : '需修复'} · ${local.single.displayVersion}${active == null ? '' : ' · 当前'}'
                    : '${local.length} 个版本${active == null ? '' : ' · 当前 ${active.version}'}${damaged == 0 ? '' : ' · $damaged 个需修复'}';
                final status = !initialized
                    ? '初始化后可管理'
                    : env.checking
                    ? '正在检测…'
                    : !known
                    ? '安装状态待确认'
                    : local.isEmpty
                    ? '未安装'
                    : installedSummary;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    damaged > 0
                        ? Icons.error_outline
                        : known && local.isNotEmpty
                        ? Icons.check_circle_outline
                        : Icons.inventory_2_outlined,
                    size: 20,
                    color: !known
                        ? AppColors.textSecondary
                        : damaged > 0
                        ? AppColors.danger
                        : local.isNotEmpty
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                  title: Text(
                    component.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    status,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: !initialized
                      ? null
                      : () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => ComponentVersionsSheet(
                            component: component,
                            environment: env,
                            catalog: catalog,
                            onInstall: onInstall,
                            onChange: onChange,
                          ),
                        ),
                );
              },
            ),
        ],
      ),
    );
  }
}
