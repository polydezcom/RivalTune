/* device_page.rs
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

use adw::prelude::*;
use adw::subclass::prelude::*;
use gtk::glib;
use std::collections::HashMap;
use std::cell::RefCell;

use crate::devices::DeviceProfile;
use crate::state::{DeviceState, UserPreset};

const LIGHT_THEMES: [(&str, [&str; 8]); 8] = [
    ("Sunset", ["#ff6b6b", "#ff8e53", "#ffcd56", "#ffe66d", "#ff6b6b", "#ff8e53", "#ffcd56", "#ffe66d"]),
    ("Ocean", ["#004e92", "#000428", "#2c7da0", "#61a5c2", "#004e92", "#000428", "#2c7da0", "#61a5c2"]),
    ("Forest", ["#1b4332", "#2d6a4f", "#40916c", "#74c69d", "#1b4332", "#2d6a4f", "#40916c", "#74c69d"]),
    ("Aurora", ["#80ffdb", "#72efdd", "#64dfdf", "#48bfe3", "#5390d9", "#6930c3", "#7400b8", "#5e60ce"]),
    ("Volcano", ["#370617", "#6a040f", "#9d0208", "#d00000", "#dc2f02", "#e85d04", "#f48c06", "#faa307"]),
    ("Ice", ["#caf0f8", "#ade8f4", "#90e0ef", "#48cae4", "#00b4d8", "#0096c7", "#0077b6", "#023e8a"]),
    ("Candy", ["#ff99c8", "#fcf6bd", "#d0f4de", "#a9def9", "#e4c1f9", "#ff99c8", "#fcf6bd", "#a9def9"]),
    ("Mono", ["#ffffff", "#e0e0e0", "#c2c2c2", "#a3a3a3", "#858585", "#666666", "#474747", "#282828"]),
];

mod imp {
    use super::*;

    #[derive(Debug, Default)]
    pub struct DevicePage {
        pub content_box: RefCell<Option<gtk::Box>>,
        pub section_stack: RefCell<Option<gtk::Stack>>,
        pub sensitivity_scales: RefCell<Vec<gtk::Scale>>,
        pub color_buttons: RefCell<Vec<(String, gtk::ColorDialogButton)>>,
        pub polling_rate_dropdown: RefCell<Option<gtk::DropDown>>,
        pub rgb_switch: RefCell<Option<gtk::Switch>>,
        pub preset_name_entry: RefCell<Option<gtk::Entry>>,
        pub preset_dropdown: RefCell<Option<gtk::DropDown>>,
        pub preset_model: RefCell<Option<gtk::StringList>>,
        pub theme_dropdown: RefCell<Option<gtk::DropDown>>,
        pub user_presets: RefCell<Vec<UserPreset>>,
        pub profile_name: RefCell<String>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for DevicePage {
        const NAME: &'static str = "RivaltuneDevicePage";
        type Type = super::DevicePage;
        type ParentType = adw::Bin;
    }

    impl ObjectImpl for DevicePage {}
    impl WidgetImpl for DevicePage {}
    impl BinImpl for DevicePage {}
}

glib::wrapper! {
    pub struct DevicePage(ObjectSubclass<imp::DevicePage>)
        @extends gtk::Widget, adw::Bin;
}

impl DevicePage {
    pub fn new() -> Self {
        glib::Object::builder().build()
    }

    pub fn load_device(&self, profile: &'static DeviceProfile) {
        let imp = self.imp();
        imp.profile_name.replace(profile.name.to_string());

        let scroll = gtk::ScrolledWindow::builder()
            .hscrollbar_policy(gtk::PolicyType::Never)
            .vexpand(true)
            .build();

        let clamp = adw::Clamp::builder()
            .maximum_size(600)
            .tightening_threshold(400)
            .build();

        let main_box = gtk::Box::builder()
            .orientation(gtk::Orientation::Vertical)
            .spacing(24)
            .margin_top(24)
            .margin_bottom(24)
            .margin_start(12)
            .margin_end(12)
            .build();

        // Device name header
        let device_label = gtk::Label::builder()
            .label(profile.name)
            .css_classes(vec!["title-1".to_string()])
            .build();
        main_box.append(&device_label);

        let section_stack = gtk::Stack::builder()
            .transition_type(gtk::StackTransitionType::SlideLeftRight)
            .transition_duration(200)
            .build();

        let sensitivity_tab = gtk::Box::builder()
            .orientation(gtk::Orientation::Vertical)
            .spacing(16)
            .build();
        self.build_sensitivity_section(&sensitivity_tab, profile);
        self.build_polling_rate_section(&sensitivity_tab, profile);
        self.build_action_buttons(&sensitivity_tab);

        let rgb_tab = gtk::Box::builder()
            .orientation(gtk::Orientation::Vertical)
            .spacing(16)
            .build();
        self.build_color_section(&rgb_tab, profile);

        section_stack.add_titled(&sensitivity_tab, Some("sensitivity"), "Sensitivity");
        section_stack.add_titled(&rgb_tab, Some("rgb-effects"), "RGB & Effects");
        main_box.append(&section_stack);

        clamp.set_child(Some(&main_box));
        scroll.set_child(Some(&clamp));
        self.set_child(Some(&scroll));

        imp.content_box.replace(Some(main_box));
        imp.section_stack.replace(Some(section_stack));
        self.restore_state(profile);
        self.refresh_preset_dropdown(profile);
    }

    pub fn build_header_tab_switcher(&self) -> Option<gtk::StackSwitcher> {
        let imp = self.imp();
        let stack = imp.section_stack.borrow();
        let stack_ref = stack.as_ref()?;

        Some(
            gtk::StackSwitcher::builder()
                .stack(stack_ref)
                .halign(gtk::Align::Center)
                .css_classes(vec!["flat".to_string(), "compact-tabs".to_string()])
                .build(),
        )
    }

    pub fn build_header_controls(&self, profile: &'static DeviceProfile) -> gtk::Box {
        let imp = self.imp();

        let controls = gtk::Box::builder()
            .orientation(gtk::Orientation::Horizontal)
            .spacing(6)
            .valign(gtk::Align::Center)
            .build();

        let preset_model = gtk::StringList::new(&[]);
        let preset_dropdown = gtk::DropDown::builder()
            .model(&preset_model)
            .tooltip_text("Select saved preset")
            .valign(gtk::Align::Center)
            .hexpand(true)
            .width_request(180)
            .build();

        let preset_name_entry = gtk::Entry::builder()
            .placeholder_text("Preset name")
            .hexpand(true)
            .build();

        let save_button = gtk::Button::builder()
            .label("Save Preset")
            .css_classes(vec!["pill".to_string()])
            .build();

        let apply_preset_button = gtk::Button::builder()
            .label("Apply Selected")
            .css_classes(vec!["pill".to_string()])
            .build();

        let popover_content = gtk::Box::builder()
            .orientation(gtk::Orientation::Vertical)
            .spacing(8)
            .margin_top(8)
            .margin_bottom(8)
            .margin_start(8)
            .margin_end(8)
            .build();
        popover_content.append(&preset_dropdown);
        popover_content.append(&preset_name_entry);
        popover_content.append(&save_button);
        popover_content.append(&apply_preset_button);

        let popover = gtk::Popover::builder().child(&popover_content).build();

        let presets_button = gtk::MenuButton::builder()
            .label("Presets")
            .popover(&popover)
            .valign(gtk::Align::Center)
            .build();

        let apply_button = gtk::Button::builder()
            .label("Apply")
            .css_classes(vec!["suggested-action".to_string()])
            .valign(gtk::Align::Center)
            .build();

        let page_for_save = self.clone();
        let profile_for_save = profile;
        save_button.connect_clicked(move |_| {
            page_for_save.save_current_as_preset(profile_for_save);
        });

        let page_for_save_enter = self.clone();
        let profile_for_save_enter = profile;
        preset_name_entry.connect_activate(move |_| {
            page_for_save_enter.save_current_as_preset(profile_for_save_enter);
        });

        let page_for_apply_preset = self.clone();
        let profile_for_apply_preset = profile;
        apply_preset_button.connect_clicked(move |_| {
            page_for_apply_preset.apply_selected_preset(profile_for_apply_preset);
        });

        let page_for_apply_settings = self.clone();
        let profile_for_apply_settings = profile;
        apply_button.connect_clicked(move |btn| {
            page_for_apply_settings.apply_settings(profile_for_apply_settings, btn);
        });

        controls.append(&presets_button);
        controls.append(&apply_button);

        imp.preset_name_entry.replace(Some(preset_name_entry));
        imp.preset_model.replace(Some(preset_model));
        imp.preset_dropdown.replace(Some(preset_dropdown));

        self.refresh_preset_dropdown(profile);

        controls
    }

    fn build_sensitivity_section(&self, parent: &gtk::Box, profile: &'static DeviceProfile) {
        let imp = self.imp();

        let group = adw::PreferencesGroup::builder()
            .title("Sensitivity (DPI)")
            .description(format!(
                "Up to {} presets, {} – {} DPI",
                profile.max_sensitivity_presets,
                profile.sensitivity_min,
                profile.sensitivity_max
            ))
            .build();

        let mut scales = Vec::new();

        for i in 0..profile.max_sensitivity_presets {
            let default_dpi = match i {
                0 => 800.0,
                1 => 1600.0,
                _ => 800.0 + (i as f64 * 400.0),
            };
            let default_dpi = default_dpi.min(profile.sensitivity_max as f64);

            let row = adw::ActionRow::builder()
                .title(format!("Preset {}", i + 1))
                .build();

            let scale_box = gtk::Box::builder()
                .orientation(gtk::Orientation::Horizontal)
                .spacing(8)
                .valign(gtk::Align::Center)
                .build();

            let adj = gtk::Adjustment::new(
                default_dpi,
                profile.sensitivity_min as f64,
                profile.sensitivity_max as f64,
                profile.sensitivity_step as f64,
                profile.sensitivity_step as f64 * 5.0,
                0.0,
            );

            let scale = gtk::Scale::builder()
                .adjustment(&adj)
                .orientation(gtk::Orientation::Horizontal)
                .width_request(250)
                .draw_value(false)
                .build();

            let dpi_label = gtk::Label::builder()
                .label(&format!("{} DPI", default_dpi as u32))
                .width_chars(9)
                .css_classes(vec!["monospace".to_string()])
                .build();

            let dpi_label_clone = dpi_label.clone();
            scale.connect_value_changed(move |s| {
                let val = s.value() as u32;
                dpi_label_clone.set_label(&format!("{} DPI", val));
            });

            scale_box.append(&scale);
            scale_box.append(&dpi_label);

            row.add_suffix(&scale_box);
            group.add(&row);
            scales.push(scale);
        }

        imp.sensitivity_scales.replace(scales);
        parent.append(&group);
    }

    fn build_color_section(&self, parent: &gtk::Box, profile: &'static DeviceProfile) {
        let imp = self.imp();

        if profile.color_zones.is_empty() {
            return;
        }

        let group = adw::PreferencesGroup::builder()
            .title("Colors")
            .description("Set the LED colors for each zone")
            .build();

        let rgb_row = adw::ActionRow::builder()
            .title("Enable RGB")
            .subtitle("Turn off to disable all lighting")
            .build();

        let rgb_switch = gtk::Switch::builder()
            .active(true)
            .valign(gtk::Align::Center)
            .build();
        rgb_row.add_suffix(&rgb_switch);
        group.add(&rgb_row);

        let mut buttons = Vec::new();

        for zone in profile.color_zones {
            let row = adw::ActionRow::builder()
                .title(zone.label)
                .build();

            let dialog = gtk::ColorDialog::builder()
                .with_alpha(false)
                .build();

            let color_button = gtk::ColorDialogButton::builder()
                .dialog(&dialog)
                .valign(gtk::Align::Center)
                .build();

            // Default to white
            color_button.set_rgba(&gtk::gdk::RGBA::new(1.0, 0.0, 0.0, 1.0));

            row.add_suffix(&color_button);
            group.add(&row);
            buttons.push((zone.cli_flag.to_string(), color_button));
        }

        let theme_row = adw::ActionRow::builder()
            .title("Built-in Light Theme")
            .subtitle("Quickly apply one of the included color themes")
            .build();

        let theme_items: Vec<&str> = LIGHT_THEMES.iter().map(|(name, _)| *name).collect();
        let theme_model = gtk::StringList::new(&theme_items);
        let theme_dropdown = gtk::DropDown::builder()
            .model(&theme_model)
            .selected(0)
            .valign(gtk::Align::Center)
            .build();

        let theme_apply = gtk::Button::builder()
            .label("Apply Theme")
            .css_classes(vec!["pill".to_string()])
            .valign(gtk::Align::Center)
            .build();

        let theme_box = gtk::Box::builder()
            .orientation(gtk::Orientation::Horizontal)
            .spacing(8)
            .build();
        theme_box.append(&theme_dropdown);
        theme_box.append(&theme_apply);

        theme_row.add_suffix(&theme_box);
        group.add(&theme_row);

        let page_for_switch = self.clone();
        let profile_for_switch = profile;
        rgb_switch.connect_active_notify(move |_| {
            page_for_switch.update_rgb_widgets_enabled();
            page_for_switch.save_current_state(profile_for_switch);
        });

        let page_for_theme = self.clone();
        let profile_for_theme = profile;
        theme_apply.connect_clicked(move |_| {
            page_for_theme.apply_selected_theme();
            page_for_theme.save_current_state(profile_for_theme);
        });

        imp.rgb_switch.replace(Some(rgb_switch));
        imp.theme_dropdown.replace(Some(theme_dropdown));
        imp.color_buttons.replace(buttons);
        parent.append(&group);
    }

    fn build_polling_rate_section(&self, parent: &gtk::Box, profile: &'static DeviceProfile) {
        let imp = self.imp();

        if profile.polling_rates.is_empty() {
            return;
        }

        let group = adw::PreferencesGroup::builder()
            .title("Polling Rate")
            .build();

        let row = adw::ActionRow::builder()
            .title("Polling Rate (Hz)")
            .build();

        let items: Vec<String> = profile.polling_rates.iter().map(|r| format!("{} Hz", r)).collect();
        let string_list = gtk::StringList::new(&items.iter().map(|s| s.as_str()).collect::<Vec<_>>());

        let dropdown = gtk::DropDown::builder()
            .model(&string_list)
            .valign(gtk::Align::Center)
            .build();

        // Default to 1000 Hz (last item typically)
        if let Some(idx) = profile.polling_rates.iter().position(|r| *r == 1000) {
            dropdown.set_selected(idx as u32);
        }

        let page_for_polling = self.clone();
        let profile_for_polling = profile;
        dropdown.connect_selected_notify(move |_| {
            page_for_polling.save_current_state(profile_for_polling);
        });

        row.add_suffix(&dropdown);
        group.add(&row);

        imp.polling_rate_dropdown.replace(Some(dropdown));
        parent.append(&group);
    }

    fn build_action_buttons(&self, parent: &gtk::Box) {
        let button_box = gtk::Box::builder()
            .orientation(gtk::Orientation::Horizontal)
            .spacing(12)
            .halign(gtk::Align::Center)
            .margin_top(12)
            .build();

        let reset_button = gtk::Button::builder()
            .label("Reset to Defaults")
            .css_classes(vec!["destructive-action".to_string(), "pill".to_string()])
            .build();

        reset_button.connect_clicked(|btn| {
            btn.set_sensitive(false);
            match crate::rivalcfg::reset() {
                Ok(_) => {
                    btn.set_sensitive(true);
                }
                Err(e) => {
                    eprintln!("Reset failed: {}", e);
                    btn.set_sensitive(true);
                }
            }
        });

        button_box.append(&reset_button);
        parent.append(&button_box);
    }

    fn apply_settings(&self, profile: &'static DeviceProfile, button: &gtk::Button) {
        button.set_sensitive(false);

        let state = self.collect_current_state(profile);
        let presets = state.sensitivities.clone();
        let colors = if state.rgb_enabled {
            state.colors
        } else {
            let mut off = HashMap::new();
            for zone in profile.color_zones {
                off.insert(zone.cli_flag.to_string(), "#000000".to_string());
            }
            off
        };
        let polling_rate = state.polling_rate;

        // Apply all settings
        let mut errors = Vec::new();

        if let Err(e) = crate::rivalcfg::set_sensitivity(&presets) {
            errors.push(format!("Sensitivity: {}", e));
        }

        for (flag, color) in &colors {
            if let Err(e) = crate::rivalcfg::set_color(flag, color) {
                errors.push(format!("Color {}: {}", flag, e));
            }
        }

        if let Err(e) = crate::rivalcfg::set_polling_rate(polling_rate) {
            errors.push(format!("Polling rate: {}", e));
        }

        if !errors.is_empty() {
            eprintln!("Errors applying settings:\n{}", errors.join("\n"));
        } else if let Err(e) = crate::state::save_device_state(profile.name, self.collect_current_state(profile)) {
            eprintln!("Failed to persist device settings: {}", e);
        }

        button.set_sensitive(true);
    }

    fn collect_current_state(&self, profile: &'static DeviceProfile) -> DeviceState {
        let imp = self.imp();
        let sensitivities = imp
            .sensitivity_scales
            .borrow()
            .iter()
            .map(|s| s.value() as u32)
            .collect::<Vec<_>>();

        let colors = imp
            .color_buttons
            .borrow()
            .iter()
            .map(|(flag, btn)| (flag.clone(), rgba_to_hex(btn.rgba())))
            .collect::<HashMap<_, _>>();

        let polling_rate = {
            let dropdown = imp.polling_rate_dropdown.borrow();
            if let Some(ref dd) = *dropdown {
                let idx = dd.selected() as usize;
                profile.polling_rates.get(idx).copied().unwrap_or(1000)
            } else {
                1000
            }
        };

        let rgb_enabled = imp
            .rgb_switch
            .borrow()
            .as_ref()
            .map(|s| s.is_active())
            .unwrap_or(true);

        DeviceState {
            sensitivities,
            colors,
            polling_rate,
            rgb_enabled,
        }
    }

    fn save_current_state(&self, profile: &'static DeviceProfile) {
        let state = self.collect_current_state(profile);
        if let Err(e) = crate::state::save_device_state(profile.name, state) {
            eprintln!("Failed to persist device settings: {}", e);
        }
    }

    fn restore_state(&self, profile: &'static DeviceProfile) {
        let Some(state) = crate::state::load_device_state(profile.name) else {
            self.connect_change_watchers(profile);
            return;
        };

        let imp = self.imp();

        for (idx, scale) in imp.sensitivity_scales.borrow().iter().enumerate() {
            if let Some(value) = state.sensitivities.get(idx) {
                scale.set_value(*value as f64);
            }
        }

        for (flag, button) in imp.color_buttons.borrow().iter() {
            if let Some(color) = state.colors.get(flag) {
                if let Some(rgba) = hex_to_rgba(color) {
                    button.set_rgba(&rgba);
                }
            }
        }

        if let Some(dropdown) = imp.polling_rate_dropdown.borrow().as_ref() {
            if let Some(pos) = profile
                .polling_rates
                .iter()
                .position(|r| *r == state.polling_rate)
            {
                dropdown.set_selected(pos as u32);
            }
        }

        if let Some(rgb_switch) = imp.rgb_switch.borrow().as_ref() {
            rgb_switch.set_active(state.rgb_enabled);
        }

        self.update_rgb_widgets_enabled();
        self.connect_change_watchers(profile);
    }

    fn connect_change_watchers(&self, profile: &'static DeviceProfile) {
        let imp = self.imp();

        for scale in imp.sensitivity_scales.borrow().iter() {
            let page = self.clone();
            let profile_for_save = profile;
            scale.connect_value_changed(move |_| {
                page.save_current_state(profile_for_save);
            });
        }

        for (_, button) in imp.color_buttons.borrow().iter() {
            let page = self.clone();
            let profile_for_save = profile;
            button.connect_rgba_notify(move |_| {
                page.save_current_state(profile_for_save);
            });
        }
    }

    fn update_rgb_widgets_enabled(&self) {
        let imp = self.imp();
        let enabled = imp
            .rgb_switch
            .borrow()
            .as_ref()
            .map(|s| s.is_active())
            .unwrap_or(true);

        for (_, button) in imp.color_buttons.borrow().iter() {
            button.set_sensitive(enabled);
        }

        if let Some(theme_dropdown) = imp.theme_dropdown.borrow().as_ref() {
            theme_dropdown.set_sensitive(enabled);
        }
    }

    fn refresh_preset_dropdown(&self, profile: &'static DeviceProfile) {
        let imp = self.imp();
        let presets = crate::state::list_presets(profile.name);
        let names = presets
            .iter()
            .map(|p| p.name.as_str())
            .collect::<Vec<_>>();

        let model = gtk::StringList::new(&names);
        if let Some(dropdown) = imp.preset_dropdown.borrow().as_ref() {
            dropdown.set_model(Some(&model));
            if !presets.is_empty() {
                dropdown.set_selected(0);
            }
        }

        imp.preset_model.replace(Some(model));
        imp.user_presets.replace(presets);
    }

    fn save_current_as_preset(&self, profile: &'static DeviceProfile) {
        let imp = self.imp();
        let name = imp
            .preset_name_entry
            .borrow()
            .as_ref()
            .map(|entry| entry.text().trim().to_string())
            .unwrap_or_default();

        let name = if name.is_empty() {
            let count = crate::state::list_presets(profile.name).len() + 1;
            format!("Preset {}", count)
        } else {
            name
        };

        let state = self.collect_current_state(profile);
        let preset = UserPreset {
            name,
            sensitivities: state.sensitivities,
            colors: state.colors,
            polling_rate: state.polling_rate,
            rgb_enabled: state.rgb_enabled,
        };

        if let Err(e) = crate::state::save_preset(profile.name, preset) {
            eprintln!("Failed to save preset: {}", e);
            return;
        }

        if let Some(entry) = imp.preset_name_entry.borrow().as_ref() {
            entry.set_text("");
        }

        self.refresh_preset_dropdown(profile);
        self.save_current_state(profile);
    }

    fn apply_selected_preset(&self, profile: &'static DeviceProfile) {
        let imp = self.imp();
        let idx = imp
            .preset_dropdown
            .borrow()
            .as_ref()
            .map(|dd| dd.selected() as usize)
            .unwrap_or(usize::MAX);

        let presets = imp.user_presets.borrow();
        let Some(preset) = presets.get(idx) else {
            return;
        };

        for (i, scale) in imp.sensitivity_scales.borrow().iter().enumerate() {
            if let Some(val) = preset.sensitivities.get(i) {
                scale.set_value(*val as f64);
            }
        }

        for (flag, button) in imp.color_buttons.borrow().iter() {
            if let Some(hex) = preset.colors.get(flag) {
                if let Some(rgba) = hex_to_rgba(hex) {
                    button.set_rgba(&rgba);
                }
            }
        }

        if let Some(dd) = imp.polling_rate_dropdown.borrow().as_ref() {
            if let Some(pos) = profile
                .polling_rates
                .iter()
                .position(|r| *r == preset.polling_rate)
            {
                dd.set_selected(pos as u32);
            }
        }

        if let Some(rgb_switch) = imp.rgb_switch.borrow().as_ref() {
            rgb_switch.set_active(preset.rgb_enabled);
        }

        self.update_rgb_widgets_enabled();
        self.save_current_state(profile);
    }

    fn apply_selected_theme(&self) {
        let imp = self.imp();
        let idx = imp
            .theme_dropdown
            .borrow()
            .as_ref()
            .map(|dd| dd.selected() as usize)
            .unwrap_or(0);

        let Some((_, palette)) = LIGHT_THEMES.get(idx) else {
            return;
        };

        for (zone_index, (_, button)) in imp.color_buttons.borrow().iter().enumerate() {
            let color = palette[zone_index % palette.len()];
            if let Some(rgba) = hex_to_rgba(color) {
                button.set_rgba(&rgba);
            }
        }
    }
}

fn rgba_to_hex(rgba: gtk::gdk::RGBA) -> String {
    format!(
        "#{:02x}{:02x}{:02x}",
        (rgba.red() * 255.0) as u8,
        (rgba.green() * 255.0) as u8,
        (rgba.blue() * 255.0) as u8
    )
}

fn hex_to_rgba(hex: &str) -> Option<gtk::gdk::RGBA> {
    let normalized = hex.trim().trim_start_matches('#');
    if normalized.len() != 6 {
        return None;
    }

    let r = u8::from_str_radix(&normalized[0..2], 16).ok()?;
    let g = u8::from_str_radix(&normalized[2..4], 16).ok()?;
    let b = u8::from_str_radix(&normalized[4..6], 16).ok()?;

    Some(gtk::gdk::RGBA::new(
        r as f32 / 255.0,
        g as f32 / 255.0,
        b as f32 / 255.0,
        1.0,
    ))
}
