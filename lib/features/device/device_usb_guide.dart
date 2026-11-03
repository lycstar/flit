import 'package:flit/l10n/strings.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../services/shell.dart';
import 'device_connection.dart';

class DeviceUsbGuide extends StatefulWidget {
  const DeviceUsbGuide({super.key, required this.connection});
  final DeviceConnection connection;

  @override
  State<DeviceUsbGuide> createState() => _DeviceUsbGuideState();
}

class _DeviceUsbGuideState extends State<DeviceUsbGuide>
    with WidgetsBindingObserver {
  bool _windows = true;
  bool _copied = false;
  bool _checking = false;
  bool _foreground = true;
  bool _timedOut = false;
  String _status = 'waiting';
  String? _error;
  Timer? _timer;
  Timer? _expiry;
  int _generation = 0;

  String get _adb => _windows ? r'.\adb.exe' : './adb';
  String get _command => '$_adb -d tcpip 5555';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimeout();
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _generation++;
      _timer?.cancel();
    } else {
      _check();
    }
  }

  Future<void> _check({bool restart = false}) async {
    if (!mounted || !_foreground || _checking || _status == 'connected') return;
    _timer?.cancel();
    if (restart) {
      _timedOut = false;
      _startTimeout();
    }
    if (_timedOut) return;
    final generation = _generation;
    setState(() => _checking = true);
    final result = await widget.connection.checkUsb(
      cancelled: () =>
          !mounted || !_foreground || _timedOut || generation != _generation,
    );
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (_foreground && !_timedOut && generation == _generation) {
        _status = result;
      }
    });
    if (_status == 'connected') _expiry?.cancel();
    if (_foreground && !_timedOut && _status != 'connected') {
      _timer = Timer(const Duration(seconds: 2), _check);
    }
  }

  void _startTimeout() {
    _expiry?.cancel();
    _expiry = Timer(const Duration(minutes: 2), () {
      _timer?.cancel();
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _generation++;
    _timer?.cancel();
    _expiry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String get _message => _status == 'connected'
      ? context.strings.connectedLocallyYouCanUnplugTheCable
      : _timedOut
      ? context.strings.waitTimedOutCheckTheComputerCommand
      : switch (_status) {
          'unauthorized' => context.strings.allowUsbDebuggingOnThePhoneFlit,
          'failed' => context.strings.unableToReadAdbStatusCheckThe,
          _ => context.strings.waitingForComputerActivationFlitWillConnect,
        };

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.strings.activateViaComputerUsb),
    scrollable: true,
    content: SizedBox(
      width: 440,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.strings.enableUsbDebuggingConnectThePhoneTo),
          const SizedBox(height: 16),
          Text(context.strings.downloadAndExtractPlatformToolsOnThe),
          TextButton.icon(
            onPressed: () async {
              try {
                if (!await Shell.instance.openUrl(
                  'https://developer.android.com/tools/releases/platform-tools',
                )) {
                  throw StateError(strings.unableToOpenTheDownloadPage);
                }
              } catch (_) {
                if (mounted) {
                  setState(
                    () => _error =
                        context.strings.onTheComputerVisitDeveloperAndroidCom,
                  );
                }
              }
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(context.strings.platformToolsWebsite),
          ),
          const SizedBox(height: 8),
          Text(context.strings.runThisCommandOnTheComputerKeep),
          const SizedBox(height: 8),
          DropdownButtonFormField<bool>(
            isExpanded: true,
            initialValue: _windows,
            decoration: InputDecoration(labelText: context.strings.computerOs),
            items: const [
              DropdownMenuItem(
                value: true,
                child: Text('Windows · PowerShell'),
              ),
              DropdownMenuItem(value: false, child: Text('macOS / Linux')),
            ],
            onChanged: (value) => setState(() {
              _windows = value ?? true;
              _copied = false;
            }),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              _command,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.8,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                try {
                  await Clipboard.setData(ClipboardData(text: _command));
                  if (mounted) setState(() => _copied = true);
                } catch (_) {
                  if (mounted) {
                    setState(
                      () => _error =
                          context.strings.copyFailedLongPressTheCommandTo,
                    );
                  }
                }
              },
              icon: Icon(_copied ? Icons.check : Icons.copy, size: 16),
              label: Text(
                _copied ? context.strings.copied : context.strings.copyCommand,
              ),
            ),
          ),
          Text(context.strings.afterTheComputerShowsRestartingInTcp),
          const SizedBox(height: 16),
          Text(_message),
          if (_error != null) Text(_error!),
          const SizedBox(height: 16),
          Text(context.strings.waitsAutomaticallyForUpToMinutesClosing),
          const SizedBox(height: 8),
          Text(context.strings.tcpDebuggingMayAlsoListenOnNetwork(_adb)),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(
          _status == 'connected' ? context.strings.done : context.strings.close,
        ),
      ),
      if (_status != 'connected')
        FilledButton(
          onPressed: _checking ? null : () => _check(restart: true),
          child: Text(
            _timedOut ? context.strings.reconnect : context.strings.connectNow,
          ),
        ),
    ],
  );
}
