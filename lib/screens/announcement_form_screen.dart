import 'package:flutter/material.dart';
import '../data/sample_data.dart';
import '../models/announcement.dart';

/// Add a new item, or edit one when `existing` is given.
class AnnouncementFormScreen extends StatefulWidget {
  final Announcement? existing;
  const AnnouncementFormScreen({super.key, this.existing});

  @override
  State<AnnouncementFormScreen> createState() => _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState extends State<AnnouncementFormScreen> {
  final formKey = GlobalKey<FormState>();
  late String type = widget.existing?.type ?? 'Announcement';
  late String category = widget.existing?.category ?? 'General';
  late bool featured = widget.existing?.isFeatured ?? false;
  late final title = TextEditingController(text: widget.existing?.title);
  late final description =
      TextEditingController(text: widget.existing?.description);
  late final date = TextEditingController(text: widget.existing?.date);
  late final time = TextEditingController(text: widget.existing?.time);
  late final location = TextEditingController(text: widget.existing?.location);

  @override
  void dispose() {
    for (final c in [title, description, date, time, location]) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration decoration(String label, [IconData? icon]) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: icon == null ? null : Icon(icon),
      );

  Future<void> pickDate() async {
    final d = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2035));
    if (d != null) date.text = formatDate(d);
  }

  Future<void> pickTime() async {
    final t =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null && mounted) time.text = t.format(context);
  }

  String? requiredField(String? v, String message) =>
      (v == null || v.trim().isEmpty) ? message : null;

  void save() {
    if (!formKey.currentState!.validate()) return; // show errors, add nothing

    final editing = widget.existing != null;
    final item = Announcement(
      id: widget.existing?.id ?? newId(),
      type: type,
      title: title.text.trim(),
      description: description.text.trim(),
      date: date.text,
      time: time.text,
      location: location.text.trim(),
      category: category,
      isFeatured: featured,
    );

    setState(() {
      if (featured) {
        // Only one featured item at a time.
        for (final a in announcements) {
          a.isFeatured = false;
        }
      }
      final i = announcements.indexWhere((a) => a.id == item.id);
      if (i == -1) {
        announcements.add(item);
      } else {
        announcements[i] = item;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(editing
            ? 'Announcement updated successfully!'
            : 'Announcement added successfully!')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);
    const big = TextStyle(fontSize: 20, color: Colors.black);
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.existing == null
              ? 'Add Announcement / Event'
              : 'Edit Announcement')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          // White card so the form reads clearly on the navy page background.
          child: Card(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(children: [
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    style: big,
                    decoration: decoration('Type'),
                    items: itemTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => type = v!),
                  ),
                  gap,
                  TextFormField(
                    controller: title,
                    style: big,
                    decoration: decoration('Title'),
                    validator: (v) => requiredField(v, 'Please enter a title.'),
                  ),
                  gap,
                  TextFormField(
                    controller: description,
                    style: big,
                    maxLines: 3,
                    decoration: decoration('Description'),
                    validator: (v) =>
                        requiredField(v, 'Please enter a description.'),
                  ),
                  gap,
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                          controller: date,
                          style: big,
                          readOnly: true,
                          onTap: pickDate,
                          decoration: decoration('Date', Icons.calendar_today)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                          controller: time,
                          style: big,
                          readOnly: true,
                          onTap: pickTime,
                          decoration: decoration('Time', Icons.access_time)),
                    ),
                  ]),
                  gap,
                  TextFormField(
                      controller: location,
                      style: big,
                      decoration: decoration('Location', Icons.place)),
                  gap,
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    style: big,
                    decoration: decoration('Category'),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => category = v!),
                  ),
                  SwitchListTile(
                    title: const Text('Show as the featured announcement',
                        style: TextStyle(fontSize: 18)),
                    value: featured,
                    onChanged: (v) => setState(() => featured = v),
                  ),
                  gap,
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      key: const Key('submitButton'),
                      onPressed: save,
                      icon: const Icon(Icons.check),
                      label: Text(
                          widget.existing == null ? 'Add' : 'Save Changes',
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
