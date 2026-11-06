import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The same editable source generates the store's policy documents and webpage.
/// This screen loads locally, so reading the policy never requires a network.
class PrivacyView extends StatefulWidget {
  const PrivacyView({super.key});
  @override
  State<PrivacyView> createState() => _PrivacyViewState();
}

class _PrivacyViewState extends State<PrivacyView> {
  late final Future<Map<String, dynamic>> policy = rootBundle
      .loadString('store/source/policy.json')
      .then((value) => jsonDecode(value) as Map<String, dynamic>);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Privacy policy')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: policy,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load the local policy.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final sections = data['sections'] as List;
        return SelectionArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'ServicePing Privacy Policy',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Effective ${data['effective_date']} • Version ${data['version']}',
              ),
              if (data['contact_is_placeholder'] == true) ...[
                const SizedBox(height: 16),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Draft contact address: replace the temporary email before publication.',
                    ),
                  ),
                ),
              ],
              for (var i = 0; i < sections.length; i++) ...[
                const SizedBox(height: 24),
                Text(
                  '${i + 1}. ${sections[i]['title']}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (sections[i]['body'] as String)
                      .replaceAll('{operator}', data['operator'] as String)
                      .replaceAll(
                        '{contact_email}',
                        data['contact_email'] as String,
                      ),
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}
