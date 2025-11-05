# Device Selection Feature

## Overview

RivalTune now supports device selection! Since different SteelSeries mice have different supported commands (e.g., Rival 3 vs Rival 100), you can now select which mouse you're using to ensure compatibility.

## Features

### 1. **Auto-Detection**
- The app can automatically detect connected SteelSeries devices using `lsusb` (on Linux/macOS)
- Shows detected devices with a "Connected" badge
- USB device information display for troubleshooting

### 2. **Manual Selection**
- Complete list of supported SteelSeries devices
- Shows USB Vendor/Product IDs for each device
- Clear indication of which device is currently selected

### 3. **Device-Specific Commands**
- Each device model has its own list of supported commands
- View supported commands in the Settings page
- Link to official documentation for each device

## Supported Devices

The app supports the following SteelSeries mice:

- Rival 3
- Rival 100
- Rival 110
- Rival 300
- Rival 310
- Rival 500
- Rival 600
- Rival 650 Wireless
- Rival 700
- Sensei 310
- Sensei [RAW]
- Aerox 3

Each device has its USB Vendor ID (1038 for SteelSeries) and Product ID for auto-detection.

## How to Use

### From Home Page
1. Look for the device info banner at the top of the home page
2. Tap the banner to open Settings
3. Navigate to the Device Configuration section
4. Click "Change" to select your device

### From Settings Page
1. Click the Settings icon in the top-right corner of the home page
2. Find the "Device Configuration" section at the top
3. Click "Change" to open the device selection dialog

### Auto-Detection
1. Open the device selection dialog
2. The app will automatically scan for connected devices
3. If detected, your device will show with a "Connected" badge
4. Click "Select" on your device
5. Or click "View USB Device Details" to see raw `lsusb` output

### Manual Selection
1. If auto-detection doesn't find your device, scroll through the list
2. Find your device model (e.g., "Rival 3")
3. Tap to select it, or use the radio button
4. Click "Confirm" to save

## Technical Details

### Files Added/Modified

**New Files:**
- `lib/data/models/device.dart` - Device model and supported devices list
- `lib/services/device_detection_service.dart` - Auto-detection using lsusb
- `lib/presentation/dialogs/device_selection_dialog.dart` - Device selection UI
- `lib/presentation/widgets/device_info_banner.dart` - Home page device banner

**Modified Files:**
- `lib/services/rivalcfg_service.dart` - Added device tracking
- `lib/data/repositories/settings_repository.dart` - Added device persistence
- `lib/presentation/pages/home_page.dart` - Added device banner
- `lib/presentation/pages/settings_page.dart` - Added device selection section

### Device Detection

The device detection uses `lsusb` command to find connected USB devices:
```bash
lsusb | grep 1038  # SteelSeries vendor ID
```

The app parses the output to extract:
- USB Vendor ID (1038 for SteelSeries)
- USB Product ID (device-specific)
- Matches against the known device database

### Persistence

Selected device is saved to SharedPreferences and automatically restored on app restart.

### Command Validation

Each device has a list of supported commands. The RivalcfgService can check if a command is supported before execution:

```dart
if (_rivalcfg.isCommandSupported('strip_top_color')) {
  // Execute command
}
```

## Future Enhancements

Potential improvements:
- Add more device models as they become supported by rivalcfg
- Device-specific UI (hide/show controls based on device capabilities)
- Battery level display for wireless devices
- Device firmware version display
- More detailed device information from rivalcfg

## Documentation

For device-specific documentation, see:
- [rivalcfg Device List](https://flozz.github.io/rivalcfg/devices/index.html)
- Each device has its own documentation page with supported commands

## Troubleshooting

**Auto-detection not working?**
- Ensure `lsusb` is installed (`sudo apt install usbutils` on Ubuntu/Debian)
- Check if your device is connected and recognized by the system
- Try manual selection instead

**Device not in the list?**
- Check if your device is supported by rivalcfg
- Submit a feature request on GitHub
- Use the app without device selection (auto-detect mode)

**Commands not working?**
- Verify your device is selected correctly
- Check the supported commands list for your device
- Ensure udev rules are updated (see Settings page)
