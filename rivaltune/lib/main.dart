import 'package:flutter/material.dart';
import 'package:process_run/shell.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:window_size/window_size.dart';
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    setWindowMinSize(const Size(300, 400));
    setWindowFrame(const Rect.fromLTWH(0, 0, 650, 750));
    setWindowTitle('SteelSeries Configurator');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
  
  // Available light effects
  final List<String> _lightEffects = [
    'steady',
    'rainbow-shift',
    'breath-fast',
    'breath',
    'breath-slow',
    'rainbow-breath',
    'disco',
  ];
  
  // Device state
  int _currentSensitivity = 800;
  Color _currentTopColor = Colors.red;
  Color _currentMiddleColor = Colors.lime;
  Color _currentBottomColor = Colors.blue;
  Color _currentLogoColor = Colors.purple;
  String _currentEffect = 'steady';
  
  // UI state
  int _pendingSensitivity = 800;
  Color _pendingTopColor = Colors.red;
  Color _pendingMiddleColor = Colors.lime;
  Color _pendingBottomColor = Colors.blue;
  Color _pendingLogoColor = Colors.purple;
  String _pendingEffect = 'steady';

  // Add this with the other state variables
  bool _isRgbEnabled = true;

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

  Future<void> _applyEffect() async {
    final command = 'rivalcfg -e $_pendingEffect';
    try {
      await _shell.run(command);
      setState(() {
        _currentEffect = _pendingEffect;
      });
    } catch (e) {
      print('Error executing command: $e');
    }
  }

  Future<void> _toggleRgb(bool enabled) async {
    try {
      if (enabled) {
        // Turn on - restore all saved colors in a single command
        final command = 'rivalcfg '
            '--strip-top-color ${_colorToHex(_pendingTopColor)} '
            '--strip-middle-color ${_colorToHex(_pendingMiddleColor)} '
            '--strip-bottom-color ${_colorToHex(_pendingBottomColor)} '
            '--logo-color ${_colorToHex(_pendingLogoColor)} '
            '-e $_pendingEffect';
        await _shell.run(command);
      } else {
        // Turn off - set all zones to black in a single command
        const command = 'rivalcfg '
            '--strip-top-color 000000 '
            '--strip-middle-color 000000 '
            '--strip-bottom-color 000000 '
            '--logo-color 000000';
        await _shell.run(command);
      }
      setState(() {
        _isRgbEnabled = enabled;
      });
    } catch (e) {
      print('Error executing command: $e');
    }
  }

  String _colorToHex(Color color) {
    return color.value.toRadixString(16).substring(2).padLeft(6, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SteelSeries Configurator'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'RGB Lighting',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Switch(
                        value: _isRgbEnabled,
                        onChanged: _toggleRgb,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Wrap the LED zones and effects in an Opacity widget
              Opacity(
                opacity: _isRgbEnabled ? 1.0 : 0.5,
                child: IgnorePointer(
                  ignoring: !_isRgbEnabled,
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
                      
                      // Light Effect Dropdown
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Light Effect', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButton<String>(
                                      value: _pendingEffect,
                                      isExpanded: true,
                                      items: _lightEffects.map((String effect) {
                                        return DropdownMenuItem<String>(
                                          value: effect,
                                          child: Text(effect.replaceAll('-', ' ').toUpperCase()),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            _pendingEffect = newValue;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: _applyEffect,
                                    child: const Text('Apply Effect'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Keep the sensitivity controls outside the Opacity widget
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
