import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities.dart';
import '../data/repositories/local_repository.dart';
import '../services/notification_service.dart';

final repositoryProvider = Provider<LocalRepository>(
  (ref) => throw UnimplementedError(),
);
final notificationsProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError(),
);
final garageProvider = NotifierProvider<GarageViewModel, GarageState>(
  GarageViewModel.new,
);

class GarageState {
  final List<Vehicle> vehicles;
  final List<ServiceRecord> records;
  final List<MaintenanceSchedule> schedules;
  final List<OdometerEntry> entries;
  final String? selectedId;
  final String theme;
  const GarageState({
    this.vehicles = const [],
    this.records = const [],
    this.schedules = const [],
    this.entries = const [],
    this.selectedId,
    this.theme = 'system',
  });
  Vehicle? get selected =>
      vehicles.where((v) => v.id == selectedId).firstOrNull ??
      vehicles.firstOrNull;
  GarageState copy({
    List<Vehicle>? vehicles,
    List<ServiceRecord>? records,
    List<MaintenanceSchedule>? schedules,
    List<OdometerEntry>? entries,
    String? selectedId,
    String? theme,
  }) => GarageState(
    vehicles: vehicles ?? this.vehicles,
    records: records ?? this.records,
    schedules: schedules ?? this.schedules,
    entries: entries ?? this.entries,
    selectedId: selectedId ?? this.selectedId,
    theme: theme ?? this.theme,
  );
  ThemeMode get themeMode => ThemeMode.values.byName(theme);
}

class GarageViewModel extends Notifier<GarageState> {
  @override
  GarageState build() {
    final j = ref.read(repositoryProvider).load();
    return GarageState(
      vehicles: (j['vehicles'] as List? ?? [])
          .map((e) => Vehicle.fromJson(e))
          .toList(),
      records: (j['records'] as List? ?? [])
          .map((e) => ServiceRecord.fromJson(e))
          .toList(),
      schedules: (j['schedules'] as List? ?? [])
          .map((e) => MaintenanceSchedule.fromJson(e))
          .toList(),
      entries: (j['entries'] as List? ?? [])
          .map((e) => OdometerEntry.fromJson(e))
          .toList(),
      theme: j['theme'] ?? 'system',
    );
  }

  Future<void> commit(GarageState next) async {
    await ref
        .read(repositoryProvider)
        .save(
          next.vehicles,
          next.records,
          next.schedules,
          next.entries,
          next.theme,
        );
    state = next;
    try {
      await ref
          .read(notificationsProvider)
          .sync(state.schedules, state.vehicles);
    } catch (_) {
      /* Records remain saved if OS notification scheduling fails. */
    }
  }

  void select(String id) {
    state = state.copy(selectedId: id);
  }

  Future<void> setTheme(String theme) => commit(state.copy(theme: theme));
  Future<void> saveVehicle(Vehicle v) async {
    if (v.name.trim().isEmpty ||
        v.manufacturer.trim().isEmpty ||
        v.model.trim().isEmpty) {
      throw ArgumentError(
        'Vehicle name, manufacturer, and model are required.',
      );
    }
    if (!v.currentOdometer.isFinite || v.currentOdometer < 0) {
      throw ArgumentError('Odometer must be a finite non-negative number.');
    }
    final old = state.vehicles.where((e) => e.id == v.id).firstOrNull;
    if (old != null && v.currentOdometer < old.currentOdometer) {
      throw ArgumentError('Odometer cannot decrease.');
    }
    if (old != null && old.distanceUnit != v.distanceUnit) {
      throw ArgumentError('Distance unit cannot change after creation.');
    }
    final entries = [...state.entries];
    if (old == null || old.currentOdometer != v.currentOdometer) {
      entries.add(
        OdometerEntry(
          id: newId(),
          vehicleId: v.id,
          reading: v.currentOdometer,
          recordedAt: DateTime.now(),
        ),
      );
    }
    await commit(
      state.copy(
        vehicles: [...state.vehicles.where((e) => e.id != v.id), v],
        entries: entries,
        selectedId: v.id,
      ),
    );
  }

