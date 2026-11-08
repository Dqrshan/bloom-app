import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/day_note.dart';
import '../../services/bloom_provider.dart';
import '../../theme/bloom_theme.dart';
import '../../theme/design_system.dart';

class DayDetailScreen extends StatefulWidget {
  final DateTime date;

  const DayDetailScreen({required this.date, super.key});

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

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    final prov = context.read<BloomProvider>();
    final note = await prov.getNoteForDate(widget.date);
    if (!mounted) return;
    setState(() {
      if (note != null) {
        _existing = note;
        _mood = note.mood;
        _flowLevel = note.flowLevel;
        _cramps = note.crampsSeverity;
        _contentCtrl.text = note.content;
        _symptoms
          ..clear()
          ..addAll(note.symptoms);
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = BloomPalette.of(context);
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('EEEE, MMM d, yyyy').format(widget.date),
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          if (_existing != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: p.period),
              tooltip: 'Delete Note',
              onPressed: _confirmDelete,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BloomDesign.gutter,
          12,
          BloomDesign.gutter,
          28,
        ),
        children: [
          _buildFlowLevel(),
          const SizedBox(height: 14),
          _buildMood(),
          const SizedBox(height: 14),
          _buildCramps(),
          const SizedBox(height: 14),
          _buildSymptoms(),
          const SizedBox(height: 14),
          _buildRelief(),
          const SizedBox(height: 14),
          _buildNotes(),
          const SizedBox(height: 24),
          BloomDesign.primaryButton(
            context,
            label: 'Save Entry',
            onPressed: _save,
            icon: Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildFlowLevel() {
    return _card(
      'Flow Level',
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _flows
            .map(
              (f) => BloomDesign.pillChip(
                context,
                label: f,
                selected: _flowLevel == f,
                onTap: () => setState(() => _flowLevel = f),
                activeColor: BloomPalette.of(context).period,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMood() {
    return _card(
      'Mood',
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _moods
            .map(
              (m) => BloomDesign.pillChip(
                context,
                label: m,
                selected: _mood == m,
                onTap: () => setState(() => _mood = _mood == m ? null : m),
                activeColor: BloomPalette.of(context).notes,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCramps() {
    final p = BloomPalette.of(context);
    final theme = Theme.of(context);
    return _card(
      'Cramps',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Slider(
            value: _cramps.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            label: '$_cramps/10',
            onChanged: (v) => setState(() => _cramps = v.round()),
          ),
          Text(
            _cramps == 0
                ? 'No cramps'
                : _cramps <= 3
                ? 'Mild'
                : _cramps <= 6
                ? 'Moderate'
                : 'Severe',
            style: theme.textTheme.bodySmall?.copyWith(color: p.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptoms() {
    return _card(
      'Symptoms',
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _symptomList
            .map(
              (s) => BloomDesign.pillChip(
                context,
                label: s,
                selected: _symptoms.contains(s),
                onTap: () => setState(() {
                  _symptoms.contains(s)
                      ? _symptoms.remove(s)
                      : _symptoms.add(s);
                }),
                activeColor: BloomPalette.of(context).fertile,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildRelief() {
    final p = BloomPalette.of(context);
    final theme = Theme.of(context);

    return BloomDesign.card(
      color: p.notesContainer,
      borderColor: p.notes.withValues(alpha: 0.28),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: p.notes, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bloom AI Relief Suggestions',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              TextButton(
                onPressed: _isAILoading ? null : _fetchAIRelief,
                child: _isAILoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.8),
                      )
                    : const Text('Get Relief Tips'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_aiReliefTips != null)
            Text(
              _aiReliefTips!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: p.inkLight,
                height: 1.45,
              ),
            )
          else
            Text(
              'Tap "Get Relief Tips" for holistic, herbal, and gentle movement remedies for your current symptoms.',
              style: theme.textTheme.bodySmall?.copyWith(color: p.muted),
            ),
        ],
      ),
    );
  }

  Widget _buildNotes() {
    return _card(
      'Notes',
      BloomDesign.textField(
        context,
        controller: _contentCtrl,
        hint: 'How are you feeling today?',
        maxLines: 3,
      ),
    );
  }

  Widget _card(String title, Widget child) {
    final theme = Theme.of(context);
    return BloomDesign.card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          child,
        ],
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
    final note = DayNote(
      id: _existing?.id,
      date: DateTime(widget.date.year, widget.date.month, widget.date.day),
      content: _contentCtrl.text.trim(),
      mood: _mood,
      flowLevel: _flowLevel,
      crampsSeverity: _cramps,
      symptoms: _symptoms,
    );
    await context.read<BloomProvider>().saveNote(note);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Note saved')));
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    if (_existing?.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: BloomPalette.of(ctx).period,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<BloomProvider>().deleteNote(_existing!.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Note deleted')));
    Navigator.of(context).pop();
  }
}
