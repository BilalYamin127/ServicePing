import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:service_ping/data/repositories/local_repository.dart';
import 'package:service_ping/models/entities.dart';
import 'package:service_ping/services/notification_service.dart';
import 'package:service_ping/viewmodels/garage_view_model.dart';

void main() {
  late Directory directory;
  late LocalRepository repo;
  late ProviderContainer container;
  late GarageViewModel vm;
  ProviderContainer create() => ProviderContainer(
    overrides: [
      repositoryProvider.overrideWithValue(repo),
      notificationsProvider.overrideWithValue(NotificationService()),
    ],
  );
  Vehicle vehicle(String id, {double reading = 100}) => Vehicle(
    id: id,
    name: id,
    manufacturer: 'Honda',
    model: 'Civic',
    type: VehicleType.car,
    currentOdometer: reading,
    distanceUnit: DistanceUnit.km,
    createdAt: DateTime(2026),
  );
  ServiceRecord record(String id, String vehicleId) => ServiceRecord(
    id: id,
    vehicleId: vehicleId,
    serviceType: 'Oil',
    serviceDate: DateTime(2020),
    odometer: 50,
    cost: 25,
    createdAt: DateTime(2020),
  );
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('serviceping_test');
    Hive.init(directory.path);
    repo = LocalRepository(await Hive.openBox<String>('garage'));
    container = create();
    vm = container.read(garageProvider.notifier);
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  test(
    'Manual odometer updates reject decreases and preserve history',
    () async {
      await vm.saveVehicle(vehicle('a'));
      await vm.updateOdometer(vehicle('a'), 150);
      await expectLater(
        vm.updateOdometer(vehicle('a'), 99),
        throwsArgumentError,
      );
      expect(
        container.read(garageProvider).vehicles.single.currentOdometer,
        150,
      );
      expect(container.read(garageProvider).entries.map((e) => e.reading), [
        100,
        150,
      ]);
      await expectLater(
        vm.saveVehicle(vehicle('b', reading: double.nan)),
        throwsArgumentError,
      );
    },
  );
  test(
    'Service completion preserves history without generating recurrence',
    () async {
      await vm.saveVehicle(vehicle('a'));
      await vm.saveSchedule(
        MaintenanceSchedule(
          id: 's',
          vehicleId: 'a',
          title: 'Oil',
          nextServiceOdometer: 100,
        ),
      );
      await vm.saveRecord(record('r', 'a'), completeScheduleId: 's');
      final state = container.read(garageProvider);
      expect(state.records.single.id, 'r');
      expect(state.schedules.single.isCompleted, isTrue);
      expect(state.schedules.length, 1);
      expect(state.vehicles.single.currentOdometer, 100);
      await expectLater(
        vm.saveRecord(record('r2', 'a'), completeScheduleId: 's'),
        throwsArgumentError,
      );
    },
  );
  test(
    'Cross-vehicle completion is rejected and deletion is isolated',
    () async {
      await vm.saveVehicle(vehicle('a'));
      await vm.saveVehicle(vehicle('b'));
      await vm.saveRecord(record('a-r', 'a'));
      await vm.saveRecord(record('b-r', 'b'));
      await vm.saveSchedule(
        MaintenanceSchedule(
          id: 's',
          vehicleId: 'a',
          title: 'Oil',
          nextServiceOdometer: 200,
        ),
      );
      await expectLater(
        vm.saveRecord(record('wrong', 'b'), completeScheduleId: 's'),
        throwsArgumentError,
      );
      await vm.deleteVehicle('a');
      final state = container.read(garageProvider);
      expect(state.vehicles.single.id, 'b');
      expect(state.records.single.vehicleId, 'b');
      expect(state.schedules, isEmpty);
      expect(state.entries.single.vehicleId, 'b');
    },
  );
  test(
    'Hive state survives reopening and record edits do not duplicate expenses',
    () async {
      await vm.saveVehicle(vehicle('a'));
      await vm.saveRecord(record('r', 'a'));
      await vm.saveRecord(record('r', 'a'));
      await vm.setTheme('dark');
      container.dispose();
      await Hive.close();
      repo = LocalRepository(await Hive.openBox<String>('garage'));
      container = create();
      final state = container.read(garageProvider);
      expect(state.vehicles.single.id, 'a');
      expect(state.records.length, 1);
      expect(state.records.fold<double>(0, (s, r) => s + r.cost), 25);
      expect(state.theme, 'dark');
    },
  );
}
