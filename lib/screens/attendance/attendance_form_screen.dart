import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../models/attendance.dart';
import '../../providers/attendance_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class AttendanceFormScreen extends ConsumerStatefulWidget {
  const AttendanceFormScreen({super.key, this.existing});
  final Object? existing; // AttendanceItem? — typed via extra

  @override
  ConsumerState<AttendanceFormScreen> createState() =>
      _AttendanceFormScreenState();
}

class _AttendanceFormScreenState
    extends ConsumerState<AttendanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _total;
  late final TextEditingController _attended;
  bool _saving = false;
  String? _error;

  AttendanceItem? get _editing =>
      widget.existing is AttendanceItem ? widget.existing as AttendanceItem : null;

  @override
  void initState() {
    super.initState();
    final ex = _editing;
    _name = TextEditingController(text: ex?.subjectName ?? '');
    _total = TextEditingController(text: ex?.totalClasses.toString() ?? '');
    _attended =
        TextEditingController(text: ex?.attendedClasses.toString() ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _total.dispose();
    _attended.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final total = int.parse(_total.text.trim());
    final attended = int.parse(_attended.text.trim());
    if (attended > total) {
      setState(() => _error = 'Attended classes cannot exceed total classes.');
      return;
    }
    setState(() => _saving = true);
    try {
      final base = _editing;
      final item = AttendanceItem(
        id: base?.id ?? 'new',
        userId: base?.userId ?? '',
        subjectName: _name.text.trim(),
        totalClasses: total,
        attendedClasses: attended,
        createdAt: base?.createdAt ?? DateTime.now(),
      );
      final ctrl = ref.read(attendanceProvider.notifier);
      if (base == null) {
        await ctrl.create(item);
      } else {
        await ctrl.update(item);
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
        title: Text(editing ? 'Edit subject' : 'Add subject'),
        actions: [
          if (editing)
            IconButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete subject?'),
                    content: const Text('Attendance data will be lost.'),
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
                      .read(attendanceProvider.notifier)
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
                  controller: _name,
                  label: 'Subject name',
                  prefixIcon: Icons.menu_book_rounded,
                  validator: (v) =>
                      Validators.required(v, field: 'Subject name'),
                ),
                const SizedBox(height: AppPadding.md),
                AppTextField(
                  controller: _total,
                  label: 'Total classes',
                  prefixIcon: Icons.event_note_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      Validators.integerMin(v, min: 0, field: 'Total classes'),
                ),
                const SizedBox(height: AppPadding.md),
                AppTextField(
                  controller: _attended,
                  label: 'Attended classes',
                  prefixIcon: Icons.check_circle_outline,
                  keyboardType: TextInputType.number,
                  validator: (v) => Validators.integerMin(v,
                      min: 0, field: 'Attended classes'),
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
                  label: editing ? 'Save changes' : 'Add subject',
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
