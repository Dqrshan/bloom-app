import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/bloom_provider.dart';
import '../theme/bloom_theme.dart';

class LogPeriodDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  const LogPeriodDialog({super.key, this.initialStartDate});

  static Future<void> show(BuildContext context, {DateTime? initialDate}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogPeriodDialog(initialStartDate: initialDate),
    );
  }

  @override
  State<LogPeriodDialog> createState() => _LogPeriodDialogState();
}

class _LogPeriodDialogState extends State<LogPeriodDialog> {
  late DateTime _startDate;
  DateTime? _endDate;
  bool _isOngoing = false;
  int _selectedLengthPreset = 5;
  final _notesCtrl = TextEditingController();

  final _presets = [3, 4, 5, 6, 7];

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate ?? DateTime.now();
    _endDate = _startDate.add(Duration(days: _selectedLengthPreset - 1));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: BloomColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Log Period / Past Period',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: BloomColors.ink,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: BloomColors.muted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Start Date picker
            const Text(
              'START DATE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: BloomColors.muted, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickStartDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: BloomColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BloomColors.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_startDate),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: BloomColors.ink),
                    ),
                    const Icon(Icons.calendar_today_rounded, size: 18, color: BloomColors.rose500),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ongoing toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ongoing Period', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: BloomColors.ink)),
                    Text('Check if period has not ended yet', style: TextStyle(fontSize: 12, color: BloomColors.muted)),
                  ],
                ),
                Switch.adaptive(
                  value: _isOngoing,
                  activeTrackColor: BloomColors.periodRed,
                  onChanged: (val) {
                    setState(() {
                      _isOngoing = val;
                      if (val) {
                        _endDate = null;
                      } else {
                        _endDate = _startDate.add(Duration(days: _selectedLengthPreset - 1));
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (!_isOngoing) ...[
              // Period Duration Presets
              const Text(
                'PERIOD DURATION (DAYS)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: BloomColors.muted, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              Row(
                children: _presets.map((days) {
                  final isSelected = _selectedLengthPreset == days && _endDate != null;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: ChoiceChip(
                        label: Text('$days d', style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                        selected: isSelected,
                        selectedColor: BloomColors.periodRed.withValues(alpha: 0.15),
                        labelStyle: TextStyle(color: isSelected ? BloomColors.periodRed : BloomColors.ink),
                        onSelected: (_) {
                          setState(() {
                            _selectedLengthPreset = days;
                            _endDate = _startDate.add(Duration(days: days - 1));
                          });
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // End Date picker
              const Text(
                'END DATE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: BloomColors.muted, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickEndDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: BloomColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BloomColors.divider),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _endDate != null
                            ? DateFormat('EEEE, MMMM d, yyyy').format(_endDate!)
                            : 'Select End Date',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: BloomColors.ink),
                      ),
                      const Icon(Icons.event_available_rounded, size: 18, color: BloomColors.rose500),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Notes
            const Text(
              'NOTES (OPTIONAL)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: BloomColors.muted, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                hintText: 'Flow intensity, symptoms, or notes...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _savePeriod,
                icon: const Icon(Icons.water_drop_rounded, size: 18),
                label: const Text('Save Period Log'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BloomColors.periodRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (!_isOngoing) {
          _endDate = _startDate.add(Duration(days: _selectedLengthPreset - 1));
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 4)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 10)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _selectedLengthPreset = picked.difference(_startDate).inDays + 1;
      });
    }
  }

  Future<void> _savePeriod() async {
    final messenger = ScaffoldMessenger.of(context);
    final prov = context.read<BloomProvider>();
    final navigator = Navigator.of(context);

    await prov.logPastPeriod(
      startDate: _startDate,
      endDate: _isOngoing ? null : _endDate,
      periodLength: _isOngoing ? null : _selectedLengthPreset,
      notes: _notesCtrl.text.trim(),
    );

    messenger.showSnackBar(
      const SnackBar(content: Text('Period log saved successfully')),
    );
    navigator.pop();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }
}
