# Multiple DPI Sensitivity Presets

## Overview

RivalTune now supports configuring multiple DPI sensitivity presets, with **device-specific adaptations** for different mouse models. The app automatically adjusts the UI and command format based on your selected device!

## Features

### Multiple DPI Presets
- Add between 1 and 5 DPI presets (device-dependent)
- **Rival 3, 110, 310, etc**: Range 200-8500 DPI, up to 5 presets
- **Rival 100**: Specific values (250, 500, 1000, 1250, 1500, 1750, 2000, 4000), up to 2 presets
- Default presets vary by device

### Device-Specific UI
- **Slider Controls**: For devices with continuous DPI ranges (Rival 3, 110, etc.)
- **Dropdown Selectors**: For devices with specific allowed values (Rival 100)
- Automatic adjustment when switching devices

### Easy Management
- **Add/Remove**: Easily add or remove presets within device limits
- **Manual Input**: Type exact DPI values (for slider-based devices)
- **Visual Feedback**: Numbered presets with color-coded indicators

## Supported Devices & Configurations

### Rival 3
- **Type**: Comma-separated list
- **Command**: `-s 800,1600,3200`
- **Max Presets**: 5
- **Range**: 200-8500 DPI
- **Default**: 800, 1600

### Rival 100 ⭐ NEW
- **Type**: Separate flags
- **Command**: `-s 1000 -S 2000`
- **Max Presets**: 2 (sensitivity1 and sensitivity2)
- **Allowed Values**: 250, 500, 1000, 1250, 1500, 1750, 2000, 4000 DPI
- **Default**: 1000, 2000
- **UI**: Dropdown selectors

### Rival 110
- **Type**: Comma-separated list
- **Command**: `-s 800,1600,3200`
- **Max Presets**: 5
- **Range**: 200-7200 DPI
- **Default**: 800, 1600

### Other Models
Most other Rival and Sensei mice follow similar patterns. Check device documentation for specifics.

## How to Use

### Accessing DPI Settings
1. Open RivalTune
2. Scroll down to the "DPI Sensitivity Presets" card
3. You'll see your current presets listed

### Adjusting DPI Values

**Using the Slider:**
1. Drag the slider left (lower DPI) or right (higher DPI)
2. The DPI value updates in real-time
3. Click "Apply" to save to your mouse

**Using Manual Input:**
1. Click in the text field showing the DPI value
2. Type your desired DPI (200-8500)
3. Press Enter
4. Click "Apply" to save to your mouse

### Adding Presets
1. Click "Add DPI Preset" button at the bottom
2. A new preset will be added:
   - **Rival 3/110/etc**: Default 800 DPI
   - **Rival 100**: Default 1000 DPI (first allowed value)
3. Adjust it as needed
4. Maximum presets vary by device (2-5)

### Adjusting DPI Values

#### For Slider-Based Devices (Rival 3, 110, etc)
**Using the Slider:**
1. Drag the slider left (lower DPI) or right (higher DPI)
2. The DPI value updates in real-time
3. Click "Apply" to save to your mouse

**Using Manual Input:**
1. Click in the text field showing the DPI value
2. Type your desired DPI (within device range)
3. Press Enter
4. Click "Apply" to save to your mouse

#### For Dropdown Devices (Rival 100)
1. Click the dropdown menu next to the DPI value
2. Select from the allowed values
3. Click "Apply" to save to your mouse

## Examples

### Gaming Setup
Set multiple presets for different game scenarios:
1. **400 DPI** - Precise aiming (sniping)
2. **800 DPI** - General gaming
3. **1600 DPI** - Fast-paced action
4. **3200 DPI** - Quick turns

### Work/Productivity
Set presets for different tasks:
1. **800 DPI** - Standard desktop use
2. **1200 DPI** - Design work
3. **1600 DPI** - Large displays

### Minimal Setup
Keep it simple with just two presets:
1. **800 DPI** - Normal use
2. **1600 DPI** - High sensitivity

