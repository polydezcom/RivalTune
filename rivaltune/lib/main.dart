import 'package:flutter/material.dart';
import 'package:process_run/shell.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:window_size/window_size.dart' show setWindowFrame, setWindowMinSize, setWindowTitle;
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    setWindowMinSize(const Size(300, 400));
    
    SharedPreferences.getInstance().then((prefs) {
      final double? savedWidth = prefs.getDouble('window_width');
      final double? savedHeight = prefs.getDouble('window_height');
      
      if (savedWidth != null && savedHeight != null) {
        setWindowFrame(Rect.fromLTWH(0, 0, savedWidth, savedHeight));
      } else {
        setWindowFrame(const Rect.fromLTWH(0, 0, 650, 750));
      }
    });
    
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.robotoTextTheme().copyWith(
          titleLarge: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
          titleMedium: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500),
          bodyLarge: GoogleFonts.roboto(fontSize: 14),
          bodyMedium: GoogleFonts.roboto(fontSize: 13),
          headlineSmall: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
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
  late SharedPreferences _prefs;
  
  @override
  void initState() {
    super.initState();
    _loadSavedSettings().then((_) => _loadCustomPresets());
  }

  Future<void> _loadSavedSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _pendingTopColor = Color(_prefs.getInt('topColor') ?? Colors.red.value);
      _pendingMiddleColor = Color(_prefs.getInt('middleColor') ?? Colors.lime.value);
      _pendingBottomColor = Color(_prefs.getInt('bottomColor') ?? Colors.blue.value);
      _pendingLogoColor = Color(_prefs.getInt('logoColor') ?? Colors.purple.value);
      _pendingEffect = _prefs.getString('effect') ?? 'steady';
      _pendingSensitivity = _prefs.getInt('sensitivity') ?? 800;
      _isRgbEnabled = _prefs.getBool('rgbEnabled') ?? true;
      
      // Set current values to match pending values
      _currentTopColor = _pendingTopColor;
      _currentMiddleColor = _pendingMiddleColor;
      _currentBottomColor = _pendingBottomColor;
      _currentLogoColor = _pendingLogoColor;
      _currentEffect = _pendingEffect;
      _currentSensitivity = _pendingSensitivity;
    });
  }

  Future<void> _saveSettings() async {
    await _prefs.setInt('topColor', _pendingTopColor.value);
    await _prefs.setInt('middleColor', _pendingMiddleColor.value);
    await _prefs.setInt('bottomColor', _pendingBottomColor.value);
    await _prefs.setInt('logoColor', _pendingLogoColor.value);
    await _prefs.setString('effect', _pendingEffect);
    await _prefs.setInt('sensitivity', _pendingSensitivity);
    await _prefs.setBool('rgbEnabled', _isRgbEnabled);
  }

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

  final List<ColorPreset> _builtInPresets = [
    ColorPreset(
      name: 'Rainbow',
      topColor: Colors.red,
      middleColor: Colors.green,
      bottomColor: Colors.blue,
      logoColor: Colors.purple,
      effect: 'rainbow-shift',
    ),
    ColorPreset(
      name: 'Fire',
      topColor: Colors.red,
      middleColor: Colors.orange,
      bottomColor: Colors.yellow,
      logoColor: Colors.deepOrange,
      effect: 'breath-fast',
    ),
    ColorPreset(
      name: 'Ocean',
      topColor: Colors.blue,
      middleColor: Colors.cyan,
      bottomColor: Colors.lightBlue,
      logoColor: Colors.indigo,
      effect: 'breath-slow',
    ),
    ColorPreset(
      name: 'Forest',
      topColor: Colors.green,
      middleColor: Colors.lightGreen,
      bottomColor: Colors.lime,
      logoColor: Colors.green,
    ),
    ColorPreset(
      name: 'Sunset',
      topColor: Colors.deepOrange,
      middleColor: Colors.orange,
      bottomColor: Colors.amber,
      logoColor: Colors.red,
    ),
    ColorPreset(
      name: 'Cyberpunk',
      topColor: Colors.pink,
      middleColor: Colors.cyan,
      bottomColor: Colors.yellow,
      logoColor: Colors.purple,
      effect: 'disco',
    ),
    // Add more built-in presets as desired
  ];

  List<ColorPreset> _customPresets = [];

  Future<void> _loadCustomPresets() async {
    final presetList = _prefs.getStringList('customPresets') ?? [];
    _customPresets = presetList
        .map((String presetStr) => ColorPreset.fromJson(
            Map<String, dynamic>.from(json.decode(presetStr))))
        .toList();
  }

  Future<void> _saveCustomPresets() async {
    final presetList = _customPresets
        .map((preset) => json.encode(preset.toJson()))
        .toList();
    await _prefs.setStringList('customPresets', presetList);
  }

  Future<void> _saveCurrentAsPreset() async {
    final name = await _showPresetNameDialog();
    if (name != null && name.isNotEmpty) {
      setState(() {
        _customPresets.add(ColorPreset(
          name: name,
          topColor: _pendingTopColor,
          middleColor: _pendingMiddleColor,
          bottomColor: _pendingBottomColor,
          logoColor: _pendingLogoColor,
          effect: _pendingEffect,
        ));
      });
      await _saveCustomPresets();
    }
  }

  Future<void> _applyPreset(ColorPreset preset) async {
    setState(() {
      _pendingTopColor = preset.topColor;
      _pendingMiddleColor = preset.middleColor;
      _pendingBottomColor = preset.bottomColor;
      _pendingLogoColor = preset.logoColor;
      _pendingEffect = preset.effect;
    });
    
    if (_isRgbEnabled) {
      final command = 'rivalcfg '
          '--strip-top-color ${_colorToHex(preset.topColor)} '
          '--strip-middle-color ${_colorToHex(preset.middleColor)} '
          '--strip-bottom-color ${_colorToHex(preset.bottomColor)} '
          '--logo-color ${_colorToHex(preset.logoColor)} '
          '-e ${preset.effect}';
      try {
        await _shell.run(command);
        await _saveSettings();
      } catch (e) {
        print('Error executing command: $e');
      }
    }
  }

  Future<String?> _showPresetNameDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
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
      ),
    );
  }

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
      await _saveSettings();
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
      await _saveSettings();
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
      await _saveSettings();
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
      await _saveSettings();
    } catch (e) {
      print('Error executing command: $e');
    }
  }

  String _colorToHex(Color color) {
    return color.value.toRadixString(16).substring(2).padLeft(6, '0');
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SteelSeries Configurator',
          style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Master RGB Switch
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RGB Lighting',
                        style: theme.textTheme.titleLarge,
                      ),
                      Switch(
                        value: _isRgbEnabled,
                        onChanged: _toggleRgb,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Add the presets menu here
              _buildPresetsMenu(),
              const SizedBox(height: 8),
              
              // LED Zones Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
        child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LED Zones',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _buildColorZone(1, 'Top Strip', _pendingTopColor),
                      const Divider(height: 1),
                      _buildColorZone(2, 'Middle Strip', _pendingMiddleColor),
                      const Divider(height: 1),
                      _buildColorZone(3, 'Bottom Strip', _pendingBottomColor),
                      const Divider(height: 1),
                      _buildColorZone(4, 'Logo', _pendingLogoColor),
                    ],
                  ),
                ),
              ),

              // Light Effect Card
              Card(
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
                            value: _pendingEffect,
                            isDense: true,
                            isExpanded: true,
                            padding: EdgeInsets.zero,
                            underline: const SizedBox(),
                            items: _lightEffects.map((String effect) {
                              return DropdownMenuItem<String>(
                                value: effect,
                                child: Text(
                                  effect.replaceAll('-', ' ').toUpperCase(),
                                  style: theme.textTheme.bodyLarge,
                                ),
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
                      ),
                      const SizedBox(width: 16),
                      FilledButton(
                        onPressed: _applyEffect,
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ),
              ),

              // Sensitivity Section
              const SizedBox(height: 16),
              Card(
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
                        '$_pendingSensitivity DPI',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Slider(
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
                      ),
                      FilledButton(
                        onPressed: _applySensitivity,
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorZone(int zone, String label, Color color) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      dense: true,
      title: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      trailing: InkWell(
        onTap: () => _showColorPicker(zone, color),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 0.5,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetsMenu() {
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
                    borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  isDense: true,
                  constraints: const BoxConstraints(maxHeight: 36),
                ),
                hint: const Text('Select a preset'),
                items: [
                  ..._builtInPresets.map((preset) => DropdownMenuItem(
                        value: preset,
                        child: Text('📦 ${preset.name}'),
                      )),
                  if (_customPresets.isNotEmpty) const DropdownMenuItem(
                    enabled: false,
                    child: Divider(),
                  ),
                  ..._customPresets.map((preset) => DropdownMenuItem(
                        value: preset,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('💾 ${preset.name}'),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                setState(() {
                                  _customPresets.remove(preset);
                                });
                                await _saveCustomPresets();
                              },
                            ),
                          ],
                        ),
                      )),
                ],
                onChanged: (preset) {
                  if (preset != null) {
                    _applyPreset(preset);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: _saveCurrentAsPreset,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class ColorPreset {
  final String name;
  final Color topColor;
  final Color middleColor;
  final Color bottomColor;
  final Color logoColor;
  final String effect;

  const ColorPreset({
    required this.name,
    required this.topColor,
    required this.middleColor,
    required this.bottomColor,
    required this.logoColor,
    this.effect = 'steady',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'topColor': topColor.value,
    'middleColor': middleColor.value,
    'bottomColor': bottomColor.value,
    'logoColor': logoColor.value,
    'effect': effect,
  };

  factory ColorPreset.fromJson(Map<String, dynamic> json) => ColorPreset(
    name: json['name'],
    topColor: Color(json['topColor']),
    middleColor: Color(json['middleColor']),
    bottomColor: Color(json['bottomColor']),
    logoColor: Color(json['logoColor']),
    effect: json['effect'],
  );
}
