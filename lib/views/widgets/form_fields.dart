import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String dateLabel(DateTime? d) =>
    d == null ? 'Not set' : DateFormat.yMMMd().format(d);
String number(num n) => NumberFormat('#,##0.##').format(n);

class DateField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String label;
  final DateTime? lastDate;
  const DateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Date',
    this.lastDate,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Row(
        children: [
          Expanded(child: Text(dateLabel(value))),
          IconButton(
            tooltip: 'Choose date',
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: lastDate ?? DateTime(2200),
              );
              if (d != null) onChanged(d);
            },
          ),
          if (value != null)
            IconButton(
              tooltip: 'Clear date',
              onPressed: () => onChanged(null),
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    ),
  );
}

class Input extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool requiredField, numeric;
  final int lines;
  final String? Function(String?)? validator;
  const Input(
    this.controller,
    this.label, {
    super.key,
    this.requiredField = true,
    this.numeric = false,
    this.lines = 1,
    this.validator,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      maxLines: lines,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      validator:
          validator ??
          (v) {
            if (requiredField && (v == null || v.trim().isEmpty)) {
              return 'Required';
            }
            if (numeric && v != null && v.isNotEmpty) {
              final n = double.tryParse(v);
              if (n == null || !n.isFinite || n < 0) {
                return 'Enter a valid non-negative number';
              }
            }
            return null;
          },
    ),
  );
}

Future<bool> confirmDelete(BuildContext context, String message) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
    false;
Future<void> runAction(
  BuildContext context,
  Future<void> Function() action, {
  bool pop = false,
}) async {
  try {
    await action();
    if (context.mounted) {
      if (pop) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved successfully')));
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class EmptyState extends StatelessWidget {
  final String title, message;
  final Widget? action;
  const EmptyState(this.title, this.message, {super.key, this.action});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
    child: Column(
      children: [
        Icon(
          Icons.garage_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        if (action != null)
          Padding(padding: const EdgeInsets.only(top: 20), child: action),
      ],
    ),
  );
}
