import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/bloom_provider.dart';
import '../../models/cycle.dart';
import '../../theme/bloom_theme.dart';
import '../../theme/design_system.dart';
import '../../widgets/bloom_dial.dart';
import '../../widgets/log_period_dialog.dart';
import '../day/day_detail_screen.dart';
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
        final p = BloomPalette.of(context);
        final theme = Theme.of(context);

        return CustomScrollView(
          slivers: [
            // Greeting, partner state and the Bloom AI entry.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  BloomDesign.gutter,
                  12,
                  BloomDesign.gutter,
                  0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTimeGreeting(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getCyclePhaseSubtitle(prov),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: p.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (prov.syncService.isPartnerLinked)
                      _LinkedBadge(
                        color: p.fertile,
                        background: p.fertileContainer,
                      ),
                    const SizedBox(width: 8),
                    _BloomAiChip(
                      color: p.period,
                      background: p.periodContainer,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BloomAIChatScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // The bloom: the cycle dial and the app's mark are one object.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  BloomDesign.gutter,
                  8,
                  BloomDesign.gutter,
                  0,
                ),
                child: Center(
                  child: BloomDial(
                    day: day,
                    cycleLength: total,
                    isOnPeriod: isOnPeriod,
                  ),
                ),
              ),
            ),

            // One action, clearly dominant.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  BloomDesign.gutter,
                  BloomDesign.xl,
                  BloomDesign.gutter,
                  0,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            isOnPeriod ? prov.endPeriod() : prov.startPeriod(),
                        icon: Icon(
                          isOnPeriod
                              ? Icons.stop_rounded
                              : Icons.water_drop_outlined,
                          size: 20,
                        ),
                        label: Text(isOnPeriod ? 'End Period' : 'Log Period'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOnPeriod ? p.ink : p.period,
                          foregroundColor: isOnPeriod ? p.surface : p.onAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              BloomDesign.radiusMd,
                            ),
                          ),
                          textStyle: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontVariations: const [FontVariation('wght', 600)],
                            letterSpacing: 0.2,
                            color: isOnPeriod ? p.surface : p.onAccent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => _pickDateForNote(context),
                        icon: Icon(Icons.edit_note_rounded, size: 20),
                        label: const Text('Daily Note'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: p.notesContainer,
                          foregroundColor: p.notes,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              BloomDesign.radiusMd,
                            ),
                          ),
                          textStyle: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontVariations: const [FontVariation('wght', 600)],
                            letterSpacing: 0.2,
                            color: p.notes,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => LogPeriodDialog.show(context),
                      child: const Text('Log Past Period'),
                    ),
                  ],
                ),
              ),
            ),

            // Bloom's own read on today.
            if (prov.dailyAIGreeting != null &&
                prov.dailyAIGreeting!.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BloomDesign.gutter,
                    8,
                    BloomDesign.gutter,
                    0,
                  ),
                  child: _InsightCard(
                    text: prov.dailyAIGreeting!,
                    loading: prov.isAILoading,
                    color: p.notes,
                    background: p.notesContainer,
                    onRefresh: () => prov.refreshDailyAIGreeting(),
                  ),
                ),
              ),

            // The next estimated window.
            if (prov.predictedNextStart != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BloomDesign.gutter,
                    12,
                    BloomDesign.gutter,
                    0,
                  ),
                  child: _PredictionBanner(
                    date: prov.predictedNextStart!,
                    color: p.predicted,
                    background: p.predictedContainer,
                  ),
                ),
              ),

            // Rolling baselines.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  BloomDesign.gutter,
                  20,
                  BloomDesign.gutter,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: BloomMetricTile(
                        value: '${prov.averageCycleLength}d',
                        label: 'avg cycle',
                        color: p.period,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: BloomMetricTile(
                        value: '${prov.averagePeriodLength}d',
                        label: 'avg period',
                        color: p.fertile,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: BloomMetricTile(
                        value: '${prov.totalCycles}',
                        label: 'cycles logged',
                        color: p.notes,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // History.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  BloomDesign.gutter,
                  24,
                  BloomDesign.gutter,
                  0,
                ),
                child: BloomDesign.groupLabel(context, 'Recent Cycles'),
              ),
            ),
            if (prov.cycles.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BloomDesign.gutter,
                    0,
                    BloomDesign.gutter,
                    0,
                  ),
                  child: BloomDesign.card(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 28,
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.history_rounded, size: 32, color: p.muted),
                        const SizedBox(height: 12),
                        Text(
                          'No cycles logged yet',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your logged periods will appear here once you log your first one.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: p.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList.separated(
                itemCount: math.min(prov.cycles.length, 4),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final c = prov.cycles[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BloomDesign.gutter,
                    ),
                    child: _CycleRow(
                      cycle: c,
                      color: p.period,
                      background: p.periodContainer,
                      onDelete: c.id == null
                          ? null
                          : () => _confirmDeleteCycle(context, prov, c.id!),
                    ),
                  );
                },
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        );
      },
    );
  }

  static Future<void> _confirmDeleteCycle(
    BuildContext context,
    BloomProvider prov,
    int id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete cycle?'),
        content: const Text(
          'Are you sure you want to remove this logged cycle?',
        ),
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

    if (confirmed == true) {
      await prov.deleteCycle(id);
    }
  }

  static Future<void> _pickDateForNote(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && context.mounted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => DayDetailScreen(date: picked)));
    }
  }
}

