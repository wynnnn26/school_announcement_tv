import 'package:flutter/material.dart';

import '../models/announcement.dart';
import 'tv_focus.dart';

/// Remote-friendly date picker: Day / Month / Year dropdowns + CANCEL/OK.
/// Dropdown menus, focus rings and OK handling all work with a D-pad.
/// Returns the chosen date, or null when cancelled.
Future<DateTime?> showTvDatePicker(BuildContext context,
        {required DateTime initial}) =>
    showDialog<DateTime>(
        context: context, builder: (_) => _TvDatePicker(initial: initial));

/// Remote-friendly time picker: Hour / Minute / AM-PM dropdowns + CANCEL/OK.
Future<TimeOfDay?> showTvTimePicker(BuildContext context,
        {required TimeOfDay initial}) =>
    showDialog<TimeOfDay>(
        context: context, builder: (_) => _TvTimePicker(initial: initial));

final _years = [for (var y = 2020; y <= 2035; y) '$y'];

/// One labelled dropdown row inside a picker dialog. Only the first field
/// should pass `autofocus: true` so the remote always starts somewhere sane.
Widget _field(String label, List<String> items, String value,
    ValueChanged<String> onChanged,
    {bool autofocus = false}) {
  return TvFocusable(
    focusable: false,
    child: DropdownButtonFormField<String>(
      autofocus: autofocus,
      initialValue: value,
      decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true),
      items: items
          .map((i) => DropdownMenuItem(value: i, child: Text(i)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    ),
  );
}

/// CANCEL / OK row. Both are reachable by D-pad and activate on OK press.
List<Widget> _actions(VoidCallback cancel, VoidCallback confirm) => [
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TvFocusable(
          focusable: false,
          onPressed: cancel,
          child: TextButton(
              onPressed: cancel, child: const Text('CANCEL')),
        ),
        const SizedBox(width: 8),
        TvFocusable(
          focusable: false,
          onPressed: confirm,
          child: TextButton(onPressed: confirm, child: const Text('OK')),
        ),
      ]),
    ];

class _TvDatePicker extends StatefulWidget {
  const _TvDatePicker({required this.initial});
  final DateTime initial;

  @override
  State<_TvDatePicker> createState() => _TvDatePickerState();
}

class _TvDatePickerState extends State<_TvDatePicker> {
  late int year = widget.initial.year.clamp(2020, 2035);
  late int month = widget.initial.month;
  late int day = widget.initial.day;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 12);
    return AlertDialog(
      title: const Text('Select date'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        // Day always offers 1..31; a too-large day for a short month is
        // clamped when the user presses OK (no invalid dropdown state).
        _field('Day', [for (var d = 1; d <= 31; d++) '$d'], '$day',
            (v) => setState(() => day = int.parse(v)),
            autofocus: true),
        gap,
        _field('Month', monthNames, monthNames[month - 1],
            (v) => setState(() => month = monthNames.indexOf(v) + 1)),
        gap,
        _field('Year', _years, '$year', (v) => setState(() => year = int.parse(v))),
      ]),
      actions: _actions(
        () => Navigator.pop(context),
        () => Navigator.pop(
            context,
            DateTime(
                year, month, day > DateTime(year, month + 1, 0).day
                    ? DateTime(year, month + 1, 0).day
                    : day)),
      ),
    );
  }
}

class _TvTimePicker extends StatefulWidget {
  const _TvTimePicker({required this.initial});
  final TimeOfDay initial;

  @override
  State<_TvTimePicker> createState() => _TvTimePickerState();
}

class _TvTimePickerState extends State<_TvTimePicker> {
  late int hour12 =
      widget.initial.hour % 12 == 0 ? 12 : widget.initial.hour % 12;
  late bool pm = widget.initial.hour >= 12;
  late int minute = widget.initial.minute;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 12);
    return AlertDialog(
      title: const Text('Select time'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _field('Hour', [for (var h = 1; h <= 12; h++) '$h'], '$hour12',
            (v) => setState(() => hour12 = int.parse(v)),
            autofocus: true),
        gap,
        _field('Minute', [for (var m = 0; m < 60; m++) m.toString().padLeft(2, '0')],
            minute.toString().padLeft(2, '0'),
            (v) => setState(() => minute = int.parse(v))),
        gap,
        _field('AM/PM', const ['AM', 'PM'], pm ? 'PM' : 'AM',
            (v) => setState(() => pm = v == 'PM')),
      ]),
      actions: _actions(
        () => Navigator.pop(context),
        () => Navigator.pop(
            context,
            TimeOfDay(
                hour: pm ? (hour12 % 12) + 12 : hour12 % 12,
                minute: minute)),
      ),
    );
  }
}
