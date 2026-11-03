# Localization

Flit supports English and Simplified Chinese. Settings offers Follow System,
简体中文, and English. Follow System selects a supported language from the system
locale list and falls back to English. Chinese regional locales use the shared
Simplified Chinese translation.

The choice is stored as `system`, `zh`, or `en` in the existing appearance
preferences. Updating it rebuilds localized widgets without replacing the
navigator, active project, editor documents, or terminal processes.

## Flutter strings

Edit `lib/l10n/app_zh.arb` and `lib/l10n/app_en.arb`, then run:

```sh
flutter gen-l10n
```

Use `context.strings` in widgets so they depend on Flutter's localization scope.
Use `strings` from `lib/l10n/strings.dart` for controllers and process messages
without a build context. It follows the application's resolved language. Avoid
caching translated labels in static fields; prefer getters for shared metadata.

Use resource placeholders for dynamic values. Do not translate identifiers,
paths, shell commands, user content, or external tool output. Existing task logs
retain the language in which they were produced; new messages use the selected
language.

## Android strings

The device, work, and files plugins use Android `values/strings.xml` (English)
and `values-zh/strings.xml`. The device bridge synchronizes the language choice
to native preferences when loading or changing it. Notifications and the
DocumentsProvider use a localized context for explicit overrides, while System
uses Android resource resolution. Resource names are prefixed by plugin to
avoid collisions when Android merges resources.

## Validation

```sh
flutter analyze
flutter test test/localization_test.dart
flutter test
flutter build apk --debug --target-platform android-arm64
```

The localization tests cover catalog parity, placeholders, language persistence,
system locale changes, and switching language on an existing route without
replacing its state or the terminal session.
