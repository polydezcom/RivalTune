/* application.rs
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

use gettextrs::gettext;
use adw::prelude::*;
use adw::subclass::prelude::*;
use gtk::{gio, glib};
use std::cell::Cell;

use crate::config::VERSION;
use crate::RivaltuneWindow;

mod imp {
    use super::*;

    #[derive(Debug, Default)]
    pub struct RivaltuneApplication {
        pub css_loaded: Cell<bool>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for RivaltuneApplication {
        const NAME: &'static str = "RivaltuneApplication";
        type Type = super::RivaltuneApplication;
        type ParentType = adw::Application;
    }

    impl ObjectImpl for RivaltuneApplication {
        fn constructed(&self) {
            self.parent_constructed();
            let obj = self.obj();
            obj.setup_gactions();
            obj.set_accels_for_action("app.quit", &["<control>q"]);
            obj.set_accels_for_action("win.tab1", &["<alt>1"]);
            obj.set_accels_for_action("win.tab2", &["<alt>2"]);
        }
    }

    impl ApplicationImpl for RivaltuneApplication {
        // We connect to the activate callback to create a window when the application
        // has been launched. Additionally, this callback notifies us when the user
        // tries to launch a "second instance" of the application. When they try
        // to do that, we'll just present any existing window.
        fn activate(&self) {
            let application = self.obj();

            if !self.css_loaded.get() {
                application.setup_css();
                self.css_loaded.set(true);
            }

            // Get the current window or create one if necessary
            let window = application.active_window().unwrap_or_else(|| {
                let window = RivaltuneWindow::new(&*application);
                window.upcast()
            });

            // Ask the window manager/compositor to present the window
            window.present();
        }
    }

    impl GtkApplicationImpl for RivaltuneApplication {}
    impl AdwApplicationImpl for RivaltuneApplication {}
}

glib::wrapper! {
    pub struct RivaltuneApplication(ObjectSubclass<imp::RivaltuneApplication>)
        @extends gio::Application, gtk::Application, adw::Application,
        @implements gio::ActionGroup, gio::ActionMap;
}

impl RivaltuneApplication {
    pub fn new(application_id: &str, flags: &gio::ApplicationFlags) -> Self {
        glib::Object::builder()
            .property("application-id", application_id)
            .property("flags", flags)
            .property("resource-base-path", "/com/polydez/rivaltune")
            .build()
    }

    fn setup_gactions(&self) {
        let quit_action = gio::ActionEntry::builder("quit")
            .activate(move |app: &Self, _, _| app.quit())
            .build();
        let about_action = gio::ActionEntry::builder("about")
            .activate(move |app: &Self, _, _| app.show_about())
            .build();
        let shortcuts_action = gio::ActionEntry::builder("shortcuts")
            .activate(move |app: &Self, _, _| app.show_shortcuts())
            .build();
        self.add_action_entries([quit_action, about_action, shortcuts_action]);
    }

    fn setup_css(&self) {
        let provider = gtk::CssProvider::new();
        provider.load_from_resource("/com/polydez/rivaltune/style.css");

        if let Some(display) = gtk::gdk::Display::default() {
            gtk::style_context_add_provider_for_display(
                &display,
                &provider,
                gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
            );
        }
    }

    fn show_about(&self) {
        let window = self.active_window().unwrap();
        let about = adw::AboutDialog::builder()
            .application_name("RivalTune")
            .application_icon("com.polydez.rivaltune")
            .developer_name("berk")
            .version(VERSION)
            .developers(vec!["berk"])
            .comments("Configure your SteelSeries mouse on Linux using rivalcfg")
            .website("https://github.com/polydezcom/RivalTune")
            .issue_url("https://github.com/polydezcom/RivalTune/issues")
            .license_type(gtk::License::Gpl30)
            // Translators: Replace "translator-credits" with your name/username, and optionally an email or URL.
            .translator_credits(&gettext("translator-credits"))
            .copyright("© 2026 berk")
            .build();

        about.present(Some(&window));
    }

    fn show_shortcuts(&self) {
        let window = self.active_window().unwrap();
        let builder = gtk::Builder::from_resource("/com/polydez/rivaltune/shortcuts-dialog.ui");
        let dialog = builder
            .object::<gtk::ShortcutsWindow>("shortcuts_dialog")
            .unwrap();
        dialog.set_transient_for(Some(&window));
        dialog.present();
    }
}