class _LinkedBadge extends StatelessWidget {
  final Color color;
  final Color background;

  const _LinkedBadge({required this.color, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(BloomDesign.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            'Linked',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontVariations: const [FontVariation('wght', 600)],
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BloomAiChip extends StatelessWidget {
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _BloomAiChip({
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(BloomDesign.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BloomDesign.radiusPill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                'Bloom AI',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontVariations: const [FontVariation('wght', 700)],
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String text;
  final bool loading;
  final Color color;
  final Color background;
  final VoidCallback onRefresh;

  const _InsightCard({
    required this.text,
    required this.loading,
    required this.color,
    required this.background,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final p = BloomPalette.of(context);
    return BloomDesign.card(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(BloomDesign.radiusSm),
            ),
            child: Icon(Icons.auto_awesome, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: p.inkLight,
                  height: 1.45,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: loading ? null : onRefresh,
            iconSize: 18,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
            icon: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh_rounded, color: p.muted),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }
}

class _PredictionBanner extends StatelessWidget {
  final DateTime date;
  final Color color;
  final Color background;

  const _PredictionBanner({
    required this.date,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    final p = BloomPalette.of(context);
    return BloomDesign.card(
      color: background,
      borderColor: color.withValues(alpha: 0.28),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(BloomDesign.radiusSm),
            ),
            child: Icon(Icons.auto_awesome, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next period estimated',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('EEEE, MMMM d').format(date),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: p.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleRow extends StatelessWidget {
  final Cycle cycle;
  final Color color;
  final Color background;
  final VoidCallback? onDelete;

  const _CycleRow({
    required this.cycle,
    required this.color,
    required this.background,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = BloomPalette.of(context);
    final theme = Theme.of(context);

    final duration = cycle.periodLength != null
        ? '${cycle.periodLength} days period'
        : cycle.endDate != null
        ? '${cycle.daysSinceStart} days'
        : 'Ongoing period';

    return BloomDesign.card(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(BloomDesign.radiusSm),
            ),
            child: Icon(Icons.water_drop_outlined, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM d, yyyy').format(cycle.startDate),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  duration,
                  style: theme.textTheme.bodySmall?.copyWith(color: p.muted),
                ),
              ],
            ),
          ),
          if (cycle.endDate == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Active',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontVariations: const [FontVariation('wght', 600)],
                  color: color,
                ),
              ),
            )
          else if (onDelete != null)
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 19,
                color: p.muted,
              ),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
