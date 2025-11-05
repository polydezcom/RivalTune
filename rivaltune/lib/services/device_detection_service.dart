import 'dart:io';
import 'package:process_run/shell.dart';
import '../data/models/device.dart';

/// Service for detecting connected SteelSeries devices
class DeviceDetectionService {
  final Shell _shell = Shell();

  /// Detects connected SteelSeries devices using lsusb
  /// Returns a list of detected devices
  Future<List<Device>> detectDevices() async {
    if (!Platform.isLinux && !Platform.isMacOS) {
      // lsusb is primarily available on Linux/macOS
      return [];
    }

    try {
      final result = await _shell.run('lsusb');
      final output = result.first.stdout as String;
      final detectedDevices = <Device>[];

      // Parse lsusb output
      // Format: Bus XXX Device XXX: ID vendorId:productId Description
      final lines = output.split('\n');

      for (final line in lines) {
        if (line.isEmpty) continue;

        // Look for SteelSeries vendor ID (1038)
        final idMatch =
            RegExp(r'ID ([0-9a-fA-F]{4}):([0-9a-fA-F]{4})').firstMatch(line);
        if (idMatch != null) {
          final vendorId = idMatch.group(1);
          final productId = idMatch.group(2);

          if (vendorId == null || productId == null) continue;

          // Check if this is a SteelSeries device (vendor ID 1038)
          if (vendorId.toLowerCase() == '1038') {
            final device = SupportedDevices.findByUsbIds(vendorId, productId);
            if (device != null && !detectedDevices.contains(device)) {
              detectedDevices.add(device);
            }
          }
        }
      }

      return detectedDevices;
    } catch (e) {
      // lsusb might not be available or might fail
      // print('Error detecting devices: $e');
      return [];
    }
  }

  /// Gets a detailed description of lsusb output for troubleshooting
  Future<String> getLsusbOutput() async {
    if (!Platform.isLinux && !Platform.isMacOS) {
      return 'lsusb is not available on this platform (Windows).\n'
          'Please manually select your device from the list.';
    }

    try {
      final result = await _shell.run('lsusb');
      final output = result.first.stdout as String;

      // Filter for SteelSeries devices
      final lines = output.split('\n');
      final steelSeriesLines = lines.where((line) =>
          line.toLowerCase().contains('1038') ||
          line.toLowerCase().contains('steelseries'));

      if (steelSeriesLines.isEmpty) {
        return 'No SteelSeries devices detected.\n'
            'Make sure your device is connected and recognized by the system.';
      }

      return 'Detected SteelSeries USB devices:\n\n${steelSeriesLines.join('\n')}';
    } catch (e) {
      return 'Error running lsusb: $e\n\n'
          'Make sure lsusb is installed on your system.\n'
          'On Ubuntu/Debian: sudo apt install usbutils';
    }
  }
}
