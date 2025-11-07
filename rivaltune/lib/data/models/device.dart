/// Sensitivity configuration type for different devices
enum SensitivityType {
  /// Single sensitivity value or comma-separated list (e.g., Rival 3: -s 800,1600)
  single,

  /// Multiple separate flags (e.g., Rival 100: -s 1000 -S 2000)
  multiple,
}

/// Sensitivity configuration metadata
class SensitivityConfig {
  final SensitivityType type;
  final int maxPresets;
  final List<int> allowedValues;
  final int minValue;
  final int maxValue;

  const SensitivityConfig({
    required this.type,
    required this.maxPresets,
    this.allowedValues = const [],
    this.minValue = 200,
    this.maxValue = 8500,
  });

  /// Check if a value is valid for this device
  bool isValidValue(int value) {
    if (allowedValues.isNotEmpty) {
      return allowedValues.contains(value);
    }
    return value >= minValue && value <= maxValue;
  }
}

/// Represents a SteelSeries device that can be configured with rivalcfg
class Device {
  final String id;
  final String name;
  final String? usbVendorId;
  final String? usbProductId;
  final List<String> supportedCommands;
  final String docsUrl;
  final SensitivityConfig sensitivityConfig;

  const Device({
    required this.id,
    required this.name,
    this.usbVendorId,
    this.usbProductId,
    required this.supportedCommands,
    required this.docsUrl,
    this.sensitivityConfig = const SensitivityConfig(
      type: SensitivityType.single,
      maxPresets: 5,
    ),
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'usbVendorId': usbVendorId,
        'usbProductId': usbProductId,
        'supportedCommands': supportedCommands,
        'docsUrl': docsUrl,
      };

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        id: json['id'],
        name: json['name'],
        usbVendorId: json['usbVendorId'],
        usbProductId: json['usbProductId'],
        supportedCommands: List<String>.from(json['supportedCommands']),
        docsUrl: json['docsUrl'],
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Device && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Feature detection helper methods

  /// Check if device supports a specific command
  bool supportsCommand(String command) => supportedCommands.contains(command);

  /// Check if device supports LED strip zones (top, middle, bottom)
  bool get hasStripZones =>
      supportsCommand('strip_top_color') ||
      supportsCommand('strip_middle_color') ||
      supportsCommand('strip_bottom_color');

  /// Check if device supports logo color
  bool get hasLogoColor =>
      supportsCommand('logo_color') || supportsCommand('color');

  /// Check if device supports wheel color
  bool get hasWheelColor => supportsCommand('wheel_color');

  /// Check if device supports individual zone colors
  /// (returns false if device only has a single unified color)
  bool get hasMultipleZones => hasStripZones || (hasLogoColor && hasWheelColor);

  /// Check if device supports light effects
  bool get hasLightEffects =>
      supportsCommand('led_style') || supportsCommand('light_effect');

  /// Check if device supports RGB at all
  bool get hasRgb =>
      hasLogoColor ||
      hasWheelColor ||
      hasStripZones ||
      supportsCommand('color');

  /// Check if device supports polling rate
  bool get hasPollingRate => supportsCommand('polling_rate');

  /// Check if device supports battery level (wireless devices)
  bool get hasBattery => supportsCommand('battery_level');

  /// Get a list of available LED zones for this device
  List<String> get availableZones {
    final zones = <String>[];
    if (supportsCommand('strip_top_color')) zones.add('strip_top');
    if (supportsCommand('strip_middle_color')) zones.add('strip_middle');
    if (supportsCommand('strip_bottom_color')) zones.add('strip_bottom');
    if (supportsCommand('logo_color')) zones.add('logo');
    if (supportsCommand('wheel_color')) zones.add('wheel');
    if (supportsCommand('color') && zones.isEmpty) {
      zones.add('unified'); // Single color for whole device
    }
    return zones;
  }
}

/// Static list of supported SteelSeries devices
/// Based on https://flozz.github.io/rivalcfg/devices/index.html
class SupportedDevices {
  static const List<Device> all = [
    Device(
      id: 'rival3',
      name: 'Rival 3',
      usbVendorId: '1038',
      usbProductId: '1824',
      supportedCommands: [
        'sensitivity',
        'polling_rate',
        'strip_top_color', // z1
        'strip_middle_color', // z2
        'strip_bottom_color', // z3
        'logo_color', // z4
        'light_effect',
        'buttons_mapping',
      ],
      docsUrl: 'https://flozz.github.io/rivalcfg/devices/rival3.html',
      sensitivityConfig: SensitivityConfig(
        type: SensitivityType.single,
        maxPresets: 5,
        minValue: 200,
        maxValue: 8500,
      ),
    ),
    Device(
      id: 'rival100',
      name: 'Rival 100',
      usbVendorId: '1038',
      usbProductId: '1702',
      supportedCommands: [
        'sensitivity',
        'polling_rate',
        'color', // Unified color for LED
        'light_effect',
        'btn6_mode',
      ],
      docsUrl: 'https://flozz.github.io/rivalcfg/devices/rival100.html',
      sensitivityConfig: SensitivityConfig(
        type: SensitivityType.multiple,
        maxPresets: 2,
        allowedValues: [250, 500, 1000, 1250, 1500, 1750, 2000, 4000],
      ),
    ),
    Device(
      id: 'rival105',
      name: 'Rival 105',
      usbVendorId: '1038',
      usbProductId: '1814',
      supportedCommands: [
        'sensitivity',
        'polling_rate',
        'color', // Unified color for LED
        'light_effect',
        'btn6_mode',
      ],
      docsUrl: 'https://flozz.github.io/rivalcfg/devices/rival105.html',
      sensitivityConfig: SensitivityConfig(
        type: SensitivityType.multiple,
        maxPresets: 2,
        allowedValues: [250, 500, 1000, 1250, 1500, 1750, 2000, 4000],
      ),
    ),
  ];

  /// Find a device by its USB vendor and product ID
  static Device? findByUsbIds(String vendorId, String productId) {
    try {
      return all.firstWhere(
        (device) =>
            device.usbVendorId?.toLowerCase() == vendorId.toLowerCase() &&
            device.usbProductId?.toLowerCase() == productId.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Find a device by its ID
  static Device? findById(String id) {
    try {
      return all.firstWhere((device) => device.id == id);
    } catch (e) {
      return null;
    }
  }
}
