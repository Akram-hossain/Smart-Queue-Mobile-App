import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/env.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/error_messages.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _department = TextEditingController();
  final _semester = TextEditingController();
  final _university = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _password,
      _confirm,
      _department,
      _semester,
      _university,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _info = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!Env.isConfigured) {
      setState(() => _error =
          'The app isn\'t connected to the server. Please reinstall the latest version.');
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final res = await repo.signUp(
        fullName: _name.text,
        email: _email.text,
        password: _password.text,
        department: _department.text,
        semester: _semester.text,
        university: _university.text,
      );
      if (!mounted) return;
      if (res.session != null) {
        context.go(AppRoutes.dashboard);
      } else {
        setState(() => _info =
            'Account created. Check your email for a confirmation link, then sign in.');
      }
    } catch (e) {
      setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.lg, vertical: AppPadding.md),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create your account',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Join SemesterMate and stay on top of your semester',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: AppPadding.xl),
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
                  controller: _email,
                  label: 'Email',
                  prefixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppPadding.md),
                AppTextField(
                  controller: _password,
                  label: 'Password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                  validator: Validators.password,
                  textInputAction: TextInputAction.next,
                  suffix: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: AppPadding.md),
                AppTextField(
                  controller: _confirm,
                  label: 'Confirm password',
                  prefixIcon: Icons.lock_reset_rounded,
                  obscure: _obscure,
                  validator: (v) =>
                      Validators.confirmPassword(v, _password.text),
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
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppPadding.md),
                  _Banner(text: _error!, danger: true),
                ],
                if (_info != null) ...[
                  const SizedBox(height: AppPadding.md),
                  _Banner(text: _info!, danger: false),
                ],
                const SizedBox(height: AppPadding.lg),
                PrimaryButton(
                  label: 'Create account',
                  loading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppPadding.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Sign in'),
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

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.danger});
  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.md, vertical: AppPadding.sm + 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            danger ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: color))),
        ],
      ),
    );
  }
}
