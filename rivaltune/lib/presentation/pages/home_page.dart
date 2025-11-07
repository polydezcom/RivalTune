import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:window_size/window_size.dart';
// For running shell commands
import '../../data/models/color_preset.dart';
import '../../data/repositories/settings_repository.dart';
import '../../services/rivalcfg_service.dart';
import '../widgets/color_zone_tile.dart';
import '../widgets/effect_selector.dart';
import '../widgets/preset_selector.dart';
import '../widgets/rgb_switch.dart';
import '../widgets/multi_sensitivity_editor.dart';
import '../widgets/device_info_banner.dart';
// ...existing code...
import '../dialogs/color_picker_dialog.dart';
import '../dialogs/preset_name_dialog.dart';
import './settings_page.dart'; // Import the new settings page
import 'package:shared_preferences/shared_preferences.dart';
import './onboarding_page.dart'; // Import OnboardingPage

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final RivalcfgService _rivalcfg;
  late final SettingsRepository _settings;
  bool _isLoading = true;
  String _loadingMessage = 'Initializing...';
  bool _udevIssueDetected = false; // New state variable

  // Device state
  List<int> _currentSensitivities = [800, 1600];
  Color _currentTopColor = Colors.red;
  Color _currentMiddleColor = Colors.lime;
  Color _currentBottomColor = Colors.blue;
  Color _currentLogoColor = Colors.purple;
  Color _currentWheelColor = Colors.orange;
  String _currentEffect = 'steady';
  bool _isRgbEnabled = true;

  // UI state
  List<int> _pendingSensitivities = [800, 1600];
  Color _pendingTopColor = Colors.red;
  Color _pendingMiddleColor = Colors.lime;
  Color _pendingBottomColor = Colors.blue;
  Color _pendingLogoColor = Colors.purple;
  Color _pendingWheelColor = Colors.orange;
  String _pendingEffect = 'steady';
  List<ColorPreset> _customPresets = [];

  final List<ColorPreset> _builtInPresets = [
    ColorPreset(
      name: 'Rainbow',
      topColor: Colors.red,
      middleColor: Colors.green,
      bottomColor: Colors.blue,
      logoColor: Colors.purple,
      effect: 'rainbow-shift',
    ),
    ColorPreset(
      name: 'Fire',
      topColor: Colors.red,
      middleColor: Colors.orange,
      bottomColor: Colors.yellow,
      logoColor: Colors.deepOrange,
      effect: 'breath-fast',
    ),
    ColorPreset(
      name: 'Ocean',
      topColor: Colors.blue,
      middleColor: Colors.cyan,
      bottomColor: Colors.lightBlue,
      logoColor: Colors.indigo,
      effect: 'breath-slow',
    ),
    ColorPreset(
      name: 'Forest',
      topColor: Colors.green,
      middleColor: Colors.lightGreen,
      bottomColor: Colors.lime,
      logoColor: Colors.green,
    ),
    ColorPreset(
      name: 'Sunset',
      topColor: Colors.deepOrange,
      middleColor: Colors.orange,
      bottomColor: Colors.amber,
      logoColor: Colors.red,
    ),
    ColorPreset(
      name: 'Cyberpunk',
      topColor: Colors.pink,
      middleColor: Colors.cyan,
      bottomColor: Colors.yellow,
      logoColor: Colors.purple,
      effect: 'disco',
    ),
    ColorPreset(
      name: 'Arctic',
      topColor: Colors.lightBlue,
      middleColor: Colors.white,
      bottomColor: Colors.blue.shade100,
      logoColor: Colors.blue,
      effect: 'breath-slow',
    ),
    ColorPreset(
      name: 'Neon',
      topColor: Colors.purple,
      middleColor: Colors.pink,
      bottomColor: Colors.blue,
      logoColor: Colors.deepPurple,
      effect: 'rainbow-breath',
    ),
    ColorPreset(
      name: 'Gold',
      topColor: Colors.amber,
      middleColor: Colors.yellow,
      bottomColor: Colors.orange,
      logoColor: Colors.amber.shade900,
    ),
    ColorPreset(
      name: 'Matrix',
      topColor: Colors.green,
      middleColor: Colors.lightGreen,
      bottomColor: Colors.lime,
      logoColor: Colors.green.shade900,
      effect: 'breath-fast',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _restoreWindowSize();
    _initializeAsyncDependenciesAndSettings();
  }

  @override
  void dispose() {
    _saveWindowSize();
    super.dispose();
  }

  Future<void> _restoreWindowSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final double? width = prefs.getDouble('window_width');
      final double? height = prefs.getDouble('window_height');

      if (width != null && height != null) {
        final window = await getWindowInfo();
        if (window.screen != null) {
          setWindowFrame(Rect.fromLTWH(
            window.frame.left,
            window.frame.top,
            width,
            height,
          ));
        }
      }
    } catch (e) {
      // Silently fail if window size restoration doesn't work
      // print('Failed to restore window size: $e');
    }
  }

  Future<void> _saveWindowSize() async {
    try {
      final window = await getWindowInfo();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('window_width', window.frame.width);
      await prefs.setDouble('window_height', window.frame.height);
    } catch (e) {
      // Silently fail if window size saving doesn't work
      // print('Failed to save window size: $e');
    }
  }

  Future<void> _runProcess(String executable, List<String> arguments,
      String workingDirectory, String stepName) async {
    setState(() {
      _loadingMessage = 'Running: $stepName...';
    });
    // print('Executing: $executable ${arguments.join(' ')} in $workingDirectory');
    try {
      final ProcessResult result = await Process.run(executable, arguments,
          workingDirectory: workingDirectory);
      if (result.exitCode != 0) {
        // print('$stepName failed. Exit code: ${result.exitCode}, Stdout: ${result.stdout}, Stderr: ${result.stderr}');
        throw Exception(
            '$stepName failed.\nStdout: ${result.stdout}\nStderr: ${result.stderr}');
      }
      // print('$stepName Succeeded. Stdout: ${result.stdout}');
    } catch (e) {
      // print('Exception during $stepName: $e');
      rethrow; // Rethrow to be caught by the main initialization logic
    }
  }

  Future<void> _checkAndShowOnboarding() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool onboardingComplete =
        prefs.getBool(OnboardingPage.onboardingCompleteKey) ?? false;

    if (!onboardingComplete && mounted) {
      // print("Onboarding not complete, navigating to OnboardingPage.");
      // We use pushReplacement to prevent going back to an empty HomePage during initial loading
      // However, HomePage is already the root if we are here after _isLoading is false.
      // So, a normal push that replaces the current route might be okay, or ensuring HomePage doesn't build its main UI yet.
      // For now, let's use pushReplacement. This assumes HomePage might be briefly visible.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OnboardingPage(rivalcfgService: _rivalcfg),
        ),
      );
    }
  }

  Future<void> _showDisclaimerDialog() async {
    // Show disclaimer on every app launch
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text('Welcome to RivalTune!'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ Testing Phase',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This app is still in the testing phase, so some issues may still occur. More devices will be supported soon!',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  '🐛 Issues or Feature Requests?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'If you run into any issues or have any feature requests, please open an issue on the GitHub repository:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    // Copy URL to clipboard
                    Clipboard.setData(
                      const ClipboardData(
                        text: 'https://github.com/polydezcom/RivalTune/issues',
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.link, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'github.com/polydezcom/RivalTune/issues',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Icon(Icons.content_copy,
                            size: 14, color: Colors.blue[700]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Thanks for trying out RivalTune! 🎉',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Got it!'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _initializeAsyncDependenciesAndSettings() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Preparing rivalcfg environment...';
    });

    try {
      final Directory appSupportDir = await getApplicationSupportDirectory();
      // Path where the rivalcfg repository will be cloned and set up
      final String rivalcfgToolPath =
          p.join(appSupportDir.path, 'rivalcfg_tool');
      final Directory rivalcfgToolDir = Directory(rivalcfgToolPath);

      final String rivalcfgExecutableName =
          Platform.isWindows ? 'rivalcfg.exe' : 'rivalcfg';
      final String pipExecutableName = Platform.isWindows ? 'pip.exe' : 'pip';
      final String pythonExecutableName =
          Platform.isWindows ? 'python.exe' : 'python3'; // Or just 'python'

      final String expectedRivalcfgEnvPath =
          p.join(rivalcfgToolPath, 'rivalcfg.env');
      final String expectedPipPath = Platform.isWindows
          ? p.join(expectedRivalcfgEnvPath, 'Scripts', pipExecutableName)
          : p.join(expectedRivalcfgEnvPath, 'bin', pipExecutableName);
      final String expectedRivalcfgExecutablePath = Platform.isWindows
          ? p.join(expectedRivalcfgEnvPath, 'Scripts', rivalcfgExecutableName)
          : p.join(expectedRivalcfgEnvPath, 'bin', rivalcfgExecutableName);

      if (!await File(expectedRivalcfgExecutablePath).exists()) {
        setState(() {
          _loadingMessage = 'rivalcfg not found. Attempting installation...';
        });

        if (await rivalcfgToolDir.exists()) {
          // print('Cleaning up previous rivalcfg_tool directory...');
          await rivalcfgToolDir.delete(recursive: true);
        }
        await rivalcfgToolDir.create(recursive: true);

        // 1. Git Clone
        // print('Cloning rivalcfg repository...');
        await _runProcess(
            'git',
            ['clone', 'https://github.com/flozz/rivalcfg.git', '.'],
            rivalcfgToolPath,
            'Git Clone');

        // 2. Create Python Virtual Environment
        // print('Creating Python virtual environment...');
        await _runProcess(pythonExecutableName, ['-m', 'venv', 'rivalcfg.env'],
            rivalcfgToolPath, 'Create venv');

        // 3. Pip Install rivalcfg using the virtual environment's pip
        // print('Installing rivalcfg via pip...');
        await _runProcess(expectedPipPath, ['install', 'rivalcfg'],
            rivalcfgToolPath, 'Pip Install');

        // 4. Set Executable Permissions (Linux/macOS)
        if (!Platform.isWindows) {
          // print('Setting executable permissions for rivalcfg...');
          await _runProcess('chmod', ['+x', expectedRivalcfgExecutablePath],
              rivalcfgToolPath, 'Chmod rivalcfg');

          // 5. Update udev rules (Linux only)
          // print('Updating udev rules...');
          setState(() {
            _loadingMessage = 'Updating system permissions (udev rules)...';
          });
          try {
            await _runProcess(
                'sudo',
                [expectedRivalcfgExecutablePath, '--update-udev'],
                rivalcfgToolPath,
                'Update udev rules');
          } catch (e) {
            // print('Udev update failed, user will need to run it manually: $e');
            // We'll handle this in the verification step below
          }
        }
        // print('rivalcfg installation process completed.');
      } else {
        // print('rivalcfg already installed at $expectedRivalcfgExecutablePath');
      }

      _rivalcfg = RivalcfgService(rivalcfgDirectoryPath: rivalcfgToolPath);
      _settings = SettingsRepository();

      await _settings.init();

      // Load saved device and set it in the service
      final savedDevice = _settings.getSelectedDevice();
      if (savedDevice != null) {
        _rivalcfg.setSelectedDevice(savedDevice);
      }

      // Attempt a benign command to check rivalcfg and udev status early
      try {
        setState(() {
          _loadingMessage = 'Verifying device access...';
        });
        await _rivalcfg.setSensitivity(_settings
            .getSensitivity()); // Or another simple get command if available
        // print("Initial device access check successful.");
      } catch (e) {
        // print("Initial device access check failed: $e");
        if (e.toString().toLowerCase().contains("udev") ||
            e.toString().toLowerCase().contains("permission denied")) {
          // print("Udev issue detected during initial check.");
          setState(() {
            _udevIssueDetected = true;
            _loadingMessage =
                'Device permission issue detected. Please check Settings (top-right icon) for udev instructions.';
          });
        }
        // Don't rethrow here, let the app load, but with the error message.
      }

      // Load settings into UI state
      _pendingTopColor = _currentTopColor = _settings.getTopColor();
      _pendingMiddleColor = _currentMiddleColor = _settings.getMiddleColor();
      _pendingBottomColor = _currentBottomColor = _settings.getBottomColor();
      _pendingLogoColor = _currentLogoColor = _settings.getLogoColor();
      _pendingEffect = _currentEffect = _settings.getEffect();
      _pendingSensitivities =
          _currentSensitivities = _settings.getSensitivities();
      _isRgbEnabled = _settings.getRgbEnabled();
      _customPresets = _settings.getCustomPresets();

      setState(() {
        _isLoading = false;
        if (!_udevIssueDetected) {
          // Clear loading message only if no udev issue
          _loadingMessage = '';
        }
      });

      // After all initialization and loading, check for onboarding
      // Ensure _rivalcfg is initialized before calling this
      if (!_isLoading) {
        // print("Initialization complete. Checking onboarding status...");
        await _checkAndShowOnboarding();
        // Show disclaimer dialog after onboarding
        await _showDisclaimerDialog();
      } else if (_isLoading) {
        // print("Skipping onboarding check as page is still loading or rivalcfg not ready.");
      } else {
        // print("Skipping onboarding check as rivalcfg is null even after loading.");
        // This case might indicate a severe failure in rivalcfg init that didn't throw an exception caught above.
        // The general error message from the catch block should cover this.
      }
    } catch (e) {
      // print('Error during initialization: $e');
      setState(() {
        _isLoading = false;
        _loadingMessage =
            'Initialization failed: ${e.toString()}\nPlease ensure Git and Python3 (with venv) are installed and in your PATH, then restart the app.';
        _udevIssueDetected = false; // Reset udev flag on general init failure
      });
      // No onboarding check if core initialization fails
    }
  }

  Future<void> _applyZoneColor(int zone, Color color) async {
    String? zoneFlag;
    final device = _settings.getSelectedDevice();

    switch (zone) {
      case 1: // Top strip
        if (device?.supportsCommand('strip_top_color') ?? true) {
          zoneFlag = 'strip-top-color';
          _currentTopColor = color;
        }
      case 2: // Middle strip
        if (device?.supportsCommand('strip_middle_color') ?? true) {
          zoneFlag = 'strip-middle-color';
          _currentMiddleColor = color;
        }
      case 3: // Bottom strip
        if (device?.supportsCommand('strip_bottom_color') ?? true) {
          zoneFlag = 'strip-bottom-color';
          _currentBottomColor = color;
        }
      case 4: // Logo
        if (device?.supportsCommand('logo_color') ?? true) {
          zoneFlag = 'logo-color';
          _currentLogoColor = color;
        }
      case 5: // Wheel
        if (device?.supportsCommand('wheel_color') ?? false) {
          zoneFlag = 'wheel-color';
          _currentWheelColor = color;
        }
      case 6: // Unified color (e.g., Rival 100)
        if (device?.supportsCommand('color') ?? false) {
          zoneFlag = 'color';
          _currentLogoColor = color;
        }
      default:
        return;
    }

    if (zoneFlag == null) return;

    try {
      await _rivalcfg.setZoneColor(zoneFlag, color);
      await _settings.saveColors(
        topColor: _currentTopColor,
        middleColor: _currentMiddleColor,
        bottomColor: _currentBottomColor,
        logoColor: _currentLogoColor,
        wheelColor: _currentWheelColor,
      );
    } catch (e) {
      // print("Error applying zone color: $e");
      if (e.toString().toLowerCase().contains("udev") ||
          e.toString().toLowerCase().contains("permission denied")) {
        setState(() {
          _udevIssueDetected = true;
          _loadingMessage =
              'Device permission issue detected. Please update udev rules via Settings (top-right icon).';
        });
      }
      // Show a snackbar or dialog maybe?
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Failed to apply color. ${_udevIssueDetected ? _loadingMessage : e.toString()}')),
      );
    }
  }

  Future<void> _saveCurrentAsPreset() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => PresetNameDialog(controller: controller),
    );

    if (name != null && name.isNotEmpty) {
      setState(() {
        _customPresets.add(ColorPreset(
          name: name,
          topColor: _pendingTopColor,
          middleColor: _pendingMiddleColor,
          bottomColor: _pendingBottomColor,
          logoColor: _pendingLogoColor,
          effect: _pendingEffect,
        ));
      });
      await _settings.saveCustomPresets(_customPresets);
    }
  }

  /// Get the title for the LED zones card based on device capabilities
  String _getZoneCardTitle() {
    final device = _settings.getSelectedDevice();
    if (device == null) return 'LED Zones';

    if (device.hasStripZones) {
      return 'LED Zones';
    } else if (device.availableZones.length == 1) {
      return 'LED Color';
    } else {
      return 'LED Colors';
    }
  }

  /// Build zone tiles based on device capabilities
  List<Widget> _buildZoneTiles() {
    final device = _settings.getSelectedDevice();
    final tiles = <Widget>[];

    // If no device selected, show all zones (default behavior)
    if (device == null) {
      return [
        ColorZoneTile(
          label: 'Top Strip',
          color: _pendingTopColor,
          onTap: () => _showColorPicker(1, _pendingTopColor),
        ),
        const Divider(height: 1),
        ColorZoneTile(
          label: 'Middle Strip',
          color: _pendingMiddleColor,
          onTap: () => _showColorPicker(2, _pendingMiddleColor),
        ),
        const Divider(height: 1),
        ColorZoneTile(
          label: 'Bottom Strip',
          color: _pendingBottomColor,
          onTap: () => _showColorPicker(3, _pendingBottomColor),
        ),
        const Divider(height: 1),
        ColorZoneTile(
          label: 'Logo',
          color: _pendingLogoColor,
          onTap: () => _showColorPicker(4, _pendingLogoColor),
        ),
      ];
    }

    // Build tiles based on available zones
    final zones = device.availableZones;
    bool needsDivider = false;

    for (final zone in zones) {
      if (needsDivider) {
        tiles.add(const Divider(height: 1));
      }

      switch (zone) {
        case 'strip_top':
          tiles.add(ColorZoneTile(
            label: 'Top Strip',
            color: _pendingTopColor,
            onTap: () => _showColorPicker(1, _pendingTopColor),
          ));
          needsDivider = true;
          break;
        case 'strip_middle':
          tiles.add(ColorZoneTile(
            label: 'Middle Strip',
            color: _pendingMiddleColor,
            onTap: () => _showColorPicker(2, _pendingMiddleColor),
          ));
          needsDivider = true;
          break;
        case 'strip_bottom':
          tiles.add(ColorZoneTile(
            label: 'Bottom Strip',
            color: _pendingBottomColor,
            onTap: () => _showColorPicker(3, _pendingBottomColor),
          ));
          needsDivider = true;
          break;
        case 'logo':
          tiles.add(ColorZoneTile(
            label: 'Logo',
            color: _pendingLogoColor,
            onTap: () => _showColorPicker(4, _pendingLogoColor),
          ));
          needsDivider = true;
          break;
        case 'wheel':
          tiles.add(ColorZoneTile(
            label: 'Scroll Wheel',
            color: _pendingWheelColor,
            onTap: () => _showColorPicker(5, _pendingWheelColor),
          ));
          needsDivider = true;
          break;
        case 'unified':
          tiles.add(ColorZoneTile(
            label: 'LED Color',
            color: _pendingLogoColor, // Using logo color for unified
            onTap: () => _showColorPicker(6, _pendingLogoColor),
          ));
          needsDivider = true;
          break;
      }
    }

    return tiles;
  }

  void _showColorPicker(int zone, Color currentColor) {
    Color pendingColor = currentColor;

    showDialog(
      context: context,
      builder: (context) => ColorPickerDialog(
        zone: zone,
        currentColor: currentColor,
        onColorChanged: (color) {
          pendingColor = color;
          setState(() {
            switch (zone) {
              case 1:
                _pendingTopColor = color;
              case 2:
                _pendingMiddleColor = color;
              case 3:
                _pendingBottomColor = color;
              case 4:
                _pendingLogoColor = color;
              case 5:
                _pendingWheelColor = color;
              case 6:
                _pendingLogoColor = color; // Unified uses logo color
            }
          });
        },
        onApply: () => _applyZoneColor(zone, pendingColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'SteelSeries Configurator',
            style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(_loadingMessage, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    // Display persistent message if udev issue or critical init error
    final String persistentMessage = _udevIssueDetected
        ? 'Device permission issue: Please see Settings (top-right icon) for udev update instructions.'
        : (_loadingMessage.isNotEmpty && !_isLoading ? _loadingMessage : '');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SteelSeries Configurator',
          style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings & Troubleshooting',
            onPressed: () {
              if (!_isLoading) {
                // Ensure rivalcfg is initialized
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(
                      rivalcfgService: _rivalcfg,
                      settingsRepository: _settings,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Service not yet initialized. Please wait.')),
                );
              }
            },
          ),
        ],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Get the selected device once for use throughout the widget tree
              Builder(
                builder: (context) {
                  final device = _settings.getSelectedDevice();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (persistentMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8.0),
                                border:
                                    Border.all(color: Colors.orange.shade300)),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Colors.orange.shade800, size: 28),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    persistentMessage,
                                    style: TextStyle(
                                        color: Colors.orange.shade900,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      DeviceInfoBanner(
                        device: _settings.getSelectedDevice(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsPage(
                                rivalcfgService: _rivalcfg,
                                settingsRepository: _settings,
                              ),
                            ),
                          ).then((_) {
                            // Refresh the page when coming back from settings
                            setState(() {});
                          });
                        },
                      ),
                      if (device?.hasRgb ?? true) ...[
                        RgbSwitch(
                          value: _isRgbEnabled,
                          onChanged: (enabled) async {
                            if (enabled) {
                              await _rivalcfg.setAllZones(
                                topColor: _pendingTopColor,
                                middleColor: _pendingMiddleColor,
                                bottomColor: _pendingBottomColor,
                                logoColor: _pendingLogoColor,
                                effect: _pendingEffect,
                              );
                            } else {
                              await _rivalcfg.turnOffLights();
                            }
                            setState(() => _isRgbEnabled = enabled);
                            await _settings.saveRgbEnabled(enabled);
                          },
                        ),
                        const SizedBox(height: 8),

                        // ...existing code...

                        PresetSelector(
                          builtInPresets: _builtInPresets,
                          customPresets: _customPresets,
                          onPresetSelected: (preset) async {
                            if (preset != null) {
                              setState(() {
                                _pendingTopColor = preset.topColor;
                                _pendingMiddleColor = preset.middleColor;
                                _pendingBottomColor = preset.bottomColor;
                                _pendingLogoColor = preset.logoColor;
                                _pendingEffect = preset.effect;
                              });
                              if (_isRgbEnabled) {
                                await _rivalcfg.setAllZones(
                                  topColor: preset.topColor,
                                  middleColor: preset.middleColor,
                                  bottomColor: preset.bottomColor,
                                  logoColor: preset.logoColor,
                                  effect: preset.effect,
                                );
                                await _settings.saveColors(
                                  topColor: preset.topColor,
                                  middleColor: preset.middleColor,
                                  bottomColor: preset.bottomColor,
                                  logoColor: preset.logoColor,
                                );
                                await _settings.saveEffect(preset.effect);
                              }
                            }
                          },
                          onSavePressed: _saveCurrentAsPreset,
                          onDeletePreset: (preset) async {
                            setState(() {
                              _customPresets.remove(preset);
                            });
                            await _settings.saveCustomPresets(_customPresets);
                          },
                        ),
                      ] else ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.grey[600]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    device == null
                                        ? 'Select a device in settings to configure RGB lighting'
                                        : 'This device does not support RGB lighting',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),

                      // LED Zones - Only show if device has RGB capabilities
                      if (_settings.getSelectedDevice()?.hasRgb ?? true) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getZoneCardTitle(),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                ..._buildZoneTiles(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Light Effects - Only show if device supports effects
                      if (_settings.getSelectedDevice()?.hasLightEffects ??
                          true) ...[
                        EffectSelector(
                          value: _pendingEffect,
                          onChanged: (effect) {
                            if (effect != null) {
                              setState(() => _pendingEffect = effect);
                            }
                          },
                          onApply: () async {
                            await _rivalcfg.setEffect(_pendingEffect);
                            await _settings.saveEffect(_pendingEffect);
                            setState(() => _currentEffect = _pendingEffect);
                          },
                        ),
                        const SizedBox(height: 8),
                      ],

                      MultiSensitivityEditor(
                        sensitivities: _pendingSensitivities,
                        device: device,
                        onChanged: (sensitivities) {
                          setState(() => _pendingSensitivities = sensitivities);
                        },
                        onApply: () async {
                          await _rivalcfg
                              .setSensitivities(_pendingSensitivities);
                          await _settings
                              .saveSensitivities(_pendingSensitivities);
                          setState(() => _currentSensitivities =
                              List.from(_pendingSensitivities));
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
