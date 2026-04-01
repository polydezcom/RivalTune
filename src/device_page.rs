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
use std::cell::RefCell;

use crate::devices::DeviceProfile;

mod imp {
    use super::*;

    #[derive(Debug, Default)]
    pub struct DevicePage {
        pub content_box: RefCell<Option<gtk::Box>>,
        pub sensitivity_scales: RefCell<Vec<gtk::Scale>>,
        pub color_buttons: RefCell<Vec<(String, gtk::ColorDialogButton)>>,
        pub polling_rate_dropdown: RefCell<Option<gtk::DropDown>>,
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

        // --- Sensitivity section ---
        self.build_sensitivity_section(&main_box, profile);

        // --- Color section ---
        self.build_color_section(&main_box, profile);

        // --- Polling Rate section ---
        self.build_polling_rate_section(&main_box, profile);

        // --- Apply / Reset buttons ---
        self.build_action_buttons(&main_box, profile);

        clamp.set_child(Some(&main_box));
        scroll.set_child(Some(&clamp));
        self.set_child(Some(&scroll));

        imp.content_box.replace(Some(main_box));
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

        row.add_suffix(&dropdown);
        group.add(&row);

        imp.polling_rate_dropdown.replace(Some(dropdown));
        parent.append(&group);
    }

    fn build_action_buttons(&self, parent: &gtk::Box, profile: &'static DeviceProfile) {
        let button_box = gtk::Box::builder()
            .orientation(gtk::Orientation::Horizontal)
            .spacing(12)
            .halign(gtk::Align::Center)
            .margin_top(12)
            .build();

        let apply_button = gtk::Button::builder()
            .label("Apply")
            .css_classes(vec!["suggested-action".to_string(), "pill".to_string()])
            .build();

        let reset_button = gtk::Button::builder()
            .label("Reset to Defaults")
            .css_classes(vec!["destructive-action".to_string(), "pill".to_string()])
            .build();

        let page = self.clone();
        let profile_for_apply = profile;
        apply_button.connect_clicked(move |btn| {
            page.apply_settings(profile_for_apply, btn);
        });

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

        button_box.append(&apply_button);
        button_box.append(&reset_button);
        parent.append(&button_box);
    }

    fn apply_settings(&self, profile: &'static DeviceProfile, button: &gtk::Button) {
        let imp = self.imp();
        button.set_sensitive(false);

        // Collect sensitivity presets
        let scales = imp.sensitivity_scales.borrow();
        let presets: Vec<u32> = scales.iter().map(|s| s.value() as u32).collect();

        // Collect colors
        let color_buttons = imp.color_buttons.borrow();
        let colors: Vec<(String, String)> = color_buttons
            .iter()
            .map(|(flag, btn)| {
                let rgba = btn.rgba();
                let hex = format!(
                    "#{:02x}{:02x}{:02x}",
                    (rgba.red() * 255.0) as u8,
                    (rgba.green() * 255.0) as u8,
                    (rgba.blue() * 255.0) as u8
                );
                (flag.clone(), hex)
            })
            .collect();

        // Collect polling rate
        let polling_rate = {
            let dropdown = imp.polling_rate_dropdown.borrow();
            if let Some(ref dd) = *dropdown {
                let idx = dd.selected() as usize;
                profile.polling_rates.get(idx).copied().unwrap_or(1000)
            } else {
                1000
            }
        };

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
        }

        button.set_sensitive(true);
    }
}
