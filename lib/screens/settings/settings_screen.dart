import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/env.dart';
import '../../providers/theme_provider.dart';
import '../../services/notification_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final notif = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppPadding.lg),
        children: [
          _SectionHeader('Appearance'),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: themeMode,
                  title: const Text('System'),
                  subtitle: const Text('Follow device setting'),
                  onChanged: (v) =>
                      ref.read(themeModeProvider.notifier).set(v!),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: themeMode,
                  title: const Text('Light'),
                  onChanged: (v) =>
                      ref.read(themeModeProvider.notifier).set(v!),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: themeMode,
                  title: const Text('Dark'),
                  onChanged: (v) =>
                      ref.read(themeModeProvider.notifier).set(v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppPadding.lg),
          _SectionHeader('Notifications'),
          Card(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: notif,
                  onChanged: (v) async {
                    if (v) {
                      await NotificationService.instance.requestPermission();
                    } else {
                      await NotificationService.instance.cancelAll();
                    }
                    await ref
                        .read(notificationsEnabledProvider.notifier)
                        .set(v);
                  },
                  title: const Text('Enable reminders'),
                  subtitle: const Text(
                      'Local notifications for exams, assignments and fees'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Send a test notification'),
                  subtitle: const Text(
                      'Fires immediately so you can confirm permissions'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final granted = await NotificationService.instance
                        .requestPermission();
                    if (!granted) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Notification permission was denied. Enable it in your phone\'s Settings → Apps → SemesterMate → Notifications.'),
                          ),
                        );
                      }
                      return;
                    }
                    await NotificationService.instance
                        .showTestNotification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Test notification sent. Pull down the status bar to see it.'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppPadding.lg),
          _SectionHeader('Account'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded),
                  title: const Text('Change password'),
                  subtitle: const Text(
                      'A reset link will be sent to your email'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Pressing this triggers a future enhancement: send reset
                    // link to logged-in user. For now, hint that we can't.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Sign out and use "Forgot password" from the login screen.'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppPadding.lg),
          _SectionHeader('About'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.school_rounded),
                  title: Text('SemesterMate'),
                  subtitle: Text(
                      'Student productivity & academic management — v1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: const Text('Backend'),
                  subtitle: Text(
                    Env.isConfigured
                        ? 'Supabase configured ✓'
                        : 'Supabase not configured — add secrets and rebuild',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(4, 4, 4, AppPadding.sm),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
