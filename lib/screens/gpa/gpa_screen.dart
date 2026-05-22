import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../models/gpa_record.dart';
import '../../providers/gpa_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/grade.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/section_header.dart';

class GpaScreen extends ConsumerWidget {
  const GpaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(gpaProvider);
    final cgpa = ref.watch(cgpaProvider);
    final perSemester = ref.watch(gpaBySemesterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('GPA & CGPA')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.gpaNew),
        icon: const Icon(Icons.add),
        label: const Text('Add course'),
      ),
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppPadding.lg),
          child: LoadingSkeleton(),
        ),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load GPA',
          message: e.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.read(gpaProvider.notifier).refresh(),
        ),
        data: (records) {
          if (records.isEmpty) {
            return EmptyState(
              icon: Icons.school_outlined,
              title: 'No courses added',
              message:
                  'Add the courses you took with credits and grades — we\'ll do the math.',
              actionLabel: 'Add course',
              onAction: () => context.push(AppRoutes.gpaNew),
            );
          }
          final grouped = <String, List<GpaRecord>>{};
          for (final r in records) {
            grouped.putIfAbsent(r.semesterLabel, () => []).add(r);
          }
          final sortedSemesters = grouped.keys.toList()..sort();

          return RefreshIndicator(
            onRefresh: () => ref.read(gpaProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(AppPadding.lg),
              children: [
                GradientCard(
                  colors: const [AppColors.secondary, AppColors.primary],
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Cumulative GPA',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              cgpa.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Letter ${GradeCalc.letter(cgpa).label}  ·  ${records.length} courses',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.school_rounded,
                            color: Colors.white, size: 32),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppPadding.lg),
                if (perSemester.length >= 2) ...[
                  SectionHeader(
                    title: 'GPA trend',
                    subtitle: 'Across semesters',
                  ),
                  const SizedBox(height: AppPadding.sm + 4),
                  _GpaLineChart(perSemester: perSemester),
                  const SizedBox(height: AppPadding.lg),
                ],
                SectionHeader(
                  title: 'Semesters',
                  subtitle: '${grouped.length} semesters tracked',
                ),
                const SizedBox(height: AppPadding.sm + 4),
                for (final sem in sortedSemesters)
                  _SemesterBlock(
                    label: sem,
                    records: grouped[sem]!,
                  ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SemesterBlock extends StatelessWidget {
  const _SemesterBlock({required this.label, required this.records});
  final String label;
  final List<GpaRecord> records;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gpa = GradeCalc.gpa(records);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppPadding.lg),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'GPA ${gpa.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...records.map((r) => _CourseRow(record: r)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseRow extends ConsumerWidget {
  const _CourseRow({required this.record});
  final GpaRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () => context.push(AppRoutes.gpaNew, extra: record),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                record.grade.label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppPadding.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.courseName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if ((record.courseCode ?? '').isNotEmpty)
                    Text(
                      record.courseCode!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${record.credit.toStringAsFixed(record.credit % 1 == 0 ? 0 : 2)} cr',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GpaLineChart extends StatelessWidget {
  const _GpaLineChart({required this.perSemester});
  final Map<String, double> perSemester;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = perSemester.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppPadding.md, AppPadding.lg, AppPadding.md, AppPadding.md),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 4,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
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
                    interval: 1,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= entries.length) return const SizedBox();
                      final lbl = entries[i].key;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          lbl.length > 8 ? lbl.substring(0, 8) : lbl,
                          style: theme.textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < entries.length; i++)
                      FlSpot(i.toDouble(), entries[i].value),
                  ],
                  isCurved: true,
                  barWidth: 3,
                  color: AppColors.secondary,
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary.withOpacity(0.3),
                        AppColors.secondary.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
