import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:service_ping/main.dart';
import 'package:service_ping/core/app_router.dart';
import 'package:service_ping/data/repositories/local_repository.dart';
import 'package:service_ping/models/entities.dart';
import 'package:service_ping/services/notification_service.dart';
import 'package:service_ping/viewmodels/garage_view_model.dart';

void main() {
  testWidgets('All screens render on a mobile viewport in both themes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    late Directory directory;
    late ProviderContainer container;
    late GarageViewModel vm;
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('serviceping_ui');
      Hive.init(directory.path);
      final repo = LocalRepository(await Hive.openBox<String>('ui'));
      container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          notificationsProvider.overrideWithValue(NotificationService()),
        ],
      );
      vm = container.read(garageProvider.notifier);
      await vm.saveVehicle(
        Vehicle(
          id: 'v',
          name: 'Daily driver',
          manufacturer: 'Honda',
          model: 'Civic',
          type: VehicleType.car,
          currentOdometer: 30000,
          distanceUnit: DistanceUnit.km,
          createdAt: DateTime.now(),
        ),
      );
      await vm.saveSchedule(
        MaintenanceSchedule(
          id: 's',
          vehicleId: 'v',
          title: 'Oil change',
          nextServiceOdometer: 31000,
          nextServiceDate: DateTime.now().add(const Duration(days: 30)),
        ),
      );
      await vm.saveRecord(
        ServiceRecord(
          id: 'r',
          vehicleId: 'v',
          serviceType: 'Oil change',
          serviceDate: DateTime(2020),
          odometer: 25000,
          cost: 100,
          createdAt: DateTime(2020),
        ),
      );
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ServicePingApp(),
      ),
    );
    await tester.pumpAndSettle();
    for (final theme in ['light', 'dark']) {
      await tester.runAsync(() => vm.setTheme(theme));
      for (final path in [
        '/',
        '/vehicles',
        '/history',
        '/schedules',
        '/statistics',
        '/settings',
        '/privacy',
        '/vehicle/v',
        '/vehicle/new',
        '/vehicle/v/edit',
        '/service/new',
        '/service/r/edit',
        '/schedule/new',
        '/schedule/s/edit',
      ]) {
        appRouter.go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$theme $path');
        if (path == '/privacy') {
          expect(find.text('ServicePing Privacy Policy'), findsOneWidget);
        }
        if (theme == 'light' && path == '/') {
          await tester.tap(find.text('Update odometer'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextFormField), '29999');
          await tester.tap(find.widgetWithText(FilledButton, 'Update'));
          await tester.pumpAndSettle();
          expect(
            find.textContaining('Enter a reading of at least'),
            findsOneWidget,
          );
          await tester.enterText(find.byType(TextFormField), '31000');
          await tester.runAsync(() async {
            await tester.tap(find.widgetWithText(FilledButton, 'Update'));
            await Future<void>.delayed(const Duration(milliseconds: 100));
          });
          await tester.pumpAndSettle();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pumpAndSettle();
          expect(
            container.read(garageProvider).selected!.currentOdometer,
            31000,
          );
          expect(container.read(garageProvider).entries.length, 2);
        }
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.runAsync(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
