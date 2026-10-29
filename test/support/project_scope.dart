import 'package:flit/features/editor/workbench_layout.dart';
import 'package:flit/features/git/project_git.dart';
import 'package:flit/features/run/web_runner.dart';
import 'package:flit/features/terminal/run_sessions.dart';
import 'package:flit/features/workspace/project_scope.dart';
import 'package:flit/features/workspace/project_session.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// 完整工程走生产的 ProjectScope; 只测某个面板时, 按需提供它用到的那几个对象。
Widget scopedProject({
  required Widget child,
  ProjectSession? session,
  ProjectGit? git,
  WebRunController? web,
  RunSessions? executions,
  WorkbenchLayout? layout,
}) {
  if (session != null) {
    return ProjectScope(
      session: session,
      layout: layout ?? WorkbenchLayout(session.executions),
      child: child,
    );
  }
  final runs = executions ?? git?.executions ?? web!.executions;
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<WorkbenchLayout>.value(
        value: layout ?? WorkbenchLayout(runs),
      ),
      ChangeNotifierProvider<RunSessions>.value(value: runs),
      if (git != null) ChangeNotifierProvider<ProjectGit>.value(value: git),
      if (web != null)
        ChangeNotifierProvider<WebRunController>.value(value: web),
    ],
    child: child,
  );
}
