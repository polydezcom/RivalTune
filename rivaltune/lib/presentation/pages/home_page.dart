import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/color_preset.dart';
import '../../data/repositories/settings_repository.dart';
import '../../services/rivalcfg_service.dart';
import '../widgets/color_zone_tile.dart';
import '../widgets/effect_selector.dart';
import '../widgets/preset_selector.dart';
import '../widgets/rgb_switch.dart';
import '../widgets/sensitivity_slider.dart';
import '../dialogs/color_picker_dialog.dart';
import '../dialogs/preset_name_dialog.dart';
import '../../core/constants/light_effects.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final RivalcfgService _rivalcfg;
  late final SettingsRepository _settings;
  
  // Device state
  int _currentSensitivity = 800;
  Color _currentTopColor = Colors.red;
  Color _currentMiddleColor = Colors.lime;
  Color _currentBottomColor = Colors.blue;
  Color _currentLogoColor = Colors.purple;
  String _currentEffect = 'steady';
  bool _isRgbEnabled = true;

  // UI state
  int _pendingSensitivity = 800;
  Color _pendingTopColor = Colors.red;
  Color _pendingMiddleColor = Colors.lime;
  Color _pendingBottomColor = Colors.blue;
  Color _pendingLogoColor = Colors.purple;
  String _pendingEffect = 'steady';
  List<ColorPreset> _customPresets = [];

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
    ColorPreset(
      name: 'Arctic',
      topColor: Colors.lightBlue,
      middleColor: Colors.white,
      bottomColor: Colors.blue.shade100,
      logoColor: Colors.blue,
      effect: 'breath-slow',
    ),
    ColorPreset(
      name: 'Neon',
      topColor: Colors.purple,
      middleColor: Colors.pink,
      bottomColor: Colors.blue,
      logoColor: Colors.deepPurple,
      effect: 'rainbow-breath',
    ),
    ColorPreset(
      name: 'Gold',
      topColor: Colors.amber,
      middleColor: Colors.yellow,
      bottomColor: Colors.orange,
      logoColor: Colors.amber.shade900,
    ),
    ColorPreset(
      name: 'Matrix',
      topColor: Colors.green,
      middleColor: Colors.lightGreen,
      bottomColor: Colors.lime,
      logoColor: Colors.green.shade900,
      effect: 'breath-fast',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _rivalcfg = RivalcfgService();
    _settings = SettingsRepository();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    await _settings.init();
    setState(() {
      _pendingTopColor = _currentTopColor = _settings.getTopColor();
      _pendingMiddleColor = _currentMiddleColor = _settings.getMiddleColor();
      _pendingBottomColor = _currentBottomColor = _settings.getBottomColor();
      _pendingLogoColor = _currentLogoColor = _settings.getLogoColor();
      _pendingEffect = _currentEffect = _settings.getEffect();
      _pendingSensitivity = _currentSensitivity = _settings.getSensitivity();
      _isRgbEnabled = _settings.getRgbEnabled();
      _customPresets = _settings.getCustomPresets();
    });
  }

  void _showColorPicker(int zone, Color currentColor) {
    Color pendingColor = currentColor;
    
    showDialog(
      context: context,
      builder: (context) => ColorPickerDialog(
        zone: zone,
        currentColor: currentColor,
        onColorChanged: (color) {
          pendingColor = color;
          setState(() {
            switch (zone) {
              case 1: _pendingTopColor = color;
              case 2: _pendingMiddleColor = color;
              case 3: _pendingBottomColor = color;
              case 4: _pendingLogoColor = color;
            }
          });
        },
        onApply: () => _applyZoneColor(zone, pendingColor),
      ),
    );
  }

  Future<void> _applyZoneColor(int zone, Color color) async {
    String zoneFlag;
    switch (zone) {
      case 1:
        zoneFlag = 'strip-top-color';
        _currentTopColor = color;
      case 2:
        zoneFlag = 'strip-middle-color';
        _currentMiddleColor = color;
      case 3:
        zoneFlag = 'strip-bottom-color';
        _currentBottomColor = color;
      case 4:
        zoneFlag = 'logo-color';
        _currentLogoColor = color;
      default:
        return;
    }
    
    await _rivalcfg.setZoneColor(zoneFlag, color);
    await _settings.saveColors(
      topColor: _currentTopColor,
      middleColor: _currentMiddleColor,
      bottomColor: _currentBottomColor,
      logoColor: _currentLogoColor,
    );
  }

  Future<void> _saveCurrentAsPreset() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => PresetNameDialog(controller: controller),
    );

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
      await _settings.saveCustomPresets(_customPresets);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              RgbSwitch(
                value: _isRgbEnabled,
                onChanged: (enabled) async {
                  if (enabled) {
                    await _rivalcfg.setAllZones(
                      topColor: _pendingTopColor,
                      middleColor: _pendingMiddleColor,
                      bottomColor: _pendingBottomColor,
                      logoColor: _pendingLogoColor,
                      effect: _pendingEffect,
                    );
                  } else {
                    await _rivalcfg.turnOffLights();
                  }
                  setState(() => _isRgbEnabled = enabled);
                  await _settings.saveRgbEnabled(enabled);
                },
              ),
              const SizedBox(height: 8),
              
              PresetSelector(
                builtInPresets: _builtInPresets,
                customPresets: _customPresets,
                onPresetSelected: (preset) async {
                  if (preset != null) {
                    setState(() {
                      _pendingTopColor = preset.topColor;
                      _pendingMiddleColor = preset.middleColor;
                      _pendingBottomColor = preset.bottomColor;
                      _pendingLogoColor = preset.logoColor;
                      _pendingEffect = preset.effect;
                    });
                    if (_isRgbEnabled) {
                      await _rivalcfg.setAllZones(
                        topColor: preset.topColor,
                        middleColor: preset.middleColor,
                        bottomColor: preset.bottomColor,
                        logoColor: preset.logoColor,
                        effect: preset.effect,
                      );
                      await _settings.saveColors(
                        topColor: preset.topColor,
                        middleColor: preset.middleColor,
                        bottomColor: preset.bottomColor,
                        logoColor: preset.logoColor,
                      );
                      await _settings.saveEffect(preset.effect);
                    }
                  }
                },
                onSavePressed: _saveCurrentAsPreset,
                onDeletePreset: (preset) async {
                  setState(() {
                    _customPresets.remove(preset);
                  });
                  await _settings.saveCustomPresets(_customPresets);
                },
              ),
              const SizedBox(height: 8),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LED Zones',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ColorZoneTile(
                        label: 'Top Strip',
                        color: _pendingTopColor,
                        onTap: () => _showColorPicker(1, _pendingTopColor),
                      ),
                      const Divider(height: 1),
                      ColorZoneTile(
                        label: 'Middle Strip',
                        color: _pendingMiddleColor,
                        onTap: () => _showColorPicker(2, _pendingMiddleColor),
                      ),
                      const Divider(height: 1),
                      ColorZoneTile(
                        label: 'Bottom Strip',
                        color: _pendingBottomColor,
                        onTap: () => _showColorPicker(3, _pendingBottomColor),
                      ),
                      const Divider(height: 1),
                      ColorZoneTile(
                        label: 'Logo',
                        color: _pendingLogoColor,
                        onTap: () => _showColorPicker(4, _pendingLogoColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              EffectSelector(
                value: _pendingEffect,
                onChanged: (effect) {
                  if (effect != null) {
                    setState(() => _pendingEffect = effect);
                  }
                },
                onApply: () async {
                  await _rivalcfg.setEffect(_pendingEffect);
                  await _settings.saveEffect(_pendingEffect);
                  setState(() => _currentEffect = _pendingEffect);
                },
              ),
              const SizedBox(height: 8),
              
              SensitivitySlider(
                value: _pendingSensitivity,
                onChanged: (value) {
                  setState(() => _pendingSensitivity = value.toInt());
                },
                onApply: () async {
                  await _rivalcfg.setSensitivity(_pendingSensitivity);
                  await _settings.saveSensitivity(_pendingSensitivity);
                  setState(() => _currentSensitivity = _pendingSensitivity);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 