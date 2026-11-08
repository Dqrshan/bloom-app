import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/bloom_provider.dart';
import '../theme/bloom_theme.dart';
import '../theme/design_system.dart';

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
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = BloomPalette.of(context);
    final theme = Theme.of(context);
    // The keyboard and the home indicator are separate insets and only one of
    // them is ever on screen at a time, so the larger one wins.
    final bottomInset = math.max(
      MediaQuery.viewInsetsOf(context).bottom,
      MediaQuery.viewPaddingOf(context).bottom,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            BloomDesign.xl,
            12,
            BloomDesign.xl,
            BloomDesign.lg + bottomInset,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Log Period / Past Period',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: p.muted),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Start date
              _fieldLabel('START DATE'),
              const SizedBox(height: 8),
              _dateField(
                label: DateFormat('EEEE, MMMM d, yyyy').format(_startDate),
                icon: Icons.calendar_today_rounded,
                color: p.period,
                onTap: _pickStartDate,
              ),
              const SizedBox(height: 20),

              // Ongoing
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ongoing Period',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Check if period has not ended yet',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: p.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _isOngoing,
                    activeTrackColor: p.period,
                    onChanged: (val) {
                      setState(() {
                        _isOngoing = val;
                        if (val) {
                          _endDate = null;
                        } else {
                          _endDate = _startDate.add(
                            Duration(days: _selectedLengthPreset - 1),
                          );
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (!_isOngoing) ...[
                _fieldLabel('PERIOD DURATION (DAYS)'),
                const SizedBox(height: 8),
                Row(
                  children: _presets.map((days) {
                    final isSelected =
                        _selectedLengthPreset == days && _endDate != null;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: SizedBox(
                          height: 42,
                          child: BloomDesign.pillChip(
                            context,
                            label: '$days d',
                            selected: isSelected,
                            activeColor: p.period,
                            onTap: () {
                              setState(() {
                                _selectedLengthPreset = days;
                                _endDate = _startDate.add(
                                  Duration(days: days - 1),
                                );
                              });
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // End date
                _fieldLabel('END DATE'),
                const SizedBox(height: 8),
                _dateField(
                  label: _endDate != null
                      ? DateFormat('EEEE, MMMM d, yyyy').format(_endDate!)
                      : 'Select End Date',
                  icon: Icons.event_available_rounded,
                  color: p.period,
                  onTap: _pickEndDate,
                ),
                const SizedBox(height: 20),
              ],

              // Notes
              _fieldLabel('NOTES (OPTIONAL)'),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Flow intensity, symptoms, or notes...',
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _savePeriod,
                  icon: const Icon(Icons.water_drop_rounded, size: 18),
                  label: const Text('Save Period Log'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.period,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(BloomDesign.radiusMd),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: BloomPalette.of(context).muted,
        letterSpacing: 0.9,
      ),
    );
  }

  Widget _dateField({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final p = BloomPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BloomDesign.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: p.surfaceAlt,
            borderRadius: BorderRadius.circular(BloomDesign.radiusMd),
            border: Border.all(color: p.divider, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: p.ink),
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
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
}
