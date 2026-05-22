import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../models/enums.dart';
import '../../models/gpa_record.dart';
import '../../providers/gpa_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class GpaFormScreen extends ConsumerStatefulWidget {
  const GpaFormScreen({super.key, this.existing});
  final Object? existing;

  @override
  ConsumerState<GpaFormScreen> createState() => _GpaFormScreenState();
}

class _GpaFormScreenState extends ConsumerState<GpaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _semester;
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _credit;
  late Grade _grade;
  bool _saving = false;
  String? _error;

  GpaRecord? get _editing =>
      widget.existing is GpaRecord ? widget.existing as GpaRecord : null;

  @override
  void initState() {
    super.initState();
    final ex = _editing;
    _semester = TextEditingController(text: ex?.semesterLabel ?? '');
    _name = TextEditingController(text: ex?.courseName ?? '');
    _code = TextEditingController(text: ex?.courseCode ?? '');
    _credit = TextEditingController(
      text: ex == null
          ? '3'
          : ex.credit.toStringAsFixed(ex.credit % 1 == 0 ? 0 : 2),
    );
    _grade = ex?.grade ?? Grade.b;
  }

  @override
  void dispose() {
    _semester.dispose();
    _name.dispose();
    _code.dispose();
    _credit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final base = _editing;
      final item = GpaRecord(
        id: base?.id ?? 'new',
        userId: base?.userId ?? '',
        semesterLabel: _semester.text.trim(),
        courseName: _name.text.trim(),
        courseCode:
            _code.text.trim().isEmpty ? null : _code.text.trim(),
        credit: double.parse(_credit.text.trim()),
        grade: _grade,
        createdAt: base?.createdAt ?? DateTime.now(),
      );
      final ctrl = ref.read(gpaProvider.notifier);
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
        title: Text(editing ? 'Edit course' : 'Add course'),
        actions: [
          if (editing)
            IconButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete course?'),
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
                      .read(gpaProvider.notifier)
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
                  controller: _semester,
                  label: 'Semester (e.g. Spring 2026)',
                  prefixIcon: Icons.event_note_outlined,
                  validator: (v) =>
                      Validators.required(v, field: 'Semester'),
                ),
                const SizedBox(height: AppPadding.md),
                AppTextField(
                  controller: _name,
                  label: 'Course name',
                  prefixIcon: Icons.menu_book_outlined,
                  validator: (v) =>
                      Validators.required(v, field: 'Course name'),
                ),
                const SizedBox(height: AppPadding.md),
                AppTextField(
                  controller: _code,
                  label: 'Course code (optional)',
                  prefixIcon: Icons.code,
                ),
                const SizedBox(height: AppPadding.md),
                AppTextField(
                  controller: _credit,
                  label: 'Credit',
                  prefixIcon: Icons.layers_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) =>
                      Validators.numberPositive(v, field: 'Credit'),
                ),
                const SizedBox(height: AppPadding.lg),
                Text('Grade', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final g in Grade.values)
                      _GradeChip(
                        grade: g,
                        selected: g == _grade,
                        onTap: () => setState(() => _grade = g),
                      ),
                  ],
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
                  label: editing ? 'Save changes' : 'Add course',
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

class _GradeChip extends StatelessWidget {
  const _GradeChip({
    required this.grade,
    required this.selected,
    required this.onTap,
  });
  final Grade grade;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c =
        grade.points >= 3.0 ? AppColors.success
        : grade.points >= 2.0 ? AppColors.warning
        : AppColors.danger;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c : c.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(selected ? 1 : 0.3)),
        ),
        child: Text(
          '${grade.label}  (${grade.points.toStringAsFixed(2)})',
          style: TextStyle(
            color: selected ? Colors.white : c,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
