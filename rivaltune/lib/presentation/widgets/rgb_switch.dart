import 'package:flutter/material.dart';

class RgbSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const RgbSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RGB Lighting',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
