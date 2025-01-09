import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/color_preset.dart';
import 'dart:convert';

class SettingsRepository {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveColors({
    required Color topColor,
    required Color middleColor,
    required Color bottomColor,
    required Color logoColor,
  }) async {
    await _prefs.setInt('topColor', topColor.value);
    await _prefs.setInt('middleColor', middleColor.value);
    await _prefs.setInt('bottomColor', bottomColor.value);
    await _prefs.setInt('logoColor', logoColor.value);
  }

  Future<void> saveEffect(String effect) async {
    await _prefs.setString('effect', effect);
  }

  Future<void> saveSensitivity(int sensitivity) async {
    await _prefs.setInt('sensitivity', sensitivity);
  }

  Future<void> saveRgbEnabled(bool enabled) async {
    await _prefs.setBool('rgbEnabled', enabled);
  }

  Color getTopColor() => Color(_prefs.getInt('topColor') ?? Colors.red.value);
  Color getMiddleColor() => Color(_prefs.getInt('middleColor') ?? Colors.lime.value);
  Color getBottomColor() => Color(_prefs.getInt('bottomColor') ?? Colors.blue.value);
  Color getLogoColor() => Color(_prefs.getInt('logoColor') ?? Colors.purple.value);
  String getEffect() => _prefs.getString('effect') ?? 'steady';
  int getSensitivity() => _prefs.getInt('sensitivity') ?? 800;
  bool getRgbEnabled() => _prefs.getBool('rgbEnabled') ?? true;

  Future<void> saveCustomPresets(List<ColorPreset> presets) async {
    final presetList = presets.map((preset) => json.encode(preset.toJson())).toList();
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