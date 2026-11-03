import 'package:flit/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/page_layout.dart';
import '../../core/theme.dart';
import '../../services/shell.dart';

/// env -0 preserves values containing line breaks or '='.
List<(String, String)> parseEnvironment(String output) {
  final values = <(String, String)>[];
  for (final entry in output.split('\x00')) {
    final index = entry.indexOf('=');
    if (index > 0) {
      values.add((entry.substring(0, index), entry.substring(index + 1)));
    }
  }
  return values..sort((a, b) => a.$1.compareTo(b.$1));
}

class EnvVarsPage extends StatefulWidget {
  const EnvVarsPage({super.key});
  @override
  State<EnvVarsPage> createState() => _EnvVarsPageState();
}

class _EnvVarsPageState extends State<EnvVarsPage> {
  List<(String, String)> _vars = const [];
  bool _loading = true;
  String? _error;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Shell.instance.exec(
        '${terminalEnvSource}env -0',
        timeoutMs: 15000,
      );
      if (result['exitCode'] != 0) {
        throw StateError(
          strings.environmentCommandFailedExitCodeP(result['exitCode']),
        );
      }
      final values = parseEnvironment(result['output'] as String? ?? '');
      if (mounted) setState(() => _vars = values);
    } catch (error) {
      if (mounted) setState(() => _error = context.strings.readFailedP(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _filter.toLowerCase();
    final vars = _vars
        .where(
          (v) =>
              v.$1.toLowerCase().contains(query) ||
              v.$2.toLowerCase().contains(query),
        )
        .toList();
    const tools = {
      'JAVA_HOME',
      'ANDROID_HOME',
      'ANDROID_SDK_ROOT',
      'FLIT_TOOLCHAINS',
      'FLUTTER_ROOT',
      'GRADLE_USER_HOME',
    };
    const dirs = {'HOME', 'PREFIX', 'TMPDIR', 'PWD'};
    final toolVars = vars.where((v) => tools.contains(v.$1)).toList();
    final dirVars = vars.where((v) => dirs.contains(v.$1)).toList();
    final rest = vars
        .where(
          (v) =>
              !tools.contains(v.$1) && !dirs.contains(v.$1) && v.$1 != 'PATH',
        )
        .toList();
    final path = vars.where((v) => v.$1 == 'PATH').firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.strings.environmentVariables),
        actions: [
          IconButton(
            tooltip: context.strings.refreshSnapshot,
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: PageContent(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: TextField(
                onChanged: (value) => setState(() => _filter = value.trim()),
                decoration: InputDecoration(
                  hintText: context.strings.searchVariablesOrValues,
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        StatusNotice(_error!, error: true),
                        TextButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: Text(context.strings.retry),
                        ),
                      ],
                    )
                  : vars.isEmpty
                  ? Center(
                      child: Text(
                        context.strings.noMatchingVariables,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        if (query.isEmpty)
                          StatusNotice(
                            context
                                .strings
                                .readOnlyEnvironmentSnapshotForNewTasks,
                          ),
                        if (query.isNotEmpty) ...[
                          SectionLabel(
                            context.strings.searchResultsP(vars.length),
                          ),
                          _card(vars),
                        ] else ...[
                          if (toolVars.isNotEmpty) ...[
                            SectionLabel(context.strings.toolchains),
                            _card(toolVars),
                          ],
                          if (path != null) ...[
                            SectionLabel(
                              context.strings.pathCommandLookupOrder,
                            ),
                            SurfaceCard(
                              padding: EdgeInsets.zero,
                              child: ExpansionTile(
                                title: Text(context.strings.commandSearchPaths),
                                subtitle: Text(
                                  context.strings.pDirectoriesInLookupOrder(
                                    path.$2.split(':').length,
                                  ),
                                ),
                                children: [
                                  for (final (index, part)
                                      in path.$2.split(':').indexed)
                                    ListTile(
                                      leading: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: AppColors.textFaint,
                                        ),
                                      ),
                                      title: SelectableText(
                                        part.isEmpty
                                            ? context.strings.currentDirectory
                                            : part,
                                        style: AppColors.mono,
                                      ),
                                      trailing: _copy(part),
                                    ),
                                ],
                              ),
                            ),
                          ],
                          if (dirVars.isNotEmpty) ...[
                            SectionLabel(context.strings.directoriesAndCaches),
                            _card(dirVars),
                          ],
                          if (rest.isNotEmpty) ...[
                            SectionLabel(
                              context.strings.otherVariablesP(rest.length),
                            ),
                            _card(rest),
                          ],
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _copy(String value) => IconButton(
    tooltip: context.strings.copyValue,
    icon: const Icon(Icons.copy_outlined, size: 18),
    onPressed: () async {
      await Clipboard.setData(ClipboardData(text: value));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.strings.variableValueCopied)),
        );
      }
    },
  );

  Widget _card(List<(String, String)> values) => SurfaceCard(
    padding: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (final value in values)
          ExpansionTile(
            key: ValueKey(value.$1),
            title: Text(value.$1, style: AppColors.mono),
            subtitle: Text(
              value.$2.isEmpty ? context.strings.empty : value.$2,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SelectableText(
                        value.$2.isEmpty ? context.strings.empty : value.$2,
                        style: AppColors.mono,
                      ),
                    ),
                    _copy(value.$2),
                  ],
                ),
              ),
            ],
          ),
      ],
    ),
  );
}
