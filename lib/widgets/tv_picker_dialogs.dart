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

// Written out as a const so opening the Date picker allocates nothing: on
// the device the heap sits near its cap and this list's lazy init was the
// exact allocation that died (round-2 report 8.2.1).
const _years = [
  '2020', '2021', '2022', '2023', '2024', '2025', '2026', '2027',
  '2028', '2029', '2030', '2031', '2032', '2033', '2034', '2035',
];

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

  /// Real length of the selected month — the Day menu only offers these
  /// days, so an invalid date like February 31 cannot be selected at all.
  int get _daysInMonth => DateTime(year, month + 1, 0).day;

  void _setMonth(int v) => setState(() {
        month = v;
        if (day > _daysInMonth) day = _daysInMonth;
      });

  void _setYear(int v) => setState(() {
        year = v;
        if (day > _daysInMonth) day = _daysInMonth;
      });

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 12);
    return AlertDialog(
      title: const Text('Select date'),
      // stretch: every row spans the dialog width, so Down always moves
      // to the row below (fields → CANCEL → OK) with no spatial gaps.
      content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('Day', [for (var d = 1; d <= _daysInMonth; d++) '$d'], '$day',
                (v) => setState(() => day = int.parse(v)),
                autofocus: true),
            gap,
            _field('Month', monthNames, monthNames[month - 1],
                (v) => _setMonth(monthNames.indexOf(v) + 1)),
            gap,
            _field(
                'Year', _years, '$year', (v) => _setYear(int.parse(v))),
          ]),
      actions: _actions(
        () => Navigator.pop(context),
        () => Navigator.pop(context, DateTime(year, month, day)),
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
      content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('Hour', [for (var h = 1; h <= 12; h++) '$h'], '$hour12',
                (v) => setState(() => hour12 = int.parse(v)),
                autofocus: true),
            gap,
            _field(
                'Minute',
                [for (var m = 0; m < 60; m++) m.toString().padLeft(2, '0')],
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
