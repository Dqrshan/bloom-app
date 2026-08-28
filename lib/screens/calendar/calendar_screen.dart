import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/bloom_provider.dart';
import '../../services/pdf_export_service.dart';
import '../../theme/bloom_theme.dart';
import '../../widgets/log_period_dialog.dart';
import '../notes/day_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

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

        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Calendar',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf_outlined, color: BloomColors.rose500),
                        tooltip: 'Share PDF Report',
                        onPressed: () => _sharePdfReport(context, prov),
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton.icon(
                        onPressed: () => LogPeriodDialog.show(context),
                        icon: const Icon(Icons.water_drop_rounded, size: 14),
                        label: const Text('Log Period', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BloomColors.periodRed,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Month navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () => setState(() {
                              _focusedMonth = DateTime(year, month - 1);
                            }),
                          ),
                          Text(
                            '${_monthName(month)} $year',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: BloomColors.ink,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => setState(() {
                              _focusedMonth = DateTime(year, month + 1);
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Weekday labels
                      Row(
                        children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                            .map((d) => Expanded(
                                  child: Center(
                                    child: Text(
                                      d,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: BloomColors.muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      // Day grid
                      for (var row = 0; row < ((firstWeekday + daysInMonth + 6) ~/ 7); row++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: List.generate(7, (col) {
                              final idx = row * 7 + col - firstWeekday + 1;
                              if (idx < 1 || idx > daysInMonth) {
                                return const Expanded(child: SizedBox(height: 42));
                              }
                              final d = DateTime(year, month, idx);
                              final isFuture = d.isAfter(todayDate);
                              final isToday = d.year == today.year &&
                                  d.month == today.month &&
                                  d.day == today.day;
                              final isPeriod = prov.periodDays.any(
                                  (p) => p.year == d.year && p.month == d.month && p.day == d.day);
                              final isPredicted = prov.predictedDays.any(
                                  (p) => p.year == d.year && p.month == d.month && p.day == d.day);
                              final isFertile = prov.fertileDays.any(
                                  (p) => p.year == d.year && p.month == d.month && p.day == d.day);
                              final hasNote = prov.notes.any(
                                  (n) => n.date.year == d.year && n.date.month == d.month && n.date.day == d.day);

                              Color? bg;
                              BoxBorder? border;
                              Color textColor = isFuture ? Colors.grey.shade400 : BloomColors.ink;

                              if (isPeriod && !isFuture) {
                                bg = BloomColors.periodRedLight;
                                textColor = BloomColors.periodRed;
                              } else if (isPredicted) {
                                bg = BloomColors.predictedOrangeLight.withValues(alpha: isFuture ? 0.4 : 0.8);
                                textColor = isFuture ? BloomColors.predictedOrange.withValues(alpha: 0.7) : BloomColors.predictedOrange;
                                if (isFuture) {
                                  border = Border.all(color: BloomColors.predictedOrange.withValues(alpha: 0.3), width: 1);
                                }
                              } else if (isFertile) {
                                bg = BloomColors.fertileGreenLight.withValues(alpha: isFuture ? 0.4 : 0.8);
                                textColor = isFuture ? BloomColors.sage.withValues(alpha: 0.7) : BloomColors.sage;
                              }

                              return Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: isFuture ? null : () => _onDayTapped(context, d),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.all(2),
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: isToday ? BloomColors.rose500 : bg,
                                          shape: BoxShape.circle,
                                          border: border,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$idx',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isToday || (isPeriod && !isFuture)
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              color: isToday ? Colors.white : textColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (hasNote && !isFuture)
                                        Positioned(
                                          bottom: 4,
                                          child: Container(
                                            width: 4,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: isToday ? Colors.white : BloomColors.lavender,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Legend
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BloomColors.divider, width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _legend(BloomColors.periodRed, 'Period'),
                    _legend(BloomColors.predictedOrange, 'Predicted'),
                    _legend(BloomColors.sage, 'Fertile'),
                    _legend(BloomColors.lavender, 'Note'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sharePdfReport(BuildContext context, BloomProvider prov) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating PDF Report...'), duration: Duration(seconds: 1)),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    }
  }

  void _onDayTapped(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_note_rounded, color: BloomColors.lavender),
              title: const Text('Add / View Daily Notes'),
              subtitle: const Text('Log mood, flow, symptoms, and thoughts'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DayDetailScreen(date: date)),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.water_drop_rounded, color: BloomColors.periodRed),
              title: const Text('Log Period Starting on this Date'),
              subtitle: const Text('Set start & end dates for this period'),
              onTap: () {
                Navigator.pop(ctx);
                LogPeriodDialog.show(context, initialDate: date);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return names[m];
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: BloomColors.muted, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
