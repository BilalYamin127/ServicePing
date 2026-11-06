// Run: SERVICEPING_CAPTURE_FONT=/absolute/path/Roboto.ttf flutter test
// tool/capture_store_screenshots_test.dart --run-skipped
// Captures the real app widgets with fictional local data; never runs in app.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
  testWidgets('Export seven real ServicePing screens for the store', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2340);
    tester.view.devicePixelRatio = 3;
    late Directory temp;
    late ProviderContainer container;
    late GarageViewModel vm;
    final boundaryKey = GlobalKey();
    await tester.runAsync(() async {
      final fontPath = Platform.environment['SERVICEPING_CAPTURE_FONT'];
      if (fontPath == null) {
        throw StateError('Set SERVICEPING_CAPTURE_FONT to Roboto.ttf');
      }
      final font = FontLoader('Roboto')
        ..addFont(
          Future.value(
            ByteData.sublistView(await File(fontPath).readAsBytes()),
          ),
        );
      await font.load();
      final material = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await material.load();
      temp = await Directory.systemTemp.createTemp('serviceping_store_');
      Hive.init(temp.path);
      final repo = LocalRepository(await Hive.openBox<String>('store_capture'));
      container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          notificationsProvider.overrideWithValue(NotificationService()),
        ],
      );
      vm = container.read(garageProvider.notifier);
      final now = DateTime.now();
      await vm.saveVehicle(
        Vehicle(
          id: 'car',
          name: 'Daily driver',
          manufacturer: 'Honda',
          model: 'Civic',
          year: 2022,
          type: VehicleType.car,
          currentOdometer: 42850,
          distanceUnit: DistanceUnit.km,
          createdAt: now.subtract(const Duration(days: 200)),
        ),
      );
      await vm.saveVehicle(
        Vehicle(
          id: 'bike',
          name: 'Weekend rider',
          manufacturer: 'Yamaha',
          model: 'MT-07',
          year: 2023,
          type: VehicleType.motorcycle,
          currentOdometer: 12640,
          distanceUnit: DistanceUnit.km,
          createdAt: now.subtract(const Duration(days: 100)),
        ),
      );
      await vm.saveVehicle(
        Vehicle(
          id: 'suv',
          name: 'Family explorer',
          manufacturer: 'Toyota',
          model: 'RAV4',
          year: 2021,
          type: VehicleType.car,
          currentOdometer: 31200,
          distanceUnit: DistanceUnit.miles,
          createdAt: now.subtract(const Duration(days: 150)),
        ),
      );
      const titles = [
        'General servicing',
        'Brake maintenance',
        'Tire replacement',
        'Air filter replacement',
        'Oil change',
        'Oil change',
      ];
      const costs = [180.0, 120.0, 360.0, 45.0, 85.0, 95.0];
      for (var i = 0; i < 6; i++) {
        await vm.saveRecord(
          ServiceRecord(
            id: 'record$i',
            vehicleId: 'car',
            serviceType: titles[i],
            serviceDate: DateTime(now.year, now.month - 5 + i, 3),
            odometer: 34000 + i * 1400,
            cost: costs[i],
            notes: i == 5
                ? 'Oil and filter replaced. Ready for the next journey.'
                : null,
            createdAt: now,
          ),
        );
      }
      await vm.saveSchedule(
        MaintenanceSchedule(
          id: 'oil',
          vehicleId: 'car',
          title: 'Oil & filter change',
          nextServiceDate: now.add(const Duration(days: 24)),
          nextServiceOdometer: 45000,
          reminderDays: [7, 1],
        ),
      );
      await vm.saveSchedule(
        MaintenanceSchedule(
          id: 'brakes',
          vehicleId: 'car',
          title: 'Brake inspection',
          nextServiceDate: now.subtract(const Duration(days: 2)),
          nextServiceOdometer: 42500,
          reminderDays: [7, 1],
        ),
      );
      await vm.saveSchedule(
        MaintenanceSchedule(
          id: 'tires',
          vehicleId: 'car',
          title: 'Tire rotation',
          nextServiceDate: now.add(const Duration(days: 52)),
          nextServiceOdometer: 47000,
          reminderDays: [3],
        ),
      );
      for (final reading in [43120.0, 43560.0, 43850.0]) {
        await vm.updateOdometer(
          container
              .read(garageProvider)
              .vehicles
              .firstWhere((v) => v.id == 'car'),
          reading,
        );
      }
      await vm.setTheme('light');
      vm.select('car');
      await Directory('store/screenshots/raw').create(recursive: true);
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(key: boundaryKey, child: const ServicePingApp()),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('store/branding/app-icon-512.png'),
        boundaryKey.currentContext!,
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 3);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'store/screenshots/raw/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    appRouter.go('/');
    await tester.pumpAndSettle();
    await capture('01-dashboard');
    appRouter.go('/vehicles');
    await tester.pumpAndSettle();
    await capture('02-garage');
    appRouter.go('/schedules');
    await tester.pumpAndSettle();
    await capture('03-schedules');
    appRouter.go('/history');
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -230));
    await tester.pumpAndSettle();
    await capture('04-history');
    appRouter.go('/statistics');
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -260));
    await tester.pumpAndSettle();
    await capture('05-statistics');
    appRouter.go('/vehicle/car');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update odometer'));
    await tester.pumpAndSettle();
    await capture('06-manual-odometer');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => vm.setTheme('dark'));
    appRouter.go('/');
    await tester.pumpAndSettle();
    await capture('07-dark-mode');
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.runAsync(() async {
      await Hive.close();
      await temp.delete(recursive: true);
    });
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
