import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/core/app_scope.dart';
import 'package:flit/app.dart';

import 'support/app_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flit/env'), (
          call,
        ) async {
          switch (call.method) {
            case 'bootstrapStatus':
              return {
                'bootstrapped': false,
                'prefix': '/data/x/files/usr',
                'home': '/data/x/files/home',
              };
            default:
              return null;
          }
        });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flit/env'), null);
  });

  testWidgets('启动后打开项目列表，未初始化时显示开发环境页', (tester) async {
    await tester.pumpWidget(
      AppScope(services: testServices(), child: const FlitApp()),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('开发环境'), findsOneWidget);
    final labels = MaterialLocalizations.of(tester.element(find.text('开发环境')));
    expect(labels.copyButtonLabel, '复制');
    expect(labels.pasteButtonLabel, '粘贴');
  });
}
