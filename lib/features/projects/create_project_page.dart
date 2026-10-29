import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/page_layout.dart';
import '../../services/shell.dart';

/// 新建项目参数(页面 → 工作台的返回值)
class CreateProjectParams {
  const CreateProjectParams({
    required this.type,
    required this.name,
    required this.org,
    required this.platforms,
    required this.empty,
    required this.androidLang,
    required this.description,
    required this.projectRoot,
    this.template = 'console',
  });

  final String type; // flutter | dart
  final String name;
  final String org;
  final List<String> platforms;
  final bool empty;
  final String androidLang; // kotlin | java
  final String description;
  final String projectRoot;
  final String template; // dart create 模板(console/package/server/web)
}

/// 组装 dart create 命令(纯 Dart 项目, console 模板可 dart run)。
/// --no-pub: 像 AS 一样把"生成文件"和"解析依赖"分开——前者瞬时、不联网, 退出 0
/// 即项目已存在; pub get 交给打开工程后的「获取依赖」任务, 中断也不会留下半成品。
String buildDartCreateCommand(CreateProjectParams p) {
  return "mkdir -p ${shQuote(p.projectRoot)} && cd ${shQuote(p.projectRoot)} && "
      "dart create --no-pub --template ${shQuote(p.template)} ${shQuote(p.name)}";
}

String buildFlutterCreateCommand(CreateProjectParams p) {
  final flags = <String>[
    '--platforms=${p.platforms.join(',')}',
    '--org ${shQuote(p.org)}',
    if (p.empty) '--empty',
    if (p.platforms.contains('android') && p.androidLang == 'java') '-a java',
  ];
  final desc = p.description.trim();
  if (desc.isNotEmpty) flags.add('--description ${shQuote(desc)}');
  return "mkdir -p ${shQuote(p.projectRoot)} && cd ${shQuote(p.projectRoot)} && "
      "flutter create --no-pub ${flags.join(' ')} ${shQuote(p.name)}";
}

/// dart 保留字/系统保留名: 用作包名会直接编译炸, 提前拦
const _reservedNames = {
  'flutter', 'dart', 'test', 'example', //
  'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch',
  'class', 'const', 'continue', 'default', 'do', 'dynamic', 'else', 'enum',
  'export', 'extends', 'extension', 'external', 'factory', 'false', 'final',
  'finally', 'for', 'get', 'if', 'implements', 'import', 'in', 'interface',
  'is', 'library', 'mixin', 'new', 'null', 'on', 'operator', 'part',
  'required', 'rethrow', 'return', 'sealed', 'set', 'show', 'static',
  'super', 'switch', 'sync', 'this', 'throw', 'true', 'try', 'typedef',
  'var', 'void', 'while', 'with', 'yield',
};

/// 新建项目整页表单。
/// 替代原对话框: 秒开 + 异步预检进预览卡 + 完整 flutter create 参数,
/// 滚动/键盘由页面 Scaffold 兜底, 不再有对话框溢出一类问题。
class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({
    super.key,
    this.onOpenEnvironment,
    required this.projectRoot,
  });

  /// SDK 不可用时, "配置开发环境"按钮的出口(先 pop 本页再调)
  final VoidCallback? onOpenEnvironment;

  /// 工程根($HOME/projects), 新项目在其下创建
  final String projectRoot;

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

enum _ToolCheck { checking, ok, missing, broken }

