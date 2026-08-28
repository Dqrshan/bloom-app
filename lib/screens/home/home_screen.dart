import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/bloom_provider.dart';
import '../../theme/bloom_theme.dart';
import '../../widgets/log_period_dialog.dart';
import '../notes/day_detail_screen.dart';
import '../ai/bloom_ai_chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning 🌸';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon ✨';
    } else if (hour >= 17 && hour < 22) {
      return 'Good evening 🌙';
    } else {
      return 'Good night 💫';
    }
  }

  String _getCyclePhaseSubtitle(BloomProvider prov) {
    final day = prov.currentDay;
    if (prov.isOnPeriod) {
      return 'Period Active • Day ${day ?? 1}';
    }
    if (day == null) {
      return 'Tap below to log your period';
    }
    final avgCycle = prov.averageCycleLength;
    final avgPeriod = prov.averagePeriodLength;
    if (day <= avgPeriod) {
      return 'Cycle Day $day • Menstrual Phase';
    } else if (day <= (avgCycle ~/ 2) - 2) {
      return 'Cycle Day $day • Follicular Phase';
    } else if (day <= (avgCycle ~/ 2) + 2) {
      return 'Cycle Day $day • Ovulatory Phase';
    } else {
      return 'Cycle Day $day • Luteal Phase';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BloomProvider>(
      builder: (context, prov, _) {
        final day = prov.currentDay;
        final isOnPeriod = prov.isOnPeriod;
        final total = prov.averageCycleLength;
        final progress = day != null ? (day / total).clamp(0.0, 1.0) : 0.0;
        final syncService = prov.syncService;

        return SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              // Top Header with simple 1-line time-of-day greeting & Bloom AI shortcut
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTimeGreeting(),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  letterSpacing: -0.5,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getCyclePhaseSubtitle(prov),
                            style: const TextStyle(
                              fontSize: 13,
                              color: BloomColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (syncService.isPartnerLinked)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: BloomColors.sage.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: BloomColors.sage.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.link, size: 14, color: BloomColors.sage),
                                  SizedBox(width: 4),
                                  Text(
                                    'Linked',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: BloomColors.sage,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BloomAIChatScreen()),
                            ),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: BloomColors.rose500.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: BloomColors.rose500.withValues(alpha: 0.25)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome, size: 14, color: BloomColors.rose500),
                                  SizedBox(width: 5),
                                  Text(
                                    'Bloom AI',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: BloomColors.rose500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Main cycle visual dial
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: SizedBox(
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer ring
                        SizedBox(
                          width: 210,
                          height: 210,
                          child: CustomPaint(
                            painter: _CyclePainter(
                              progress: progress,
                              color: isOnPeriod ? BloomColors.periodRed : BloomColors.rose500,
                              trackColor: BloomColors.divider,
                            ),
                          ),
                        ),
                        // Center content
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              day != null ? '$day' : '--',
                              style: const TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w300,
                                color: BloomColors.ink,
                                height: 1,
                                letterSpacing: -2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              day != null
                                  ? (isOnPeriod ? 'period day' : 'of $total day cycle')
                                  : 'no cycle logged',
                              style: const TextStyle(
                                fontSize: 13,
                                color: BloomColors.muted,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Action buttons (Log Period / Log Past Period / Add Note)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: isOnPeriod
                            ? _ActionBtn(
                                label: 'End Period',
                                icon: Icons.stop_rounded,
                                color: BloomColors.ink,
                                onTap: () => prov.endPeriod(),
                              )
                            : _ActionBtn(
                                label: 'Log Period',
                                icon: Icons.water_drop_outlined,
                                color: BloomColors.periodRed,
                                onTap: () => LogPeriodDialog.show(context),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionBtn(
                          label: 'Daily Note',
                          icon: Icons.edit_note_rounded,
                          color: BloomColors.lavender,
                          onTap: () => _pickDateForNote(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Prediction banner (if available)
              if (prov.predictedNextStart != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            BloomColors.predictedOrange.withValues(alpha: 0.1),
                            BloomColors.rose500.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: BloomColors.predictedOrange.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: BloomColors.predictedOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.auto_awesome, color: BloomColors.predictedOrange, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Next period estimated',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: BloomColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('EEEE, MMMM d').format(prov.predictedNextStart!),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: BloomColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Stats row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Row(
                    children: [
                      _StatPill(
                        value: '${prov.averageCycleLength}d',
                        label: 'avg cycle',
                        color: BloomColors.rose500,
                      ),
                      const SizedBox(width: 8),
                      _StatPill(
                        value: '${prov.averagePeriodLength}d',
                        label: 'avg period',
                        color: BloomColors.periodRed,
                      ),
                      const SizedBox(width: 8),
                      _StatPill(
                        value: '${prov.totalCycles}',
                        label: 'cycles logged',
                        color: BloomColors.sage,
                      ),
                    ],
                  ),
                ),
              ),

              // Recent cycles list
              if (prov.cycles.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Cycles',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: BloomColors.muted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => LogPeriodDialog.show(context),
                              icon: const Icon(Icons.add, size: 16, color: BloomColors.periodRed),
                              label: const Text(
                                'Log Past Period',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: BloomColors.periodRed),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...prov.cycles.take(4).map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: BloomColors.divider, width: 0.5),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: BloomColors.periodRedLight,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.water_drop_outlined,
                                          color: BloomColors.periodRed, size: 18),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            DateFormat('MMMM d, yyyy').format(c.startDate),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: BloomColors.ink,
                                            ),
                                          ),
                                          Text(
                                            c.periodLength != null
                                                ? '${c.periodLength} days period'
                                                : c.endDate != null
                                                    ? '${c.daysSinceStart} days'
                                                    : 'Ongoing period',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: BloomColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (c.endDate == null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: BloomColors.periodRedLight,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Active',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: BloomColors.periodRed,
                                          ),
                                        ),
                                      )
                                    else if (c.id != null)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: BloomColors.muted),
                                        onPressed: () => _confirmDeleteCycle(context, prov, c.id!),
                                      ),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),

              // Bottom padding for navigation bar
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _confirmDeleteCycle(BuildContext context, BloomProvider prov, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete cycle?'),
        content: const Text('Are you sure you want to remove this logged cycle?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: BloomColors.periodRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await prov.deleteCycle(id);
    }
  }

  Future<void> _pickDateForNote(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: BloomColors.lavender,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DayDetailScreen(date: picked),
        ),
      );
    }
  }
}

class _CyclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _CyclePainter({required this.progress, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    if (progress > 0) {
      final dotAngle = -pi / 2 + sweepAngle;
      final dotX = center.dx + radius * cos(dotAngle);
      final dotY = center.dy + radius * sin(dotAngle);

      canvas.drawCircle(Offset(dotX, dotY), 6, Paint()..color = color);
      canvas.drawCircle(Offset(dotX, dotY), 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _CyclePainter old) =>
      old.progress != progress || old.color != color;
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatPill({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BloomColors.divider, width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: BloomColors.muted,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
