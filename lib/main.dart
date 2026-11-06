import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'core/app_router.dart';
import 'core/app_theme.dart';
import 'data/repositories/local_repository.dart';
import 'services/notification_service.dart';
import 'viewmodels/garage_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final box = await Hive.openBox<String>('serviceping');
  final notifications = NotificationService();
  try {
    await notifications.initialize();
  } catch (_) {
    /* App remains usable when notifications are unavailable. */
  }
  runApp(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(LocalRepository(box)),
        notificationsProvider.overrideWithValue(notifications),
      ],
      child: const ServicePingApp(),
    ),
  );
}

class ServicePingApp extends ConsumerStatefulWidget {
  const ServicePingApp({super.key});
  @override
  ConsumerState<ServicePingApp> createState() => _ServicePingAppState();
}

class _ServicePingAppState extends ConsumerState<ServicePingApp>
    with WidgetsBindingObserver {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
    timer = Timer.periodic(const Duration(minutes: 1), (_) {
      ref.read(garageProvider.notifier).refreshDateStatuses();
    });
  }

  Future<void> refresh() async {
    if (!mounted) return;
    ref.read(garageProvider.notifier).refreshDateStatuses();
    final state = ref.read(garageProvider);
    try {
      await ref
          .read(notificationsProvider)
          .sync(state.schedules, state.vehicles);
    } catch (_) {
      /* Notification access can be disabled in device settings. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'ServicePing',
    debugShowCheckedModeBanner: false,
    theme: appTheme(Brightness.light),
    darkTheme: appTheme(Brightness.dark),
    themeMode: ref.watch(garageProvider).themeMode,
    routerConfig: appRouter,
  );
}
