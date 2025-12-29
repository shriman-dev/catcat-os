/* -*- mode: js2; js2-basic-offset: 4; indent-tabs-mode: nil -*- */

import Gtk from 'gi://Gtk'
import Adw from 'gi://Adw';

import {ExtensionPreferences, gettext as _} from 'resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js';

export default class ActivityAppLauncherPreferences extends ExtensionPreferences {
    fillPreferencesWindow(window) {

        let settings = this.getSettings();
        const page = new Adw.PreferencesPage();

        const group = new Adw.PreferencesGroup({
            title: 'Activity App Launcher',
        });
        page.add(group);

        window.add(page);

        let frame = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL});
        frame.margin_end = frame.margin_start = frame.margin_top = frame.margin_bottom = 10;

        let show_favorites = this.buildSwitcher(settings, 'show-favorites',_("Show 'Favorite apps' in the category menu."));
        frame.append(show_favorites);

        let show_frequent = this.buildSwitcher(settings, 'show-frequent',_("Show 'Frequent apps' in the category menu."));
        frame.append(show_frequent);

        let show_tooltip = this.buildSwitcher(settings, 'show-centered',_("Show the categories vertically centered."));
        frame.append(show_tooltip);

        frame.show();

        group.add(frame);
    }

    buildSwitcher(settings, key, labeltext) {
        let hbox = new Gtk.Box({orientation: Gtk.Orientation.HORIZONTAL });
        hbox.margin_end = hbox.margin_start = hbox.margin_top = hbox.margin_bottom = 10;

        let label = new Gtk.Label({label: labeltext, xalign: 0 });

        let switcher = new Gtk.Switch({active: settings.get_boolean(key)});

        settings.bind(key,switcher,'active',3);

        hbox.append(label);
        hbox.append(switcher);

        return hbox;
    }
}
