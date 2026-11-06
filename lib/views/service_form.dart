import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities.dart';
import '../viewmodels/garage_view_model.dart';
import 'widgets/form_fields.dart';

const serviceTypes = [
  'Oil change',
  'Air filter replacement',
  'Tire replacement',
  'Brake maintenance',
  'Battery replacement',
  'General servicing',
];

class ServiceForm extends ConsumerStatefulWidget {
  final String? id, scheduleId;
  const ServiceForm({super.key, this.id, this.scheduleId});
  @override
  ConsumerState<ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends ConsumerState<ServiceForm> {
  final key = GlobalKey<FormState>();
  final title = TextEditingController(),
      odometer = TextEditingController(),
      cost = TextEditingController(),
      notes = TextEditingController();
  ServiceRecord? original;
  MaintenanceSchedule? schedule;
  String? vehicleId;
  DateTime? date = DateTime.now();
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final state = ref.read(garageProvider);
    original = state.records.where((r) => r.id == widget.id).firstOrNull;
    schedule = state.schedules
        .where((s) => s.id == widget.scheduleId)
        .firstOrNull;
    vehicleId =
        original?.vehicleId ?? schedule?.vehicleId ?? state.selected?.id;
    title.text = original?.serviceType ?? schedule?.title ?? serviceTypes.first;
    odometer.text =
        (original?.odometer ??
                state.vehicles
                    .where((v) => v.id == vehicleId)
                    .firstOrNull
                    ?.currentOdometer ??
                0)
            .toString();
    cost.text = (original?.cost ?? 0).toString();
    notes.text = original?.notes ?? '';
    date = original?.serviceDate ?? date;
  }

  @override
  void dispose() {
    for (final c in [title, odometer, cost, notes]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(garageProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          original == null ? 'Add service record' : 'Edit service record',
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
              onChanged: original != null || schedule != null
                  ? null
                  : (v) => setState(() {
                      vehicleId = v;
                      odometer.text = state.vehicles
                          .firstWhere((e) => e.id == v)
                          .currentOdometer
                          .toString();
                    }),
              validator: (v) => v == null ? 'Add a vehicle first' : null,
            ),
            const SizedBox(height: 16),
            Input(title, 'Service type / custom service'),
            Wrap(
              spacing: 6,
              children: serviceTypes
                  .map(
                    (s) => ActionChip(
                      label: Text(s),
                      onPressed: () => setState(() => title.text = s),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            DateField(
              value: date,
              onChanged: (d) => setState(() => date = d),
              label: 'Service date',
              lastDate: DateTime.now(),
            ),
            Input(
              odometer,
              'Odometer at service',
              numeric: true,
              validator: (s) {
                final n = double.tryParse(s ?? '');
                if (n == null || !n.isFinite || n < 0) {
                  return 'Enter a valid reading';
                }
                final v = state.vehicles
                    .where((v) => v.id == vehicleId)
                    .firstOrNull;
                if (v != null && n > v.currentOdometer) {
                  return 'Update vehicle odometer first';
                }
                return null;
              },
            ),
            Input(cost, 'Service cost (local currency)', numeric: true),
            Input(notes, 'Notes (optional)', requiredField: false, lines: 3),
            if (schedule != null)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Saving this record also completes the maintenance schedule.',
                ),
              ),
            FilledButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      if (!key.currentState!.validate()) return;
                      if (date == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Select a service date'),
                          ),
                        );
                        return;
                      }
                      setState(() => saving = true);
                      await runAction(
                        context,
                        () => ref
                            .read(garageProvider.notifier)
                            .saveRecord(
                              ServiceRecord(
                                id: original?.id ?? newId(),
                                vehicleId: vehicleId!,
                                serviceType: title.text.trim(),
                                serviceDate: date!,
                                odometer: double.parse(odometer.text),
                                cost: double.parse(cost.text),
                                notes: notes.text.trim(),
                                createdAt:
                                    original?.createdAt ?? DateTime.now(),
                              ),
                              completeScheduleId: schedule?.id,
                            ),
                        pop: true,
                      );
                      if (mounted) setState(() => saving = false);
                    },
              icon: const Icon(Icons.check),
              label: const Text('Save service'),
            ),
          ],
        ),
      ),
    );
  }
}
