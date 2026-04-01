/* devices.rs
 *
 * Copyright 2026 berk
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/// Describes a color zone on a mouse (what CLI flag to use and a human label).
#[derive(Debug, Clone)]
pub struct ColorZone {
    pub label: &'static str,
    pub cli_flag: &'static str,
}

/// Describes the capabilities of a supported device.
#[derive(Debug, Clone)]
pub struct DeviceProfile {
    pub name: &'static str,
    pub vid_pid: &'static [&'static str],
    pub color_zones: &'static [ColorZone],
    pub max_sensitivity_presets: u8,
    pub sensitivity_min: u32,
    pub sensitivity_max: u32,
    pub sensitivity_step: u32,
    pub polling_rates: &'static [u32],
    pub has_rainbow_effect: bool,
    pub has_light_effect: bool,
}

pub static DEVICES: &[DeviceProfile] = &[
    // --- Aerox 3 ---
    DeviceProfile {
        name: "SteelSeries Aerox 3",
        vid_pid: &["1038:1836"],
        color_zones: &[
            ColorZone { label: "Top", cli_flag: "--z1" },
            ColorZone { label: "Middle", cli_flag: "--z2" },
            ColorZone { label: "Bottom", cli_flag: "--z3" },
        ],
        max_sensitivity_presets: 5,
        sensitivity_min: 200,
        sensitivity_max: 8500,
        sensitivity_step: 100,
        polling_rates: &[125, 250, 500, 1000],
        has_rainbow_effect: true,
        has_light_effect: false,
    },
    // --- Aerox 3 Wireless ---
    DeviceProfile {
        name: "SteelSeries Aerox 3 Wireless",
        vid_pid: &["1038:183a"],
        color_zones: &[
            ColorZone { label: "Top", cli_flag: "--z1" },
            ColorZone { label: "Middle", cli_flag: "--z2" },
            ColorZone { label: "Bottom", cli_flag: "--z3" },
        ],
        max_sensitivity_presets: 5,
        sensitivity_min: 200,
        sensitivity_max: 8500,
        sensitivity_step: 100,
        polling_rates: &[125, 250, 500, 1000],
        has_rainbow_effect: true,
        has_light_effect: false,
    },
    // --- Aerox 5 ---
    DeviceProfile {
        name: "SteelSeries Aerox 5",
        vid_pid: &["1038:1850"],
        color_zones: &[
            ColorZone { label: "Top", cli_flag: "--z1" },
            ColorZone { label: "Middle", cli_flag: "--z2" },
            ColorZone { label: "Bottom", cli_flag: "--z3" },
        ],
        max_sensitivity_presets: 5,
        sensitivity_min: 200,
        sensitivity_max: 18000,
        sensitivity_step: 100,
        polling_rates: &[125, 250, 500, 1000],
        has_rainbow_effect: true,
        has_light_effect: false,
    },
    // --- Rival 3 ---
    DeviceProfile {
        name: "SteelSeries Rival 3",
        vid_pid: &["1038:1824", "1038:184c"],
        color_zones: &[
            ColorZone { label: "Strip Top", cli_flag: "--z1" },
            ColorZone { label: "Strip Middle", cli_flag: "--z2" },
            ColorZone { label: "Strip Bottom", cli_flag: "--z3" },
            ColorZone { label: "Logo", cli_flag: "--z4" },
        ],
        max_sensitivity_presets: 5,
        sensitivity_min: 200,
        sensitivity_max: 8500,
        sensitivity_step: 100,
        polling_rates: &[125, 250, 500, 1000],
        has_rainbow_effect: false,
        has_light_effect: true,
    },
    // --- Rival 3 Gen 2 ---
    DeviceProfile {
        name: "SteelSeries Rival 3 Gen 2",
        vid_pid: &["1038:1866"],
        color_zones: &[
            ColorZone { label: "LED", cli_flag: "--z1" },
        ],
        max_sensitivity_presets: 5,
        sensitivity_min: 200,
        sensitivity_max: 8500,
        sensitivity_step: 100,
        polling_rates: &[125, 250, 500, 1000],
        has_rainbow_effect: true,
        has_light_effect: false,
    },
    // --- Rival 5 ---
    DeviceProfile {
        name: "SteelSeries Rival 5",
        vid_pid: &["1038:1854"],
        color_zones: &[
            ColorZone { label: "Top", cli_flag: "--z1" },
            ColorZone { label: "Middle", cli_flag: "--z2" },
            ColorZone { label: "Bottom", cli_flag: "--z3" },
            ColorZone { label: "Reactive", cli_flag: "--reactive-color" },
        ],
        max_sensitivity_presets: 5,
        sensitivity_min: 200,
        sensitivity_max: 18000,
        sensitivity_step: 100,
        polling_rates: &[125, 250, 500, 1000],
        has_rainbow_effect: true,
        has_light_effect: false,
    },
    // --- Rival 100 / 105 ---
    DeviceProfile {
        name: "SteelSeries Rival 100",
        vid_pid: &["1038:1702", "1038:170a", "1038:170b", "1038:170c", "1038:1814"],
        color_zones: &[
            ColorZone { label: "LED", cli_flag: "--color" },
        ],
        max_sensitivity_presets: 2,
        sensitivity_min: 250,
        sensitivity_max: 4000,
        sensitivity_step: 250,
        polling_rates: &[125, 250, 500, 1000],
        has_rainbow_effect: false,
        has_light_effect: true,
    },
    // --- Rival 110 / 106 ---
    DeviceProfile {
        name: "SteelSeries Rival 110",
        vid_pid: &["1038:1816", "1038:1818"],
        color_zones: &[
            ColorZone { label: "LED", cli_flag: "--color" },
        ],
        max_sensitivity_presets: 2,
        sensitivity_min: 200,
        sensitivity_max: 7200,
        sensitivity_step: 100,
        polling_rates: &[125, 250, 500, 1000],
        has_rainbow_effect: false,
        has_light_effect: true,
    },
    // --- Rival 300 / original Rival ---
    DeviceProfile {
        name: "SteelSeries Rival 300",
        vid_pid: &["1038:1710", "1038:1720", "1038:1718", "1038:171a"],
        color_zones: &[
            ColorZone { label: "Logo", cli_flag: "--logo-color" },
            ColorZone { label: "Scroll Wheel", cli_flag: "--wheel-color" },
        ],
        max_sensitivity_presets: 2,
        sensitivity_min: 50,
        sensitivity_max: 6500,
        sensitivity_step: 50,
        polling_rates: &[125, 250, 500, 1000],
        has_rainbow_effect: false,
        has_light_effect: true,
    },
    // --- Rival 300S ---
    DeviceProfile {
        name: "SteelSeries Rival 300S",
        vid_pid: &["1038:1810"],
        color_zones: &[
            ColorZone { label: "Logo", cli_flag: "--logo-color" },
            ColorZone { label: "Scroll Wheel", cli_flag: "--wheel-color" },
        ],
        max_sensitivity_presets: 2,
        sensitivity_min: 50,
        sensitivity_max: 6500,
        sensitivity_step: 50,
        polling_rates: &[125, 250, 500, 1000],
        has_rainbow_effect: false,
        has_light_effect: true,
    },
    // --- Rival 310 ---
    DeviceProfile {
        name: "SteelSeries Rival 310",
        vid_pid: &["1038:1720"],
        color_zones: &[
            ColorZone { label: "Logo", cli_flag: "--z1" },
            ColorZone { label: "Scroll Wheel", cli_flag: "--z2" },
        ],
        max_sensitivity_presets: 2,
        sensitivity_min: 100,
        sensitivity_max: 12000,
        sensitivity_step: 100,
        polling_rates: &[125, 250, 500, 1000],
        has_rainbow_effect: false,
        has_light_effect: false,
    },
    // --- Rival 600 ---
    DeviceProfile {
        name: "SteelSeries Rival 600",
        vid_pid: &["1038:1724", "1038:172e"],
        color_zones: &[
            ColorZone { label: "Scroll Wheel", cli_flag: "--z0" },
            ColorZone { label: "Logo", cli_flag: "--z1" },
            ColorZone { label: "Left Strip Top", cli_flag: "--z2" },
            ColorZone { label: "Right Strip Top", cli_flag: "--z3" },
            ColorZone { label: "Left Strip Middle", cli_flag: "--z4" },
            ColorZone { label: "Right Strip Middle", cli_flag: "--z5" },
            ColorZone { label: "Left Strip Bottom", cli_flag: "--z6" },
            ColorZone { label: "Right Strip Bottom", cli_flag: "--z7" },
        ],
        max_sensitivity_presets: 2,
        sensitivity_min: 100,
        sensitivity_max: 12000,
        sensitivity_step: 100,
        polling_rates: &[125, 250, 500, 1000],
        has_rainbow_effect: false,
        has_light_effect: false,
    },
    // --- Rival 700 / 710 ---
    DeviceProfile {
        name: "SteelSeries Rival 700",
        vid_pid: &["1038:1700", "1038:1730"],
        color_zones: &[
            ColorZone { label: "Scroll Wheel", cli_flag: "--z1" },
            ColorZone { label: "Logo", cli_flag: "--z2" },
        ],
        max_sensitivity_presets: 2,
        sensitivity_min: 100,
        sensitivity_max: 16000,
        sensitivity_step: 100,
        polling_rates: &[125, 250, 500, 1000],
        has_rainbow_effect: false,
        has_light_effect: false,
    },
    // --- Prime ---
    DeviceProfile {
        name: "SteelSeries Prime",
        vid_pid: &["1038:1840", "1038:1842"],
        color_zones: &[
            ColorZone { label: "LED", cli_flag: "--z1" },
        ],
        max_sensitivity_presets: 5,
        sensitivity_min: 50,
        sensitivity_max: 18000,
        sensitivity_step: 50,
        polling_rates: &[125, 250, 500, 1000],
        has_rainbow_effect: false,
        has_light_effect: false,
    },
    // --- Prime Mini ---
    DeviceProfile {
        name: "SteelSeries Prime Mini",
        vid_pid: &["1038:1844"],
        color_zones: &[
            ColorZone { label: "LED", cli_flag: "--z1" },
        ],
        max_sensitivity_presets: 5,
        sensitivity_min: 50,
        sensitivity_max: 18000,
        sensitivity_step: 50,
        polling_rates: &[125, 250, 500, 1000],
        has_rainbow_effect: false,
        has_light_effect: false,
    },
    // --- Sensei 310 ---
    DeviceProfile {
        name: "SteelSeries Sensei 310",
        vid_pid: &["1038:1722"],
        color_zones: &[
            ColorZone { label: "Logo", cli_flag: "--z1" },
            ColorZone { label: "Scroll Wheel", cli_flag: "--z2" },
        ],
        max_sensitivity_presets: 2,
        sensitivity_min: 100,
        sensitivity_max: 12000,
        sensitivity_step: 100,
        polling_rates: &[125, 250, 500, 1000],
        has_rainbow_effect: false,
        has_light_effect: false,
    },
    // --- Sensei TEN ---
    DeviceProfile {
        name: "SteelSeries Sensei TEN",
        vid_pid: &["1038:1832"],
        color_zones: &[
            ColorZone { label: "Logo", cli_flag: "--z1" },
            ColorZone { label: "Scroll Wheel", cli_flag: "--z2" },
        ],
        max_sensitivity_presets: 2,
        sensitivity_min: 100,
        sensitivity_max: 18000,
        sensitivity_step: 100,
        polling_rates: &[125, 250, 500, 1000],
        has_rainbow_effect: false,
        has_light_effect: false,
    },
];

/// Look up a device profile given a name (fuzzy) or vid:pid.
pub fn find_profile_by_vid_pid(vid_pid: &str) -> Option<&'static DeviceProfile> {
    DEVICES.iter().find(|d| d.vid_pid.iter().any(|vp| *vp == vid_pid))
}

pub fn find_profile_by_name(name: &str) -> Option<&'static DeviceProfile> {
    let name_lower = name.to_lowercase();
    DEVICES.iter().find(|d| name_lower.contains(&d.name.to_lowercase()))
}

/// Try to find a device profile from rivalcfg detection.
pub fn detect_device() -> Option<&'static DeviceProfile> {
    if let Some((name, vid_pid)) = crate::rivalcfg::detect_mouse() {
        // Try vid:pid first
        if !vid_pid.is_empty() {
            if let Some(profile) = find_profile_by_vid_pid(&vid_pid) {
                return Some(profile);
            }
        }
        // Fallback to name matching
        if !name.is_empty() {
            return find_profile_by_name(&name);
        }
    }

    // Last resort: parse rivalcfg -h to detect device name from CLI help text
    if let Ok(output) = std::process::Command::new("rivalcfg").arg("-h").output() {
        let help = String::from_utf8_lossy(&output.stdout);
        for device in DEVICES {
            if help.contains(device.name) {
                return Some(device);
            }
        }
    }

    None
}
