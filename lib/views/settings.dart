import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/garage_view_model.dart';
import 'widgets/form_fields.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(garageProvider);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Make it yours',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          initialValue: state.theme,
          decoration: const InputDecoration(
            labelText: 'Appearance',
            prefixIcon: Icon(Icons.palette_outlined),
          ),
          items: const [
            DropdownMenuItem(value: 'system', child: Text('System')),
            DropdownMenuItem(value: 'light', child: Text('Light')),
            DropdownMenuItem(value: 'dark', child: Text('Dark')),
          ],
          onChanged: (v) => runAction(
            context,
            () => ref.read(garageProvider.notifier).setTheme(v!),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service reminders',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enable notifications to receive reminders at 9:00 AM on the due date and the days you choose. The nearest 64 reminders are queued; reopening the app refills the queue. Delivery depends on device notification settings. Mileage reminders appear in the app after manual updates.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    final n = ref.read(notificationsProvider);
                    try {
                      final granted = await n.requestPermission();
                      await n.sync(state.schedules, state.vehicles);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              granted
                                  ? 'Notifications enabled'
                                  : 'Enable notification access in device settings. Mobile notifications require Android or iOS.',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not enable reminders: $e'),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.notifications_outlined),
                  label: const Text('Enable notifications'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy policy'),
            subtitle: const Text('Read how your local records are handled.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/privacy'),
          ),
        ),
        const SizedBox(height: 16),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline by design',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'No account. No cloud. Your garage is stored on this device. Removing the app or clearing its data removes your records. Device backups are disabled on Android.',
                ),
                SizedBox(height: 16),
                Text('ServicePing • Version 1.0.0'),
                Text('Vehicle Maintenance Tracker'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
