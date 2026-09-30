import 'package:flutter/material.dart';
import '../data/sample_data.dart';
import '../models/announcement.dart';
import '../widgets/announcement_card.dart';
import '../widgets/header_widget.dart';
import 'announcement_form_screen.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  String orDash(String v) => v.isEmpty ? '—' : v;

  // Search / filter state (local only, rebuilt with setState).
  String search = '';
  String typeFilter = 'All';
  String categoryFilter = 'All';

  List<Announcement> get filtered => announcements.where((a) {
        final q = search.trim().toLowerCase();
        final text = q.isEmpty ||
            a.title.toLowerCase().contains(q) ||
            a.description.toLowerCase().contains(q) ||
            a.location.toLowerCase().contains(q);
        final type = typeFilter == 'All' || a.type == typeFilter;
        final cat = categoryFilter == 'All' || a.category == categoryFilter;
        return text && type && cat;
      }).toList();

  bool get noMatch => announcements.isNotEmpty && filtered.isEmpty;

  Widget dropdown(
          String value, List<String> items, void Function(String?) onChanged) =>
      DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true, // long labels ellipsize instead of overflowing
        style: const TextStyle(fontSize: 18, color: Colors.black),
        decoration:
            const InputDecoration(isDense: true, border: OutlineInputBorder()),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      );

  Future<void> openForm([Announcement? item]) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AnnouncementFormScreen(existing: item)));
    setState(() {});
  }

  void viewItem(Announcement a) => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(a.title),
          content: SingleChildScrollView(
            child: Text('${a.description}\n\n'
                'Type: ${a.type}\nCategory: ${a.category}\n'
                'Date: ${orDash(a.date)}\nTime: ${orDash(a.time)}\nLocation: ${orDash(a.location)}'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CLOSE'))
          ],
        ),
      );

  Future<void> deleteItem(Announcement a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Announcement?'),
        content:
            const Text('Are you sure you want to delete this announcement?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('DELETE')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => announcements.remove(a));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Announcement deleted.')));
    }
  }

  Widget statCard(String label, String type) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Text('${announcements.where((a) => a.type == type).length}',
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold, color: navy)),
              FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, style: const TextStyle(fontSize: 18))),
            ]),
          ),
        ),
      );

  Widget recordCard(Announcement a) {
    final (icon, color) = categoryStyle(a.category);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text('${a.type}  •  ${a.category}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: navy, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            if (a.isFeatured) const Icon(Icons.star, color: gold),
          ]),
          const SizedBox(height: 8),
          Text(a.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Date: ${orDash(a.date)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18)),
          Text('Time: ${orDash(a.time)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18)),
          Text('Location: ${orDash(a.location)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18)),
          const Spacer(),
          Wrap(spacing: 4, children: [
            TextButton.icon(
                onPressed: () => viewItem(a),
                icon: const Icon(Icons.visibility),
                label: const Text('View')),
            TextButton.icon(
                onPressed: () => openForm(a),
                icon: const Icon(Icons.edit),
                label: const Text('Edit')),
            TextButton.icon(
              onPressed: () => deleteItem(a),
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Summary / Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add New', style: TextStyle(fontSize: 18)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            statCard('Announcements', 'Announcement'),
            statCard('Events', 'Event'),
            statCard('Reminders', 'Reminder'),
            statCard('Schedule Items', 'Schedule'),
          ]),
        ),
        // Search + type/category filters for the records below.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            Expanded(
              flex: 3,
              child: TextField(
                style: const TextStyle(fontSize: 18),
                onChanged: (v) => setState(() => search = v),
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search title, description or location',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
                flex: 2,
                child: dropdown(typeFilter, ['All', ...itemTypes],
                    (v) => setState(() => typeFilter = v ?? 'All'))),
            const SizedBox(width: 12),
            Expanded(
                flex: 2,
                child: dropdown(categoryFilter, ['All', ...categories],
                    (v) => setState(() => categoryFilter = v ?? 'All'))),
          ]),
        ),
        Expanded(
          child: announcements.isEmpty
              ? const Center(
                  child: Text('No announcements available.',
                      style: TextStyle(fontSize: 24, color: Colors.white)))
              : noMatch
                  ? const Center(
                      child: Text('No records match your search.',
                          style: TextStyle(fontSize: 24, color: Colors.white)))
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 560,
                        mainAxisExtent: 270,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => recordCard(filtered[i]),
                    ),
        ),
      ]),
    );
  }
}
