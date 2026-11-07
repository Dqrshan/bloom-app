import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/bloom_provider.dart';
import '../../models/day_note.dart';
import '../../theme/design_system.dart';
import '../../theme/bloom_theme.dart';

class DayDetailScreen extends StatefulWidget {
  final DateTime date;
  const DayDetailScreen({required this.date, super.key});
  @override State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  String? _mood;
  String? _flowLevel;
  int _cramps = 0;
  final _contentCtrl = TextEditingController();
  final _symptoms = <String>[];
  DayNote? _existing;
  bool _isLoading = true;

  static const _moods = ['😊', '😢', '😠', '😰', '😴', '🥰', '😐'];
  static const _flows = ['None', 'Light', 'Medium', 'Heavy'];
  static const _symptomList = [
    'Headache', 'Bloating', 'Fatigue', 'Backache',
    'Breast tenderness', 'Insomnia', 'Cravings', 'Nausea',
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('EEEE, MMM d, yyyy').format(widget.date),
          style: BloomDesign.h3.copyWith(color: BloomColors.ink),
        ),
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
        child: Column(
          children: [
            _buildFlowLevel(),
            const SizedBox(height: BloomDesign.md),
            _buildMood(),
            const SizedBox(height: BloomDesign.md),
            _buildCramps(),
            const SizedBox(height: BloomDesign.md),
            _buildSymptoms(),
            const SizedBox(height: BloomDesign.md),
            _buildNotes(),
            const SizedBox(height: BloomDesign.xl),
            BloomDesign.primaryButton(
              label: 'Save Entry',
              onPressed: _save,
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowLevel() {
    return _buildCard('Flow Level', Wrap(
      spacing: BloomDesign.sm,
      children: _flows.map((f) => BloomDesign.pillChip(
        label: f,
        selected: _flowLevel == f,
        onTap: () => setState(() => _flowLevel = f),
        activeColor: BloomColors.periodRed,
      )).toList(),
    ));
  }

  Widget _buildMood() {
    return _buildCard('Mood', Wrap(
      spacing: BloomDesign.sm,
      children: _moods.map((m) => BloomDesign.pillChip(
        label: m,
        selected: _mood == m,
        onTap: () => setState(() => _mood = _mood == m ? null : m),
        activeColor: BloomColors.lavender,
      )).toList(),
    ));
  }

  Widget _buildCramps() {
    return _buildCard('Cramps', Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slider(
          value: _cramps.toDouble(),
          min: 0,
          max: 10,
          divisions: 10,
          activeColor: BloomColors.periodRed,
          label: '$_cramps/10',
          onChanged: (v) => setState(() => _cramps = v.round()),
        ),
        Text(
          _cramps == 0 ? 'No cramps' : _cramps <= 3 ? 'Mild' : _cramps <= 6 ? 'Moderate' : 'Severe',
          style: BloomDesign.caption.copyWith(color: BloomColors.muted),
        ),
      ],
    ));
  }

  Widget _buildSymptoms() {
    return _buildCard('Symptoms', Wrap(
      spacing: BloomDesign.sm,
      runSpacing: BloomDesign.sm,
      children: _symptomList.map((s) => BloomDesign.pillChip(
        label: s,
        selected: _symptoms.contains(s),
        onTap: () => setState(() => _symptoms.contains(s) ? _symptoms.remove(s) : _symptoms.add(s)),
        activeColor: BloomColors.sage,
      )).toList(),
    ));
  }

  Widget _buildNotes() {
    return _buildCard('Notes', BloomDesign.textField(
      controller: _contentCtrl,
      hint: 'How are you feeling today?',
      maxLines: 3,
    ));
  }

  Widget _buildCard(String title, Widget child) {
    return BloomDesign.card(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: BloomDesign.label.copyWith(color: BloomColors.ink)),
        const SizedBox(height: 10), child,
      ]),
    );
  }

  Future<void> _save() async {
    final note = DayNote(id: _existing?.id, date: DateTime(widget.date.year, widget.date.month, widget.date.day),
      content: _contentCtrl.text.trim(), mood: _mood, flowLevel: _flowLevel, crampsSeverity: _cramps, symptoms: _symptoms);
    await context.read<BloomProvider>().saveNote(note);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note saved')));
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    if (_existing?.id == null) return;
    final confirmed = await showDialog<bool>(context: context,
      builder: (ctx) => AlertDialog(title: const Text('Delete note?'),
        content: const Text('Are you sure?'), actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<BloomProvider>().deleteNote(_existing!.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note deleted')));
    Navigator.of(context).pop();
  }
}
