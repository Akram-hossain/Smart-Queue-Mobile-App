import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../models/enums.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/date_format.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key, this.existing});
  final TaskItem? existing;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late TaskType _type;
  late TaskPriority _priority;
  late TaskStatus _status;
  late DateTime _due;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _title = TextEditingController(text: ex?.title ?? '');
    _description = TextEditingController(text: ex?.description ?? '');
    _type = ex?.type ?? TaskType.assignment;
    _priority = ex?.priority ?? TaskPriority.medium;
    _status = ex?.status ?? TaskStatus.pending;
    _due = ex?.dueDate ?? DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (d == null) return;
    if (!mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_due),
    );
    if (t == null) return;
    setState(() => _due = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final base = widget.existing;
      final task = TaskItem(
        id: base?.id ?? 'new',
        userId: base?.userId ?? '',
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        type: _type,
        dueDate: _due,
        priority: _priority,
        status: _status,
        createdAt: base?.createdAt ?? DateTime.now(),
      );
      final ctrl = ref.read(tasksProvider.notifier);
      if (base == null) {
        await ctrl.create(task);
      } else {
        await ctrl.update(task);
      }

      // schedule a reminder one hour before — best effort
      if (ref.read(notificationsEnabledProvider) &&
          _due.isAfter(DateTime.now()) &&
          _status != TaskStatus.completed) {
        await NotificationService.instance.scheduleAt(
          id: task.id.hashCode & 0x7fffffff,
          title: '${_type.label} reminder',
          body: '"${task.title}" is due at ${DateFmt.time(_due)}',
          when: _due.subtract(const Duration(hours: 1)),
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit task' : 'New task'),
        actions: [
          if (editing)
            IconButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete task?'),
                    content: const Text('This cannot be undone.'),
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
                );
                if (ok == true) {
                  await ref
                      .read(tasksProvider.notifier)
                      .delete(widget.existing!.id);
                  if (mounted) context.pop();
                }
              },
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppPadding.lg),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _title,
                  label: 'Title',
                  prefixIcon: Icons.title_rounded,
                  validator: (v) => Validators.required(v, field: 'Title'),
                ),
                const SizedBox(height: AppPadding.md),
                AppTextField(
                  controller: _description,
                  label: 'Description (optional)',
                  prefixIcon: Icons.notes_rounded,
                  maxLines: 4,
                  minLines: 2,
                ),
                const SizedBox(height: AppPadding.lg),
                Text('Type', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in TaskType.values)
                      _SelectChip(
                        icon: t.icon,
                        label: t.label,
                        color: t.color,
                        selected: t == _type,
                        onTap: () => setState(() => _type = t),
                      ),
                  ],
                ),
                const SizedBox(height: AppPadding.lg),
                Text('Priority', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final p in TaskPriority.values)
                      _SelectChip(
                        label: p.label,
                        color: p.color,
                        selected: p == _priority,
                        onTap: () => setState(() => _priority = p),
                      ),
                  ],
                ),
                const SizedBox(height: AppPadding.lg),
                Text('Status', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final s in TaskStatus.values)
                      _SelectChip(
                        label: s.label,
                        color: AppColors.primary,
                        selected: s == _status,
                        onTap: () => setState(() => _status = s),
                      ),
                  ],
                ),
                const SizedBox(height: AppPadding.lg),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.event_rounded),
                    title: const Text('Due'),
                    subtitle: Text(DateFmt.shortDateTime(_due)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickDateTime,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppPadding.md),
                  Container(
                    padding: const EdgeInsets.all(AppPadding.md),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(_error!,
                        style: const TextStyle(color: AppColors.danger)),
                  ),
                ],
                const SizedBox(height: AppPadding.lg),
                PrimaryButton(
                  label: editing ? 'Save changes' : 'Create task',
                  loading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectChip extends StatelessWidget {
  const _SelectChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(selected ? 1 : 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 16, color: selected ? Colors.white : color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