class _CreateProjectPageState extends State<CreateProjectPage> {
  final _name = TextEditingController(text: 'my_app');
  final _org = TextEditingController(text: 'com.example');
  final _description = TextEditingController();
  String _type = 'flutter';
  String _template = 'console';
  final _platforms = <String>{'android'};
  bool _empty = false;
  String _androidLang = 'kotlin';
  _ToolCheck _tool = _ToolCheck.checking;
  String _toolDetail = '';
  String? _error;
  bool _submitting = false;
  int _checkSequence = 0;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _name.dispose();
    _org.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final sequence = ++_checkSequence;
    final tool = _type;
    setState(() {
      _tool = _ToolCheck.checking;
      _toolDetail = '';
    });
    try {
      final result = await Shell.instance.exec(
        '${terminalEnvSource}command -v $tool >/dev/null 2>&1 || exit 127; $tool --version',
        timeoutMs: 120000,
      );
      if (!mounted || sequence != _checkSequence) return;
      setState(() {
        _tool = switch (result['exitCode']) {
          0 => _ToolCheck.ok,
          127 => _ToolCheck.missing,
          _ => _ToolCheck.broken,
        };
        _toolDetail = (result['output'] as String? ?? '').trim();
      });
    } catch (error) {
      if (!mounted || sequence != _checkSequence) return;
      setState(() {
        _tool = _ToolCheck.broken;
        _toolDetail = '$error';
      });
    }
  }

  String? get _nameError {
    final name = _name.text.trim();
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
      return '以小写字母开头，只能包含小写字母、数字和下划线';
    }
    if (_reservedNames.contains(name)) return '不能使用 Dart 保留字或工具名称';
    return null;
  }

  String? get _orgError =>
      _org.text.trim().isEmpty ||
          RegExp(
            r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$',
          ).hasMatch(_org.text.trim())
      ? null
      : '使用反向域名格式，例如 com.example';
  bool get _valid =>
      _nameError == null &&
      (_type == 'dart' || _orgError == null && _platforms.isNotEmpty);

  Future<void> _submit() async {
    if (_submitting || !_valid || _tool != _ToolCheck.ok) return;
    final params = CreateProjectParams(
      type: _type,
      name: _name.text.trim(),
      org: _org.text.trim().isEmpty ? 'com.example' : _org.text.trim(),
      platforms: _platforms.toList(),
      empty: _empty,
      androidLang: _androidLang,
      description: _description.text.trim(),
      projectRoot: widget.projectRoot,
      template: _template,
    );
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final path = shQuote('${widget.projectRoot}/${params.name}');
      final result = await Shell.instance.exec(
        '[ -e $path ] || [ -L $path ]',
        timeoutMs: 15000,
      );
      if (!mounted) return;
      if (result['exitCode'] == 0) {
        setState(() => _error = '项目 ${params.name} 已存在，请换一个名称');
      } else if (result['exitCode'] == 1) {
        Navigator.pop(context, params);
      } else {
        setState(() => _error = '无法检查目标目录，请查看开发环境后重试');
      }
    } catch (error) {
      if (mounted) setState(() => _error = '创建前检查失败：$error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('新建项目')),
    body: PageContent(
      child: Column(
        children: [
          Expanded(
            child: AbsorbPointer(
              absorbing: _submitting,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  PageIntro(
                    '项目配置',
                    '设置项目类型、名称和目标平台。创建完成后打开项目。\n保存位置：${widget.projectRoot}',
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'flutter',
                          icon: Icon(Icons.flutter_dash),
                          label: Text('Flutter'),
                        ),
                        ButtonSegment(
                          value: 'dart',
                          icon: Icon(Icons.terminal),
                          label: Text('Dart'),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (values) {
                        if (values.first == _type) return;
                        setState(() {
                          _type = values.first;
                          _error = null;
                        });
                        _check();
                      },
                    ),
                  ),
                  const SectionLabel('项目信息'),
                  SurfaceCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: _name,
                          autocorrect: false,
                          onChanged: (_) => setState(() => _error = null),
                          decoration: InputDecoration(
                            labelText: '项目名称',
                            hintText: 'my_app',
                            helperText: '小写字母、数字与下划线',
                            errorText: _nameError,
                            errorMaxLines: 2,
                          ),
                        ),
                        if (_type == 'flutter') ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _org,
                            autocorrect: false,
                            onChanged: (_) => setState(() => _error = null),
                            decoration: InputDecoration(
                              labelText: '组织标识（可选）',
                              hintText: 'com.example',
                              errorText: _orgError,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SectionLabel(_type == 'flutter' ? '目标平台' : '项目模板'),
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (_type == 'flutter')
                              for (final (value, label) in const [
                                ('android', 'Android'),
                                ('web', 'Web'),
                                ('ios', 'iOS'),
                                ('windows', 'Windows'),
                                ('macos', 'macOS'),
                                ('linux', 'Linux'),
                              ])
                                FilterChip(
                                  label: Text(label),
                                  selected: _platforms.contains(value),
                                  onSelected: (selected) => setState(() {
                                    selected
                                        ? _platforms.add(value)
                                        : _platforms.remove(value);
                                  }),
                                )
                            else
                              for (final (value, label) in const [
                                ('console', '控制台应用'),
                                ('package', 'Dart 包'),
                                ('server', '服务端应用'),
                                ('web', 'Web'),
                              ])
                                ChoiceChip(
                                  label: Text(label),
                                  selected: _template == value,
                                  onSelected: (_) =>
                                      setState(() => _template = value),
                                ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _type == 'dart'
                              ? '控制台项目可在终端使用 dart run 运行。'
                              : _platforms.isEmpty
                              ? '请至少选择一个平台。'
                              : '本机可构建 Android、预览 Web；其他平台生成代码后需在对应系统构建。',
                          style: TextStyle(
                            color: _type == 'flutter' && _platforms.isEmpty
                                ? AppColors.danger
                                : AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_type == 'flutter') ...[
                    const SizedBox(height: 16),
                    SurfaceCard(
                      padding: EdgeInsets.zero,
                      child: ExpansionTile(
                        title: const Text('高级设置'),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('空白项目'),
                            subtitle: const Text('不包含计数器示例'),
                            value: _empty,
                            onChanged: (value) =>
                                setState(() => _empty = value),
                          ),
                          if (_platforms.contains('android')) ...[
                            const SizedBox(height: 12),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Android 源码语言'),
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'kotlin',
                                  label: Text('Kotlin'),
                                ),
                                ButtonSegment(
                                  value: 'java',
                                  label: Text('Java'),
                                ),
                              ],
                              selected: {_androidLang},
                              onSelectionChanged: (values) =>
                                  setState(() => _androidLang = values.first),
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextField(
                            controller: _description,
                            decoration: const InputDecoration(
                              labelText: '项目描述（可选）',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SectionLabel('创建前检查'),
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _tool == _ToolCheck.ok
                                  ? Icons.check_circle_outline
                                  : Icons.build_circle_outlined,
                              color: _tool == _ToolCheck.ok
                                  ? AppColors.success
                                  : AppColors.accent,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${_type == 'dart' ? 'Dart' : 'Flutter'} · ${switch (_tool) {
                                  _ToolCheck.checking => '检测中…',
                                  _ToolCheck.ok => '就绪',
                                  _ToolCheck.missing => '未安装',
                                  _ToolCheck.broken => '无法运行',
                                }}',
                              ),
                            ),
                            IconButton(
                              tooltip: '重新检测',
                              onPressed: _tool == _ToolCheck.checking
                                  ? null
                                  : _check,
                              icon: const Icon(Icons.refresh, size: 20),
                            ),
                          ],
                        ),
                        if (_tool == _ToolCheck.checking)
                          const LinearProgressIndicator(),
                        if (_toolDetail.isNotEmpty)
                          Text(
                            _tool == _ToolCheck.ok
                                ? _toolDetail.split('\n').first
                                : _toolDetail,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: _tool == _ToolCheck.broken
                                  ? AppColors.danger
                                  : AppColors.textSecondary,
                            ),
                          ),
                        if (_tool == _ToolCheck.missing ||
                            _tool == _ToolCheck.broken)
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onOpenEnvironment?.call();
                            },
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('配置开发环境'),
                          ),
                        const Divider(height: 24),
                        Text(
                          '保存位置',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$HOME/${_name.text.trim()}',
                          style: AppColors.mono,
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    StatusNotice(_error!, error: true),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _valid && _tool == _ToolCheck.ok && !_submitting
                    ? _submit
                    : null,
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('创建项目'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
