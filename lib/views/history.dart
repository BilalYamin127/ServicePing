import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/garage_view_model.dart';
import 'widgets/form_fields.dart';

class HistoryView extends ConsumerStatefulWidget {
  const HistoryView({super.key});
  @override
  ConsumerState<HistoryView> createState() => _HistoryState();
}

class _HistoryState extends ConsumerState<HistoryView> {
  String vehicle = 'all', type = 'all', search = '';
  bool initialized = false;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(garageProvider);
    if (!initialized) {
      vehicle = state.selected?.id ?? 'all';
      initialized = true;
    }
    if (vehicle != 'all' && !state.vehicles.any((v) => v.id == vehicle)) {
      vehicle = 'all';
    }
    final types = state.records.map((r) => r.serviceType).toSet().toList()
      ..sort();
    if (type != 'all' && !types.contains(type)) type = 'all';
    final records =
        state.records
            .where(
              (r) =>
                  (vehicle == 'all' || r.vehicleId == vehicle) &&
                  (type == 'all' || r.serviceType == type) &&
                  ('${r.serviceType} ${r.notes ?? ''}'.toLowerCase().contains(
                    search.toLowerCase(),
                  )),
            )
            .toList()
          ..sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
    final total = records.fold<double>(0, (sum, r) => sum + r.cost);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Service history',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search services and notes',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => search = v),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: ValueKey('v$vehicle'),
          initialValue: vehicle,
          decoration: const InputDecoration(labelText: 'Vehicle'),
          items: [
            const DropdownMenuItem(value: 'all', child: Text('All vehicles')),
            ...state.vehicles.map(
              (v) => DropdownMenuItem(value: v.id, child: Text(v.name)),
            ),
          ],
          onChanged: (v) => setState(() => vehicle = v!),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: ValueKey('t$type'),
          initialValue: type,
          decoration: const InputDecoration(labelText: 'Service type'),
          items: [
            const DropdownMenuItem(
              value: 'all',
              child: Text('All service types'),
            ),
            ...types.map((t) => DropdownMenuItem(value: t, child: Text(t))),
          ],
          onChanged: (v) => setState(() => type = v!),
        ),
        const SizedBox(height: 20),
        Text(
          '${records.length} services • Total cost ${number(total)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Text('Amounts use your local currency.'),
        const SizedBox(height: 12),
        if (records.isEmpty)
          const EmptyState(
            'No matching services',
            'Add a service record or adjust your filters.',
          ),
        ...records.map((r) {
          final v = state.vehicles.firstWhere((v) => v.id == r.vehicleId);
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.serviceType,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        number(r.cost),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (a) async {
                          if (a == 'edit') {
                            context.push('/service/${r.id}/edit');
                          } else if (await confirmDelete(
                            context,
                            'Delete this service record?',
                          )) {
                            if (context.mounted) {
                              await runAction(
                                context,
                                () => ref
                                    .read(garageProvider.notifier)
                                    .deleteRecord(r.id),
                              );
                            }
                          }
                        },
                        itemBuilder: (c) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                  Text('${v.name} • ${dateLabel(r.serviceDate)}'),
                  Text('${number(r.odometer)} ${v.distanceUnit.name}'),
                  if (r.notes?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(r.notes!),
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: state.vehicles.isEmpty
              ? null
              : () => context.push('/service/new'),
          icon: const Icon(Icons.add),
          label: const Text('Add service record'),
        ),
      ],
    );
  }
}
