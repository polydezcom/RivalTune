import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerDialog extends StatelessWidget {
  final int zone;
  final Color currentColor;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onApply;

  const ColorPickerDialog({
    super.key,
    required this.zone,
    required this.currentColor,
    required this.onColorChanged,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Pick Zone $zone Color'),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: currentColor,
          onColorChanged: onColorChanged,
          enableAlpha: false,
          hexInputBar: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            onApply();
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
} 