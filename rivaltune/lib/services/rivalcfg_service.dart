import 'dart:io' show Platform;
import 'package:path/path.dart' as p;
import 'package:process_run/shell.dart';
import 'package:flutter/material.dart';
import '../core/utils/color_utils.dart';
import '../data/models/device.dart';

class RivalcfgService {
  final Shell _shell;
  final String _rivalcfgExecutableCommand;
  final String _rivalcfgDirectoryPath;
  Device? _selectedDevice;

  RivalcfgService({required String rivalcfgDirectoryPath})
      : _rivalcfgDirectoryPath = rivalcfgDirectoryPath,
        _shell = Shell(workingDirectory: rivalcfgDirectoryPath),
        _rivalcfgExecutableCommand = Platform.isWindows
            ? p.join('.', 'rivalcfg.env', 'Scripts', 'rivalcfg.exe')
            : p.join('.', 'rivalcfg.env', 'bin', 'rivalcfg');

  /// Set the currently selected device
  void setSelectedDevice(Device? device) {
    _selectedDevice = device;
  }

  /// Get the currently selected device
  Device? getSelectedDevice() => _selectedDevice;

  /// Check if a command is supported by the current device
  bool isCommandSupported(String command) {
    if (_selectedDevice == null) {
      return true; // Assume all commands if no device selected
    }
    return _selectedDevice!.supportedCommands.contains(command);
  }

  Future<void> setZoneColor(String zone, Color color) async {
    final String hexColor = colorToHex(color);
    final String command = '$_rivalcfgExecutableCommand --$zone $hexColor';
    await _shell.run(command);
  }

  Future<void> setSensitivity(int dpi) async {
    await _shell.run('$_rivalcfgExecutableCommand -s $dpi');
  }

  /// Set multiple sensitivity presets (up to 5)
  /// Handles device-specific formats:
  /// - Rival 3, 110, etc: -s 800,1600,3200 (comma-separated)
  /// - Rival 100: -s 1000 -S 2000 (separate flags)
  Future<void> setSensitivities(List<int> dpiList) async {
    if (dpiList.isEmpty) return;

    // Determine command format based on selected device
    if (_selectedDevice != null &&
        _selectedDevice!.sensitivityConfig.type == SensitivityType.multiple) {
      // Rival 100 style: separate flags for each preset
      final flags = <String>[];
      for (int i = 0; i < dpiList.length && i < 2; i++) {
        if (i == 0) {
          flags.add('-s ${dpiList[i]}');
        } else if (i == 1) {
          flags.add('-S ${dpiList[i]}');
        }
      }
      await _shell.run('$_rivalcfgExecutableCommand ${flags.join(' ')}');
    } else {
      // Default style: comma-separated list (Rival 3, 110, etc)
      final dpiString = dpiList.join(',');
      await _shell.run('$_rivalcfgExecutableCommand -s $dpiString');
    }
  }

  Future<void> setEffect(String effect) async {
    await _shell.run('$_rivalcfgExecutableCommand -e $effect');
  }

  Future<void> setAllZones({
    required Color topColor,
    required Color middleColor,
    required Color bottomColor,
    required Color logoColor,
    String? effect,
  }) async {
    String command = '$_rivalcfgExecutableCommand '
        '--strip-top-color ${colorToHex(topColor)} '
        '--strip-middle-color ${colorToHex(middleColor)} '
        '--strip-bottom-color ${colorToHex(bottomColor)} '
        '--logo-color ${colorToHex(logoColor)}';
    if (effect != null && effect.isNotEmpty) {
      command += ' -e $effect';
    }
    await _shell.run(command.trim());
  }

  Future<void> turnOffLights() async {
    final String command = '$_rivalcfgExecutableCommand '
        '--strip-top-color 000000 '
        '--strip-middle-color 000000 '
        '--strip-bottom-color 000000 '
        '--logo-color 000000';
    await _shell.run(command);
  }

  String getUdevUpdateCommandInstructions() {
    if (Platform.isWindows) {
      return "Udev rules are typically for Linux. On Windows, please ensure that device drivers are correctly installed and that the rivalcfg utility has the necessary permissions to access your SteelSeries device.";
    }
    final String fullExecutablePath =
        p.join(_rivalcfgDirectoryPath, _rivalcfgExecutableCommand);
    return 'For rivalcfg to control your device without needing root privileges for every command, '
        'your system\'s udev rules need to be updated. '
        'Please run the following command in a terminal. You might be prompted for your administrator password:\n\n'
        'sudo "$fullExecutablePath" --update-udev\n\n'
        'After running this command, you may need to unplug and then replug your SteelSeries device for the changes to take full effect.';
  }
}
