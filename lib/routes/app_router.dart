import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../screens/attendance/attendance_form_screen.dart';
import '../screens/attendance/attendance_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/fees/fee_form_screen.dart';
import '../screens/fees/fees_screen.dart';
import '../screens/gpa/gpa_form_screen.dart';
import '../screens/gpa/gpa_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/splash_screen.dart';
import '../screens/tasks/calendar_screen.dart';
import '../screens/tasks/task_form_screen.dart';
import '../screens/tasks/tasks_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgot = '/forgot';
  static const dashboard = '/dashboard';
  static const tasks = '/tasks';
  static const tasksCalendar = '/tasks/calendar';
  static const taskNew = '/tasks/new';
  static const taskEdit = '/tasks/edit';
  static const attendance = '/attendance';
  static const attendanceNew = '/attendance/new';
  static const fees = '/fees';
  static const feeNew = '/fees/new';
  static const gpa = '/gpa';
  static const gpaNew = '/gpa/new';
  static const profile = '/profile';
  static const settings = '/settings';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthListenable(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isSplash = loc == AppRoutes.splash;
      final inAuth = loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.forgot;

      final isLoggedIn =
          ref.read(authRepositoryProvider).currentUser != null;

      if (isSplash) {
        return isLoggedIn ? AppRoutes.dashboard : AppRoutes.login;
      }
      if (!isLoggedIn && !inAuth) return AppRoutes.login;
      if (isLoggedIn && inAuth) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgot,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            MainShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.tasks,
            builder: (_, __) => const TasksScreen(),
          ),
          GoRoute(
            path: AppRoutes.attendance,
            builder: (_, __) => const AttendanceScreen(),
          ),
          GoRoute(
            path: AppRoutes.fees,
            builder: (_, __) => const FeesScreen(),
          ),
          GoRoute(
            path: AppRoutes.gpa,
            builder: (_, __) => const GpaScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.tasksCalendar,
        builder: (_, __) => const TasksCalendarScreen(),
      ),
      GoRoute(
        path: AppRoutes.taskNew,
        builder: (_, __) => const TaskFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.taskEdit,
        builder: (_, state) =>
            TaskFormScreen(existing: state.extra as TaskItem?),
      ),
      GoRoute(
        path: AppRoutes.attendanceNew,
        builder: (_, state) => AttendanceFormScreen(existing: state.extra),
      ),
      GoRoute(
        path: AppRoutes.feeNew,
        builder: (_, state) => FeeFormScreen(existing: state.extra),
      ),
      GoRoute(
        path: AppRoutes.gpaNew,
        builder: (_, state) => GpaFormScreen(existing: state.extra),
      ),
    ],
  );
});

/// Bridges Supabase auth-state changes into go_router's Listenable contract.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _sub = _ref
        .read(authRepositoryProvider)
        .authChanges()
        .listen((_) => notifyListeners());
  }
  final Ref _ref;
  StreamSubscription<AuthState>? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
