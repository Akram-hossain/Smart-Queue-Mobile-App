import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../models/semester_fee.dart';
import '../../providers/fee_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/date_format.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class FeeFormScreen extends ConsumerStatefulWidget {
  const FeeFormScreen({super.key, this.existing});
  final Object? existing;

  @override
  ConsumerState<FeeFormScreen> createState() => _FeeFormScreenState();
}

class _FeeFormScreenState extends ConsumerState<FeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _total;
  late final TextEditingController _paid;
  late final TextEditingController _note;
  late DateTime _due;
  bool _saving = false;
  String? _error;

  SemesterFee? get _editing =>
      widget.existing is SemesterFee ? widget.existing as SemesterFee : null;

  @override
  void initState() {
    super.initState();
    final ex = _editing;
    _label = TextEditingController(text: ex?.semesterLabel ?? '');
    _total = TextEditingController(text: ex?.totalFee.toStringAsFixed(0) ?? '');
    _paid =
        TextEditingController(text: ex?.paidAmount.toStringAsFixed(0) ?? '0');
    _note = TextEditingController(text: ex?.paymentNote ?? '');
    _due = ex?.dueDate ?? DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _label.dispose();
    _total.dispose();
    _paid.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Pick a reminder time for a fee deadline. The due_date column is a
  /// Postgres `date` (no time component), so we treat it as "end of day".
  DateTime? _pickFeeReminderTime(DateTime due) {
    final now = DateTime.now();
    // Treat the due date as 09:00 local on that day for a "wake-up" reminder.
    final dueMoment = DateTime(due.year, due.month, due.day, 9, 0);
    if (!dueMoment.isAfter(now)) return null;
    // Default: 1 day before at 18:00
    final oneDayBefore =
        DateTime(due.year, due.month, due.day - 1, 18, 0);
    if (oneDayBefore.isAfter(now.add(const Duration(seconds: 10)))) {
      return oneDayBefore;
    }
    // Same day, earlier in the day
    if (dueMoment.isAfter(now.add(const Duration(minutes: 1)))) {
      return dueMoment;
    }
    return now.add(const Duration(seconds: 10));
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (d != null) setState(() => _due = d);
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final total = double.parse(_total.text.trim());
    final paid = double.parse(_paid.text.trim());
    if (paid > total) {
      setState(() => _error = 'Paid amount cannot exceed total fee.');
      return;
    }
    setState(() => _saving = true);
    try {
      final base = _editing;
      final item = SemesterFee(
        id: base?.id ?? 'new',
        userId: base?.userId ?? '',
        semesterLabel: _label.text.trim(),
        totalFee: total,
        paidAmount: paid,
        dueDate: _due,
        paymentNote:
            _note.text.trim().isEmpty ? null : _note.text.trim(),
        createdAt: base?.createdAt ?? DateTime.now(),
      );
      final ctrl = ref.read(feesProvider.notifier);
      if (base == null) {
        await ctrl.create(item);
      } else {
        await ctrl.save(item);
      }

      // Notification reminder for unpaid fees — robust against short windows.
      if (ref.read(notificationsEnabledProvider) && !item.isPaid) {
        final remindAt = _pickFeeReminderTime(_due);
        if (remindAt != null) {
          await NotificationService.instance.scheduleAt(
            id: ('fee_${item.id}').hashCode & 0x7fffffff,
            title: 'Semester fee due soon',
            body:
                '${_label.text.trim()} is due on ${DateFmt.shortDate(_due)}',
            when: remindAt,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                'Reminder set for ${DateFmt.shortDateTime(remindAt)}',
              ),
            ));
          }
        }
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
    final editing = _editing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit fee' : 'New fee record'),
        actions: [
          if (editing)
            IconButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete record?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      FilledButton.tonal(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete')),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref
                      .read(feesProvider.notifier)
                      .delete(_editing!.id);
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
                  controller: _label,
                  label: 'Semester (e.g. Spring 2026)',
                  prefixIcon: Icons.event_note_rounded,
                  validator: (v) =>
                      Validators.required(v, field: 'Semester label'),
                ),
                const SizedBox(height: AppPadding.md),
                AppTextField(
                  controller: _total,
                  label: 'Total fee',
                  prefixIcon: Icons.receipt_long_rounded,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) =>
                      Validators.numberPositive(v, field: 'Total fee'),
                ),
                const SizedBox(height: AppPadding.md),
                AppTextField(
                  controller: _paid,
                  label: 'Paid so far',
                  prefixIcon: Icons.payments_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) =>
                      Validators.numberPositive(v, field: 'Paid amount'),
                ),
                const SizedBox(height: AppPadding.md),
                AppTextField(
                  controller: _note,
                  label: 'Note (optional)',
                  prefixIcon: Icons.sticky_note_2_outlined,
                  maxLines: 3,
                  minLines: 1,
                ),
                const SizedBox(height: AppPadding.md),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.event_rounded),
                    title: const Text('Due date'),
                    subtitle: Text(DateFmt.shortDate(_due)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickDate,
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
                  label: editing ? 'Save changes' : 'Add record',
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