## Migration from Old Version

If you were using the old single-sensitivity slider:
- Your previous DPI setting is automatically preserved
- A second preset of 1600 DPI is added (Rival 3 default)
- You can remove the second preset if you only want one

## UI Components

### New Widget: `MultiSensitivityEditor`
Replaces the old `SensitivitySlider` with a more powerful interface:
- Multiple preset management
- Combined slider + text input
- Add/remove functionality
- Visual preset numbering
- Compact, card-based layout

### Updated Services
- **RivalcfgService**: New `setSensitivities(List<int>)` method
- **SettingsRepository**: New `saveSensitivities()`/`getSensitivities()` methods
- Backward compatible with single sensitivity

## Troubleshooting

**Presets not working?**
- Ensure you clicked "Apply" after making changes
- Check that your device supports multiple DPI presets
- Verify udev rules are updated (Settings page)

**Can't add more presets?**
- Check your device's maximum preset count (Rival 100: 2, Most others: 5)
- This is a hardware limitation, not a software bug

**Rival 100 only shows dropdown?**
- This is correct! Rival 100 only supports specific DPI values
- Select from: 250, 500, 1000, 1250, 1500, 1750, 2000, 4000

**DPI button not cycling presets?**
- Check if your mouse has a physical DPI button
- Some mice require button remapping (see device docs)
- Try unplugging and replugging the mouse

**Values changed after switching devices?**
- This is automatic! Values are mapped to work with the new device
- Rival 100 only supports specific values, so values are adjusted

**Values reverting after restart?**
- This shouldn't happen - settings are auto-saved
- If it does, there may be a permissions issue with SharedPreferences
- Check app data storage permissions

## Technical Implementation

### Command Formats by Device

**Standard Devices (Comma-Separated)**
```bash
# Rival 3, 110, 310, 600, Sensei 310, etc.
rivalcfg -s 400,800,1600,3200
```

**Rival 100 (Separate Flags)**
```bash
# Uses -s for sensitivity1 and -S for sensitivity2
rivalcfg -s 1000 -S 2000
```

### Device Configuration

The `Device` model includes a `SensitivityConfig` that defines:
- **type**: `single` (comma-separated) or `multiple` (separate flags)
- **maxPresets**: Maximum number of presets (2-5)
- **allowedValues**: Specific allowed values (empty = continuous range)
- **minValue/maxValue**: Range limits for continuous values

### Automatic Value Mapping

When switching devices, `getSensitivitiesForDevice()` automatically:
1. Limits presets to device maximum
2. Maps values to nearest allowed value (for restricted devices)
3. Uses device-specific defaults if no values exist

Example: If you have [400, 850, 1700] on Rival 3 and switch to Rival 100:
- 400 → 500 (nearest allowed)
- 850 → 1000 (nearest allowed)
- 1700 → 1750 (nearest allowed)
- Limited to 2 presets: [500, 1000]

### Device Compatibility Table

| Device | Max Presets | Range/Values | UI Type | Command |
|--------|-------------|--------------|---------|---------|
| Rival 3 | 5 | 200-8500 DPI | Slider | `-s 800,1600,...` |
| Rival 100 | 2 | 250,500,1000,1250,1500,1750,2000,4000 | Dropdown | `-s 1000 -S 2000` |
| Rival 110 | 5 | 200-7200 DPI | Slider | `-s 800,1600,...` |
| Rival 300/310 | 5 | Variable | Slider | `-s 800,1600,...` |
| Rival 600/650 | 5 | Variable | Slider | `-s 800,1600,...` |
| Sensei 310 | 5 | Variable | Slider | `-s 800,1600,...` |

## Future Enhancements

Possible improvements:
- Per-preset color indicators on the mouse
- Preset naming (e.g., "Sniper", "Gaming", "Desktop")
- Quick preset switching from the app
- Preset profiles tied to different devices
- Import/export preset configurations
