import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/bloom_provider.dart';
import '../../models/day_note.dart';
import '../../theme/bloom_theme.dart';

class DayDetailScreen extends StatefulWidget {
  final DateTime date;
  const DayDetailScreen({super.key, required this.date});
  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  String? _mood;
  String? _flowLevel;
  int _cramps = 0;
  final _contentCtrl = TextEditingController();
  final _symptoms = <String>[];
  DayNote? _existing;
  bool _isLoading = true;
  bool _isAILoading = false;
  String? _aiReliefTips;

  static const _moods = ['😊', '😢', '😠', '😰', '😴', '🥰', '😐'];
  static const _flows = ['None', 'Light', 'Medium', 'Heavy'];
  static const _symptomList = [
    'Headache',
    'Bloating',
    'Fatigue',
    'Backache',
    'Breast tenderness',
    'Insomnia',
    'Cravings',
    'Nausea',
  ];

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    final prov = context.read<BloomProvider>();
    final note = await prov.getNoteForDate(widget.date);
    if (!mounted) return;
    if (note != null) {
      setState(() {
        _existing = note;
        _mood = note.mood;
        _flowLevel = note.flowLevel;
        _cramps = note.crampsSeverity;
        _contentCtrl.text = note.content;
        _symptoms.clear();
        _symptoms.addAll(note.symptoms);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('EEEE, MMM d, yyyy').format(widget.date)),
        actions: [
          if (_existing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: BloomColors.periodRed),
              tooltip: 'Delete Note',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          children: [
            // Flow Level
            _card(
              'Flow Level',
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _flows
                      .map((f) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(f),
                              selected: _flowLevel == f,
                              onSelected: (_) => setState(() => _flowLevel = f),
                              selectedColor: BloomColors.periodRed.withValues(alpha: 0.15),
                              labelStyle: TextStyle(
                                color: _flowLevel == f ? BloomColors.periodRed : BloomColors.ink,
                                fontWeight: _flowLevel == f ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Mood
            _card(
              'Mood',
              Wrap(
                spacing: 8,
                children: _moods
                    .map((m) => ChoiceChip(
                          label: Text(m, style: const TextStyle(fontSize: 22)),
                          selected: _mood == m,
                          onSelected: (_) => setState(() => _mood = _mood == m ? null : m),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Cramps Severity
            _card(
              'Cramps Severity',
              Column(
                children: [
                  Slider(
                    value: _cramps.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    activeColor: BloomColors.periodRed,
                    onChanged: (v) => setState(() => _cramps = v.round()),
                  ),
                  Text(
                    _cramps == 0
                        ? 'No cramps (0/10)'
                        : _cramps <= 3
                            ? 'Mild ($_cramps/10)'
                            : _cramps <= 6
                                ? 'Moderate ($_cramps/10)'
                                : 'Severe ($_cramps/10)',
                    style: const TextStyle(color: BloomColors.muted, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Symptoms
            _card(
              'Symptoms',
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _symptomList
                    .map((s) => FilterChip(
                          label: Text(s, style: const TextStyle(fontSize: 12)),
                          selected: _symptoms.contains(s),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              _symptoms.add(s);
                            } else {
                              _symptoms.remove(s);
                            }
                          }),
                          selectedColor: BloomColors.sage.withValues(alpha: 0.18),
                          checkmarkColor: BloomColors.sage,
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),

            // AI Symptom Relief Helper Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    BloomColors.rose500.withValues(alpha: 0.08),
                    BloomColors.sage.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BloomColors.rose500.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: BloomColors.rose500, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Bloom AI Relief Suggestions',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: BloomColors.ink),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _isAILoading ? null : _fetchAIRelief,
                        child: _isAILoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: BloomColors.rose500),
                              )
                            : const Text('Get Relief Tips', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  if (_aiReliefTips != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _aiReliefTips!,
                      style: const TextStyle(fontSize: 13, color: BloomColors.ink, height: 1.4),
                    ),
                  ] else
                    const Text(
                      'Tap "Get Relief Tips" for holistic, herbal, and gentle movement remedies for your current symptoms.',
                      style: TextStyle(fontSize: 12, color: BloomColors.muted),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Daily Note Text
            _card(
              'Daily Note',
              TextField(
                controller: _contentCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'How are you feeling today? Any observations or details...',
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: false,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text('Save Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchAIRelief() async {
    setState(() => _isAILoading = true);
    final ai = context.read<BloomProvider>().aiService;

    try {
      final tips = await ai.generateSymptomRelief(
        symptoms: _symptoms,
        crampSeverity: _cramps,
        mood: _mood,
      );
      if (mounted) {
        setState(() {
          _aiReliefTips = tips;
          _isAILoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isAILoading = false);
    }
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final prov = context.read<BloomProvider>();

    final note = DayNote(
      id: _existing?.id,
      date: DateTime(widget.date.year, widget.date.month, widget.date.day),
      content: _contentCtrl.text.trim(),
      mood: _mood,
      flowLevel: _flowLevel,
      crampsSeverity: _cramps,
      symptoms: _symptoms,
    );

    await prov.saveNote(note);

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Note saved successfully'),
        duration: Duration(seconds: 2),
      ),
    );
    navigator.pop();
  }

  Future<void> _confirmDelete() async {
    if (_existing?.id == null) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final prov = context.read<BloomProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('Are you sure you want to delete the notes for this day?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: BloomColors.periodRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await prov.deleteNote(_existing!.id!);
      messenger.showSnackBar(
        const SnackBar(content: Text('Note deleted')),
      );
      navigator.pop();
    }
  }

  Widget _card(String title, Widget child) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: BloomColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }
}
