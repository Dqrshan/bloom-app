import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/bloom_provider.dart';
import '../../services/pdf_export_service.dart';
import '../../theme/bloom_theme.dart';
import '../../theme/design_system.dart';
import '../../widgets/log_period_dialog.dart';
import '../day/day_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

/// A calendar grid grows with the space it is given, so on a wide viewport a
/// square grid turns into an oversized field of huge cells. The page holds to
/// a comfortable column width and centres instead.
const double _maxContentWidth = 440;

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Consumer<BloomProvider>(
      builder: (context, prov, _) {
        final year = _focusedMonth.year;
        final month = _focusedMonth.month;
        final daysInMonth = DateTime(year, month + 1, 0).day;
        final firstWeekday = DateTime(year, month, 1).weekday % 7;
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);

        final p = BloomPalette.of(context);
        final theme = Theme.of(context);

        final cellCount = ((firstWeekday + daysInMonth + 6) ~/ 7) * 7;

        final contentWidth = math.min(
          MediaQuery.sizeOf(context).width,
          _maxContentWidth,
        );

        return Center(
          child: SizedBox(
            width: contentWidth,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                BloomDesign.gutter,
                12,
                BloomDesign.gutter,
                24,
              ),
              children: [
                BloomPageHeader(
                  title: 'Calendar',
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.picture_as_pdf_outlined,
                        color: p.period,
                      ),
                      tooltip: 'Share PDF Report',
                      onPressed: () => _sharePdfReport(context, prov),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: () => LogPeriodDialog.show(context),
                        icon: const Icon(Icons.water_drop_rounded, size: 15),
                        label: const Text('Log Period'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: p.period,
                          foregroundColor: p.onAccent,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          minimumSize: const Size(0, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: theme.textTheme.labelMedium?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontVariations: const [FontVariation('wght', 600)],
                            color: p.onAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                BloomDesign.card(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: Column(
                    children: [
                      // Month navigation
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            tooltip: 'Previous month',
                            onPressed: () => setState(() {
                              _focusedMonth = DateTime(year, month - 1);
                            }),
                          ),
                          Expanded(
                            child: Text(
                              '${DateFormat('MMMM').format(_focusedMonth)} $year',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            tooltip: 'Next month',
                            onPressed: () => setState(() {
                              _focusedMonth = DateTime(year, month + 1);
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Weekday labels
                      Row(
                        children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                            .map(
                              (d) => Expanded(
                                child: Center(
                                  child: Text(
                                    d,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: p.muted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 6),

                      // Day grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cellCount,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              childAspectRatio: 1,
                            ),
                        itemBuilder: (context, index) {
                          final dayNumber = index - firstWeekday + 1;
                          if (dayNumber < 1 || dayNumber > daysInMonth) {
                            return const SizedBox.shrink();
                          }
                          final d = DateTime(year, month, dayNumber);
                          return _DayCell(
                            day: dayNumber,
                            isFuture: d.isAfter(todayDate),
                            isToday:
                                d.year == today.year &&
                                d.month == today.month &&
                                d.day == today.day,
                            isPeriod: prov.periodDays.any(
                              (p) =>
                                  p.year == d.year &&
                                  p.month == d.month &&
                                  p.day == d.day,
                            ),
                            isPredicted: prov.predictedDays.any(
                              (p) =>
                                  p.year == d.year &&
                                  p.month == d.month &&
                                  p.day == d.day,
                            ),
                            isFertile: prov.fertileDays.any(
                              (p) =>
                                  p.year == d.year &&
                                  p.month == d.month &&
                                  p.day == d.day,
                            ),
                            hasNote: prov.notes.any(
                              (n) =>
                                  n.date.year == d.year &&
                                  n.date.month == d.month &&
                                  n.date.day == d.day,
                            ),
                            onTap: () => _onDayTapped(context, d),
                          );
                        },
                      ),

                      const SizedBox(height: 14),
                      Divider(color: p.divider, height: 1),
                      const SizedBox(height: 14),

                      // Legend
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        runSpacing: 10,
                        spacing: 16,
                        children: [
                          _Legend(color: p.period, label: 'Period'),
                          _Legend(color: p.predicted, label: 'Predicted'),
                          _Legend(color: p.fertile, label: 'Fertile'),
                          _Legend(color: p.notes, label: 'Note'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sharePdfReport(BuildContext context, BloomProvider prov) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Generating PDF Report...'),
        duration: Duration(seconds: 1),
      ),
    );
    try {
      await PdfExportService.sharePeriodReport(
        context,
        cycles: prov.cycles,
        notes: prov.notes,
        averageCycleLength: prov.averageCycleLength,
        averagePeriodLength: prov.averagePeriodLength,
        currentDay: prov.currentDay,
        isOnPeriod: prov.isOnPeriod,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    }
  }

  void _onDayTapped(BuildContext context, DateTime date) {
    final p = BloomPalette.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: p.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.edit_note_rounded, color: p.notes),
                title: const Text('Add / View Daily Notes'),
                subtitle: const Text('Log mood, flow, symptoms, and thoughts'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DayDetailScreen(date: date),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 56, endIndent: 20),
              ListTile(
                leading: Icon(Icons.water_drop_rounded, color: p.period),
                title: const Text('Log Period Starting on this Date'),
                subtitle: const Text('Set start & end dates for this period'),
                onTap: () {
                  Navigator.pop(ctx);
                  LogPeriodDialog.show(context, initialDate: date);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isFuture;
  final bool isToday;
  final bool isPeriod;
  final bool isPredicted;
  final bool isFertile;
  final bool hasNote;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isFuture,
    required this.isToday,
    required this.isPeriod,
    required this.isPredicted,
    required this.isFertile,
    required this.hasNote,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = BloomPalette.of(context);

    Color? fill;
    var textColor = p.ink;
    Color? borderColor;

    if (isPeriod && !isFuture) {
      fill = p.periodContainer;
      textColor = p.period;
    } else if (isPredicted) {
      fill = p.predictedContainer;
      textColor = p.predicted;
      if (isFuture) {
        borderColor = p.predicted.withValues(alpha: 0.45);
      }
    } else if (isFertile) {
      fill = p.fertileContainer;
      textColor = p.fertile;
    }

    if (isFuture && !isPredicted && !isFertile) {
      textColor = p.muted.withValues(alpha: 0.55);
    }

    final diameter = math.min(38.0, MediaQuery.sizeOf(context).width * 0.09);

    return InkWell(
      onTap: isFuture ? null : onTap,
      customBorder: const CircleBorder(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              color: isToday ? p.period : fill,
              shape: BoxShape.circle,
              border: borderColor == null
                  ? null
                  : Border.all(color: borderColor, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: 13,
                fontWeight: isToday || (isPeriod && !isFuture)
                    ? FontWeight.w700
                    : FontWeight.w500,
                fontVariations: [
                  FontVariation(
                    'wght',
                    isToday || (isPeriod && !isFuture) ? 700 : 500,
                  ),
                ],
                color: isToday ? Colors.white : textColor,
              ),
            ),
          ),
          if (hasNote && !isFuture)
            Positioned(
              bottom: 5,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isToday ? Colors.white : p.notes,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final p = BloomPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: p.muted),
        ),
      ],
    );
  }
}
