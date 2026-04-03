/* window.rs
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

use gtk::prelude::*;
use adw::subclass::prelude::*;
use gtk::{gio, glib};

use crate::device_page::DevicePage;
use crate::onboarding::OnboardingPage;

mod imp {
    use super::*;

    #[derive(Debug, Default, gtk::CompositeTemplate)]
    #[template(resource = "/com/polydez/rivaltune/window.ui")]
    pub struct RivaltuneWindow {
        #[template_child]
        pub main_stack: TemplateChild<gtk::Stack>,
        #[template_child]
        pub header_bar: TemplateChild<adw::HeaderBar>,
        #[template_child]
        pub refresh_button: TemplateChild<gtk::Button>,
        #[template_child]
        pub header_tabs_box: TemplateChild<gtk::Box>,
        #[template_child]
        pub device_controls_box: TemplateChild<gtk::Box>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for RivaltuneWindow {
        const NAME: &'static str = "RivaltuneWindow";
        type Type = super::RivaltuneWindow;
        type ParentType = adw::ApplicationWindow;

        fn class_init(klass: &mut Self::Class) {
            klass.bind_template();
        }

        fn instance_init(obj: &glib::subclass::InitializingObject<Self>) {
            obj.init_template();
        }
    }

    impl ObjectImpl for RivaltuneWindow {
        fn constructed(&self) {
            self.parent_constructed();
            let obj = self.obj();
            obj.setup_pages();
            obj.setup_refresh();
            obj.setup_actions();
        }
    }

    impl WidgetImpl for RivaltuneWindow {}
    impl WindowImpl for RivaltuneWindow {}
    impl ApplicationWindowImpl for RivaltuneWindow {}
    impl AdwApplicationWindowImpl for RivaltuneWindow {}
}

glib::wrapper! {
    pub struct RivaltuneWindow(ObjectSubclass<imp::RivaltuneWindow>)
        @extends gtk::Widget, gtk::Window, gtk::ApplicationWindow, adw::ApplicationWindow,
        @implements gio::ActionGroup, gio::ActionMap;
}

impl RivaltuneWindow {
    pub fn new<P: IsA<gtk::Application>>(application: &P) -> Self {
        glib::Object::builder()
            .property("application", application)
            .build()
    }

    fn setup_pages(&self) {
        let imp = self.imp();
        let stack = &imp.main_stack;

        // Onboarding page
        let onboarding = OnboardingPage::new();
        stack.add_named(&onboarding, Some("onboarding"));

        // No-device status page
        let no_device = adw::StatusPage::builder()
            .icon_name("dialog-question-symbolic")
            .title("No Mouse Detected")
            .description("Connect a supported SteelSeries mouse and click Refresh")
            .build();

        let center_refresh = gtk::Button::builder()
            .label("Refresh")
            .icon_name("view-refresh-symbolic")
            .css_classes(vec!["suggested-action".to_string(), "pill".to_string()])
            .halign(gtk::Align::Center)
            .build();

        let win = self.clone();
        center_refresh.connect_clicked(move |_| {
            win.try_detect_device();
        });
        no_device.set_child(Some(&center_refresh));

        stack.add_named(&no_device, Some("no-device"));

        // Device config page (placeholder, will be replaced on detection)
        let device_page = DevicePage::new();
        stack.add_named(&device_page, Some("device"));

        // Decide which page to show first
        let installed = crate::rivalcfg::is_installed();
        let settings = gio::Settings::new("com.polydez.rivaltune");
        let onboarding_done = settings.boolean("onboarding-complete");

        if !installed || !onboarding_done {
            stack.set_visible_child_name("onboarding");
        } else {
            self.try_detect_device();
        }

        // Wire onboarding completion
        let win = self.clone();
        onboarding.connect_complete(move || {
            let settings = gio::Settings::new("com.polydez.rivaltune");
            let _ = settings.set_boolean("onboarding-complete", true);
            win.try_detect_device();
        });
    }

    fn setup_refresh(&self) {
        let win = self.clone();
        self.imp().refresh_button.connect_clicked(move |_| {
            win.try_detect_device();
        });
    }

    fn setup_actions(&self) {
        let tab1_action = gio::ActionEntry::builder("tab1")
            .activate(move |win: &Self, _, _| {
                win.select_tab(0);
            })
            .build();

        let tab2_action = gio::ActionEntry::builder("tab2")
            .activate(move |win: &Self, _, _| {
                win.select_tab(1);
            })
            .build();

        self.add_action_entries([tab1_action, tab2_action]);
    }

    fn select_tab(&self, index: u32) {
        let imp = self.imp();
        let stack = &imp.main_stack;
        let Some(child) = stack.child_by_name("device") else {
            return;
        };

        let Ok(device_page) = child.downcast::<DevicePage>() else {
            return;
        };

        device_page.select_tab(index);
    }

    fn try_detect_device(&self) {
        let imp = self.imp();
        let stack = &imp.main_stack;
        let controls_box = imp.device_controls_box.get();
        let tabs_box = imp.header_tabs_box.get();

        while let Some(child) = controls_box.first_child() {
            controls_box.remove(&child);
        }

        while let Some(child) = tabs_box.first_child() {
            tabs_box.remove(&child);
        }

        if let Some(profile) = crate::devices::detect_device() {
            // Remove old device page if exists
            if let Some(old) = stack.child_by_name("device") {
                stack.remove(&old);
            }

            let device_page = DevicePage::new();
            device_page.load_device(profile);
            let controls = device_page.build_header_controls(profile);
            if let Some(tab_switcher) = device_page.build_header_tab_switcher() {
                tabs_box.append(&tab_switcher);
                tabs_box.set_visible(true);
            }
            controls_box.append(&controls);
            controls_box.set_visible(true);
            stack.add_named(&device_page, Some("device"));
            stack.set_visible_child_name("device");
        } else {
            tabs_box.set_visible(false);
            controls_box.set_visible(false);
            stack.set_visible_child_name("no-device");
        }
    }
}
