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
    this.onPressed,
  });

  final Widget child;

  /// True: this wrapper is focusable itself (cards, rows).
  /// False: only the widget inside can be focused (buttons, fields).
  final bool focusable;

  /// Up/Down (and OK) jump between fields instead of moving the cursor.
  final bool moveFocusOnUpDown;

  /// Runs on OK / Enter / Select when set.
  final VoidCallback? onPressed;

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  bool selected = false;
  double _bottomInset = 0;

  // When the on-screen keyboard opens or closes the layout shrinks; make
  // sure the focused control stays visible above the keyboard.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bottom = MediaQuery.maybeViewInsetsOf(context)?.bottom ?? 0;
    final changed = bottom != _bottomInset;
    _bottomInset = bottom;
    if (changed && selected) _scrollIntoView();
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
      if (view.contains(child.topLeft) && view.contains(child.bottomRight)) {
        return; // already fully visible
      }
      Scrollable.ensureVisible(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      // With focusable: false the wrapper never takes primary focus itself;
      // it only rings and handles keys bubbling up from the control inside.
      canRequestFocus: widget.focusable,
      onKeyEvent: _onKey,
      onFocusChange: (hasFocus) {
        if (!mounted) return;
        setState(() => selected = hasFocus);
        if (hasFocus) _scrollIntoView();
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
