import 'package:process_run/shell.dart';
import 'package:flutter/material.dart';
import '../core/utils/color_utils.dart';

class RivalcfgService {
  final Shell _shell = Shell();

  Future<void> setZoneColor(String zone, Color color) async {
    final command = 'rivalcfg --$zone ${colorToHex(color)}';
    await _shell.run(command);
  }

  Future<void> setSensitivity(int dpi) async {
    await _shell.run('rivalcfg -s $dpi');
  }

  Future<void> setEffect(String effect) async {
    await _shell.run('rivalcfg -e $effect');
  }

  Future<void> setAllZones({
    required Color topColor,
    required Color middleColor,
    required Color bottomColor,
    required Color logoColor,
    String? effect,
  }) async {
    final command = 'rivalcfg '
        '--strip-top-color ${colorToHex(topColor)} '
        '--strip-middle-color ${colorToHex(middleColor)} '
        '--strip-bottom-color ${colorToHex(bottomColor)} '
        '--logo-color ${colorToHex(logoColor)} '
        '${effect != null ? '-e $effect' : ''}';
    await _shell.run(command);
  }

  Future<void> turnOffLights() async {
    const command = 'rivalcfg '
        '--strip-top-color 000000 '
        '--strip-middle-color 000000 '
        '--strip-bottom-color 000000 '
        '--logo-color 000000';
    await _shell.run(command);
  }
} 