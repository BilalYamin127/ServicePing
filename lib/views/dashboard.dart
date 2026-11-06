import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/entities.dart';
import '../viewmodels/garage_view_model.dart';
import 'widgets/form_fields.dart';

class Dashboard extends ConsumerWidget {
  const Dashboard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(garageProvider);
    final v = state.selected;
    if (v == null) {
      return EmptyState(
        'Your garage starts here',
        'Add a vehicle to track every mile and every service.',
        action: FilledButton.icon(
          onPressed: () => context.push('/vehicle/new'),
          icon: const Icon(Icons.add),
          label: const Text('Add your first vehicle'),
        ),
      );
    }
    final records = state.records.where((r) => r.vehicleId == v.id).toList()
      ..sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
    final schedules =
        state.schedules
            .where((s) => s.vehicleId == v.id && !s.isCompleted)
            .toList()
          ..sort((a, b) {
            final ad = a.due(v, DateTime.now()), bd = b.due(v, DateTime.now());
            return ad == bd
                ? (a.nextServiceDate ?? DateTime(9999)).compareTo(
                    b.nextServiceDate ?? DateTime(9999),
                  )
                : ad
                ? -1
                : 1;
          });
    final due = schedules.where((s) => s.due(v, DateTime.now())).length;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'KEEP EVERY JOURNEY READY',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your garage, at a glance.',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: v.id,
          key: ValueKey(v.id),
          decoration: const InputDecoration(
            labelText: 'Selected vehicle',
            prefixIcon: Icon(Icons.garage_outlined),
          ),
          items: state.vehicles
              .map((e) => DropdownMenuItem(value: e.id, child: Text(e.name)))
              .toList(),
          onChanged: (id) => ref.read(garageProvider.notifier).select(id!),
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Container(
            key: ValueKey('${v.id}-${v.currentOdometer}'),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff102b55), Color(0xff204c81)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        v.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(
                      v.type == VehicleType.car
                          ? Icons.directions_car_filled
                          : Icons.two_wheeler,
                      color: const Color(0xffffa24b),
                      size: 48,
                    ),
                  ],
                ),
                Text(
                  '${v.manufacturer} ${v.model} • ${v.year ?? '—'}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 28),
                const Text(
                  'CURRENT ODOMETER',
                  style: TextStyle(
                    color: Colors.white70,
                    letterSpacing: 1.5,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '${number(v.currentOdometer)} ${v.distanceUnit.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xffff9446),
                    foregroundColor: const Color(0xff102b55),
                  ),
                  onPressed: () => updateReading(context, ref, v),
                  icon: const Icon(Icons.edit_road),
                  label: const Text('Update odometer'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                'Last service',
                records.isEmpty
                    ? 'No records'
                    : dateLabel(records.first.serviceDate),
                Icons.build_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                'Needs attention',
                '$due due',
                Icons.warning_amber_rounded,
                accent: due > 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => context.push('/service/new'),
          icon: const Icon(Icons.add),
          label: const Text('Add service record'),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Upcoming maintenance',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/schedules'),
              child: const Text('View all'),
            ),
          ],
        ),
        if (schedules.isEmpty)
          const EmptyState(
            'All clear',
            'Set a date or mileage target for your next service.',
          )
        else
          ...schedules
              .take(4)
              .map((s) => ScheduleCard(schedule: s, vehicle: v)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => context.push('/schedule/new'),
          icon: const Icon(Icons.event_available),
          label: const Text('Schedule maintenance'),
        ),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool accent;
  const MetricCard(
    this.label,
    this.value,
    this.icon, {
    super.key,
    this.accent = false,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: accent
                ? Colors.deepOrange
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class ScheduleCard extends ConsumerWidget {
  final MaintenanceSchedule schedule;
  final Vehicle vehicle;
  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.vehicle,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = schedule;
    final due = s.due(vehicle, DateTime.now());
    final remaining = s.remaining(vehicle);
    final target = s.nextServiceOdometer;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  s.isCompleted
                      ? Icons.check_circle_outline
                      : Icons.build_circle_outlined,
                  color: due
                      ? Colors.deepOrange
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(
                    s.isCompleted
                        ? 'Completed'
                        : s.overdue(vehicle, DateTime.now())
                        ? 'Overdue'
                        : due
                        ? 'Due'
                        : 'Upcoming',
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (a) async {
                    if (a == 'edit') {
                      context.push('/schedule/${s.id}/edit');
                    } else if (await confirmDelete(
                      context,
                      'Delete this schedule? Service history is preserved.',
                    )) {
                      if (context.mounted) {
                        await runAction(
                          context,
                          () => ref
                              .read(garageProvider.notifier)
                              .deleteSchedule(s.id),
                        );
                      }
                    }
                  },
                  itemBuilder: (c) => [
                    if (!s.isCompleted)
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            Text(vehicle.name, style: Theme.of(context).textTheme.bodySmall),
            if (s.nextServiceDate != null)
              Text('Service date: ${dateLabel(s.nextServiceDate)}'),
            if (remaining != null) ...[
              const SizedBox(height: 8),
              Text(
                '${number(remaining)} ${vehicle.distanceUnit.name} remaining • target ${number(target!)}',
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: target <= 0
                    ? 1
                    : (vehicle.currentOdometer / target).clamp(0.0, 1.0),
                color: due ? Colors.deepOrange : null,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
            if (!s.isCompleted)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      context.push('/service/new?complete=${s.id}'),
                  icon: const Icon(Icons.check),
                  label: const Text('Record completed service'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> updateReading(
  BuildContext context,
  WidgetRef ref,
  Vehicle v,
) async {
  var value = v.currentOdometer.toString();
  final key = GlobalKey<FormState>();
  final reading = await showDialog<double>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Update odometer'),
      content: Form(
        key: key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current: ${number(v.currentOdometer)} ${v.distanceUnit.name}\nEnter the reading from your vehicle.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: value,
              onChanged: (text) => value = text,
              decoration: const InputDecoration(labelText: 'New reading'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (s) {
                final n = double.tryParse(s ?? '');
                return n == null || !n.isFinite || n < v.currentOdometer
                    ? 'Enter a reading of at least ${number(v.currentOdometer)}'
                    : null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (key.currentState!.validate()) {
              Navigator.pop(c, double.parse(value));
            }
          },
          child: const Text('Update'),
        ),
      ],
    ),
  );
  if (reading != null && context.mounted) {
    await runAction(
      context,
      () => ref.read(garageProvider.notifier).updateOdometer(v, reading),
    );
  }
}
