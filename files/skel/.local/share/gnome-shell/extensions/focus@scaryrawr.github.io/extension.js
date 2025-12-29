import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';
import GLib from 'gi://GLib';
import Meta from 'gi://Meta';
import Clutter from 'gi://Clutter';

function get_configuration_dir(metadata) {
    const config_dir = GLib.build_filenamev([GLib.get_user_config_dir(), metadata.uuid]);
    if (GLib.file_test(config_dir, GLib.FileTest.IS_DIR)) {
        return config_dir;
    }
    // Legacy configuration location
    return GLib.build_filenamev([GLib.get_user_config_dir(), metadata.name]);
}
function get_config_path(metadata, name) {
    return GLib.build_filenamev([get_configuration_dir(metadata), name]);
}
function load_config(metadata, name) {
    const file_path = get_config_path(metadata, name);
    if (!GLib.file_test(file_path, GLib.FileTest.IS_REGULAR)) {
        return undefined;
    }
    const [loaded, content] = GLib.file_get_contents(file_path);
    if (!loaded) {
        return undefined;
    }
    try {
        return JSON.parse(new TextDecoder().decode(content));
    }
    catch {
        return undefined;
    }
}

/** 100% opacity value */
const DEFAULT_OPACITY = 255;
/** Effect that has background blur */
const BLUR_EFFECT_NAME = 'gnome-focus-blur';
/** Effect that has desaturation */
const DESATURATE_EFFECT_NAME = 'gnome-focus-desaturate';
/** Window Types that should be considered for focus changes */
const WINDOW_TYPES = [Meta.WindowType.NORMAL];
function is_valid_window_type(window) {
    return WINDOW_TYPES.includes(window.get_window_type());
}
class GnomeFocusManager {
    settings;
    special_focus;
    ignore_inactive;
    active_window_actor;
    active_destroy_signal;
    constructor(settings, special_focus, ignore_inactive) {
        this.settings = settings;
        this.special_focus = special_focus;
        this.ignore_inactive = ignore_inactive;
        settings.on('focus-opacity', this.update_focused_window_opacity);
        settings.on('special-opacity', this.update_special_focused_window_opacity);
        settings.on('inactive-opacity', this.update_inactive_windows_opacity);
        settings.on('is-background-blur', this.update_is_background_blur);
        settings.on('is-desaturate-enabled', this.update_is_desaturate_enabled);
        settings.on('desaturate-percentage', this.update_desaturate_percentage);
    }
    is_special = (window_actor) => {
        if (!this.special_focus || window_actor.is_destroyed()) {
            return false;
        }
        const window = window_actor.get_meta_window();
        return (!!window &&
            is_valid_window_type(window) &&
            this.special_focus.some(criteria => criteria === window.get_wm_class() ||
                criteria === window.get_wm_class_instance() ||
                criteria === window.get_title()));
    };
    is_ignored = (window_actor) => {
        if (window_actor.is_destroyed()) {
            return true;
        }
        if (!this.ignore_inactive) {
            return false;
        }
        const window = window_actor.get_meta_window();
        return (!!window &&
            (!is_valid_window_type(window) ||
                this.ignore_inactive.some(criteria => criteria === window.get_wm_class() ||
                    criteria === window.get_wm_class_instance() ||
                    criteria === window.get_title())));
    };
    static set_opacity(window_actor, percentage) {
        if (window_actor.is_destroyed()) {
            return;
        }
        const true_opacity = (DEFAULT_OPACITY * percentage) / 100;
        for (const actor of window_actor.get_children()) {
            actor.set_opacity(true_opacity);
        }
        window_actor.set_opacity(true_opacity);
    }
    set_blur(window_actor, blur) {
        const meta_window = window_actor.get_meta_window();
        if (window_actor.is_destroyed() || !meta_window || !is_valid_window_type(meta_window)) {
            return;
        }
        let blur_effect = window_actor.get_effect(BLUR_EFFECT_NAME);
        if (!blur_effect) {
            blur_effect = Clutter.BlurEffect.new();
            window_actor.add_effect_with_name(BLUR_EFFECT_NAME, blur_effect);
        }
        blur_effect.set_enabled(blur);
    }
    set_desaturate(window_actor, desaturate, percentage) {
        const meta_window = window_actor.get_meta_window();
        if (window_actor.is_destroyed() || !meta_window || !is_valid_window_type(meta_window)) {
            return;
        }
        let desaturate_effect = window_actor.get_effect(DESATURATE_EFFECT_NAME);
        if (!desaturate_effect) {
            desaturate_effect = Clutter.DesaturateEffect.new(percentage / 100);
            window_actor.add_effect_with_name(DESATURATE_EFFECT_NAME, desaturate_effect);
        }
        desaturate_effect.set_factor(percentage / 100);
        desaturate_effect.set_enabled(desaturate);
    }
    update_inactive_window_actor = (window_actor) => {
        if (window_actor.is_destroyed() || this.is_ignored(window_actor)) {
            return;
        }
        GnomeFocusManager.set_opacity(window_actor, this.settings.inactive_opacity);
        this.set_blur(window_actor, this.settings.is_background_blur);
        this.set_desaturate(window_actor, this.settings.is_desaturate_enabled, this.settings.desaturate_percentage);
    };
    set_active_window_actor = (window_actor) => {
        if (this.active_window_actor === window_actor) {
            return;
        }
        if (this.active_window_actor) {
            this.update_inactive_window_actor(this.active_window_actor);
            if (this.active_destroy_signal != null) {
                this.active_window_actor.disconnect(this.active_destroy_signal);
                delete this.active_destroy_signal;
            }
        }
        if (window_actor.is_destroyed() || this.is_ignored(window_actor)) {
            delete this.active_window_actor;
            return;
        }
        this.active_window_actor = window_actor;
        const opacity = this.is_special(this.active_window_actor)
            ? this.settings.special_focus_opacity
            : this.settings.focus_opacity;
        GnomeFocusManager.set_opacity(this.active_window_actor, opacity);
        this.set_blur(this.active_window_actor, false);
        this.set_desaturate(this.active_window_actor, false, this.settings.desaturate_percentage);
        this.active_destroy_signal = this.active_window_actor.connect('destroy', actor => {
            if (this.active_window_actor === actor) {
                delete this.active_window_actor;
                delete this.active_destroy_signal;
            }
        });
    };
    update_special_focused_window_opacity = (value) => {
        if (undefined === this.active_window_actor || !this.is_special(this.active_window_actor)) {
            return;
        }
        GnomeFocusManager.set_opacity(this.active_window_actor, value);
    };
    update_focused_window_opacity = (value) => {
        if (undefined === this.active_window_actor || this.is_special(this.active_window_actor)) {
            return;
        }
        GnomeFocusManager.set_opacity(this.active_window_actor, value);
    };
    update_inactive_windows_opacity = (value) => {
        for (const window_actor of global.get_window_actors()) {
            if (window_actor === this.active_window_actor || this.is_ignored(window_actor)) {
                continue;
            }
            GnomeFocusManager.set_opacity(window_actor, value);
        }
    };
    update_is_background_blur = (blur) => {
        for (const window_actor of global.get_window_actors()) {
            if (window_actor === this.active_window_actor || this.is_ignored(window_actor)) {
                continue;
            }
            this.set_blur(window_actor, blur);
        }
    };
    update_is_desaturate_enabled = (enabled) => {
        const percentage = this.settings.desaturate_percentage;
        for (const window_actor of global.get_window_actors()) {
            if (window_actor === this.active_window_actor || this.is_ignored(window_actor)) {
                continue;
            }
            this.set_desaturate(window_actor, enabled, percentage);
        }
    };
    update_desaturate_percentage = (percentage) => {
        const enabled = this.settings.is_desaturate_enabled;
        for (const window_actor of global.get_window_actors()) {
            if (window_actor === this.active_window_actor || this.is_ignored(window_actor)) {
                continue;
            }
            this.set_desaturate(window_actor, enabled, percentage);
        }
    };
    disable() {
        this.settings.clear();
        for (const window_actor of global.get_window_actors()) {
            GnomeFocusManager.set_opacity(window_actor, 100);
            window_actor.remove_effect_by_name(BLUR_EFFECT_NAME);
            window_actor.remove_effect_by_name(DESATURATE_EFFECT_NAME);
        }
    }
}

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

