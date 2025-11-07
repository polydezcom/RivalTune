import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/rivalcfg_service.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/models/device.dart';
import '../dialogs/device_selection_dialog.dart';
import './onboarding_page.dart'; // Import OnboardingPage

class SettingsPage extends StatefulWidget {
  final RivalcfgService rivalcfgService;
  final SettingsRepository settingsRepository;

  const SettingsPage({
    super.key,
    required this.rivalcfgService,
    required this.settingsRepository,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Device? _selectedDevice;
  String _version = 'Loading...';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _selectedDevice = widget.settingsRepository.getSelectedDevice();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  void _showDeviceSelection() {
    showDialog(
      context: context,
      builder: (context) => DeviceSelectionDialog(
        currentDevice: _selectedDevice,
        onDeviceSelected: (device) async {
          setState(() {
            _selectedDevice = device;
          });
          widget.rivalcfgService.setSelectedDevice(device);
          if (device != null) {
            await widget.settingsRepository.saveSelectedDevice(device);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Device set to ${device.name}')),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Device selection cleared')),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String udevCommandInstructions =
        widget.rivalcfgService.getUdevUpdateCommandInstructions();
    final String udevCommand = _extractActualCommand(udevCommandInstructions);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings & Troubleshooting',
          style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device Selection Section
            Text(
              'Device Configuration',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.mouse,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Device',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedDevice?.name ??
                                    'No device selected (auto-detect)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _selectedDevice != null
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.settings, size: 18),
                          label: const Text('Change'),
                          onPressed: _showDeviceSelection,
                        ),
                      ],
                    ),
                    if (_selectedDevice != null) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Supported Commands:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _selectedDevice!.supportedCommands.map((cmd) {
                          return Chip(
                            label: Text(
                              cmd,
                              style: const TextStyle(fontSize: 11),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('View Device Documentation'),
                        onPressed: () {
                          // Could open URL in browser
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Device Documentation'),
                              content: SelectableText(
                                'View full documentation at:\n\n${_selectedDevice!.docsUrl}',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Existing udev section
            Text(
              'rivalcfg Setup',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text(
              'For RivalTune to control your SteelSeries device on Linux without needing to run every command as root, your system\'s udev rules need to be updated. This is a one-time setup step.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Please run the following command in your terminal. You will likely be prompted for your administrator (sudo) password:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    udevCommand.isNotEmpty
                        ? udevCommand
                        : "Could not determine udev command. Ensure rivalcfg is initialized.",
                    style: GoogleFonts.sourceCodePro(fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (udevCommand.isNotEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copy Command'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: udevCommand));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Command copied to clipboard!')),
                  );
                },
              ),
            const SizedBox(height: 24),
            const Text(
              'Important Notes:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• This command only needs to be run once.\n'
              '• After running the command, you might need to unplug and replug your SteelSeries device for the changes to take full effect.\n'
              '• Your application cannot run this command for you due to security restrictions (it requires sudo/administrator access).',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Text(
              'Revisit Introduction',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'If you want to see the initial setup instructions again, you can restart the onboarding guide.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.school_outlined),
              label: const Text('Show Onboarding Guide'),
              onPressed: () {
                // Ensure rivalcfgService is available, though OnboardingPage might re-check some things
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OnboardingPage(
                      rivalcfgService: widget.rivalcfgService,
                      isInSettings: true, // So it pops back to settings
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Full Instructions from rivalcfg:', // For transparency
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onInverseSurface,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                udevCommandInstructions,
                style: GoogleFonts.sourceCodePro(fontSize: 14),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    'RivalTune',
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version $_version${_buildNumber.isNotEmpty ? ' (Build $_buildNumber)' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Made by Polydez',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(
                        const ClipboardData(
                          text: 'https://github.com/polydezcom/RivalTune',
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('GitHub URL copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 6),
                          Text(
                            'github.com/polydezcom/RivalTune',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.content_copy,
                              size: 14, color: Colors.blue[700]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Licensed under GPL-3.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to extract the actual command for the copy button
  String _extractActualCommand(String fullInstructions) {
    // This is a bit fragile and depends on the current format of getUdevUpdateCommandInstructions
    final RegExp commandRegExp = RegExp(r'sudo ".*?" --update-udev');
    final Match? match = commandRegExp.firstMatch(fullInstructions);
    if (match != null) {
      return match.group(0) ?? '';
    }
    if (fullInstructions.contains("Windows")) {
      // If on windows, there's no udev command
      return "";
    }
    return "sudo /path/to/rivalcfg_tool/rivalcfg.env/bin/rivalcfg --update-udev (command auto-detection failed)";
  }
}
