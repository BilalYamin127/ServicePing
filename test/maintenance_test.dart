import 'package:flutter_test/flutter_test.dart';
import 'package:service_ping/models/entities.dart';

void main() {
  final now = DateTime(2026, 11, 6, 12);
  Vehicle vehicle(double reading) => Vehicle(
    id: 'v',
    name: 'Car',
    manufacturer: 'Honda',
    model: 'Civic',
    type: VehicleType.car,
    currentOdometer: reading,
    distanceUnit: DistanceUnit.km,
    createdAt: now,
  );
  test('Date and mileage independently make maintenance due', () {
    final byDate = MaintenanceSchedule(
      id: 'd',
      vehicleId: 'v',
      title: 'Oil',
      nextServiceDate: DateTime(2026, 11, 6),
      nextServiceOdometer: 2000,
    );
    expect(byDate.due(vehicle(100), now), isTrue);
    final byMileage = MaintenanceSchedule(
      id: 'm',
      vehicleId: 'v',
      title: 'Oil',
      nextServiceDate: DateTime(2027),
      nextServiceOdometer: 2000,
    );
    expect(byMileage.due(vehicle(2000), now), isTrue);
    expect(byMileage.overdue(vehicle(2000), now), isFalse);
    expect(byMileage.overdue(vehicle(2001), now), isTrue);
    expect(byDate.overdue(vehicle(100), now), isFalse);
    expect(
      byDate.overdue(vehicle(100), now.add(const Duration(days: 1))),
      isTrue,
    );
    expect(byMileage.due(vehicle(2001), now), isTrue);
    expect(byMileage.due(vehicle(1999), now), isFalse);
    expect(byMileage.remaining(vehicle(2100)), -100);
  });
  test('Completed schedules never become due', () {
    final s = MaintenanceSchedule(
      id: 's',
      vehicleId: 'v',
      title: 'Oil',
      nextServiceOdometer: 0,
      nextServiceDate: DateTime(2020),
      isCompleted: true,
    );
    expect(s.due(vehicle(2000), now), isFalse);
  });
  test('Date-only and mileage-only schedules work', () {
    expect(
      MaintenanceSchedule(
        id: 's',
        vehicleId: 'v',
        title: 'Oil',
        nextServiceDate: DateTime(2026, 11, 7),
      ).due(vehicle(9999), now),
      isFalse,
    );
    expect(
      MaintenanceSchedule(
        id: 's',
        vehicleId: 'v',
        title: 'Oil',
        nextServiceOdometer: 100,
      ).due(vehicle(100), now),
      isTrue,
    );
  });
  test('Vehicle serialization retains optional fields and units', () {
    final v = vehicle(123.5);
    final restored = Vehicle.fromJson(v.toJson());
    expect(restored.currentOdometer, 123.5);
    expect(restored.year, isNull);
    expect(restored.distanceUnit, DistanceUnit.km);
  });
}
