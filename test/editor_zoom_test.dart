import 'package:flit/features/editor/controller/code_controller.dart';
import 'package:flit/features/editor/lsp/lsp_client.dart';
import 'package:flit/features/editor/widgets/code_field.dart';
import 'package:flit/features/editor/widgets/editor_surface.dart';
import 'package:flit/features/settings/appearance_preferences.dart';
import 'package:flit/services/adb_connection_method.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class ZoomPreferences extends AppearancePreferences {
  int writes = 0;

  @override
  Future<void> update({
    double? editor,
    double? terminal,
    String? terminalFont,
    double? terminalLineHeight,
    String? theme,
    bool? wrap,
    bool? backgroundNoticeShown,
    bool? adbPaired,
    String? adbHost,
    String? adbConnectPort,
    AdbConnectionMethod? adbConnectionMethod,
    int? adbPairingRevision,
    String? runDevice,
  }) async {
    if (editor != null) {
      editorSize = editor;
      writes++;
    }
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flit/lsp'),
          (_) async => true,
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flit/lsp'), null);
  });
  for (final wrap in [true, false]) {
    testWidgets('pinch zoom preserves editing state with wrap=$wrap', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final preferences = ZoomPreferences()..editorWrap = wrap;
      final language = LspClient();
      final controller = CodeController(
        text: '${'abcdefghij ' * 15}\nnext line',
        language: 'text',
      );
      final focus = FocusNode();
      controller.selection = const TextSelection(
        baseOffset: 2,
        extentOffset: 7,
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppearancePreferences>.value(
              value: preferences,
            ),
            Provider<LspClient>.value(value: language),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: EditorSurface(
                controller: controller,
                path: '/tmp/zoom.txt',
                focusNode: focus,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final original = controller.value;
      final editable = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      double lineY() => editable.renderEditable
          .getLocalRectForCaret(
            TextPosition(offset: controller.text.indexOf('\n') + 1),
          )
          .top;
      final beforeY = lineY();
      final beforeWidth = editable.renderEditable.size.width;
      final center = tester.getCenter(find.byType(CodeField));
      final first = await tester.startGesture(
        center - const Offset(40, 0),
        pointer: 1,
      );
      final second = await tester.startGesture(
        center + const Offset(40, 0),
        pointer: 2,
      );
      await first.moveBy(const Offset(-40, 0));
      await second.moveBy(const Offset(40, 0));
      await tester.pump();
      expect(tester.widget<CodeField>(find.byType(CodeField)).fontSize, 28);
      expect(preferences.writes, 0);
      if (wrap) {
        // More visual rows, beyond the height increase from doubling font size.
        expect(lineY(), greaterThan(beforeY * 2));
      } else {
        expect(
          editable.renderEditable.size.width,
          greaterThan(beforeWidth * 1.9),
        );
        expect(lineY(), closeTo(beforeY * 2, 2));
      }
      await first.up();
      await second.up();
      await tester.pumpAndSettle();
      expect(preferences.writes, 1);
      expect(preferences.editorSize, 28);
      expect(controller.value, original);
      expect(focus.hasFocus, isFalse);
      expect(tester.testTextInput.isVisible, isFalse);

      // Zooming while typing keeps the same input client, caret and focus.
      focus.requestFocus();
      controller.selection = const TextSelection.collapsed(offset: 3);
      await tester.pump();
      final input = tester.testTextInput.setClientArgs;
      final third = await tester.startGesture(
        center - const Offset(80, 0),
        pointer: 3,
      );
      final fourth = await tester.startGesture(
        center + const Offset(80, 0),
        pointer: 4,
      );
      await third.moveBy(const Offset(40, 0));
      await fourth.moveBy(const Offset(-40, 0));
      await tester.pump();
      await third.up();
      await fourth.up();
      await tester.pumpAndSettle();
      expect(preferences.editorSize, 14);
      expect(preferences.writes, 2);
      expect(controller.text, original.text);
      expect(controller.selection.baseOffset, 3);
      expect(focus.hasFocus, isTrue);
      expect(
        tester.state<EditableTextState>(find.byType(EditableText)),
        same(editable),
      );
      expect(tester.testTextInput.setClientArgs, input);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      focus.dispose();
      controller.dispose();
      preferences.dispose();
      await language.dispose();
    });
  }
}
