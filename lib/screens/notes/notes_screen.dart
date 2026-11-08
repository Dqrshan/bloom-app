import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/day_note.dart';
import '../../services/bloom_provider.dart';
import '../../theme/bloom_theme.dart';
import '../../theme/design_system.dart';
import '../day/day_detail_screen.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BloomProvider>(
      builder: (context, prov, _) {
        final notes = [...prov.notes]..sort((a, b) => b.date.compareTo(a.date));
        final p = BloomPalette.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BloomDesign.gutter,
                12,
                BloomDesign.gutter,
                0,
              ),
              child: BloomPageHeader(
                title: 'Daily Notes',
                actions: [
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: p.notes),
                    tooltip: 'Add note for today',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DayDetailScreen(date: DateTime.now()),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: notes.isEmpty
                  ? BloomDesign.emptyState(
                      context,
                      icon: Icons.edit_note_rounded,
                      iconColor: p.notes,
                      title: 'No notes logged yet',
                      subtitle:
                          'Tap the button above or any day on the calendar to record mood, flow, symptoms, and daily thoughts.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        BloomDesign.gutter,
                        0,
                        BloomDesign.gutter,
                        24,
                      ),
                      itemCount: notes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _NoteCard(
                        note: notes[i],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                DayDetailScreen(date: notes[i].date),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  final DayNote note;
  final VoidCallback onTap;

  const _NoteCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = BloomPalette.of(context);
    final theme = Theme.of(context);

    final tags = <Widget>[];
    if (note.flowLevel != null && note.flowLevel != 'None') {
      tags.add(_Tag(label: note.flowLevel!, color: p.period));
    }
    if (note.crampsSeverity > 0) {
      tags.add(
        _Tag(label: 'Cramps ${note.crampsSeverity}/10', color: p.predicted),
      );
    }

    return BloomDesign.card(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('EEE, MMM d, yyyy').format(note.date),
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    if (note.mood != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          note.mood!,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                  ],
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 6, children: tags),
                ],
                if (note.content.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: p.inkLight,
                      height: 1.4,
                    ),
                  ),
                ],
                if (note.symptoms.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: note.symptoms
                        .take(4)
                        .map((s) => _Tag(label: s, color: p.fertile))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontVariations: const [FontVariation('wght', 600)],
          color: color,
        ),
      ),
    );
  }
}
