import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../models/enums.dart';
import '../../models/task.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fee_provider.dart';
import '../../providers/gpa_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/task_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/date_format.dart';
import '../../utils/grade.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final user = ref.watch(currentUserProvider);
    final tasks = ref.watch(tasksProvider).valueOrNull ?? const <TaskItem>[];
    final upcoming = ref.watch(upcomingTasksProvider);
    final attendance = ref.watch(attendanceProvider).valueOrNull ?? const [];
    final fees = ref.watch(feesProvider).valueOrNull ?? const [];
    final cgpa = ref.watch(cgpaProvider);

    final greetingName = profileAsync.valueOrNull?.fullName ??
        user?.email?.split('@').first ??
        'student';

    final attendanceAvg = attendance.isEmpty
        ? 0.0
        : attendance.fold<double>(0, (s, a) => s + a.percentage) /
            attendance.length;

    final upcomingFee = fees
        .where((f) => !f.isPaid)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final nextFee = upcomingFee.isEmpty ? null : upcomingFee.first;

    // pick a stable motivational quote for today
    final dayIdx = DateTime.now().day % MotivationalQuotes.all.length;
    final quote = MotivationalQuotes.all[dayIdx];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(tasksProvider.notifier).refresh(),
            ref.read(attendanceProvider.notifier).refresh(),
            ref.read(feesProvider.notifier).refresh(),
            ref.read(gpaProvider.notifier).refresh(),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor:
                  Theme.of(context).scaffoldBackgroundColor.withOpacity(0.85),
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              elevation: 0,
              title: Text(
                _greeting(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              actions: [
                IconButton(
                  onPressed: () => context.push(AppRoutes.settings),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppPadding.lg, 0, AppPadding.lg, AppPadding.xl),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _HeroHeader(name: greetingName, quote: quote),
                  const SizedBox(height: AppPadding.lg),

                  // Stat row
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.checklist_rounded,
                          label: 'Pending tasks',
                          value: upcoming.length.toString(),
                          color: AppColors.primary,
                          onTap: () => context.go(AppRoutes.tasks),
                        ),
                      ),
                      const SizedBox(width: AppPadding.md),
                      Expanded(
                        child: StatCard(
                          icon: Icons.fact_check_rounded,
                          label: 'Avg attendance',
                          value: attendance.isEmpty
                              ? '—'
                              : '${attendanceAvg.toStringAsFixed(0)}%',
                          subtitle: attendance.isEmpty
                              ? null
                              : (attendanceAvg < 75 ? 'Below 75%' : 'On track'),
                          color: attendanceAvg < 75
                              ? AppColors.danger
                              : AppColors.success,
                          onTap: () => context.go(AppRoutes.attendance),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppPadding.md),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.school_rounded,
                          label: 'CGPA',
                          value: cgpa == 0 ? '—' : cgpa.toStringAsFixed(2),
                          subtitle: cgpa == 0
                              ? null
                              : 'Grade ${GradeCalc.letter(cgpa).label}',
                          color: AppColors.secondary,
                          onTap: () => context.go(AppRoutes.gpa),
                        ),
                      ),
                      const SizedBox(width: AppPadding.md),
                      Expanded(
                        child: StatCard(
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Fee due',
                          value: nextFee == null
                              ? '—'
                              : '৳${nextFee.dueAmount.toStringAsFixed(0)}',
                          subtitle: nextFee == null
                              ? null
                              : 'by ${DateFmt.shortDate(nextFee.dueDate)}',
                          color: nextFee != null && nextFee.isOverdue
                              ? AppColors.danger
                              : AppColors.warning,
                          onTap: () => context.go(AppRoutes.fees),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppPadding.lg),

                  // Quick actions
                  SectionHeader(
                    title: 'Quick actions',
                    subtitle: 'Add something new in one tap',
                  ),
                  const SizedBox(height: AppPadding.sm + 4),
                  _QuickActions(),

                  const SizedBox(height: AppPadding.lg),

                  // Weekly productivity chart
                  SectionHeader(
                    title: 'This week',
                    subtitle: 'Tasks completed per day',
                  ),
                  const SizedBox(height: AppPadding.sm + 4),
                  _WeeklyChart(allTasks: tasks),

                  const SizedBox(height: AppPadding.lg),

                  // Upcoming tasks
                  SectionHeader(
                    title: 'Upcoming',
                    subtitle:
                        '${upcoming.length} pending — tap to view all',
                    action: TextButton(
                      onPressed: () => context.go(AppRoutes.tasks),
                      child: const Text('See all'),
                    ),
                  ),
                  const SizedBox(height: AppPadding.sm + 4),
                  if (upcoming.isEmpty)
                    _InlineEmpty(
                      icon: Icons.event_available_rounded,
                      message: 'Nothing scheduled — enjoy the calm.',
                    )
                  else
                    Column(
                      children: upcoming
                          .take(4)
                          .map((t) => _UpcomingTile(task: t))
                          .toList(),
                    ),

                  const SizedBox(height: AppPadding.lg),

                  // Motivational
                  GradientCard(
                    colors: const [AppColors.secondary, AppColors.accent],
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_rounded, size: 36),
                        const SizedBox(width: AppPadding.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quote of the day',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                quote,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.name, required this.quote});
  final String name;
  final String quote;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      padding: const EdgeInsets.all(AppPadding.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello,',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  _firstName(name),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  DateFmt.longDate(DateTime.now()),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(name),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _firstName(String full) =>
      full.trim().split(RegExp(r'\s+')).first;
  String _initials(String full) {
    final parts = full.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters =
        parts.take(2).map((p) => p.characters.first.toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = <_QuickAction>[
      _QuickAction(
        icon: Icons.add_task_rounded,
        label: 'New task',
        color: AppColors.primary,
        route: AppRoutes.taskNew,
      ),
      _QuickAction(
        icon: Icons.fact_check_outlined,
        label: 'Attendance',
        color: AppColors.info,
        route: AppRoutes.attendanceNew,
      ),
      _QuickAction(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Fee record',
        color: AppColors.warning,
        route: AppRoutes.feeNew,
      ),
      _QuickAction(
        icon: Icons.school_outlined,
        label: 'GPA entry',
        color: AppColors.secondary,
        route: AppRoutes.gpaNew,
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: AppPadding.sm + 4),
          Expanded(child: items[i]),
        ],
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.allTasks});
  final List<TaskItem> allTasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    // Build last 7 days, count completed tasks per day
    final days = List<DateTime>.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i)),
    );

    final counts = days.map((d) {
      return allTasks
          .where((t) =>
              t.status == TaskStatus.completed &&
              DateFmt.isSameDay(t.dueDate, d))
          .length
          .toDouble();
    }).toList();

    final maxY = math.max(4.0, (counts.fold<double>(0, math.max)) + 1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppPadding.md, AppPadding.lg, AppPadding.md, AppPadding.md),
        child: SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: math.max(1, maxY / 4),
                getDrawingHorizontalLine: (_) => FlLine(
                  color: theme.dividerColor.withOpacity(0.4),
                  strokeWidth: 1,
                ),
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
                    reservedSize: 28,
                    interval: math.max(1, (maxY / 4).ceilToDouble()),
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= days.length) return const SizedBox();
                      const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                      final wd = days[i].weekday; // 1=Mon..7=Sun
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          labels[(wd - 1) % 7],
                          style: theme.textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < counts.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: counts[i],
                        width: 14,
                        borderRadius: BorderRadius.circular(6),
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.task});
  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = task.type.color;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppPadding.sm + 4),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => context.push(AppRoutes.taskEdit, extra: task),
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(task.type.icon, color: color),
                ),
                const SizedBox(width: AppPadding.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${task.type.label} · ${DateFmt.shortDateTime(task.dueDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: task.isOverdue
                        ? AppColors.danger.withOpacity(0.12)
                        : color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DateFmt.relative(task.dueDate),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: task.isOverdue ? AppColors.danger : color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.lg),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: AppPadding.md),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
