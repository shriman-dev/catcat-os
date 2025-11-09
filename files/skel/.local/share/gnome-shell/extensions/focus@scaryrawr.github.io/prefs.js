import Gtk from 'gi://Gtk';
import { ExtensionPreferences } from 'resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js';

class FocusSettings {
    settings;
    connection;
    listeners = {
        'focus-opacity': [],
        'inactive-opacity': [],
        'special-opacity': [],
        'is-background-blur': [],
        'desaturate-percentage': [],
        'is-desaturate-enabled': []
    };
    constructor(settings) {
        this.settings = settings;
    }
    get focus_opacity() {
        return this.settings.get_uint('focus-opacity');
    }
    set_focus_opacity(val) {
        this.settings.set_uint('focus-opacity', val);
    }
    get special_focus_opacity() {
        return this.settings.get_uint('special-focus-opacity');
    }
    set_special_focus_opacity(val) {
        this.settings.set_uint('special-focus-opacity', val);
    }
    get inactive_opacity() {
        return this.settings.get_uint('inactive-opacity');
    }
    set_inactive_opacity(val) {
        this.settings.set_uint('inactive-opacity', val);
    }
    get is_background_blur() {
        return this.settings.get_boolean('is-background-blur');
    }
    set_is_background_blur(val) {
        this.settings.set_boolean('is-background-blur', val);
    }
    get desaturate_percentage() {
        return this.settings.get_uint('desaturate-percentage');
    }
    set_desaturate_percentage(val) {
        this.settings.set_uint('desaturate-percentage', val);
    }
    get is_desaturate_enabled() {
        return this.settings.get_boolean('is-desaturate-enabled');
    }
    set_is_desaturate_enabled(val) {
        this.settings.set_boolean('is-desaturate-enabled', val);
    }
    on(event, callback) {
        if (this.connection === undefined) {
            this.connection = this.settings.connect('changed', (_, key) => {
                switch (key) {
                    case 'focus-opacity':
                    case 'inactive-opacity':
                    case 'special-opacity':
                    case 'desaturate-percentage':
                        this.emit(key, this.settings.get_uint(key));
                        break;
                    case 'is-background-blur':
                    case 'is-desaturate-enabled':
                        this.emit(key, this.settings.get_boolean(key));
                        break;
                }
            });
        }
        this.listeners[event].push(callback);
    }
    off(event, callback) {
        const index = this.listeners[event].indexOf(callback);
        if (index >= 0) {
            this.listeners[event].slice(index, 1);
        }
        for (const key in this.listeners) {
            if (this.listeners[key].length > 0) {
                return;
            }
        }
        this.clear();
    }
    emit(event, value) {
        for (const listener of this.listeners[event]) {
            listener(value);
        }
    }
    clear() {
        if (this.connection !== undefined) {
            this.settings.disconnect(this.connection);
            delete this.connection;
        }
        for (const key in this.listeners) {
            if (this.listeners[key].length > 0) {
                return;
            }
        }
    }
}
function get_settings(settings) {
    return new FocusSettings(settings);
}

class GnomeFocusPreferences extends ExtensionPreferences {
    init() { }
    getPreferencesWidget() {
        const settings = get_settings(this.getSettings());
        const widget = new Gtk.Grid({
            columnSpacing: 12,
            rowSpacing: 12,
            visible: true
        });
        const title = new Gtk.Label({
            label: '<b>' + this.metadata.name + ' Extension Preferences</b>',
            halign: Gtk.Align.START,
            useMarkup: true,
            visible: true
        });
        widget.attach(title, 0, 0, 1, 1);
        const create_spin_button = ({ label, get_current_value, set_value, min, max, step }) => {
            const item_label = new Gtk.Label({
                label: `${label}: [${Math.floor(get_current_value())}]`,
                halign: Gtk.Align.START,
                visible: true
            });
            const spin_button = Gtk.SpinButton.new_with_range(min, max, step);
            spin_button.set_visible(true);
            spin_button.set_value(get_current_value());
            spin_button.connect('value-changed', (emitter) => {
                const value = emitter.get_value();
                item_label.set_label(`${label}: [${Math.floor(value)}]`);
                set_value(value);
            });
            return [item_label, spin_button];
        };
        const [focus_opacity_label, focus_opacity_scale] = create_spin_button({
            label: 'Focus Opacity',
            get_current_value: () => settings.focus_opacity,
            set_value: value => {
                settings.set_focus_opacity(value);
            },
            min: 50,
            max: 100,
            step: 5
        });
        widget.attach(focus_opacity_label, 0, 1, 1, 1);
        widget.attach(focus_opacity_scale, 0, 2, 2, 1);
        const [inactive_opacity_label, inactive_opacity_scale] = create_spin_button({
            label: 'Inactive Opacity',
            get_current_value: () => settings.inactive_opacity,
            set_value: value => {
                settings.set_inactive_opacity(value);
            },
            min: 50,
            max: 100,
            step: 5
        });
        widget.attach(inactive_opacity_label, 0, 3, 1, 1);
        widget.attach(inactive_opacity_scale, 0, 4, 2, 1);
        const [special_focus_opacity_label, special_focus_opacity_scale] = create_spin_button({
            label: 'Special Focus Opacity',
            get_current_value: () => settings.special_focus_opacity,
            set_value: value => {
                settings.set_special_focus_opacity(value);
            },
            min: 50,
            max: 100,
            step: 5
        });
        widget.attach(special_focus_opacity_label, 0, 5, 1, 1);
        widget.attach(special_focus_opacity_scale, 0, 6, 2, 1);
        const blur_label = new Gtk.Label({
            label: 'Blur',
            halign: Gtk.Align.START,
            visible: true
        });
        const blur_toggle = new Gtk.Switch({
            visible: true,
            active: settings.is_background_blur
        });
        blur_toggle.connect('notify::active', () => {
            settings.set_is_background_blur(blur_toggle.get_active());
        });
        widget.attach(blur_label, 0, 7, 1, 1);
        widget.attach(blur_toggle, 1, 7, 1, 1);
        const desaturate_label = new Gtk.Label({
            label: 'Desaturate Inactive Windows',
            halign: Gtk.Align.START,
            visible: true
        });
        const desaturate_toggle = new Gtk.Switch({
            visible: true,
            active: settings.is_desaturate_enabled
        });
        desaturate_toggle.connect('notify::active', () => {
            settings.set_is_desaturate_enabled(desaturate_toggle.get_active());
        });
        widget.attach(desaturate_label, 0, 8, 1, 1);
        widget.attach(desaturate_toggle, 1, 8, 1, 1);
        const [desaturate_percentage_label, desaturate_percentage_scale] = create_spin_button({
            label: 'Desaturate Percentage',
            get_current_value: () => settings.desaturate_percentage,
            set_value: value => {
                settings.set_desaturate_percentage(value);
            },
            min: 0,
            max: 100,
            step: 10
        });
        widget.attach(desaturate_percentage_label, 0, 9, 1, 1);
        widget.attach(desaturate_percentage_scale, 0, 10, 2, 1);
        return widget;
    }
}

export { GnomeFocusPreferences as default };
