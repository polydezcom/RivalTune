import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/rivalcfg_service.dart'; // To get udev command
import './home_page.dart'; // To navigate after onboarding

class OnboardingPage extends StatefulWidget {
  final RivalcfgService rivalcfgService; // Needed for udev command
  final bool isInSettings;

  static const String onboardingCompleteKey = 'onboarding_complete';

  const OnboardingPage({
    super.key,
    required this.rivalcfgService,
    this.isInSettings = false, // To know if we should pop or replace
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Widget> _buildPages() {
    final String udevCommandInstructions = widget.rivalcfgService.getUdevUpdateCommandInstructions();
    final String udevCommand = _extractActualCommand(udevCommandInstructions);

    return [
      _buildPageContent(
        title: 'Welcome to RivalTune!',
        description: 'This app helps you configure your SteelSeries mouse on Linux.\n\nLet\'s get you set up.',
        icon: Icons.mouse_outlined,
      ),
      _buildPageContent(
        title: 'System Requirements',
        description: 'RivalTune needs Git and Python 3 (with the \'venv\' module) installed on your system to download and set up the \'rivalcfg\' utility.\n\nIf these are missing, the app will attempt to guide you, but automatic setup might fail.',
        icon: Icons.build_circle_outlined,
      ),
      if (!udevCommandInstructions.toLowerCase().contains("windows")) // Only show udev for non-Windows
         _buildPageContent(
          title: 'Linux: Udev Rules Setup',
          description: 'To allow RivalTune to communicate with your mouse without needing root privileges for every action, a one-time \'udev rule\' update is needed.\n\nAfter the app initializes, if you see a permission warning, please run the following command in your terminal:',
          commandToCopy: udevCommand,
          icon: Icons.terminal_outlined,
          extraNotes: 'You might need to unplug and replug your mouse after running the command.',
      ),
      _buildPageContent(
        title: 'All Set!',
        description: 'You\'re ready to start configuring your mouse.\n\nIf you encounter any issues, check the Settings & Troubleshooting section (top-right icon on the main page).',
        icon: Icons.check_circle_outline,
      ),
    ];
  }

  Widget _buildPageContent({
    required String title,
    required String description,
    IconData? icon,
    String? commandToCopy,
    String? extraNotes,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null)
            Icon(icon, size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          if (commandToCopy != null && commandToCopy.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  children: [
                    Text(
                      commandToCopy,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sourceCodePro(fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy Command'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: commandToCopy));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Command copied!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          if (extraNotes != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                extraNotes,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          const Spacer(), // Pushes controls to the bottom if content is short
        ],
      ),
    );
  }

  String _extractActualCommand(String fullInstructions) {
    final RegExp commandRegExp = RegExp(r'sudo ".*?" --update-udev');
    final Match? match = commandRegExp.firstMatch(fullInstructions);
    if (match != null) {
      return match.group(0) ?? '';
    }
    if (fullInstructions.toLowerCase().contains("windows")) { 
        return "";
    }
    return "sudo /path/to/rivalcfg_tool/rivalcfg.env/bin/rivalcfg --update-udev (auto-detection failed)";
  }

  Future<void> _completeOnboarding() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingPage.onboardingCompleteKey, true);
    if (mounted) {
      if (widget.isInSettings) {
        Navigator.of(context).pop(); // Go back to settings
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _currentPage > 0
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null, // Disable if on the first page
                    child: const Text('BACK'),
                  ),
                  Row(
                    children: List.generate(pages.length, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        width: _currentPage == index ? 12.0 : 8.0,
                        height: _currentPage == index ? 12.0 : 8.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                      );
                    }),
                  ),
                  _currentPage == pages.length - 1
                      ? TextButton(
                          onPressed: _completeOnboarding,
                          child: const Text('FINISH'),
                        )
                      : TextButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text('NEXT'),
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