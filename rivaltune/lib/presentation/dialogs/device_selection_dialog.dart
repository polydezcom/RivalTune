import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/device.dart';
import '../../services/device_detection_service.dart';

class DeviceSelectionDialog extends StatefulWidget {
  final Device? currentDevice;
  final Function(Device?) onDeviceSelected;

  const DeviceSelectionDialog({
    super.key,
    this.currentDevice,
    required this.onDeviceSelected,
  });

  @override
  State<DeviceSelectionDialog> createState() => _DeviceSelectionDialogState();
}

class _DeviceSelectionDialogState extends State<DeviceSelectionDialog> {
  final DeviceDetectionService _detectionService = DeviceDetectionService();
  bool _isDetecting = false;
  List<Device> _detectedDevices = [];
  String _detectionMessage = '';
  Device? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _selectedDevice = widget.currentDevice;
    _autoDetectDevices();
  }

  Future<void> _autoDetectDevices() async {
    setState(() {
      _isDetecting = true;
      _detectionMessage = 'Scanning for connected devices...';
    });

    try {
      final devices = await _detectionService.detectDevices();
      setState(() {
        _detectedDevices = devices;
        _isDetecting = false;
        if (devices.isEmpty) {
          _detectionMessage =
              'No devices detected automatically. Please select manually below.';
        } else {
          _detectionMessage = 'Found ${devices.length} device(s)';
        }
      });
    } catch (e) {
      setState(() {
        _isDetecting = false;
        _detectionMessage = 'Auto-detection failed: $e';
      });
    }
  }

  Future<void> _showLsusbOutput() async {
    final output = await _detectionService.getLsusbOutput();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('USB Device Information'),
        content: SingleChildScrollView(
          child: SelectableText(
            output,
            style: GoogleFonts.robotoMono(fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.mouse,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select Your Device',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Auto-detection section
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 20, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Auto-Detection',
                                    style: GoogleFonts.roboto(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                                if (_isDetecting)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                else
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    tooltip: 'Rescan',
                                    iconSize: 20,
                                    onPressed: _autoDetectDevices,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _detectionMessage,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.blue.shade800),
                            ),
                            if (_detectedDevices.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ...(_detectedDevices.map((device) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      dense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                      tileColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(
                                            color: Colors.blue.shade200),
                                      ),
                                      leading: Icon(Icons.check_circle,
                                          color: Colors.green.shade600),
                                      title: Text(
                                        device.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                      ),
                                      subtitle: Text(
                                          'USB ID: ${device.usbVendorId}:${device.usbProductId}'),
                                      trailing: ElevatedButton(
                                        onPressed: () {
                                          widget.onDeviceSelected(device);
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Select'),
                                      ),
                                    ),
                                  ))),
                            ],
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _showLsusbOutput,
                              icon: const Icon(Icons.terminal, size: 16),
                              label: const Text('View USB Device Details'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Manual selection
                    Text(
                      'Or select manually:',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Device list
                    ...SupportedDevices.all.map((device) {
                      final isSelected = _selectedDevice?.id == device.id;
                      final isDetected = _detectedDevices.contains(device);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isSelected ? Colors.blue.shade50 : null,
                        child: ListTile(
                          leading: Icon(
                            isDetected ? Icons.cable : Icons.mouse,
                            color: isDetected ? Colors.green : Colors.grey,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  device.name,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isDetected)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Connected',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            'USB: ${device.usbVendorId}:${device.usbProductId}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Radio<String>(
                            value: device.id,
                            groupValue: _selectedDevice?.id,
                            onChanged: (value) {
                              setState(() {
                                _selectedDevice = device;
                              });
                            },
                          ),
                          onTap: () {
                            setState(() {
                              _selectedDevice = device;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      widget.onDeviceSelected(null);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Clear Selection'),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _selectedDevice == null
                            ? null
                            : () {
                                widget.onDeviceSelected(_selectedDevice);
                                Navigator.of(context).pop();
                              },
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
