import 'package:flutter/material.dart';

class PresetNameDialog extends StatelessWidget {
  final TextEditingController controller;

  const PresetNameDialog({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save Preset'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Preset Name',
          hintText: 'Enter a name for your preset',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
} 