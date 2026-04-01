/* onboarding.rs
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
use gtk::{gio, glib};
use std::cell::RefCell;

mod imp {
    use super::*;

    #[derive(Default, gtk::CompositeTemplate)]
    #[template(resource = "/com/polydez/rivaltune/onboarding.ui")]
    pub struct OnboardingPage {
        #[template_child]
        pub status_page: TemplateChild<adw::StatusPage>,
        #[template_child]
        pub install_button: TemplateChild<gtk::Button>,
        #[template_child]
        pub udev_button: TemplateChild<gtk::Button>,
        #[template_child]
        pub continue_button: TemplateChild<gtk::Button>,
        #[template_child]
        pub rivalcfg_status_label: TemplateChild<gtk::Label>,
        #[template_child]
        pub udev_status_label: TemplateChild<gtk::Label>,
        pub complete_callback: RefCell<Option<Box<dyn Fn()>>>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for OnboardingPage {
        const NAME: &'static str = "RivaltuneOnboardingPage";
        type Type = super::OnboardingPage;
        type ParentType = adw::Bin;

        fn class_init(klass: &mut Self::Class) {
            klass.bind_template();
            klass.bind_template_callbacks();
        }

        fn instance_init(obj: &glib::subclass::InitializingObject<Self>) {
            obj.init_template();
        }
    }

    #[gtk::template_callbacks]
    impl OnboardingPage {
        #[template_callback]
        fn on_install_clicked(&self) {
            // Open a terminal or browser to install rivalcfg
            let _ = gio::AppInfo::launch_default_for_uri(
                "https://flozz.github.io/rivalcfg/install.html",
                None::<&gio::AppLaunchContext>,
            );
        }

        #[template_callback]
        fn on_udev_clicked(&self) {
            let udev_label = self.udev_status_label.clone();

            match crate::rivalcfg::update_udev() {
                Ok(_) => {
                    udev_label.set_label("udev rules updated. Replug your mouse.");
                    udev_label.add_css_class("success");
                    udev_label.remove_css_class("error");
                    self.obj().refresh_status();
                }
                Err(e) => {
                    udev_label.set_label(&format!("Failed: {}", e));
                    udev_label.add_css_class("error");
                    udev_label.remove_css_class("success");
                }
            }
        }

        #[template_callback]
        fn on_continue_clicked(&self) {
            let cb = self.complete_callback.borrow();
            if let Some(ref callback) = *cb {
                callback();
            }
        }
    }

    impl ObjectImpl for OnboardingPage {
        fn constructed(&self) {
            self.parent_constructed();
            self.obj().refresh_status();
        }
    }

    impl WidgetImpl for OnboardingPage {}
    impl BinImpl for OnboardingPage {}
}

glib::wrapper! {
    pub struct OnboardingPage(ObjectSubclass<imp::OnboardingPage>)
        @extends gtk::Widget, adw::Bin;
}

impl OnboardingPage {
    pub fn new() -> Self {
        glib::Object::builder().build()
    }

    pub fn refresh_status(&self) {
        let imp = self.imp();

        let installed = crate::rivalcfg::is_installed();
        let udev_ok = crate::rivalcfg::check_udev();

        if installed {
            let ver = crate::rivalcfg::version().unwrap_or_else(|| "unknown".to_string());
            imp.rivalcfg_status_label.set_label(&format!("rivalcfg is installed ({})", ver));
            imp.rivalcfg_status_label.add_css_class("success");
            imp.rivalcfg_status_label.remove_css_class("error");
            imp.install_button.set_sensitive(false);
            imp.install_button.set_label("Installed");
        } else {
            imp.rivalcfg_status_label.set_label("rivalcfg is not installed");
            imp.rivalcfg_status_label.add_css_class("error");
            imp.rivalcfg_status_label.remove_css_class("success");
            imp.install_button.set_sensitive(true);
        }

        if udev_ok {
            imp.udev_status_label.set_label("udev rules are installed");
            imp.udev_status_label.add_css_class("success");
            imp.udev_status_label.remove_css_class("error");
        } else {
            imp.udev_status_label.set_label("udev rules need to be installed");
            imp.udev_status_label.add_css_class("error");
            imp.udev_status_label.remove_css_class("success");
        }

        // Enable continue only if rivalcfg is installed
        imp.continue_button.set_sensitive(installed);
    }

    pub fn connect_complete<F: Fn() + 'static>(&self, callback: F) {
        self.imp().complete_callback.replace(Some(Box::new(callback)));
    }
}
