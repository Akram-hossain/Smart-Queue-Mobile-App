import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../models/profile.dart';
import '../../providers/profile_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key, required this.profile});
  final Profile profile;

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _department;
  late final TextEditingController _semester;
  late final TextEditingController _university;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.fullName);
    _department = TextEditingController(text: widget.profile.department ?? '');
    _semester = TextEditingController(text: widget.profile.semester ?? '');
    _university = TextEditingController(text: widget.profile.university ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _department.dispose();
    _semester.dispose();
    _university.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final updated = widget.profile.copyWith(
        fullName: _name.text.trim(),
        department: _department.text.trim(),
        semester: _semester.text.trim(),
        university: _university.text.trim(),
      );
      await ref.read(profileRepositoryProvider).updateProfile(updated);
      // Refresh the profile + anything that reads it (dashboard greeting etc.)
      ref.invalidate(profileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Edit profile'),
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
                // Email — read-only (can't be changed from here)
                AppTextField(
                  controller:
                      TextEditingController(text: widget.profile.email),
                  label: 'Email (cannot be changed)',
                  prefixIcon: Icons.alternate_email_rounded,
                  enabled: false,
                ),
                const SizedBox(height: AppPadding.md),
                AppTextField(
                  controller: _name,
                  label: 'Full name',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) =>
                      Validators.required(v, field: 'Full name'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppPadding.md),
                AppTextField(
                  controller: _university,
                  label: 'University',
                  prefixIcon: Icons.account_balance_outlined,
                  validator: (v) =>
                      Validators.required(v, field: 'University'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppPadding.md),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _department,
                        label: 'Department',
                        prefixIcon: Icons.science_outlined,
                        validator: (v) =>
                            Validators.required(v, field: 'Department'),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: AppPadding.md),
                    Expanded(
                      child: AppTextField(
                        controller: _semester,
                        label: 'Semester',
                        prefixIcon: Icons.calendar_view_month_rounded,
                        validator: (v) =>
                            Validators.required(v, field: 'Semester'),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _save(),
                      ),
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
                      border: Border.all(
                          color: AppColors.danger.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.danger, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_error!,
                              style:
                                  const TextStyle(color: AppColors.danger)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppPadding.lg),
                PrimaryButton(
                  label: 'Save changes',
                  loading: _saving,
                  onPressed: _save,
                ),
                const SizedBox(height: AppPadding.md),
                Text(
                  'Need to change your email? Sign out and contact support — '
                  'email is tied to your Supabase auth account.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
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
