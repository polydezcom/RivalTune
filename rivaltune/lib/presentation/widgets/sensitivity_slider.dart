import 'package:flutter/material.dart';

class SensitivitySlider extends StatelessWidget {
  final int value;
  final ValueChanged<double> onChanged;
  final VoidCallback onApply;

  const SensitivitySlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Text(
              'Mouse Sensitivity',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(width: 8),
            Text(
              '$value DPI',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: 200,
                max: 8500,
                divisions: 83,
                label: value.toString(),
                onChanged: onChanged,
              ),
            ),
            FilledButton(
              onPressed: onApply,
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
