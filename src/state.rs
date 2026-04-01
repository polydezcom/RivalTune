/* state.rs
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

use serde::{Deserialize, Serialize};
use gtk::glib;
use std::collections::HashMap;
use std::fs;
use std::path::PathBuf;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeviceState {
    pub sensitivities: Vec<u32>,
    pub colors: HashMap<String, String>,
    pub polling_rate: u32,
    pub rgb_enabled: bool,
}

impl Default for DeviceState {
    fn default() -> Self {
        Self {
            sensitivities: Vec::new(),
            colors: HashMap::new(),
            polling_rate: 1000,
            rgb_enabled: true,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserPreset {
    pub name: String,
    pub sensitivities: Vec<u32>,
    pub colors: HashMap<String, String>,
    pub polling_rate: u32,
    pub rgb_enabled: bool,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
struct AppState {
    device_settings: HashMap<String, DeviceState>,
    presets: HashMap<String, Vec<UserPreset>>,
}

fn state_file_path() -> PathBuf {
    let mut path = glib::user_config_dir();
    path.push("rivaltune");
    path.push("state.json");
    path
}

fn load_state() -> AppState {
    let path = state_file_path();
    let Ok(content) = fs::read_to_string(path) else {
        return AppState::default();
    };

    serde_json::from_str(&content).unwrap_or_default()
}

fn save_state(state: &AppState) -> Result<(), String> {
    let path = state_file_path();
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)
            .map_err(|e| format!("Failed to create state directory: {}", e))?;
    }

    let content = serde_json::to_string_pretty(state)
        .map_err(|e| format!("Failed to serialize state: {}", e))?;

    fs::write(path, content).map_err(|e| format!("Failed to write state file: {}", e))
}

pub fn load_device_state(device_name: &str) -> Option<DeviceState> {
    let state = load_state();
    state.device_settings.get(device_name).cloned()
}

pub fn save_device_state(device_name: &str, device_state: DeviceState) -> Result<(), String> {
    let mut state = load_state();
    state
        .device_settings
        .insert(device_name.to_string(), device_state);
    save_state(&state)
}

pub fn list_presets(device_name: &str) -> Vec<UserPreset> {
    let state = load_state();
    state
        .presets
        .get(device_name)
        .cloned()
        .unwrap_or_default()
}

pub fn save_preset(device_name: &str, preset: UserPreset) -> Result<(), String> {
    let mut state = load_state();
    let presets = state.presets.entry(device_name.to_string()).or_default();

    if let Some(existing) = presets.iter_mut().find(|p| p.name == preset.name) {
        *existing = preset;
    } else {
        presets.push(preset);
    }

    save_state(&state)
}