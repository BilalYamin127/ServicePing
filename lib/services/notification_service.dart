import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/entities.dart';

/// A deterministic, chronological queue, also used by unit tests.
List<({DateTime at, String title, String body})> reminderQueue(
  List<MaintenanceSchedule> schedules,
  List<Vehicle> vehicles,
  DateTime now,
) {
  final queue = <({DateTime at, String title, String body})>[];
  for (final s in schedules.where(
    (s) => !s.isCompleted && s.nextServiceDate != null,
  )) {
    final v = vehicles.where((v) => v.id == s.vehicleId).firstOrNull;
    if (v == null) continue;
    final date = s.nextServiceDate!;
    for (final days in {...s.reminderDays, 0}) {
      // Calendar arithmetic preserves the intended day across DST transitions.
      final at = DateTime(date.year, date.month, date.day - days, 9);
      if (!at.isAfter(now)) continue;
      queue.add((
        at: at,
        title: '${v.name}: ${s.title}',
        body: days == 0
            ? 'Maintenance is due today.'
            : 'Maintenance is due in $days days.',
      ));
    }
  }
  queue.sort((a, b) => a.at.compareTo(b.at));
  // iOS supports 64 pending notifications. Keep the nearest reminders on both
  // platforms and refill the rolling queue whenever the app opens/resumes.
  return queue.take(64).toList();
}

class NotificationService {
  final plugin = FlutterLocalNotificationsPlugin();
  bool ready = false;
  Future<void> _pending = Future.value();
  Future<void> initialize() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    tzdata.initializeTimeZones();
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    ready = true;
  }

  Future<bool> requestPermission() async {
    if (!ready) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  Future<void> sync(
    List<MaintenanceSchedule> schedules,
    List<Vehicle> vehicles,
  ) {
    if (!ready) return Future.value();
    // Serialize OS mutations so rapid edits cannot restore an obsolete queue.
    _pending = _pending
        .catchError((Object _) {})
        .then((_) => _sync(schedules, vehicles));
    return _pending;
  }

  Future<void> _sync(
    List<MaintenanceSchedule> schedules,
    List<Vehicle> vehicles,
  ) async {
    await plugin.cancelAll();
    var id = 1;
    for (final reminder in reminderQueue(schedules, vehicles, DateTime.now())) {
      await plugin.zonedSchedule(
        id++,
        reminder.title,
        reminder.body,
        tz.TZDateTime.from(reminder.at, tz.UTC),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'maintenance',
            'Maintenance reminders',
            channelDescription: 'Service dates you configured',
            importance: Importance.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
