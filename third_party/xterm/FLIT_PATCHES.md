# xterm 4.0.0 local patches

Source: https://pub.dev/packages/xterm/versions/4.0.0
The upstream license is retained in LICENSE.

- Open the keyboard on a completed single tap, rather than pointer down, so a
  long press can select text without the IME moving its target.
- Deliver the completed tap notification from TerminalGestureHandler to
  TerminalView (upstream's onTapUp property was not invoked).

- Keep touch selection handles available after long press, with character-level
  adjustment and edge scrolling. Handles do not request the keyboard or send PTY
  input. Flit's selection actions occupy the existing header to avoid covering
  the handles or resizing the viewport.
- Anchor the main-buffer cursor through resize/reflow so repeated pinch zoom
  preserves the insertion position, including wide characters and pending wraps.
  Alternate-screen applications still control their own layout.

Regression coverage lives in `test/terminal_interaction_test.dart`, `test/terminal_reflow_test.dart`,
and `test/terminal_appearance_test.dart`.
