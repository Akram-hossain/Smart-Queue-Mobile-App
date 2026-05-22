import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../models/attendance.dart';
import '../../providers/attendance_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/section_header.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(attendanceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.attendanceNew),
        icon: const Icon(Icons.add),
        label: const Text('Add subject'),
      ),
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppPadding.lg),
          child: LoadingSkeleton(),
        ),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load attendance',
          message: e.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.read(attendanceProvider.notifier).refresh(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.fact_check_outlined,
              title: 'Track your attendance',
              message: 'Add subjects to keep an eye on the 75% threshold.',
              actionLabel: 'Add subject',
              onAction: () => context.push(AppRoutes.attendanceNew),
            );
          }
          final avg = items.fold<double>(0, (s, a) => s + a.percentage) /
              items.length;
          final below = items.where((a) => a.isBelowThreshold).length;

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(attendanceProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(AppPadding.lg),
              children: [
                _OverviewHeader(avg: avg, below: below, total: items.length),
                const SizedBox(height: AppPadding.lg),
                SectionHeader(
                  title: 'Subjects',
                  subtitle: '${items.length} tracked',
                ),
                const SizedBox(height: AppPadding.sm + 4),
                ...items.map((a) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppPadding.sm + 4),
                      child: _AttendanceCard(item: a),
                    )),
                const SizedBox(height: AppPadding.lg),
                SectionHeader(
                  title: 'Per-subject %',
                  subtitle: 'Visual breakdown',
                ),
                const SizedBox(height: AppPadding.sm + 4),
                _AttendanceChart(items: items),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OverviewHeader extends StatelessWidget {
  const _OverviewHeader({
    required this.avg,
    required this.below,
    required this.total,
  });
  final double avg;
  final int below;
  final int total;

  @override
  Widget build(BuildContext context) {
    final color = avg < 75 ? AppColors.danger : AppColors.success;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.lg),
        child: Row(
          children: [
            SizedBox(
              width: 86,
              height: 86,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 86,
                    height: 86,
                    child: CircularProgressIndicator(
                      value: (avg / 100).clamp(0, 1),
                      strokeWidth: 8,
                      backgroundColor: color.withOpacity(0.15),
                      color: color,
                    ),
                  ),
                  Text(
                    '${avg.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppPadding.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Average attendance',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    below == 0
                        ? 'All $total subjects on track 🎉'
                        : '$below of $total below 75%',
                    style: TextStyle(
                      color: below == 0 ? AppColors.success : AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceCard extends ConsumerWidget {
  const _AttendanceCard({required this.item});
  final AttendanceItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pct = item.percentage;
    final color = item.isBelowThreshold ? AppColors.danger : AppColors.success;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () =>
            context.push(AppRoutes.attendanceNew, extra: item),
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.subjectName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (pct / 100).clamp(0, 1),
                  minHeight: 8,
                  backgroundColor: color.withOpacity(0.12),
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '${item.attendedClasses} / ${item.totalClasses} classes',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (item.isBelowThreshold)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Below 75%',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceChart extends StatelessWidget {
  const _AttendanceChart({required this.items});
  final List<AttendanceItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppPadding.md, AppPadding.lg, AppPadding.md, AppPadding.md),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: 100,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: theme.dividerColor, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 25,
                    reservedSize: 32,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toInt()}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= items.length) return const SizedBox();
                      final name = items[i].subjectName;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          name.length > 6 ? '${name.substring(0, 6)}…' : name,
                          style: theme.textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < items.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: items[i].percentage,
                        width: 14,
                        borderRadius: BorderRadius.circular(6),
                        color: items[i].isBelowThreshold
                            ? AppColors.danger
                            : AppColors.success,
                      ),
                    ],
                  ),
              ],
              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(
                  y: 75,
                  color: AppColors.warning,
                  strokeWidth: 1.5,
                  dashArray: [4, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                    labelResolver: (_) => '75%',
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
