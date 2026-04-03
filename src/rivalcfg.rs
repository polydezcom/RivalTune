/* rivalcfg.rs
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

use std::process::Command;

#[derive(Debug, Clone, Default)]
pub struct EffectSupport {
    pub light_effect_values: Vec<String>,
    pub rainbow_effect_values: Vec<String>,
}

/// Check whether rivalcfg is installed and reachable.
pub fn is_installed() -> bool {
    Command::new("rivalcfg")
        .arg("--version")
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false)
}

/// Return the installed rivalcfg version string, or None.
pub fn version() -> Option<String> {
    let output = Command::new("rivalcfg")
        .arg("--version")
        .output()
        .ok()?;
    if output.status.success() {
        Some(String::from_utf8_lossy(&output.stdout).trim().to_string())
    } else {
        None
    }
}

/// Check whether udev rules are installed by running `rivalcfg --print-udev`
/// and seeing if rules exist as files.
pub fn check_udev() -> bool {
    // A simple heuristic: try to run rivalcfg --print-debug and see if it
    // mentions "udev" rules. For now we just check if the program runs at all
    // with the device — if rivalcfg works, udev is probably fine.
    std::path::Path::new("/etc/udev/rules.d/50-steelseries.rules").exists()
        || std::path::Path::new("/usr/lib/udev/rules.d/50-steelseries.rules").exists()
}

/// Run `rivalcfg --update-udev` (requires pkexec for privilege escalation).
pub fn update_udev() -> Result<String, String> {
    if std::path::Path::new("/.flatpak-info").exists() {
        return Err(
            "Running inside Flatpak: udev rules must be installed on the host system. Run on host: sudo rivalcfg --update-udev"
                .to_string(),
        );
    }

    let output = Command::new("pkexec")
        .args(["rivalcfg", "--update-udev"])
        .output()
        .map_err(|e| format!("Failed to run pkexec: {}", e))?;
    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
    } else {
        Err(String::from_utf8_lossy(&output.stderr).trim().to_string())
    }
}

/// Print debug info — used to detect which mouse is connected.
/// Returns the raw output of `rivalcfg --print-debug`.
pub fn print_debug() -> Option<String> {
    let output = Command::new("rivalcfg")
        .arg("--print-debug")
        .output()
        .ok()?;
    Some(String::from_utf8_lossy(&output.stdout).to_string())
}

/// Detect the connected mouse by parsing `rivalcfg --print-debug`.
/// Returns (device_name, vendor_id, product_id) if found.
pub fn detect_mouse() -> Option<(String, String)> {
    let debug = print_debug()?;
    // The print-debug output contains lines like:
    //   Found device: SteelSeries Rival 3 (1038:1824)
    for line in debug.lines() {
        let line = line.trim();
        if line.contains("Found device") || line.contains("found device") {
            // Try to extract name and (vid:pid)
            if let Some(paren_start) = line.rfind('(') {
                if let Some(paren_end) = line.rfind(')') {
                    let vid_pid = &line[paren_start + 1..paren_end];
                    // Name is between ":" and "("
                    let name_part = if let Some(colon_pos) = line.find(':') {
                        line[colon_pos + 1..paren_start].trim().to_string()
                    } else {
                        line[..paren_start].trim().to_string()
                    };
                    return Some((name_part, vid_pid.to_string()));
                }
            }
        }
    }
    // Fallback: try running rivalcfg -h and checking if device options appear
    // If rivalcfg can run with device options, a mouse is connected
    let help_output = Command::new("rivalcfg")
        .arg("-h")
        .output()
        .ok()?;
    let help_text = String::from_utf8_lossy(&help_output.stdout);
    if help_text.contains("Options:") && (help_text.contains("--sensitivity") || help_text.contains("--color")) {
        // A device was found — try to get name from the options header
        for line in help_text.lines() {
            if line.contains("Options:") && line.contains("SteelSeries") {
                let name = line.replace("Options:", "").trim().to_string();
                return Some((name, String::new()));
            }
        }
    }
    None
}

/// Set the sensitivity (DPI). Supports comma-separated presets.
pub fn set_sensitivity(presets: &[u32]) -> Result<(), String> {
    let preset_str = presets
        .iter()
        .map(|p| p.to_string())
        .collect::<Vec<_>>()
        .join(",");
    run_rivalcfg(&["--sensitivity", &preset_str])
}

/// Set a color for a specific zone flag (e.g. "--z1", "--logo-color", etc).
pub fn set_color(zone_flag: &str, color: &str) -> Result<(), String> {
    run_rivalcfg(&[zone_flag, color])
}

/// Set polling rate.
pub fn set_polling_rate(rate: u32) -> Result<(), String> {
    run_rivalcfg(&["--polling-rate", &rate.to_string()])
}

pub fn set_light_effect(effect: &str) -> Result<(), String> {
    run_rivalcfg(&["--light-effect", effect])
}

pub fn set_rainbow_effect(effect: Option<&str>) -> Result<(), String> {
    match effect {
        Some(value) => run_rivalcfg(&["--rainbow-effect", value]),
        None => run_rivalcfg(&["--rainbow-effect"]),
    }
}

pub fn effect_support() -> EffectSupport {
    let output = match Command::new("rivalcfg").arg("-h").output() {
        Ok(output) => output,
        Err(_) => return EffectSupport::default(),
    };

    let help_text = String::from_utf8_lossy(&output.stdout);

    EffectSupport {
        light_effect_values: extract_values_for_option(&help_text, "--light-effect"),
        rainbow_effect_values: extract_values_for_option(&help_text, "--rainbow-effect"),
    }
}

/// Reset to factory defaults.
pub fn reset() -> Result<(), String> {
    run_rivalcfg(&["--reset"])
}

/// Run rivalcfg with given arguments.
fn run_rivalcfg(args: &[&str]) -> Result<(), String> {
    let output = Command::new("rivalcfg")
        .args(args)
        .output()
        .map_err(|e| format!("Failed to run rivalcfg: {}", e))?;
    if output.status.success() {
        Ok(())
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        let stdout = String::from_utf8_lossy(&output.stdout);
        Err(format!("{}{}", stderr, stdout))
    }
}

fn extract_values_for_option(help_text: &str, option_name: &str) -> Vec<String> {
    let Some(start) = help_text.find(option_name) else {
        return Vec::new();
    };

    let end = (start + 700).min(help_text.len());
    let window = &help_text[start..end];
    let Some(values_pos) = window.find("values:") else {
        return Vec::new();
    };

    let mut values_chunk = &window[values_pos + "values:".len()..];
    if let Some(default_pos) = values_chunk.find("default:") {
        values_chunk = &values_chunk[..default_pos];
    }
    if let Some(paren_pos) = values_chunk.find(')') {
        values_chunk = &values_chunk[..paren_pos];
    }

    values_chunk
        .split(',')
        .map(|value| {
            value
                .lines()
                .map(str::trim)
                .collect::<Vec<_>>()
                .join(" ")
                .replace("- ", "-")
                .trim()
                .trim_end_matches('.')
                .to_string()
        })
        .filter(|value| !value.is_empty())
        .collect()
}
