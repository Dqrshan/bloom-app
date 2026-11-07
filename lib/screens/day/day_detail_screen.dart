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
        title: Text(DateFormat('EEEE, MMM d, yyyy').format(widget.date)),
        actions: [
          if (_existing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete Note',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          children: [
            _buildFlowLevel(),
            _buildMood(),
            _buildCramps(),
            _buildSymptoms(),
            _buildNotes(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Save Entry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowLevel() {
    List<Widget> flowWidgets = [];
    for (var f in _flows) {
      flowWidgets.add(Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(f),
          selected: _flowLevel == f,
          onSelected: (_) => setState(() => _flowLevel = f),
          selectedColor: Colors.redAccent.withValues(alpha: 0.15),
          labelStyle: TextStyle(color: _flowLevel == f ? Colors.red : Colors.black87,
            fontWeight: _flowLevel == f ? FontWeight.w600 : FontWeight.normal),
        ),
      ));
    }
    return _buildCard('Flow Level', SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: flowWidgets),
    ));
  }

  Widget _buildMood() {
    return _buildCard('Mood', DropdownButtonFormField<String>(
      initialValue: _mood,
      decoration: const InputDecoration(hintText: 'Select mood'),
      items: _moods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
      onChanged: (v) => setState(() => _mood = v),
    ));
  }

  Widget _buildCramps() {
    return _buildCard('Cramps', DropdownButtonFormField<int>(
      initialValue: _cramps,
      decoration: const InputDecoration(hintText: 'Select cramp severity'),
      items: List.generate(11, (i) => DropdownMenuItem(value: i, child: Text('$i/10'))).toList(),
      onChanged: (v) => setState(() => _cramps = v!),
    ));
  }

  Widget _buildSymptoms() {
    List<Widget> symptomWidgets = [];
    for (var s in _symptomList) {
      symptomWidgets.add(Padding(
        padding: const EdgeInsets.only(right: 4),
        child: FilterChip(
          label: Text(s), selected: _symptoms.contains(s),
          onSelected: (v) => setState(() => _symptoms.contains(s) ? _symptoms.remove(s) : _symptoms.add(s)),
        ),
      ));
    }
    return _buildCard('Symptoms', Wrap(children: symptomWidgets));
  }

  Widget _buildNotes() {
    return _buildCard('Notes', TextField(controller: _contentCtrl, maxLines: 3,
      decoration: const InputDecoration(hintText: 'Additional notes...')));
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
