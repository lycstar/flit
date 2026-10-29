import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../editor/lsp/lsp_client.dart';
import '../editor/workbench_layout.dart';
import '../git/project_git.dart';
import '../run/web_runner.dart';
import '../terminal/run_sessions.dart';
import 'editor_tabs.dart';
import 'project_actions.dart';
import 'project_documents.dart';
import 'project_files.dart';
import 'project_session.dart';

/// 把一个打开的工程及其子对象暴露给编辑器子树。对象都由 ProjectSession 持有
/// 并在关闭工程时释放, 这里一律 .value 提供、不负责 dispose。
/// [layout] 是本页的布局态, 随页面创建与销毁。
class ProjectScope extends StatelessWidget {
  const ProjectScope({
    super.key,
    required this.session,
    required this.layout,
    required this.child,
  });

  final ProjectSession session;
  final WorkbenchLayout layout;
  final Widget child;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider<ProjectSession>.value(value: session),
      ChangeNotifierProvider<ProjectDocuments>.value(value: session.documents),
      ChangeNotifierProvider<EditorTabs>.value(value: session.tabs),
      ChangeNotifierProvider<RunSessions>.value(value: session.executions),
      ChangeNotifierProvider<WebRunController>.value(value: session.web),
      ChangeNotifierProvider<ProjectGit>.value(value: session.git),
      ChangeNotifierProvider<ProjectActions>.value(value: session.actions),
      ChangeNotifierProvider<ProjectFiles>.value(value: session.files),
      Provider<LspClient>.value(value: session.language),
      ValueListenableProvider<LanguageServiceState>.value(
        value: session.language.state,
      ),
      ChangeNotifierProvider<WorkbenchLayout>.value(value: layout),
    ],
    child: child,
  );
}
