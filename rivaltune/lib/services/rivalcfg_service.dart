import 'dart:io' show Platform;
import 'package:path/path.dart' as p;
import 'package:process_run/shell.dart';
import 'package:flutter/material.dart';
import '../core/utils/color_utils.dart';

class RivalcfgService {
  final Shell _shell;
  final String _rivalcfgExecutableCommand;
  final String _rivalcfgDirectoryPath;

  RivalcfgService({required String rivalcfgDirectoryPath})
      : _rivalcfgDirectoryPath = rivalcfgDirectoryPath,
        _shell = Shell(workingDirectory: rivalcfgDirectoryPath),
        _rivalcfgExecutableCommand = Platform.isWindows
            ? p.join('.', 'rivalcfg.env', 'Scripts', 'rivalcfg.exe')
            : p.join('.', 'rivalcfg.env', 'bin', 'rivalcfg');

  Future<void> setZoneColor(String zone, Color color) async {
    final String hexColor = colorToHex(color);
    final String command = '$_rivalcfgExecutableCommand --$zone $hexColor';
    await _shell.run(command);
  }

  Future<void> setSensitivity(int dpi) async {
    await _shell.run('$_rivalcfgExecutableCommand -s $dpi');
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
    final String fullExecutablePath = p.join(_rivalcfgDirectoryPath, _rivalcfgExecutableCommand);
    return 'For rivalcfg to control your device without needing root privileges for every command, '
           'your system\'s udev rules need to be updated. '
           'Please run the following command in a terminal. You might be prompted for your administrator password:\n\n'
           'sudo "$fullExecutablePath" --update-udev\n\n'
           'After running this command, you may need to unplug and then replug your SteelSeries device for the changes to take full effect.';
  }
} 