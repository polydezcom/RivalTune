import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/device.dart';

class MultiSensitivityEditor extends StatefulWidget {
  final List<int> sensitivities;
  final ValueChanged<List<int>> onChanged;
  final VoidCallback onApply;
  final Device? device;

  const MultiSensitivityEditor({
    super.key,
    required this.sensitivities,
    required this.onChanged,
    required this.onApply,
    this.device,
  });

  @override
  State<MultiSensitivityEditor> createState() => _MultiSensitivityEditorState();
}

class _MultiSensitivityEditorState extends State<MultiSensitivityEditor> {
  late List<int> _currentSensitivities;

  @override
  void initState() {
    super.initState();
    _currentSensitivities = List.from(widget.sensitivities);
  }

  @override
  void didUpdateWidget(MultiSensitivityEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sensitivities != widget.sensitivities) {
      _currentSensitivities = List.from(widget.sensitivities);
    }
  }

  int get _maxPresets => widget.device?.sensitivityConfig.maxPresets ?? 5;

  int get _minValue => widget.device?.sensitivityConfig.minValue ?? 200;

  int get _maxValue => widget.device?.sensitivityConfig.maxValue ?? 8500;

  List<int> get _allowedValues =>
      widget.device?.sensitivityConfig.allowedValues ?? [];

  bool get _hasRestrictedValues => _allowedValues.isNotEmpty;

  void _addSensitivity() {
    if (_currentSensitivities.length < _maxPresets) {
      setState(() {
        // Add the first allowed value or a default value
        final defaultValue = _hasRestrictedValues ? _allowedValues.first : 800;
        _currentSensitivities.add(defaultValue);
      });
      widget.onChanged(_currentSensitivities);
    }
  }

  void _removeSensitivity(int index) {
    if (_currentSensitivities.length > 1) {
      setState(() {
        _currentSensitivities.removeAt(index);
      });
      widget.onChanged(_currentSensitivities);
    }
  }

  void _updateSensitivity(int index, int value) {
    setState(() {
      _currentSensitivities[index] = value;
    });
    widget.onChanged(_currentSensitivities);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rangeText = _hasRestrictedValues
        ? 'Select from: ${_allowedValues.join(", ")} DPI'
        : 'Range: $_minValue-$_maxValue DPI';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DPI Sensitivity Presets',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rangeText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: widget.onApply,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Apply'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._currentSensitivities.asMap().entries.map((entry) {
              final index = entry.key;
              final value = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _hasRestrictedValues
                          ? _buildDropdownSelector(theme, index, value)
                          : _buildSliderSelector(theme, index, value),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Remove',
                      iconSize: 20,
                      onPressed: _currentSensitivities.length > 1
                          ? () => _removeSensitivity(index)
                          : null,
                    ),
                  ],
                ),
              );
            }),
            if (_currentSensitivities.length < _maxPresets) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: _addSensitivity,
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'Add DPI Preset (${_currentSensitivities.length}/$_maxPresets)',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownSelector(ThemeData theme, int index, int value) {
    return Row(
      children: [
        Text(
          '$value DPI',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButton<int>(
            value:
                _allowedValues.contains(value) ? value : _allowedValues.first,
            isExpanded: true,
            items: _allowedValues.map((dpi) {
              return DropdownMenuItem<int>(
                value: dpi,
                child: Text('$dpi DPI'),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                _updateSensitivity(index, newValue);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSliderSelector(ThemeData theme, int index, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$value DPI',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                value: value
                    .toDouble()
                    .clamp(_minValue.toDouble(), _maxValue.toDouble()),
                min: _minValue.toDouble(),
                max: _maxValue.toDouble(),
                divisions: ((_maxValue - _minValue) / 100).round(),
                label: value.toString(),
                onChanged: (newValue) {
                  _updateSensitivity(index, newValue.toInt());
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: TextField(
                controller: TextEditingController(text: value.toString())
                  ..selection = TextSelection.collapsed(
                    offset: value.toString().length,
                  ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(),
                  suffixText: 'DPI',
                  suffixStyle: TextStyle(fontSize: 11),
                ),
                onSubmitted: (text) {
                  final newValue = int.tryParse(text);
                  if (newValue != null) {
                    final clampedValue = newValue.clamp(_minValue, _maxValue);
                    _updateSensitivity(index, clampedValue);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
