import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'header_widget.dart'; // gold

/// Makes any widget usable with a TV remote (Up / Down / Left / Right / OK):
///
///  * a clear gold focus ring while it is selected (or contains the
///    selection, when wrapping a control),
///  * it scrolls itself into view when focus lands on it,
///  * OK / Enter / Select runs [onPressed],
///  * with [moveFocusOnUpDown], Up/Down move to the previous/next focusable
///    instead of moving the text cursor, and OK advances to the next field.
///  * with [usesTextInput], the on-screen keyboard stays closed while the
///    remote navigates and opens only when OK is pressed to type.
///
/// Wrap a display-only card as-is (the default): the wrapper itself is
/// the focus target. Wrap a control (button, text field, dropdown) with
/// `focusable: false`: only the control inside takes focus, while the
/// wrapper draws the ring and handles the remote keys.
class TvFocusable extends StatefulWidget {
  const TvFocusable({
    super.key,
    required this.child,
    this.focusable = true,
    this.moveFocusOnUpDown = false,
    this.usesTextInput = false,
    this.onPressed,
  });

  final Widget child;

  /// True: this wrapper is focusable itself (cards, rows).
  /// False: only the widget inside can be focused (buttons, fields).
  final bool focusable;

  /// Up/Down (and OK) jump between fields instead of moving the cursor.
  final bool moveFocusOnUpDown;

  /// The child is a real text field. On a TV the on-screen keyboard must
  /// stay closed while the remote navigates (once open, the Android IME
  /// eats every DPAD key and the user is trapped in the field); it is
  /// opened only when the user presses OK to type.
  final bool usesTextInput;

  /// Runs on OK / Enter / Select when set.
  final VoidCallback? onPressed;

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  bool selected = false;
  double _bottomInset = 0;
  // True between an explicit OK (open the keyboard to type) and the
  // keyboard actually closing again.
  bool _imeWanted = false;

  // When the on-screen keyboard opens or closes the layout shrinks; make
  // sure the focused control stays visible above the keyboard.
  // Only runs while subscribed: `build` registers the MediaQuery dependency
  // for the focused wrapper alone, so a viewport-metrics storm cannot
  // rebuild every focusable on the board (report bug #3).
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!selected) return; // not subscribed yet (see build)
    final bottom = MediaQuery.maybeViewInsetsOf(context)?.bottom ?? 0;
    final changed = bottom != _bottomInset;
    _bottomInset = bottom;
    if (!changed) return;
    if (bottom == 0) _imeWanted = false; // really closed (e.g. BACK)
    // Safety net: the keyboard came up without us asking (a tap, or a late
    // TextInput.show) — close it again so the remote keeps its keys.
    if (widget.usesTextInput && !_imeWanted) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    }
    _scrollIntoView();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (widget.moveFocusOnUpDown) {
      if (key == LogicalKeyboardKey.arrowDown) {
        node.nextFocus();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowUp) {
        node.previousFocus();
        return KeyEventResult.handled;
      }
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.select) {
      if (widget.onPressed != null) {
        widget.onPressed!();
        return KeyEventResult.handled;
      }
      if (widget.usesTextInput) {
        // OK on a text field opens the keyboard — the only way to type on
        // a TV. The system BACK key closes it; Up/Down keep moving.
        _imeWanted = true;
        SystemChannels.textInput.invokeMethod('TextInput.show');
        return KeyEventResult.handled;
      }
      if (widget.moveFocusOnUpDown) {
        node.nextFocus(); // OK advances to the next field
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  // Scroll the newly focused widget into view, but only when it is really
  // outside its scrollable — never yank content that is already visible.
  void _scrollIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !selected) return;
      final box = context.findRenderObject();
      final scrollable = Scrollable.maybeOf(context);
      if (box is! RenderBox || !box.attached || scrollable == null) return;
      final viewport = scrollable.context.findRenderObject();
      if (viewport is! RenderBox || !viewport.attached) return;
      final child = box.localToGlobal(Offset.zero) & box.size;
      final view = viewport.localToGlobal(Offset.zero) & viewport.size;
      // Inclusive edges: Rect.contains excludes right/bottom, so a card
      // ending exactly at the viewport edge (the full-screen notice does)
      // read as "outside" and got yanked out of view on focus.
      if (child.top >= view.top &&
          child.bottom <= view.bottom &&
          child.left >= view.left &&
          child.right <= view.right) {
        return; // already fully visible
      }
      Scrollable.ensureVisible(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Register the keyboard-inset dependency only while focused: during a
    // viewport-metrics storm a dependency per focusable would rebuild the
    // whole board every frame.
    if (selected) MediaQuery.maybeViewInsetsOf(context);
    return Focus(
      // With focusable: false the wrapper never takes primary focus itself;
      // it only rings and handles keys bubbling up from the control inside.
      canRequestFocus: widget.focusable,
      onKeyEvent: _onKey,
      onFocusChange: (hasFocus) {
        if (!mounted) return;
        setState(() => selected = hasFocus);
        if (!hasFocus) {
          _imeWanted = false;
          return;
        }
        _scrollIntoView();
        if (widget.usesTextInput) {
          // EditableText posts TextInput.show the moment the field gains
          // focus (it gets a keyboard token from every focus request); on a
          // real TV that keyboard then swallows every DPAD key. Close it on
          // the next frame — after EditableText's show — so navigation keys
          // keep reaching us. OK below reopens it when typing is wanted.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && selected && !_imeWanted) {
              SystemChannels.textInput.invokeMethod('TextInput.hide');
            }
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        // The 4px border is laid out even when transparent, so focusing
        // never shifts the layout.
        decoration: BoxDecoration(
          border: Border.all(
              width: 4, color: selected ? gold : Colors.transparent),
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? [BoxShadow(color: gold.withValues(alpha: 0.55), blurRadius: 14)]
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}
