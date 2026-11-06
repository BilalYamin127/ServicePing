import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities.dart';
import '../viewmodels/garage_view_model.dart';
import 'widgets/form_fields.dart';

class ScheduleForm extends ConsumerStatefulWidget {
  final String? id;
  const ScheduleForm({super.key, this.id});
  @override
  ConsumerState<ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends ConsumerState<ScheduleForm> {
  final key = GlobalKey<FormState>();
  final title = TextEditingController(),
      odometer = TextEditingController(),
      reminders = TextEditingController();
  String? vehicleId;
  DateTime? date;
  MaintenanceSchedule? original;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final state = ref.read(garageProvider);
    original = state.schedules.where((s) => s.id == widget.id).firstOrNull;
    vehicleId = original?.vehicleId ?? state.selected?.id;
    title.text = original?.title ?? '';
    odometer.text = original?.nextServiceOdometer?.toString() ?? '';
    date = original?.nextServiceDate;
    reminders.text = original?.reminderDays.join(', ') ?? '7, 1';
  }

  @override
  void dispose() {
    title.dispose();
    odometer.dispose();
    reminders.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(garageProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          original == null ? 'Schedule maintenance' : 'Edit schedule',
        ),
      ),
      body: Form(
        key: key,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            DropdownButtonFormField<String>(
              initialValue: vehicleId,
              decoration: const InputDecoration(labelText: 'Vehicle'),
              items: state.vehicles
                  .map(
                    (v) => DropdownMenuItem(value: v.id, child: Text(v.name)),
                  )
                  .toList(),
              onChanged: original != null
                  ? null
                  : (v) => setState(() => vehicleId = v),
              validator: (v) => v == null ? 'Add a vehicle first' : null,
            ),
            const SizedBox(height: 16),
            Input(title, 'Maintenance title'),
            DateField(
              value: date,
              onChanged: (d) => setState(() => date = d),
              label: 'Next service date (optional)',
            ),
            Input(
              odometer,
              'Next service odometer (optional)',
              requiredField: false,
              numeric: true,
            ),
            Input(
              reminders,
              'Reminder days before date (e.g. 7, 1)',
              requiredField: false,
              validator: (s) {
                if (s == null || s.trim().isEmpty) return null;
                final values = s.split(',').map((e) => int.tryParse(e.trim()));
                return values.any((n) => n == null || n < 0 || n > 365)
                    ? 'Use comma-separated days from 0 to 365'
                    : null;
              },
            ),
            const Text(
              'A service becomes due when either its date or mileage is reached. Mileage is checked only when you enter a reading. No automatic recurrence.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      if (!key.currentState!.validate()) return;
                      if (date == null && odometer.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Set a date or odometer threshold'),
                          ),
                        );
                        return;
                      }
                      setState(() => saving = true);
                      await runAction(
                        context,
                        () => ref
                            .read(garageProvider.notifier)
                            .saveSchedule(
                              MaintenanceSchedule(
                                id: original?.id ?? newId(),
                                vehicleId: vehicleId!,
                                title: title.text.trim(),
                                nextServiceDate: date,
                                nextServiceOdometer: double.tryParse(
                                  odometer.text,
                                ),
                                reminderDays: reminders.text.trim().isEmpty
                                    ? []
                                    : reminders.text
                                          .split(',')
                                          .map((e) => int.parse(e.trim()))
                                          .toSet()
                                          .toList(),
                                isCompleted: original?.isCompleted ?? false,
                              ),
                            ),
                        pop: true,
                      );
                      if (mounted) setState(() => saving = false);
                    },
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Save schedule'),
            ),
          ],
        ),
      ),
    );
  }
}
