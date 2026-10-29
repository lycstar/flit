import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme.dart';
import '../editor/workbench_layout.dart';
import 'web_runner.dart';

/// An embedded workspace view. Its native WebView stays mounted between tabs.
class WebRunPreview extends StatelessWidget {
  const WebRunPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final run = context.read<WebRunController>();
    // 看日志 = 终端切到 Web 运行的会话并展开
    void onShowOutput() =>
        context.read<WorkbenchLayout>().showOutput(sessionId: run.session?.id);
    return ListenableBuilder(
      listenable: run,
      builder: (context, _) {
        if (run.serving) {
          return _WebDocument(
            key: ValueKey(run.session!.id),
            run: run,
            onShowOutput: onShowOutput,
          );
        }
        final message = switch (run.state) {
          WebRunState.idle => '运行 Web 后在这里预览',
          WebRunState.starting => '正在编译并启动 Web 服务',
          WebRunState.serving || WebRunState.stopped => 'Web 服务已停止',
          WebRunState.failed => run.error ?? 'Web 启动失败',
        };
        return ColoredBox(
          color: AppColors.bg,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (run.starting)
                    const CircularProgressIndicator(strokeWidth: 2)
                  else
                    const Icon(
                      Icons.web,
                      size: 36,
                      color: AppColors.textSecondary,
                    ),
                  const SizedBox(height: 16),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onShowOutput,
                    child: const Text('查看运行日志'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WebDocument extends StatefulWidget {
  const _WebDocument({
    super.key,
    required this.run,
    required this.onShowOutput,
  });
  final WebRunController run;
  final VoidCallback onShowOutput;

  @override
  State<_WebDocument> createState() => _WebDocumentState();
}

class _WebDocumentState extends State<_WebDocument> {
  late final WebViewController _controller;
  Timer? _frameTimeout;
  bool _loading = true;
  String? _error;
  bool _failedDocument = false;
  Uri? _documentUrl;
  int _navigation = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await _controller.addJavaScriptChannel(
        'FlitPreview',
        onMessageReceived: (message) {
          if (!mounted ||
              message.message != 'frame:$_navigation' ||
              _failedDocument) {
            return;
          }
          _frameTimeout?.cancel();
          setState(() {
            _loading = false;
            _error = null;
          });
          widget.run.setClientReady(true);
        },
      );
      await _controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (!mounted) return;
            _documentUrl = Uri.tryParse(url);
            ++_navigation;
            widget.run.setClientReady(false);
            _frameTimeout?.cancel();
            setState(() {
              _loading = true;
              _error = null;
              _failedDocument = false;
            });
            _frameTimeout = Timer(const Duration(seconds: 60), () {
              _showError('页面尚未完成首次渲染，请查看运行日志或重新加载', failedDocument: false);
            });
            unawaited(_watchFirstFrame());
          },
          // HTML load completion is not Flutter's first rendered frame.
          onPageFinished: (_) => unawaited(_watchFirstFrame()),
          onWebResourceError: (error) {
            if (error.isForMainFrame == true) {
              _showError('页面加载失败：${error.description}');
            }
          },
          onHttpError: (error) {
            if (error.request?.uri == _documentUrl) {
              _showError('页面请求失败：HTTP ${error.response?.statusCode}');
            }
          },
        ),
      );
      if (mounted) await _controller.loadRequest(widget.run.url!);
    } catch (e) {
      _showError('无法加载预览：$e');
    }
  }

  Future<void> _watchFirstFrame() async {
    if (!mounted) return;
    try {
      await _controller.runJavaScript('''
(() => {
  const token = $_navigation;
  if (window.__flitPreviewToken === token) return;
  window.__flitPreviewToken = token;
  let done = false;
  const ready = () => {
    if (done || window.__flitPreviewToken !== token) return;
    done = true;
    window.removeEventListener('flutter-first-frame', ready);
    FlitPreview.postMessage('frame:' + token);
  };
  window.addEventListener('flutter-first-frame', ready, {once: true});
  // Recover if the native callback arrived after the first-frame event.
  const scene = document.querySelector('flt-glass-pane')?.shadowRoot
      ?.querySelector('flt-scene-host > flt-scene');
  if (scene) requestAnimationFrame(() => requestAnimationFrame(ready));
})();
''');
    } catch (_) {
      // onPageStarted may precede the JS context; onPageFinished retries setup.
    }
  }

  void _showError(String message, {bool failedDocument = true}) {
    if (!mounted) return;
    _frameTimeout?.cancel();
    widget.run.setClientReady(false);
    setState(() {
      _loading = false;
      _error = message;
      _failedDocument = failedDocument;
    });
  }

  Future<void> _refresh() async {
    if (!widget.run.serving) return;
    _frameTimeout?.cancel();
    widget.run.setClientReady(false);
    setState(() {
      _loading = true;
      _error = null;
      _failedDocument = false;
    });
    try {
      await _controller.loadRequest(widget.run.url!);
    } catch (e) {
      _showError('无法加载预览：$e');
    }
  }

  @override
  void dispose() {
    _frameTimeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 36,
          color: AppColors.surface,
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            children: [
              const Icon(
                Icons.language,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.run.url.toString(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              IconButton(
                tooltip: '重新加载页面（重置页面状态）',
                iconSize: 18,
                padding: EdgeInsets.zero,
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: WebViewWidget(controller: _controller)),
              if (_loading || _error != null)
                Positioned.fill(
                  child: ColoredBox(
                    color: AppColors.bg,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_loading)
                              const CircularProgressIndicator(strokeWidth: 2),
                            const SizedBox(height: 16),
                            Text(
                              _error ?? '正在加载预览…',
                              textAlign: TextAlign.center,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: _refresh,
                                child: const Text('重新加载'),
                              ),
                              TextButton(
                                onPressed: widget.onShowOutput,
                                child: const Text('查看运行日志'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (widget.run.error != null || widget.run.reloading)
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.all(8),
            child: Text(
              widget.run.reloading ? '正在更新…' : widget.run.error!,
              style: TextStyle(
                fontSize: 12,
                color: widget.run.error != null
                    ? AppColors.danger
                    : AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}
