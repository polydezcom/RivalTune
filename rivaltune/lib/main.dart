import 'package:flutter/material.dart';
import 'package:process_run/shell.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SteelSeries Configurator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Shell _shell = Shell();
  
  // Device state (what's actually applied)
  int _currentSensitivity = 800;
  Color _currentTopColor = Colors.red;
  Color _currentMiddleColor = Colors.lime;
  Color _currentBottomColor = Colors.blue;
  Color _currentLogoColor = Colors.purple;
  
  // UI state (what's shown but not yet applied)
  int _pendingSensitivity = 800;
  Color _pendingTopColor = Colors.red;
  Color _pendingMiddleColor = Colors.lime;
  Color _pendingBottomColor = Colors.blue;
  Color _pendingLogoColor = Colors.purple;

  Future<void> _applyZoneColor(int zone, Color color) async {
    final String hexColor = color.value.toRadixString(16).substring(2).padLeft(6, '0');
    String command;
    switch (zone) {
      case 1:
        command = 'rivalcfg --strip-top-color $hexColor';
        _currentTopColor = color;
        break;
      case 2:
        command = 'rivalcfg --strip-middle-color $hexColor';
        _currentMiddleColor = color;
        break;
      case 3:
        command = 'rivalcfg --strip-bottom-color $hexColor';
        _currentBottomColor = color;
        break;
      case 4:
        command = 'rivalcfg --logo-color $hexColor';
        _currentLogoColor = color;
        break;
      default:
        return;
    }
    try {
      await _shell.run(command);
    } catch (e) {
      print('Error executing command: $e');
    }
  }

  void _showColorPicker(int zone, Color currentColor) {
    Color pendingColor = currentColor;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pick Zone $zone Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pendingColor,
            onColorChanged: (color) {
              setState(() {
                pendingColor = color;
                switch (zone) {
                  case 1:
                    _pendingTopColor = color;
                    break;
                  case 2:
                    _pendingMiddleColor = color;
                    break;
                  case 3:
                    _pendingBottomColor = color;
                    break;
                  case 4:
                    _pendingLogoColor = color;
                    break;
                }
              });
            },
            enableAlpha: false,
            hexInputBar: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _applyZoneColor(zone, pendingColor);
              Navigator.of(context).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _applySensitivity() async {
    final command = 'rivalcfg -s $_pendingSensitivity';
    try {
      await _shell.run(command);
      setState(() {
        _currentSensitivity = _pendingSensitivity;
      });
    } catch (e) {
      print('Error executing command: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SteelSeries Configurator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('LED Zones', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildColorZone(1, 'Top Strip', _pendingTopColor),
            _buildColorZone(2, 'Middle Strip', _pendingMiddleColor),
            _buildColorZone(3, 'Bottom Strip', _pendingBottomColor),
            _buildColorZone(4, 'Logo', _pendingLogoColor),
            const SizedBox(height: 20),
            Text('Sensitivity: $_pendingSensitivity DPI'),
            Slider(
              value: _pendingSensitivity.toDouble(),
              min: 200,
              max: 8500,
              divisions: 83,
              label: _pendingSensitivity.toString(),
              onChanged: (value) {
                setState(() {
                  _pendingSensitivity = value.toInt();
                });
              },
            ),
            ElevatedButton(
              onPressed: _applySensitivity,
              child: const Text('Apply Sensitivity'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorZone(int zone, String label, Color color) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: GestureDetector(
          onTap: () => _showColorPicker(zone, color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}
