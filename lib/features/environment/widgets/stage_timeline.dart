import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../environment_controller.dart';

/// 竖向时间线: 连线+圆点表达阶段顺序与状态。
/// 行状态按 stageParts 聚合; 行下方平铺每个子任务一行(自带状态/版本/体积, 任何
/// 时刻都可见——卡在哪一步、哪一步失败一眼可辨)。重试入口只有顶部「继续安装」
/// (与行内按钮曾是同逻辑, 已收敛为一处)。
class StageTimeline extends StatelessWidget {
  const StageTimeline({super.key, required this.stages, required this.busy});

  final Map<String, StageState> stages;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (final (i, s) in stageDefs.indexed) _row(context, s, i),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, Map<String, String> s, int i) {
    final id = s['id'] as String;
    final state = _aggState(id);
    final dim = state == 'BLOCKED';
    final (icon, color, label) = switch (state) {
      'DONE' => (Icons.check_circle, AppColors.success, '完成'),
      'RUNNING' => (null, AppColors.accent, '安装中'),
      'FAILED' => (Icons.error, AppColors.danger, '失败'),
      'BLOCKED' => (
        Icons.remove_circle_outline,
        AppColors.textDisabled,
        '等待依赖',
      ),
      _ => (Icons.radio_button_unchecked, AppColors.textDisabled, '待安装'),
    };
    final hint = s['hint'] as String;
    final parts = stageParts[id]!;
    final single = parts.length == 1 && parts.single == id;
    // 单任务阶段就绪后副标题给版本/体积; 多子任务阶段的细节都在子任务行里
    final primary = stages[parts.last]!;
    final doneInfo = [
      primary.version,
      primary.size,
    ].whereType<String>().where((e) => e.isNotEmpty).join(' · ');
    final subtitle = single && state == 'DONE' && doneInfo.isNotEmpty
        ? doneInfo
        : hint;
    final partRows = [
      for (final part in parts)
        if (!hiddenParts.contains(part)) _partRow(part, stages[part]!),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 26,
              child: Column(
                children: [
                  _gutterLine(i == 0),
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: icon == null
                        ? Padding(
                            padding: const EdgeInsets.all(3),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: color,
                            ),
                          )
                        : Icon(icon, size: 20, color: color),
                  ),
                  // 连线贯穿子项区, 直到最后一行的圆点为止
                  _gutterLine(i == stageDefs.length - 1),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['title']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: dim
                          ? AppColors.textDisabled
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: dim ? AppColors.border : AppColors.textFaint,
                    ),
                  ),
                  ...partRows,
                ],
              ),
            ),
            _trailing(state, label, color, dim),
          ],
        ),
      ),
    );
  }

  /// 聚合可见阶段状态: 组件里最"忙"的说话(运行>失败>拉黑>混合待装>完成)
  String _aggState(String id) {
    final states = stageParts[id]!.map((p) => stages[p]!.state).toSet();
    if (states.contains('RUNNING')) return 'RUNNING';
    if (states.contains('FAILED')) return 'FAILED';
    if (states.contains('BLOCKED')) return 'BLOCKED';
    if (states.length == 1 && states.first == 'DONE') return 'DONE';
    return 'PENDING';
  }

  /// 子任务行: 小图标 + "编号 名称 · 版本 · 体积"(就绪) / "· 待安装|安装中|失败"
  Widget _partRow(String part, StageState ps) {
    final name = partNames[part] ?? part;
    final (icon, color) = switch (ps.state) {
      'DONE' => (Icons.check_circle, AppColors.success),
      'RUNNING' => (Icons.sync, AppColors.accent),
      'FAILED' => (Icons.error, AppColors.danger),
      'BLOCKED' => (Icons.remove_circle_outline, AppColors.textDisabled),
      _ => (Icons.radio_button_unchecked, AppColors.textDisabled),
    };
    final info = [
      ps.version,
      ps.size,
    ].whereType<String>().where((e) => e.isNotEmpty).join(' · ');
    final text = switch (ps.state) {
      'DONE' => info.isEmpty ? name : '$name · $info',
      'RUNNING' => '$name · 安装中',
      'FAILED' => '$name · 失败',
      'BLOCKED' => '$name · 等待前序步骤',
      _ => '$name · 待安装',
    };
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: ps.state == 'FAILED'
                    ? AppColors.danger
                    : ps.state == 'DONE'
                    ? AppColors.textSecondary
                    : AppColors.textFaint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 连线段; 首尾行外侧断开
  Widget _gutterLine(bool edge) => Expanded(
    child: Container(
      width: 2,
      color: edge ? Colors.transparent : AppColors.border,
    ),
  );

  Widget _trailing(String state, String label, Color color, bool dim) {
    // 重试入口只有顶部「继续安装」一个: 行内按钮与它同逻辑同效果, 两处入口反而含糊
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: dim ? AppColors.textDisabled : color,
      ),
    );
  }
}
