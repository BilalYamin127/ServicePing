String newId() => DateTime.now().microsecondsSinceEpoch.toString();

enum VehicleType { motorcycle, car }

enum DistanceUnit { km, miles }

class Vehicle {
  final String id, name, manufacturer, model;
  final int? year;
  final VehicleType type;
  final String? registrationNumber;
  final double currentOdometer;
  final DistanceUnit distanceUnit;
  final DateTime createdAt;
  Vehicle({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.model,
    this.year,
    required this.type,
    this.registrationNumber,
    required this.currentOdometer,
    required this.distanceUnit,
    required this.createdAt,
  });
  Vehicle withReading(double value) => Vehicle(
    id: id,
    name: name,
    manufacturer: manufacturer,
    model: model,
    year: year,
    type: type,
    registrationNumber: registrationNumber,
    currentOdometer: value,
    distanceUnit: distanceUnit,
    createdAt: createdAt,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'manufacturer': manufacturer,
    'model': model,
    'year': year,
    'type': type.name,
    'registrationNumber': registrationNumber,
    'currentOdometer': currentOdometer,
    'distanceUnit': distanceUnit.name,
    'createdAt': createdAt.toIso8601String(),
  };
  factory Vehicle.fromJson(Map j) => Vehicle(
    id: j['id'],
    name: j['name'],
    manufacturer: j['manufacturer'],
    model: j['model'],
    year: j['year'],
    type: VehicleType.values.byName(j['type']),
    registrationNumber: j['registrationNumber'],
    currentOdometer: (j['currentOdometer'] as num).toDouble(),
    distanceUnit: DistanceUnit.values.byName(j['distanceUnit']),
    createdAt: DateTime.parse(j['createdAt']),
  );
}

class ServiceRecord {
  final String id, vehicleId, serviceType;
  final DateTime serviceDate, createdAt;
  final double odometer, cost;
  final String? notes;
  ServiceRecord({
    required this.id,
    required this.vehicleId,
    required this.serviceType,
    required this.serviceDate,
    required this.odometer,
    required this.cost,
    this.notes,
    required this.createdAt,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'vehicleId': vehicleId,
    'serviceType': serviceType,
    'serviceDate': serviceDate.toIso8601String(),
    'odometer': odometer,
    'cost': cost,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };
  factory ServiceRecord.fromJson(Map j) => ServiceRecord(
    id: j['id'],
    vehicleId: j['vehicleId'],
    serviceType: j['serviceType'],
    serviceDate: DateTime.parse(j['serviceDate']),
    odometer: (j['odometer'] as num).toDouble(),
    cost: (j['cost'] as num).toDouble(),
    notes: j['notes'],
    createdAt: DateTime.parse(j['createdAt']),
  );
}

class MaintenanceSchedule {
  final String id, vehicleId, title;
  final DateTime? nextServiceDate;
  final double? nextServiceOdometer;
  final List<int> reminderDays;
  final bool isCompleted;
  MaintenanceSchedule({
    required this.id,
    required this.vehicleId,
    required this.title,
    this.nextServiceDate,
    this.nextServiceOdometer,
    this.reminderDays = const [],
    this.isCompleted = false,
  });
  bool due(Vehicle v, DateTime now) =>
      !isCompleted &&
      ((nextServiceDate != null &&
              !DateTime(now.year, now.month, now.day).isBefore(
                DateTime(
                  nextServiceDate!.year,
                  nextServiceDate!.month,
                  nextServiceDate!.day,
                ),
              )) ||
          (nextServiceOdometer != null &&
              nextServiceOdometer! <= v.currentOdometer));
  bool overdue(Vehicle v, DateTime now) {
    if (isCompleted) return false;
    final today = DateTime(now.year, now.month, now.day);
    final date = nextServiceDate;
    return (date != null &&
            DateTime(date.year, date.month, date.day).isBefore(today)) ||
        (nextServiceOdometer != null &&
            nextServiceOdometer! < v.currentOdometer);
  }

  double? remaining(Vehicle v) => nextServiceOdometer == null
      ? null
      : nextServiceOdometer! - v.currentOdometer;
  Map<String, dynamic> toJson() => {
    'id': id,
    'vehicleId': vehicleId,
    'title': title,
    'nextServiceDate': nextServiceDate?.toIso8601String(),
    'nextServiceOdometer': nextServiceOdometer,
    'reminderDays': reminderDays,
    'isCompleted': isCompleted,
  };
  factory MaintenanceSchedule.fromJson(Map j) => MaintenanceSchedule(
    id: j['id'],
    vehicleId: j['vehicleId'],
    title: j['title'],
    nextServiceDate: j['nextServiceDate'] == null
        ? null
        : DateTime.parse(j['nextServiceDate']),
    nextServiceOdometer: (j['nextServiceOdometer'] as num?)?.toDouble(),
    reminderDays: List<int>.from(j['reminderDays']),
    isCompleted: j['isCompleted'],
  );
}

class OdometerEntry {
  final String id, vehicleId;
  final double reading;
  final DateTime recordedAt;
  OdometerEntry({
    required this.id,
    required this.vehicleId,
    required this.reading,
    required this.recordedAt,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'vehicleId': vehicleId,
    'reading': reading,
    'recordedAt': recordedAt.toIso8601String(),
  };
  factory OdometerEntry.fromJson(Map j) => OdometerEntry(
    id: j['id'],
    vehicleId: j['vehicleId'],
    reading: (j['reading'] as num).toDouble(),
    recordedAt: DateTime.parse(j['recordedAt']),
  );
}
