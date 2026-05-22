import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/constants.dart';
import '../../models/enums.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/date_format.dart';
import '../../widgets/empty_state.dart';

class TasksCalendarScreen extends ConsumerStatefulWidget {
  const TasksCalendarScreen({super.key});

  @override
  ConsumerState<TasksCalendarScreen> createState() =>
      _TasksCalendarScreenState();
}

class _TasksCalendarScreenState extends ConsumerState<TasksCalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = ref.watch(tasksProvider).valueOrNull ?? const <TaskItem>[];

    final selectedDay = _selected ?? _focused;
    final daysTasks = tasks
        .where((t) => DateFmt.isSameDay(t.dueDate, selectedDay))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.lg, vertical: AppPadding.sm),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.sm),
                child: TableCalendar<TaskItem>(
                  firstDay: DateTime.now()
                      .subtract(const Duration(days: 365 * 2)),
                  lastDay:
                      DateTime.now().add(const Duration(days: 365 * 3)),
                  focusedDay: _focused,
                  selectedDayPredicate: (d) =>
                      _selected != null && DateFmt.isSameDay(d, _selected!),
                  calendarFormat: _format,
                  onFormatChanged: (f) => setState(() => _format = f),
                  onPageChanged: (f) => _focused = f,
                  eventLoader: (day) => tasks
                      .where((t) => DateFmt.isSameDay(t.dueDate, day))
                      .toList(),
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    markersAlignment: Alignment.bottomCenter,
                    markerDecoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    formatButtonDecoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    formatButtonTextStyle: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onDaySelected: (d, f) => setState(() {
                    _selected = d;
                    _focused = f;
                  }),
                ),
              ),
            ),
          ),
          Expanded(
            child: daysTasks.isEmpty
                ? EmptyState(
                    icon: Icons.event_busy_rounded,
                    title: 'No tasks on this day',
                    message: 'Pick another day or add a new task.',
                    actionLabel: 'Add task',
                    onAction: () => context.push(AppRoutes.taskNew),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        AppPadding.lg, 0, AppPadding.lg, AppPadding.lg),
                    itemCount: daysTasks.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppPadding.sm),
                    itemBuilder: (_, i) {
                      final t = daysTasks[i];
                      final color = t.type.color;
                      return Card(
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(t.type.icon, color: color),
                          ),
                          title: Text(
                            t.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                              '${t.type.label} · ${DateFmt.time(t.dueDate)}'),
                          trailing: Icon(
                            t.status == TaskStatus.completed
                                ? Icons.check_circle
                                : Icons.chevron_right_rounded,
                            color: t.status == TaskStatus.completed
                                ? AppColors.success
                                : null,
                          ),
                          onTap: () =>
                              context.push(AppRoutes.taskEdit, extra: t),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