class Timeouts {
    /** IDs that have been created by the timeout */
    active;
    constructor() {
        this.active = new Set();
    }
    add = (callback, interval = 0, priority = GLib.PRIORITY_DEFAULT) => {
        let timeout_id = null;
        this.active.add((timeout_id = GLib.timeout_add(priority, interval, () => {
            const result = callback();
            if (!result && timeout_id !== null) {
                this.active.delete(timeout_id);
            }
            return result;
        })));
    };
    clear = () => {
        this.active.forEach(id => {
            GLib.Source.remove(id);
        });
        this.active.clear();
    };
}

let create_signal;
let extension_instance;
let timeout_manager;
function get_window_actor(window) {
    for (const actor of global.get_window_actors()) {
        if (!actor.is_destroyed() && actor.get_meta_window() === window) {
            return actor;
        }
    }
    return undefined;
}
function focus_changed(window) {
    const actor = get_window_actor(window);
    if (actor) {
        extension_instance?.set_active_window_actor(actor);
    }
}
class GnomeFocus extends Extension {
    enable() {
        extension_instance = new GnomeFocusManager(get_settings(this.getSettings()), load_config(this.metadata, 'special_focus.json'), load_config(this.metadata, 'ignore_focus.json'));
        create_signal = global.display.connect('window-created', function (_, win) {
            if (!is_valid_window_type(win)) {
                return;
            }
            win._focus_extension_signal = win.connect('focus', focus_changed);
            timeout_manager ??= new Timeouts();
            // In Wayland, when we have a new window, we need ot have a slight delay before
            // attempting to set the transparency.
            timeout_manager.add(() => {
                if (!win) {
                    return false;
                }
                if (undefined === extension_instance) {
                    return false;
                }
                // We could have something go wrong, but always want to set false,
                // otherwise we end up being called more than once
                try {
                    const actor = get_window_actor(win);
                    if (undefined === actor || actor.is_destroyed()) {
                        return false;
                    }
                    if (win.has_focus()) {
                        extension_instance.set_active_window_actor(actor);
                    }
                    else {
                        extension_instance.update_inactive_window_actor(actor);
                    }
                }
                catch (err) {
                    console.error(`Error on new window: ${err}`);
                }
                return false;
            }, 350);
        });
        for (const actor of global.get_window_actors()) {
            if (actor.is_destroyed()) {
                continue;
            }
            const win = actor.get_meta_window();
            if (!is_valid_window_type(win)) {
                continue;
            }
            if (undefined === win._focus_extension_signal) {
                win._focus_extension_signal = win.connect('focus', focus_changed);
            }
            if (win.has_focus()) {
                extension_instance.set_active_window_actor(actor);
            }
            else {
                extension_instance.update_inactive_window_actor(actor);
            }
        }
    }
    disable() {
        if (undefined !== create_signal) {
            global.display.disconnect(create_signal);
            create_signal = undefined;
        }
        timeout_manager?.clear();
        timeout_manager = undefined;
        for (const actor of global.get_window_actors()) {
            if (actor.is_destroyed()) {
                continue;
            }
            const win = actor.get_meta_window();
            if (win?._focus_extension_signal) {
                win.disconnect(win._focus_extension_signal);
                delete win._focus_extension_signal;
            }
        }
        if (undefined !== extension_instance) {
            extension_instance.disable();
            extension_instance = undefined;
        }
    }
}

export { GnomeFocus as default };
