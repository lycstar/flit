import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/background_access.dart';
import '../editor/editor_page.dart';
import '../environment/environment_page.dart';
import '../environment/environment_controller.dart';
import '../environment/environment_status.dart';
import '../settings/settings_page.dart';
import '../workspace/project_session.dart';
import 'projects_page.dart';

/// 根路由: 工作台(项目列表)为主页面;
/// 环境未就绪时首次自动进开发环境页(可关闭, 随时从设置/首页横幅重进)。
class WorkbenchPage extends StatefulWidget {
  const WorkbenchPage({super.key});

  @override
  State<WorkbenchPage> createState() => _WorkbenchPageState();
}

class _WorkbenchPageState extends State<WorkbenchPage> {
  bool? _bootstrapped;
  bool _autoOpened = false;

  @override
  void initState() {
    super.initState();
    _probeReady()
        .then((ready) {
          if (!mounted) return;
          setState(() => _bootstrapped = ready);
          if (!ready) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_autoOpened) {
                _autoOpened = true;
                _initialize();
              }
            });
          }
        })
        .catchError((_) {
          if (!mounted) return;
          setState(() => _bootstrapped = false);
        });
  }

  Future<void> _initialize() async {
    await BackgroundAccess.explain(context);
    if (mounted) await _openEnvironment();
  }

  Future<void> _openEnvironment() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const EnvironmentPage()));
    await _refreshReady(); // 装完返回后重新探测, 不能沿用启动时的旧状态
  }

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
    await _refreshReady(); // 设置里也能进开发环境页完成安装
  }

  Future<void> _refreshReady() async {
    try {
      final ready = await _probeReady();
      if (!mounted) return;
      setState(() => _bootstrapped = ready);
    } catch (_) {}
  }

  Future<bool> _probeReady() async => (await EnvironmentStatus.inspect()).ready;

  @override
  Widget build(BuildContext context) {
    return ProjectsPage(
      environmentReady: _bootstrapped == true,
      environmentChecking: _bootstrapped == null,
      onOpenProject: (path) async {
        try {
          if (context.read<EnvironmentController>().installing) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('工具链正在安装，请完成后再打开项目')));
            return;
          }
          final project = await context.read<ProjectWorkspace>().open(path);
          if (!mounted) return;
          await Navigator.of(this.context).push(
            MaterialPageRoute(
              builder: (_) => EditorPage(
                projectPath: path,
                projectName: project.name,
                session: project,
              ),
            ),
          );
          if (mounted) setState(() {});
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(
              this.context,
            ).showSnackBar(SnackBar(content: Text('$error')));
          }
        }
      },
      onOpenEnvironment: _openEnvironment,
      onOpenSettings: _openSettings,
    );
  }
}
