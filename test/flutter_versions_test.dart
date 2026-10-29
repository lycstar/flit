import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/environment/toolchain_catalog.dart';
import 'package:flit/features/environment/widgets/toolchain_versions_section.dart';

void main() {
  testWidgets('installed Flutter versions remain switchable without GitHub', (
    tester,
  ) async {
    final prefix = Directory.systemTemp.createTempSync('flit-versions-');
    addTearDown(() => prefix.deleteSync(recursive: true));
    final base = '${prefix.path}/opt/flutter';
    for (final version in ['3.47.7', '3.48.0']) {
      File('$base/$version/.flit-complete')
        ..createSync(recursive: true)
        ..writeAsStringSync('a' * 64);
    }
    Link('$base/current').createSync('3.47.7');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('flit/env'),
      (_) async => {'prefix': prefix.path},
    );
    addTearDown(
      () => messenger.setMockMethodCallHandler(
        const MethodChannel('flit/env'),
        null,
      ),
    );
    CatalogEntry? selected;
    final catalog = ToolchainCatalog()
      ..fetchJson = (_) async => throw const SocketException('offline');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ToolchainVersionsSection(
            catalog: catalog,
            installing: false,
            onInstall: (entry) async => selected = entry,
          ),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(find.text('Flutter 3.47.7'), findsOneWidget);
    expect(find.text('当前'), findsOneWidget);
    await tester.tap(find.text('切换'));
    await tester.pump();
    expect(selected?.tag, '3.48.0');
    expect(selected?.sha256, 'a' * 64);
    expect(selected?.url, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}
