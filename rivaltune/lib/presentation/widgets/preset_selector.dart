import 'package:flutter/material.dart';
import '../../data/models/color_preset.dart';

class PresetSelector extends StatelessWidget {
  final List<ColorPreset> builtInPresets;
  final List<ColorPreset> customPresets;
  final ValueChanged<ColorPreset?> onPresetSelected;
  final VoidCallback onSavePressed;
  final ValueChanged<ColorPreset> onDeletePreset;

  const PresetSelector({
    super.key,
    required this.builtInPresets,
    required this.customPresets,
    required this.onPresetSelected,
    required this.onSavePressed,
    required this.onDeletePreset,
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
              'Color Presets',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<ColorPreset>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.5)),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  isDense: true,
                  constraints: const BoxConstraints(maxHeight: 36),
                ),
                hint: const Text('Select a preset'),
                items: [
                  ...builtInPresets.map((preset) => DropdownMenuItem(
                        value: preset,
                        child: Text('📦 ${preset.name}'),
                      )),
                  if (customPresets.isNotEmpty)
                    const DropdownMenuItem(
                      enabled: false,
                      child: Divider(),
                    ),
                  ...customPresets.map((preset) => DropdownMenuItem(
                        value: preset,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('💾 ${preset.name}'),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => onDeletePreset(preset),
                            ),
                          ],
                        ),
                      )),
                ],
                onChanged: onPresetSelected,
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: onSavePressed,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
