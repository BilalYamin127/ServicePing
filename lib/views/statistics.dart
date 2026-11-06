import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../viewmodels/garage_view_model.dart';
import 'dashboard.dart';
import 'widgets/form_fields.dart';

class StatisticsView extends ConsumerStatefulWidget {
  const StatisticsView({super.key});
  @override
  ConsumerState<StatisticsView> createState() => _StatisticsState();
}

class _StatisticsState extends ConsumerState<StatisticsView> {
  bool allVehicles = false;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(garageProvider);
    final records =
        state.records
            .where((r) => allVehicles || r.vehicleId == state.selected?.id)
            .toList()
          ..sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
    final schedules = state.schedules
        .where(
          (s) =>
              !s.isCompleted &&
              (allVehicles || s.vehicleId == state.selected?.id),
        )
        .toList();
    final upcoming = schedules
        .where(
          (s) => !s.due(
            state.vehicles.firstWhere((v) => v.id == s.vehicleId),
            DateTime.now(),
          ),
        )
        .length;
    final total = records.fold<double>(0, (sum, r) => sum + r.cost);
    final now = DateTime.now();
    final months = List.generate(
      6,
      (i) => DateTime(now.year, now.month - 5 + i),
    );
    final costs = months
        .map(
          (m) => records
              .where(
                (r) =>
                    r.serviceDate.year == m.year &&
                    r.serviceDate.month == m.month,
              )
              .fold<double>(0, (sum, r) => sum + r.cost),
        )
        .toList();
    final maxCost = costs.fold<double>(0, max);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Garage insights',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('All vehicles'),
          subtitle: Text(
            allVehicles
                ? 'Combined maintenance expenses'
                : state.selected?.name ?? 'No vehicle selected',
          ),
          value: allVehicles,
          onChanged: (v) => setState(() => allVehicles = v),
        ),
        MetricCard(
          'Total maintenance expenses',
          number(total),
          Icons.account_balance_wallet_outlined,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                'Completed services',
                '${records.length}',
                Icons.task_alt,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                'Upcoming maintenance',
                '$upcoming',
                Icons.event_available,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        MetricCard(
          'Most recent service',
          records.isEmpty ? 'No records' : dateLabel(records.first.serviceDate),
          Icons.history,
        ),
        const SizedBox(height: 24),
        Text(
          'Monthly maintenance costs',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text('Last 6 months • local currency'),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(
                months.length,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: Text(DateFormat('MMM yy').format(months[i])),
                      ),
                      Expanded(
                        child: Semantics(
                          label:
                              '${DateFormat.yMMM().format(months[i])}: ${number(costs[i])}',
                          child: LinearProgressIndicator(
                            value: maxCost == 0 ? 0 : costs[i] / maxCost,
                            minHeight: 16,
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xfff58b3c),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 72,
                        child: Text(
                          number(costs[i]),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (records.isEmpty)
          const EmptyState(
            'Start building your story',
            'Your service records will bring these insights to life.',
          ),
      ],
    );
  }
}
