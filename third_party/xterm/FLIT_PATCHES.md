# xterm 4.0.0 local patches

Source: https://pub.dev/packages/xterm/versions/4.0.0
The upstream license is retained in LICENSE.

- Open the keyboard on a completed single tap, rather than pointer down, so a
  long press can select text without the IME moving its target.
- Deliver the completed tap notification from TerminalGestureHandler to
  TerminalView (upstream's onTapUp property was not invoked).

Regression coverage lives in test/terminal_interaction_test.dart.
