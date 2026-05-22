import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_router.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  int _indexFor(String loc) {
    if (loc.startsWith(AppRoutes.dashboard)) return 0;
    if (loc.startsWith(AppRoutes.tasks)) return 1;
    if (loc.startsWith(AppRoutes.attendance)) return 2;
    if (loc.startsWith(AppRoutes.fees)) return 3;
    if (loc.startsWith(AppRoutes.gpa)) return 4;
    if (loc.startsWith(AppRoutes.profile)) return 5;
    return 0;
  }

  void _onTap(BuildContext context, int i) {
    switch (i) {
      case 0:
        context.go(AppRoutes.dashboard);
        break;
      case 1:
        context.go(AppRoutes.tasks);
        break;
      case 2:
        context.go(AppRoutes.attendance);
        break;
      case 3:
        context.go(AppRoutes.fees);
        break;
      case 4:
        context.go(AppRoutes.gpa);
        break;
      case 5:
        context.go(AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final idx = _indexFor(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist_rounded),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded),
            label: 'Attend.',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Fees',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded),
            label: 'GPA',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
