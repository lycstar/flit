import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/editor/lsp/lsp_client.dart';
import 'package:flit/features/editor/lsp/protocol.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const lsp = MethodChannel('flit/lsp');
  late LspClient client;
  final calls = <String>[];
  final payloads = <Map>[];
  Completer<String>? initialization;
  Completer<String>? completion;
  bool spawn = true, notify = true;
  int session = 0;
  const initialized =
      '{"result":{"capabilities":{"completionProvider":{"resolveProvider":true}}}}';

  setUp(() async {
    client = LspClient();
    messenger.setMockMethodCallHandler(
      const MethodChannel('flit/lspEvents'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(lsp, (call) async {
      final args = call.arguments as Map? ?? {};
      if (call.method == 'start') {
        session = args['session'] as int;
        return spawn;
      }
      if (call.method == 'stop') return true;
      final method = args['method'] as String;
      calls.add(method);
      payloads.add(jsonDecode(args['params'] as String) as Map);
      if (call.method == 'notify') return notify;
      if (method == 'initialize') return initialization?.future ?? initialized;
      if (method == 'textDocument/completion') {
        return completion?.future ?? '{"result":[{"label":"print"}]}';
      }
      return '{"result":null}';
    });
    await client.stop();
    calls.clear();
    payloads.clear();
    initialization = null;
    completion = null;
    spawn = true;
    notify = true;
  });
  tearDown(() async {
    await client.dispose();
  });

  test(
    'initialize/initialized precede didOpen and latest didChange precedes completion',
    () async {
      initialization = Completer<String>();
      final start = client.ensureStarted('/p');
      await Future<void>.delayed(Duration.zero);
      expect(client.state.value, LanguageServiceState.starting);
      await client.openDocument('/p/a.dart', 'pr');
      expect(calls, ['initialize']);
      initialization!.complete(initialized);
      expect(await start, isTrue);
      await client.openDocument('/p/a.dart', 'pr');
      final result = await client.completion('/p/a.dart', 'pri', 3);
      expect(result.single.label, 'print');
      expect(calls, [
        'initialize',
        'initialized',
        'textDocument/didOpen',
        'textDocument/didChange',
        'textDocument/completion',
      ]);
      expect(payloads[3]['contentChanges'], [
        {'text': 'pri'},
      ]);
      expect(payloads[3]['textDocument']['version'], 2);
      final capabilities = payloads[0]['capabilities'];
      expect(
        capabilities['textDocument']['completion']['completionItem']['snippetSupport'],
        false,
      );
      await client.closeDocument('/p/a.dart');
      expect(calls.last, 'textDocument/didClose');
    },
  );

  test(
    'a new project ignores old process events and closed clients cannot restart',
    () async {
      await client.ensureStarted('/first');
      final oldSession = session;
      await client.dispose();
      expect(await client.ensureStarted('/first'), false);
      final next = LspClient();
      await next.ensureStarted('/second');
      expect(session, isNot(oldSession));
      await messenger.handlePlatformMessage(
        'flit/lspEvents',
        const StandardMethodCodec().encodeSuccessEnvelope(
          jsonEncode({
            'method': 'flit/serverExited',
            'flitSession': oldSession,
          }),
        ),
        (_) {},
      );
      await Future<void>.delayed(Duration.zero);
      expect(next.ready, true);
      await next.dispose();
    },
  );

  test('non Dart files never enter Dart language service', () async {
    await client.ensureStarted('/p');
    await client.openDocument('/p/a.yaml', 'name: app');
    expect(await client.completion('/p/a.yaml', 'name: app', 2), isEmpty);
    expect(calls, ['initialize', 'initialized']);
  });

  test('failed spawn or document send exposes basic fallback state', () async {
    spawn = false;
    expect(await client.ensureStarted('/p'), false);
    expect(client.state.value, LanguageServiceState.unavailable);
    spawn = true;
    expect(await client.ensureStarted('/p'), true);
    notify = false;
    expect(await client.completion('/p/a.dart', 'pr', 2), isEmpty);
    expect(client.state.value, LanguageServiceState.unavailable);
  });

  test('stop during initialize cannot resurrect service', () async {
    initialization = Completer<String>();
    final start = client.ensureStarted('/p');
    await Future<void>.delayed(Duration.zero);
    await client.stop();
    initialization!.complete(initialized);
    expect(await start, false);
    expect(client.state.value, LanguageServiceState.stopped);
    expect(calls, ['initialize']);
  });

  test('completion from a stopped generation is discarded', () async {
    await client.ensureStarted('/p');
    completion = Completer<String>();
    final request = client.completion('/p/a.dart', 'pr', 2);
    await Future<void>.delayed(Duration.zero);
    await client.stop();
    completion!.complete('{"result":[{"label":"old"}]}');
    expect(await request, isEmpty);
  });

  test(
    'diagnostic versions and old process notifications are checked',
    () async {
      await client.ensureStarted('/p');
      await client.openDocument('/p/a.dart', 'pri');
      expect(
        client.acceptsDiagnostics(
          const DiagnosticsReport(
            path: '/p/a.dart',
            errors: 0,
            messages: [],
            version: 0,
          ),
          'pri',
        ),
        false,
      );
      expect(
        client.acceptsDiagnostics(
          const DiagnosticsReport(
            path: '/p/a.dart',
            errors: 0,
            messages: [],
            version: 1,
          ),
          'pri',
        ),
        true,
      );
      expect(
        client.acceptsDiagnostics(
          const DiagnosticsReport(
            path: '/p/a.dart',
            errors: 0,
            messages: [],
            version: 1,
          ),
          'changed',
        ),
        false,
      );
      Future<void> event(int token) async {
        await messenger.handlePlatformMessage(
          'flit/lspEvents',
          const StandardMethodCodec().encodeSuccessEnvelope(
            jsonEncode({
              'method': 'flit/serverExited',
              'flitSession': token,
            }),
          ),
          (_) {},
        );
        await Future<void>.delayed(Duration.zero);
      }

      await event(session - 1);
      expect(client.ready, true);
      await event(session);
      expect(client.state.value, LanguageServiceState.unavailable);
    },
  );
}
