import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../models/enums.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/date_format.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_skeleton.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  TaskType? _filterType;
  String _query = '';
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            tooltip: 'Calendar view',
            onPressed: () => context.push(AppRoutes.tasksCalendar),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppPadding.lg),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search tasks',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(height: AppPadding.sm + 4),
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.lg),
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filterType == null,
                  onTap: () => setState(() => _filterType = null),
                ),
                const SizedBox(width: 6),
                for (final t in TaskType.values) ...[
                  _FilterChip(
                    icon: t.icon,
                    label: t.label,
                    color: t.color,
                    selected: _filterType == t,
                    onTap: () => setState(() => _filterType = t),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppPadding.lg, AppPadding.sm, AppPadding.lg, 0),
            child: Row(
              children: [
                Text(
                  _showCompleted ? 'Showing completed' : 'Showing upcoming',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const Spacer(),
                Switch.adaptive(
                  value: _showCompleted,
                  onChanged: (v) => setState(() => _showCompleted = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                final filtered = tasks.where((t) {
                  if (_filterType != null && t.type != _filterType) {
                    return false;
                  }
                  final wantCompleted =
                      _showCompleted ? TaskStatus.completed : null;
                  if (wantCompleted == null) {
                    if (t.status == TaskStatus.completed) return false;
                  } else if (t.status != wantCompleted) {
                    return false;
                  }
                  if (_query.isNotEmpty) {
                    return t.title.toLowerCase().contains(_query) ||
                        (t.description ?? '').toLowerCase().contains(_query);
                  }
                  return true;
                }).toList()
                  ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: _showCompleted
                        ? Icons.check_circle_outline
                        : Icons.task_alt_outlined,
                    title: _showCompleted
                        ? 'No completed tasks yet'
                        : 'You\'re all caught up',
                    message: _showCompleted
                        ? 'Finish a task and it\'ll show up here.'
                        : 'Add a CT, lab, viva, assignment or final exam.',
                    actionLabel: 'Add task',
                    onAction: () => context.push(AppRoutes.taskNew),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(tasksProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppPadding.lg),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppPadding.sm + 4),
                    itemBuilder: (_, i) => _TaskTile(task: filtered[i]),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(AppPadding.lg),
                child: LoadingSkeleton(),
              ),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Could not load tasks',
                message: e.toString(),
                actionLabel: 'Retry',
                onAction: () => ref.read(tasksProvider.notifier).refresh(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.taskNew),
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = selected
        ? (color ?? theme.colorScheme.primary)
        : theme.cardTheme.color ?? theme.colorScheme.surface;
    final fg = selected
        ? Colors.white
        : theme.colorScheme.onSurface.withOpacity(0.8);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected
                ? (color ?? theme.colorScheme.primary)
                : theme.dividerColor,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task});
  final TaskItem task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = task.type.color;
    final done = task.status == TaskStatus.completed;
    return Dismissible(
      key: ValueKey('task_${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppPadding.lg),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Delete task?'),
                content: Text('"${task.title}" will be removed.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) {
        ref.read(tasksProvider.notifier).delete(task.id);
      },
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => context.push(AppRoutes.taskEdit, extra: task),
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.md),
            child: Row(
              children: [
                _Checkbox(
                  done: done,
                  color: color,
                  onChanged: () =>
                      ref.read(tasksProvider.notifier).toggleComplete(task),
                ),
                const SizedBox(width: AppPadding.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          decoration:
                              done ? TextDecoration.lineThrough : null,
                          color: done
                              ? theme.colorScheme.onSurface.withOpacity(0.5)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _Pill(label: task.type.label, color: color),
                          const SizedBox(width: 6),
                          _Pill(
                              label: task.priority.label,
                              color: task.priority.color),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              DateFmt.shortDateTime(task.dueDate),
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: task.isOverdue
                                    ? AppColors.danger
                                    : theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({
    required this.done,
    required this.color,
    required this.onChanged,
  });
  final bool done;
  final Color color;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged,
      child: AnimatedContainer(
        duration: AppDuration.fast,
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: done ? color : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: done
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
