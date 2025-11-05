# RivalTune

A modern, easy-to-use mouse configuration software for SteelSeries Mice on Linux.

## Features

### 🎨 RGB Lighting Control
- Control individual LED zones (Top, Middle, Bottom strips + Logo)
- Multiple lighting effects (Rainbow, Breath, Disco, Steady, etc.)
- Custom color presets
- Built-in preset library

### 🖱️ Device Management
- **Auto-Detection**: Automatically detect connected SteelSeries devices
- **Manual Selection**: Choose from 12+ supported device models
- **Device-Specific Features**: Shows supported commands for each device
- See [DEVICE_SELECTION.md](DEVICE_SELECTION.md) for details

### 🎯 Multiple DPI Sensitivity Presets
- **Up to 5 DPI presets** (200-8500 DPI range)
- Slider + manual input for precise control
- Easy add/remove presets
- Automatic migration from single sensitivity
- See [MULTI_DPI_PRESETS.md](MULTI_DPI_PRESETS.md) for details

### ⚙️ Additional Features
- Polling rate configuration
- RGB on/off toggle
- Settings persistence across restarts
- Onboarding guide for first-time setup
- udev rules helper for Linux permissions

## Supported Devices

- Rival 3, 100, 110, 300, 310, 500, 600, 650, 700
- Sensei 310, Sensei [RAW]
- Aerox 3
- More devices supported by [rivalcfg](https://github.com/flozz/rivalcfg)

## Installation

### Prerequisites
- **Linux** (primary platform)
- **Python 3** with `venv` module
- **Git**
- **Flutter** (for building from source)

### First Run
1. Launch RivalTune
2. The app will automatically:
   - Clone the rivalcfg repository
   - Create a Python virtual environment
   - Install rivalcfg
3. Follow the onboarding guide to set up udev rules

### Manual udev Setup (Required on Linux)
```bash
sudo /path/to/rivalcfg --update-udev
```
This allows the app to communicate with your mouse without requiring root privileges.

## Building from Source

```bash
# Clone the repository
git clone https://github.com/berkiyo/RivalTune.git
cd rivaltune

# Get dependencies
flutter pub get

# Run the app
flutter run -d linux

# Or build a release
flutter build linux
```

## Usage

1. **Connect your SteelSeries mouse**
2. **Select your device** (or let it auto-detect)
3. **Configure settings:**
   - Set up DPI presets
   - Customize RGB colors and effects
   - Apply presets or create your own
4. **Click Apply** to save changes to your mouse

## Project Structure

```
lib/
├── core/              # Constants and utilities
├── data/              # Models and repositories
│   ├── models/        # Device, ColorPreset models
│   └── repositories/  # Settings persistence
├── presentation/      # UI components
│   ├── pages/         # Home, Settings, Onboarding
│   ├── widgets/       # Reusable UI widgets
│   └── dialogs/       # Color picker, Device selection
└── services/          # rivalcfg, Device detection
```

## Documentation

- [Device Selection Feature](DEVICE_SELECTION.md)
- [Multiple DPI Presets](MULTI_DPI_PRESETS.md)

## Technologies

- **Flutter** - Cross-platform UI framework
- **rivalcfg** - Python tool for SteelSeries device configuration
- **process_run** - Shell command execution
- **shared_preferences** - Settings persistence

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Credits

- Built by [berkiyo](https://github.com/berkiyo)
- Uses [rivalcfg](https://github.com/flozz/rivalcfg) by flozz
- SteelSeries mouse documentation: [rivalcfg docs](https://flozz.github.io/rivalcfg/)

## License

[Add your license here]

## Troubleshooting

### Device not detected?
- Check USB connection
- Run `lsusb | grep 1038` to verify device is recognized
- Try manual device selection in Settings

### Permission errors?
- Update udev rules via Settings page
- Unplug and replug your mouse after updating rules

### RGB not working?
- Ensure device supports RGB (not all models do)
- Check selected device matches your actual mouse
- Verify udev rules are set up correctly

### App won't start?
- Ensure Python 3 and Git are installed
- Check internet connection (needed for initial rivalcfg download)
- View terminal output for specific error messages

## Getting Started with Flutter

If this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Online documentation](https://docs.flutter.dev/)

