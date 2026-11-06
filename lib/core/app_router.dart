import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../views/dashboard.dart';
import '../views/vehicles.dart';
import '../views/vehicle_form.dart';
import '../views/service_form.dart';
import '../views/schedule_form.dart';
import '../views/history.dart';
import '../views/schedules.dart';
import '../views/statistics.dart';
import '../views/settings.dart';

final appRouter = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(path: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/', builder: (c, s) => const Dashboard()),
        GoRoute(path: '/vehicles', builder: (c, s) => const VehiclesView()),
        GoRoute(path: '/history', builder: (c, s) => const HistoryView()),
        GoRoute(path: '/schedules', builder: (c, s) => const SchedulesView()),
        GoRoute(path: '/statistics', builder: (c, s) => const StatisticsView()),
        GoRoute(path: '/settings', builder: (c, s) => const SettingsView()),
      ],
    ),
    GoRoute(path: '/vehicle/new', builder: (c, s) => const VehicleForm()),
    GoRoute(
      path: '/vehicle/:id/edit',
      builder: (c, s) => VehicleForm(id: s.pathParameters['id']),
    ),
    GoRoute(
      path: '/vehicle/:id',
      builder: (c, s) => VehicleDetails(id: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/service/new',
      builder: (c, s) =>
          ServiceForm(scheduleId: s.uri.queryParameters['complete']),
    ),
    GoRoute(
      path: '/service/:id/edit',
      builder: (c, s) => ServiceForm(id: s.pathParameters['id']),
    ),
    GoRoute(path: '/schedule/new', builder: (c, s) => const ScheduleForm()),
    GoRoute(
      path: '/schedule/:id/edit',
      builder: (c, s) => ScheduleForm(id: s.pathParameters['id']),
    ),
  ],
);

class AppShell extends StatelessWidget {
  final String path;
  final Widget child;
  const AppShell({super.key, required this.path, required this.child});
  static const paths = [
    '/',
    '/vehicles',
    '/history',
    '/schedules',
    '/statistics',
  ];
  @override
  Widget build(BuildContext context) {
    final index = paths.indexOf(path);
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sensors, color: Color(0xfff58b3c)),
            SizedBox(width: 8),
            Text('ServicePing', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: child,
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (i) => context.go(paths[i]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.garage_outlined),
            label: 'Vehicles',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(
            icon: Icon(Icons.event_note),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
        ],
      ),
    );
  }
}
