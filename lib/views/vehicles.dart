import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/entities.dart';
import '../viewmodels/garage_view_model.dart';
import 'dashboard.dart';
import 'widgets/form_fields.dart';

class VehiclesView extends ConsumerWidget {
  const VehiclesView({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(garageProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'My vehicles',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            FilledButton.icon(
              onPressed: () => context.push('/vehicle/new'),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (state.vehicles.isEmpty)
          const EmptyState(
            'Room for your whole garage',
            'Add motorcycles and cars. Track each vehicle independently.',
          ),
        ...state.vehicles.map(
          (v) => Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(20),
              leading: CircleAvatar(
                radius: 28,
                child: Icon(
                  v.type == VehicleType.car
                      ? Icons.directions_car
                      : Icons.two_wheeler,
                  size: 30,
                ),
              ),
              title: Text(
                v.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${v.manufacturer} ${v.model}\n${number(v.currentOdometer)} ${v.distanceUnit.name}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/vehicle/${v.id}'),
            ),
          ),
        ),
      ],
    );
  }
}

class VehicleDetails extends ConsumerWidget {
  final String id;
  const VehicleDetails({super.key, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(garageProvider);
    final v = state.vehicles.where((v) => v.id == id).firstOrNull;
    if (v == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          'Vehicle not found',
          'This vehicle may have been deleted.',
        ),
      );
    }
    final entries = state.entries.where((e) => e.vehicleId == id).toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return Scaffold(
      appBar: AppBar(
        title: Text(v.name),
        actions: [
          IconButton(
            tooltip: 'Edit vehicle',
            onPressed: () => context.push('/vehicle/$id/edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete vehicle',
            onPressed: () async {
              if (await confirmDelete(
                context,
                'Delete ${v.name} and all its service records, schedules, and odometer history?',
              )) {
                if (context.mounted) {
                  await runAction(
                    context,
                    () => ref.read(garageProvider.notifier).deleteVehicle(id),
                    pop: true,
                  );
                }
              }
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            v.type == VehicleType.car
                ? Icons.directions_car
                : Icons.two_wheeler,
            size: 100,
            color: Theme.of(context).colorScheme.primary,
          ),
          Text(
            '${v.manufacturer} ${v.model}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            '${v.year ?? 'Year not set'} • ${v.registrationNumber?.isNotEmpty == true ? v.registrationNumber : 'Registration not set'}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          MetricCard(
            'Current odometer',
            '${number(v.currentOdometer)} ${v.distanceUnit.name}',
            Icons.speed,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => updateReading(context, ref, v),
            icon: const Icon(Icons.edit_road),
            label: const Text('Update odometer'),
          ),
          OutlinedButton(
            onPressed: () {
              ref.read(garageProvider.notifier).select(v.id);
              context.go('/history');
            },
            child: const Text('View service history'),
          ),
          const SizedBox(height: 24),
          Text(
            'Odometer history',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          ...entries.map(
            (e) => ListTile(
              leading: const Icon(Icons.timeline),
              title: Text('${number(e.reading)} ${v.distanceUnit.name}'),
              subtitle: Text(dateLabel(e.recordedAt)),
            ),
          ),
        ],
      ),
    );
  }
}