  Future<void> updateOdometer(Vehicle v, double reading) =>
      saveVehicle(v.withReading(reading));
  Future<void> deleteVehicle(String id) => commit(
    state.copy(
      vehicles: state.vehicles.where((e) => e.id != id).toList(),
      records: state.records.where((e) => e.vehicleId != id).toList(),
      schedules: state.schedules.where((e) => e.vehicleId != id).toList(),
      entries: state.entries.where((e) => e.vehicleId != id).toList(),
    ),
  );
  Future<void> saveRecord(ServiceRecord r, {String? completeScheduleId}) async {
    final vehicle = state.vehicles.firstWhere((v) => v.id == r.vehicleId);
    if (r.serviceType.trim().isEmpty ||
        !r.cost.isFinite ||
        r.cost < 0 ||
        !r.odometer.isFinite ||
        r.odometer < 0) {
      throw ArgumentError(
        'Service type, a valid cost, and a valid odometer are required.',
      );
    }
    if (r.serviceDate.isAfter(DateTime.now())) {
      throw ArgumentError('Completed services cannot have a future date.');
    }
    final previous = state.records.where((e) => e.id == r.id).firstOrNull;
    if (previous != null && previous.vehicleId != r.vehicleId) {
      throw ArgumentError(
        'A service record cannot move to a different vehicle.',
      );
    }
    if (completeScheduleId != null) {
      final schedule = state.schedules.firstWhere(
        (s) => s.id == completeScheduleId,
      );
      if (schedule.vehicleId != r.vehicleId || schedule.isCompleted) {
        throw ArgumentError('Select an active schedule for this vehicle.');
      }
    }
    if (r.odometer > vehicle.currentOdometer) {
      throw ArgumentError('Update the vehicle odometer first.');
    }
    final schedules = state.schedules
        .map(
          (s) => s.id == completeScheduleId
              ? MaintenanceSchedule(
                  id: s.id,
                  vehicleId: s.vehicleId,
                  title: s.title,
                  nextServiceDate: s.nextServiceDate,
                  nextServiceOdometer: s.nextServiceOdometer,
                  reminderDays: s.reminderDays,
                  isCompleted: true,
                )
              : s,
        )
        .toList();
    await commit(
      state.copy(
        records: [...state.records.where((e) => e.id != r.id), r],
        schedules: schedules,
      ),
    );
  }

  Future<void> deleteRecord(String id) => commit(
    state.copy(records: state.records.where((e) => e.id != id).toList()),
  );
  Future<void> saveSchedule(MaintenanceSchedule s) async {
    if (!state.vehicles.any((v) => v.id == s.vehicleId)) {
      throw ArgumentError('Vehicle does not exist.');
    }
    if (s.title.trim().isEmpty ||
        (s.nextServiceDate == null && s.nextServiceOdometer == null)) {
      throw ArgumentError(
        'Set a title and at least one maintenance threshold.',
      );
    }
    if (s.nextServiceOdometer != null &&
        (!s.nextServiceOdometer!.isFinite || s.nextServiceOdometer! < 0)) {
      throw ArgumentError('Invalid mileage threshold.');
    }
    if (s.reminderDays.any((d) => d < 0 || d > 365)) {
      throw ArgumentError('Reminder days must be between 0 and 365.');
    }
    final old = state.schedules.where((e) => e.id == s.id).firstOrNull;
    if (old != null &&
        (old.vehicleId != s.vehicleId || old.isCompleted != s.isCompleted)) {
      throw ArgumentError('Complete a schedule by recording its service.');
    }
    await commit(
      state.copy(schedules: [...state.schedules.where((e) => e.id != s.id), s]),
    );
  }

  void refreshDateStatuses() {
    state = state.copy();
  }

  Future<void> deleteSchedule(String id) => commit(
    state.copy(schedules: state.schedules.where((e) => e.id != id).toList()),
  );
}
