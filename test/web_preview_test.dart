import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/project_scope.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:flit/features/run/web_run_page.dart';
import 'package:flit/features/run/web_runner.dart';
import 'package:flit/features/terminal/run_sessions.dart';
import 'package:flit/features/workspace/workspace_views.dart';

import 'support/fake_session_process.dart';

void main() {
  late FakeWebPlatform platform;
  late RunSessions executions;
  late WebRunController web;
  late FakeProcess process;

  setUp(() {
    platform = FakeWebPlatform();
    WebViewPlatform.instance = platform;
    process = FakeProcess();
    executions = RunSessions(
      projectPath: '/project',
      launcher:
          ({
            required command,
            required workingDirectory,
            required rows,
            required columns,
          }) async => process,
    );
    web = WebRunController(executions, allocatePort: () async => 20001);
  });

  Future<void> cleanup(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => process.finish());
    await tester.pump();
    web.dispose();
    final closing = executions.closeAll();
    await tester.pump();
    await tester.runAsync(() => closing);
  }

  Future<void> serve(WidgetTester tester) async {
    await tester.runAsync(() async {
      await web.start();
      for (final event in [
        {
          'event': 'app.start',
          'params': {'appId': 'web-app'},
        },
        {
          'event': 'app.webLaunchUrl',
          'params': {'url': 'http://127.0.0.1:20001'},
        },
        {'event': 'app.started', 'params': {}},
      ]) {
        process.emit('${jsonEncode([event])}\n');
      }
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
    'startup does not navigate; tabs and wide layout retain the same native view',
    (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      bool preview = false;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Scaffold(
                body: WorkspaceViews(
                  code: const TextField(),
                  preview: scopedProject(
                    web: web,
                    child: const WebRunPreview(),
                  ),
                  hasPreview: web.state != WebRunState.idle,
                  showPreview: preview,
                ),
              );
            },
          ),
        ),
      );
      expect(platform.controllers, isEmpty);
      await serve(tester);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(WebViewWidget), findsNothing); // Retained offstage.
      expect(platform.controllers, hasLength(1));
      final controller = platform.controllers.single;
      final nativeElement = tester.element(
        find.byType(WebViewWidget, skipOffstage: false),
      );
      expect(controller.loads, hasLength(1));
      platform.delegate.pageStarted!('http://127.0.0.1:20001');
      platform.delegate.pageFinished!('http://127.0.0.1:20001');
      await tester.pump();
      expect(
        web.canReload,
        false,
      ); // HTML finishing alone isn't a rendered app.
      controller.channel!.onMessageReceived(
        const JavaScriptMessage(message: 'frame:1'),
      );
      await tester.pump();
      expect(web.canReload, true);

      update(() => preview = true);
      await tester.pump();
      expect(find.byType(WebViewWidget), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      update(() => preview = false);
      await tester.pump();
      update(() => preview = true);
      await tester.pump();
      tester.view.physicalSize = const Size(1100, 800);
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(WebViewWidget), findsOneWidget);
      expect(tester.element(find.byType(WebViewWidget)), same(nativeElement));
      expect(platform.controllers, hasLength(1));
      expect(controller.loads, hasLength(1));
      await cleanup(tester);
    },
  );

  testWidgets(
    'subresource errors do not reload; main document failure offers manual retry',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: scopedProject(web: web, child: const WebRunPreview()),
          ),
        ),
      );
      await serve(tester);
      final controller = platform.controllers.single;
      platform.delegate.pageStarted!('http://127.0.0.1:20001');
      platform.delegate.resourceError!(
        const WebResourceError(
          errorCode: -2,
          description: 'favicon missing',
          isForMainFrame: false,
        ),
      );
      platform.delegate.httpError!(
        HttpResponseError(
          request: WebResourceRequest(
            uri: Uri.parse('http://127.0.0.1:20001/favicon.ico'),
          ),
          response: WebResourceResponse(
            statusCode: 404,
            uri: Uri.parse('http://127.0.0.1:20001/favicon.ico'),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(controller.loads, hasLength(1));
      expect(find.textContaining('favicon missing'), findsNothing);
      platform.delegate.resourceError!(
        const WebResourceError(
          errorCode: -2,
          description: 'connection refused',
          isForMainFrame: true,
        ),
      );
      await tester.pump();
      expect(find.text('页面加载失败：connection refused'), findsOneWidget);
      expect(find.text('重新加载'), findsOneWidget);
      expect(
        web.serving,
        true,
      ); // A page load error is separate from process exit.
      await tester.tap(find.text('重新加载'));
      await tester.pump();
      expect(controller.loads, hasLength(2));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(
        const Duration(seconds: 65),
      ); // No lingering retry timers.
      expect(tester.takeException(), isNull);
      await cleanup(tester);
    },
  );

  testWidgets(
    'reload uses the live Flutter session without refreshing the WebView',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: scopedProject(web: web, child: const WebRunPreview()),
          ),
        ),
      );
      await serve(tester);
      final controller = platform.controllers.single;
      platform.delegate.pageStarted!('http://127.0.0.1:20001');
      controller.channel!.onMessageReceived(
        const JavaScriptMessage(message: 'frame:1'),
      );
      await tester.pump();
      await tester.runAsync(() async {
        final update = web.reload();
        final request = (jsonDecode(process.writes.last) as List).single as Map;
        process.emit(
          '${jsonEncode([
            {
              'id': request['id'],
              'result': {'code': 0},
            },
          ])}\n',
        );
        expect(await update, true);
      });
      await tester.pump();
      expect(controller.loads, hasLength(1));
      expect(web.canReload, true);
      await cleanup(tester);
    },
  );
}

class FakeWebPlatform extends WebViewPlatform {
  final controllers = <FakeWebController>[];
  late FakeNavigationDelegate delegate;

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    final controller = FakeWebController(params);
    controllers.add(controller);
    return controller;
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) => delegate = FakeNavigationDelegate(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) => FakeWebWidget(params);
}

class FakeWebController extends PlatformWebViewController {
  FakeWebController(super.params) : super.implementation();
  final loads = <Uri>[];
  JavaScriptChannelParams? channel;
  @override
  Future<void> setJavaScriptMode(JavaScriptMode mode) async {}
  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams params) async =>
      channel = params;
  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}
  @override
  Future<void> runJavaScript(String script) async {}
  @override
  Future<void> loadRequest(LoadRequestParams params) async =>
      loads.add(params.uri);
}

class FakeNavigationDelegate extends PlatformNavigationDelegate {
  FakeNavigationDelegate(super.params) : super.implementation();
  PageEventCallback? pageStarted;
  PageEventCallback? pageFinished;
  WebResourceErrorCallback? resourceError;
  HttpResponseErrorCallback? httpError;
  @override
  Future<void> setOnPageStarted(PageEventCallback callback) async =>
      pageStarted = callback;
  @override
  Future<void> setOnPageFinished(PageEventCallback callback) async =>
      pageFinished = callback;
  @override
  Future<void> setOnWebResourceError(WebResourceErrorCallback callback) async =>
      resourceError = callback;
  @override
  Future<void> setOnHttpError(HttpResponseErrorCallback callback) async =>
      httpError = callback;
}

class FakeWebWidget extends PlatformWebViewWidget {
  FakeWebWidget(super.params) : super.implementation();
  @override
  Widget build(BuildContext context) => const ColoredBox(color: Colors.white);
}
