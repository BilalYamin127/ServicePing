import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/garage_view_model.dart';
import 'dashboard.dart';
import 'widgets/form_fields.dart';

class SchedulesView extends ConsumerStatefulWidget {
  const SchedulesView({super.key});
  @override
  ConsumerState<SchedulesView> createState() => _SchedulesState();
}

class _SchedulesState extends ConsumerState<SchedulesView> {
  String filter = 'active';
  bool allVehicles = false;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(garageProvider);
    final schedules = state.schedules
        .where(
          (s) =>
              (allVehicles || s.vehicleId == state.selected?.id) &&
              (filter == 'all' ||
                  (filter == 'completed' ? s.isCompleted : !s.isCompleted)),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Maintenance schedule',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'active', label: Text('Active')),
            ButtonSegment(value: 'completed', label: Text('Completed')),
            ButtonSegment(value: 'all', label: Text('All')),
          ],
          selected: {filter},
          onSelectionChanged: (s) => setState(() => filter = s.first),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show all vehicles'),
          subtitle: Text(
            allVehicles
                ? 'Your whole garage'
                : state.selected?.name ?? 'No vehicle',
          ),
          value: allVehicles,
          onChanged: (v) => setState(() => allVehicles = v),
        ),
        if (schedules.isEmpty)
          const EmptyState(
            'No maintenance here',
            'Create a schedule with a date, mileage target, or both.',
          ),
        ...schedules.map(
          (s) => ScheduleCard(
            schedule: s,
            vehicle: state.vehicles.firstWhere((v) => v.id == s.vehicleId),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: state.vehicles.isEmpty
              ? null
              : () => context.push('/schedule/new'),
          icon: const Icon(Icons.add),
          label: const Text('Schedule maintenance'),
        ),
      ],
    );
  }
}
