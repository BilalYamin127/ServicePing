import 'package:flutter_test/flutter_test.dart';
import 'package:service_ping/models/entities.dart';
import 'package:service_ping/services/notification_service.dart';

void main() {
  final vehicle = Vehicle(
    id: 'v',
    name: 'Car',
    manufacturer: 'Honda',
    model: 'Civic',
    type: VehicleType.car,
    currentOdometer: 100,
    distanceUnit: DistanceUnit.km,
    createdAt: DateTime(2020),
  );
  test(
    'Reminder days are deduplicated, chronological and skip elapsed dates',
    () {
      final queue = reminderQueue(
        [
          MaintenanceSchedule(
            id: 's',
            vehicleId: 'v',
            title: 'Oil',
            nextServiceDate: DateTime(2026, 11, 20),
            reminderDays: [7, 7, 1, 0],
          ),
        ],
        [vehicle],
        DateTime(2026, 11, 14),
      );
      expect(queue.length, 2);
      expect(queue.first.at, DateTime(2026, 11, 19, 9));
      expect(queue.last.at, DateTime(2026, 11, 20, 9));
    },
  );
  test('Completed and mileage-only schedules never queue notifications', () {
    final queue = reminderQueue(
      [
        MaintenanceSchedule(
          id: 's',
          vehicleId: 'v',
          title: 'Oil',
          nextServiceDate: DateTime(2027),
          isCompleted: true,
        ),
        MaintenanceSchedule(
          id: 'm',
          vehicleId: 'v',
          title: 'Tires',
          nextServiceOdometer: 200,
        ),
      ],
      [vehicle],
      DateTime(2026),
    );
    expect(queue, isEmpty);
  });
  test(
    'The closest 64 notifications are kept regardless of insertion order',
    () {
      final schedules = List.generate(
        80,
        (i) => MaintenanceSchedule(
          id: '$i',
          vehicleId: 'v',
          title: 'Service $i',
          nextServiceDate: DateTime(2027, 1, 80 - i),
        ),
      );
      final queue = reminderQueue(schedules, [vehicle], DateTime(2026));
      expect(queue.length, 64);
      expect(queue.first.at, DateTime(2027, 1, 1, 9));
      expect(queue.last.at, DateTime(2027, 1, 64, 9));
    },
  );
}
