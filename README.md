# RivalTune

An easy to use SteelSeries mouse configuration tool for Linux using "rivalcfg" as the backend.

> **Note:** This project is still in its early stages of development. Features and stability are being actively improved.

## Supported Devices

Currently supported SteelSeries mice:
- **Rival 3**
- **Rival 100**
- **Rival 105**

More devices will be added in the future as development continues. 



##  Prerequisites

* Python 3.6 or later
* rivalcfg library
  * Installation:
    ```bash
    sudo pip3 install rivalcfg
    ```
* Update udev rules
  * Run the following command **as root**:
    ```bash
    sudo rivalcfg --update-udev
    ```

## Installation

### Pre-compiled Releases (Recommended)

Download the latest pre-compiled version from the [Releases](https://github.com/polydezcom/RivalTune/releases) page.

### Flatpak

Flatpak support is currently in testing and will be available soon.

## Usage

1. Download the latest release from the [Releases](https://github.com/polydezcom/RivalTune/releases) page
2. Extract the archive
3. Run the `rivaltune` executable
4. Configure your SteelSeries mouse with the intuitive GUI

**Note:** Make sure you have completed the prerequisites setup (Python 3.6+, rivalcfg, and udev rules) before running RivalTune.

## Screenshot

![Alt Text](https://github.com/berkiyo/rivaltune/blob/main/screenshots/rivaltune-screenshot-1.png "Screenshot")


## Contributing

We encourage contributions to this project! If you have any improvements or suggestions, please feel free to open an issue or pull request on GitHub.

RivalTune is built with **Flutter for Linux**. If you encounter any issues or have feature requests, please don't hesitate to reach out.

## License

GPL-v3
