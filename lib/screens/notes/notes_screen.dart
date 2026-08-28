import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/bloom_provider.dart';
import '../../theme/bloom_theme.dart';
import 'day_detail_screen.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BloomProvider>(
      builder: (context, prov, _) {
        final notes = prov.notes;

        return SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily Notes',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: BloomColors.rose500),
                      tooltip: 'Add note for today',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DayDetailScreen(date: DateTime.now()),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (notes.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: BloomColors.rose50,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(Icons.edit_note, size: 44, color: BloomColors.rose500),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No notes logged yet',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: BloomColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap the button above or any day on the calendar to record mood, flow, symptoms, and daily thoughts.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: BloomColors.muted, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: notes.length,
                    itemBuilder: (context, i) {
                      final note = notes[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DayDetailScreen(date: note.date)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('EEE, MMM d, yyyy').format(note.date),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: BloomColors.ink,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        if (note.mood != null)
                                          Text(
                                            note.mood!,
                                            style: const TextStyle(fontSize: 18),
                                          ),
                                        if (note.flowLevel != null && note.flowLevel != 'None') ...[
                                          const SizedBox(width: 6),
                                          _tag(note.flowLevel!, BloomColors.periodRed),
                                        ],
                                        if (note.crampsSeverity > 0) ...[
                                          const SizedBox(width: 6),
                                          _tag('Cramps ${note.crampsSeverity}/10', BloomColors.peach),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                if (note.content.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    note.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: BloomColors.inkLight, fontSize: 13, height: 1.4),
                                  ),
                                ],
                                if (note.symptoms.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: note.symptoms
                                        .take(4)
                                        .map((s) => _tag(s, BloomColors.sage))
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
