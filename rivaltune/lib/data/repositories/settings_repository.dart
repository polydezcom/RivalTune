import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/color_preset.dart';
import '../models/device.dart';
import 'dart:convert';

class SettingsRepository {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveSelectedDevice(Device device) async {
    await _prefs.setString('selectedDevice', json.encode(device.toJson()));
  }

  Device? getSelectedDevice() {
    final deviceStr = _prefs.getString('selectedDevice');
    if (deviceStr == null) return null;
    try {
      return Device.fromJson(Map<String, dynamic>.from(json.decode(deviceStr)));
    } catch (e) {
      return null;
    }
  }

  Future<void> saveColors({
    required Color topColor,
    required Color middleColor,
    required Color bottomColor,
    required Color logoColor,
    Color? wheelColor,
  }) async {
    await _prefs.setInt('topColor', topColor.value);
    await _prefs.setInt('middleColor', middleColor.value);
    await _prefs.setInt('bottomColor', bottomColor.value);
    await _prefs.setInt('logoColor', logoColor.value);
    if (wheelColor != null) {
      await _prefs.setInt('wheelColor', wheelColor.value);
    }
  }

  Future<void> saveEffect(String effect) async {
    await _prefs.setString('effect', effect);
  }

  Future<void> saveSensitivity(int sensitivity) async {
    await _prefs.setInt('sensitivity', sensitivity);
  }

  // New methods for multiple sensitivity presets
  Future<void> saveSensitivities(List<int> sensitivities) async {
    final stringList = sensitivities.map((s) => s.toString()).toList();
    await _prefs.setStringList('sensitivities', stringList);
  }

  List<int> getSensitivities() {
    final stringList = _prefs.getStringList('sensitivities');
    if (stringList == null || stringList.isEmpty) {
      // Default to the old single sensitivity value, or [800, 1600] as per Rival 3 default
      final oldSensitivity = _prefs.getInt('sensitivity');
      return oldSensitivity != null ? [oldSensitivity, 1600] : [800, 1600];
    }
    return stringList.map((s) => int.tryParse(s) ?? 800).toList();
  }

  /// Get sensitivities adjusted for a specific device
  /// This ensures the returned list matches device constraints
  List<int> getSensitivitiesForDevice(Device? device) {
    final sensitivities = getSensitivities();

    if (device == null) return sensitivities;

    final config = device.sensitivityConfig;
    final maxPresets = config.maxPresets;
    final allowedValues = config.allowedValues;

    // Trim to max presets
    var adjusted = sensitivities.take(maxPresets).toList();

    // If device has restricted values, map to nearest allowed value
    if (allowedValues.isNotEmpty) {
      adjusted = adjusted.map((value) {
        // Find closest allowed value
        if (allowedValues.contains(value)) return value;

        // Find nearest allowed value
        var nearest = allowedValues.first;
        var minDiff = (value - nearest).abs();

        for (final allowed in allowedValues) {
          final diff = (value - allowed).abs();
          if (diff < minDiff) {
            minDiff = diff;
            nearest = allowed;
          }
        }

        return nearest;
      }).toList();
    }

    // Ensure we have at least default values
    if (adjusted.isEmpty) {
      if (device.id == 'rival100') {
        adjusted = [1000, 2000]; // Rival 100 defaults
      } else {
        adjusted = [800, 1600]; // General defaults
      }
    }

    return adjusted;
  }

  Future<void> saveRgbEnabled(bool enabled) async {
    await _prefs.setBool('rgbEnabled', enabled);
  }

  Color getTopColor() => Color(_prefs.getInt('topColor') ?? Colors.red.value);
  Color getMiddleColor() =>
      Color(_prefs.getInt('middleColor') ?? Colors.lime.value);
  Color getBottomColor() =>
      Color(_prefs.getInt('bottomColor') ?? Colors.blue.value);
  Color getLogoColor() =>
      Color(_prefs.getInt('logoColor') ?? Colors.purple.value);
  String getEffect() => _prefs.getString('effect') ?? 'steady';
  int getSensitivity() => _prefs.getInt('sensitivity') ?? 800;
  bool getRgbEnabled() => _prefs.getBool('rgbEnabled') ?? true;

  Future<void> saveCustomPresets(List<ColorPreset> presets) async {
    final presetList =
        presets.map((preset) => json.encode(preset.toJson())).toList();
    await _prefs.setStringList('customPresets', presetList);
  }

  List<ColorPreset> getCustomPresets() {
    final presetList = _prefs.getStringList('customPresets') ?? [];
    return presetList
        .map((String presetStr) => ColorPreset.fromJson(
            Map<String, dynamic>.from(json.decode(presetStr))))
        .toList();
  }
}
