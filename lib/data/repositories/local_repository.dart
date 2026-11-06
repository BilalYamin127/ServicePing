import 'dart:convert';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/entities.dart';

class LocalRepository {
  final Box<String> box;
  LocalRepository(this.box);
  Future<void> save(
    List<Vehicle> vehicles,
    List<ServiceRecord> records,
    List<MaintenanceSchedule> schedules,
    List<OdometerEntry> entries,
    String theme,
  ) async {
    // A single Hive entry keeps related collections consistent across restarts.
    await box.put(
      'state',
      jsonEncode({
        'schemaVersion': 1,
        'vehicles': vehicles.map((e) => e.toJson()).toList(),
        'records': records.map((e) => e.toJson()).toList(),
        'schedules': schedules.map((e) => e.toJson()).toList(),
        'entries': entries.map((e) => e.toJson()).toList(),
        'theme': theme,
      }),
    );
  }

  Map<String, dynamic> load() =>
      jsonDecode(box.get('state', defaultValue: '{}')!);
}
