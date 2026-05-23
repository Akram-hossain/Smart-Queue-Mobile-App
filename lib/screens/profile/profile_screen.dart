import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fee_provider.dart';
import '../../providers/gpa_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/task_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/grade.dart';
import '../../widgets/gradient_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _signingOut = false;

  Future<void> _confirmAndSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to log in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // Show full-screen overlay so there's no chance of a blank frame
    // while supabase clears the session and the shell route unmounts.
    setState(() => _signingOut = true);

    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      // best-effort — manual storage clearing already happened in the repo
    }

    // Drop cached user data so the next signed-in user sees fresh records.
    ref.invalidate(profileProvider);
    ref.invalidate(tasksProvider);
    ref.invalidate(attendanceProvider);
    ref.invalidate(feesProvider);
    ref.invalidate(gpaProvider);

    if (!mounted) return;

    // Navigate on the next frame so the widget tree is in a stable state
    // when GoRouter swaps the shell route for /login.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        GoRouter.of(context).go(AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(profileProvider);
    final user = ref.watch(currentUserProvider);
    final tasks = ref.watch(tasksProvider).valueOrNull ?? const [];
    final attendance = ref.watch(attendanceProvider).valueOrNull ?? const [];
    final fees = ref.watch(feesProvider).valueOrNull ?? const [];
    final cgpa = ref.watch(cgpaProvider);

    return Stack(
      children: [
        _buildScaffold(theme, profileAsync, user, tasks, attendance, fees, cgpa),
        if (_signingOut)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withOpacity(0.55),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Signing out…',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScaffold(
    ThemeData theme,
    AsyncValue<dynamic> profileAsync,
    dynamic user,
    List<dynamic> tasks,
    List<dynamic> attendance,
    List<dynamic> fees,
    double cgpa,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            onPressed: () {
              final p = profileAsync.valueOrNull;
              if (p != null) {
                context.push(AppRoutes.profileEdit, extra: p);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile still loading…')),
                );
              }
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(AppPadding.lg),
          child: Text('Could not load profile: $e'),
        ),
        data: (profile) {
          final name = profile?.fullName ??
              user?.email?.split('@').first ??
              'Student';
          return ListView(
            padding: const EdgeInsets.all(AppPadding.lg),
            children: [
              GradientCard(
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials(name),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppPadding.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '—',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppPadding.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppPadding.md),
                  child: Column(
                    children: [
                      _Row(
                        icon: Icons.account_balance_outlined,
                        label: 'University',
                        value: profile?.university ?? '—',
                      ),
                      const Divider(height: 1),
                      _Row(
                        icon: Icons.science_outlined,
                        label: 'Department',
                        value: profile?.department ?? '—',
                      ),
                      const Divider(height: 1),
                      _Row(
                        icon: Icons.calendar_view_month_rounded,
                        label: 'Semester',
                        value: profile?.semester ?? '—',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppPadding.lg),
              Text(
                'Academic snapshot',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppPadding.sm + 4),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppPadding.md),
                  child: Column(
                    children: [
                      _Row(
                        icon: Icons.checklist_rounded,
                        label: 'Tasks',
                        value: '${tasks.length}',
                      ),
                      const Divider(height: 1),
                      _Row(
                        icon: Icons.fact_check_outlined,
                        label: 'Subjects tracked',
                        value: '${attendance.length}',
                      ),
                      const Divider(height: 1),
                      _Row(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Fee records',
                        value: '${fees.length}',
                      ),
                      const Divider(height: 1),
                      _Row(
                        icon: Icons.school_outlined,
                        label: 'CGPA',
                        value: cgpa == 0
                            ? '—'
                            : '${cgpa.toStringAsFixed(2)} (${GradeCalc.letter(cgpa).label})',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppPadding.lg),
              OutlinedButton.icon(
                onPressed: _signingOut ? null : _confirmAndSignOut,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  String _initials(String full) {
    final parts =
        full.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters =
        parts.take(2).map((p) => p.characters.first.toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
