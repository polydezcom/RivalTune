import 'package:flutter/material.dart';
import '../../core/constants/light_effects.dart';

class EffectSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  final VoidCallback onApply;

  const EffectSelector({
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
              'Light Effect',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                child: DropdownButton<String>(
                  value: value,
                  isDense: true,
                  isExpanded: true,
                  padding: EdgeInsets.zero,
                  underline: const SizedBox(),
                  alignment: AlignmentDirectional.centerStart,
                  style: theme.textTheme.bodyLarge,
                  items: kLightEffects.map((String effect) {
                    return DropdownMenuItem<String>(
                      value: effect,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        effect.replaceAll('-', ' ').toUpperCase(),
                      ),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
            const SizedBox(width: 16),
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