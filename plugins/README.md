# Android native plugins

Native code is grouped by system capability. Flutter controllers own workflows and state; plugins expose Android operations or process transport.

| Plugin | Responsibility | Lifetime / dependency |
| --- | --- | --- |
| `flit_env` | Bootstrap deployment, runtime paths, short commands, SHA-256, system proxy and settings/browser intents | Engine/application; no Flutter feature state |
| `flit_lsp` | Language-server process and JSON-RPC frame transport | Project-managed server IDs; depends on `flit_env` for the runtime environment |
| `flit_device` | Local wireless ADB endpoint discovery and battery-optimization requests | Activity/engine callbacks; pairing and connection decisions remain in Dart |
| `flit_files` | Share/open files, invoke the system APK installer, expose the project directory through SAF | Activity-aware actions plus a system-managed `DocumentsProvider` |
| `flit_work` | Foreground service for active terminal and task sessions | Application service; session accounting remains in Dart |

`flutter_pty` supplies interactive PTYs separately. Long-running commands use terminal sessions, not the short-command `exec` bridge. The LSP plugin handles framing and process ownership; protocol initialization, diagnostics and completion live in the editor feature.

## File access

`flit_files` owns both file integration providers. `FileProvider` grants temporary read access to a selected file for sharing or installation. `FlitDocumentsProvider` exposes only `files/home/projects`, validates canonical paths, and is protected by Android’s `MANAGE_DOCUMENTS` permission. It does not expose toolchain directories or application credentials.

The system invokes `DocumentsProvider` directly; it needs no placeholder Flutter plugin or Dart method channel. Its authority remains `${applicationId}.documents` when implementation files move.

## Changes

Keep plugin package IDs, channels and manifest declarations aligned. Perform I/O off the UI thread and deliver channel results on Android’s main thread. Test the Dart contract and compile an Android arm64 APK for native changes. Device discovery, SAF integration and foreground-service behavior also require device verification.
