import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities.dart';
import '../viewmodels/garage_view_model.dart';
import 'widgets/form_fields.dart';

class VehicleForm extends ConsumerStatefulWidget {
  final String? id;
  const VehicleForm({super.key, this.id});
  @override
  ConsumerState<VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends ConsumerState<VehicleForm> {
  final key = GlobalKey<FormState>();
  final name = TextEditingController(),
      manufacturer = TextEditingController(),
      model = TextEditingController(),
      year = TextEditingController(),
      registration = TextEditingController(),
      odometer = TextEditingController();
  Vehicle? original;
  VehicleType type = VehicleType.car;
  DistanceUnit unit = DistanceUnit.km;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    original = ref
        .read(garageProvider)
        .vehicles
        .where((v) => v.id == widget.id)
        .firstOrNull;
    final v = original;
    if (v != null) {
      name.text = v.name;
      manufacturer.text = v.manufacturer;
      model.text = v.model;
      year.text = v.year?.toString() ?? '';
      registration.text = v.registrationNumber ?? '';
      odometer.text = v.currentOdometer.toString();
      type = v.type;
      unit = v.distanceUnit;
    }
  }

  @override
  void dispose() {
    for (final c in [name, manufacturer, model, year, registration, odometer]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(original == null ? 'Add vehicle' : 'Edit vehicle'),
    ),
    body: Form(
      key: key,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Input(name, 'Vehicle name'),
          Input(manufacturer, 'Manufacturer'),
          Input(model, 'Model'),
          Input(
            year,
            'Manufacturing year (optional)',
            requiredField: false,
            numeric: true,
            validator: (s) {
              if (s == null || s.isEmpty) return null;
              final y = int.tryParse(s);
              return y == null || y < 1886 || y > DateTime.now().year + 1
                  ? 'Enter a valid year'
                  : null;
            },
          ),
          DropdownButtonFormField<VehicleType>(
            initialValue: type,
            decoration: const InputDecoration(labelText: 'Vehicle type'),
            items: VehicleType.values
                .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                .toList(),
            onChanged: (v) => setState(() => type = v!),
          ),
          const SizedBox(height: 16),
          Input(
            registration,
            'Registration number (optional)',
            requiredField: false,
          ),
          Input(
            odometer,
            'Current odometer',
            numeric: true,
            validator: (s) {
              final n = double.tryParse(s ?? '');
              return n == null || !n.isFinite || n < 0
                  ? 'Enter a valid reading'
                  : original != null && n < original!.currentOdometer
                  ? 'Odometer cannot decrease'
                  : null;
            },
          ),
          DropdownButtonFormField<DistanceUnit>(
            initialValue: unit,
            decoration: const InputDecoration(
              labelText: 'Distance unit (fixed after creation)',
            ),
            items: DistanceUnit.values
                .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                .toList(),
            onChanged: original != null
                ? null
                : (v) => setState(() => unit = v!),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: saving
                ? null
                : () async {
                    if (!key.currentState!.validate()) return;
                    setState(() => saving = true);
                    await runAction(
                      context,
                      () => ref
                          .read(garageProvider.notifier)
                          .saveVehicle(
                            Vehicle(
                              id: original?.id ?? newId(),
                              name: name.text.trim(),
                              manufacturer: manufacturer.text.trim(),
                              model: model.text.trim(),
                              year: int.tryParse(year.text),
                              type: type,
                              registrationNumber: registration.text.trim(),
                              currentOdometer: double.parse(odometer.text),
                              distanceUnit: unit,
                              createdAt: original?.createdAt ?? DateTime.now(),
                            ),
                          ),
                      pop: true,
                    );
                    if (mounted) setState(() => saving = false);
                  },
            icon: const Icon(Icons.check),
            label: const Text('Save vehicle'),
          ),
        ],
      ),
    ),
  );
}
