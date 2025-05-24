import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/rivalcfg_service.dart';
import './onboarding_page.dart'; // Import OnboardingPage

class SettingsPage extends StatelessWidget {
  final RivalcfgService rivalcfgService;

  const SettingsPage({
    super.key,
    required this.rivalcfgService,
  });

  @override
  Widget build(BuildContext context) {
    final String udevCommandInstructions = rivalcfgService.getUdevUpdateCommandInstructions();
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
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    udevCommand.isNotEmpty ? udevCommand : "Could not determine udev command. Ensure rivalcfg is initialized.",
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
                    const SnackBar(content: Text('Command copied to clipboard!')),
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
                      rivalcfgService: rivalcfgService, 
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
    if (fullInstructions.contains("Windows")) { // If on windows, there's no udev command
        return "";
    }
    return "sudo /path/to/rivalcfg_tool/rivalcfg.env/bin/rivalcfg --update-udev (command auto-detection failed)";
  }
} 