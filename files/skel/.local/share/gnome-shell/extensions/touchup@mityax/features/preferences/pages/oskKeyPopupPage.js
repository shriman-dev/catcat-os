import Adw from 'gi://Adw';
import GObject from 'gi://GObject';
import { settings } from '../../../settings.js';
import Gtk from 'gi://Gtk';
import { buildPreferencesGroup, buildSwitchRow, buildSpinRow } from '../uiUtils.js';

class OskKeyPopupPage extends Adw.PreferencesPage {
    static {
        GObject.registerClass(this);
    }
    constructor() {
        super({
            name: 'osk-key-popups',
            title: "OSK Key Popups",
            icon_name: "input-keyboard-symbolic",
        });
        this.add(buildPreferencesGroup({
            title: "OSK Key Popups",
            description: "Configure the popups appearing when pressing a button in the On-Screen-Keyboard (OSK).",
            children: [
                buildSwitchRow({
                    title: "Enable OSK Key Popups",
                    subtitle: "Toggle to enable or disable the OSK key popup feature",
                    setting: settings.oskKeyPopups.enabled
                }),
                buildSpinRow({
                    title: "Popup Duration",
                    subtitle: "Set how long (in milliseconds) to show the OSK key popups.",
                    setting: settings.oskKeyPopups.duration,
                    adjustment: new Gtk.Adjustment({
                        lower: settings.oskKeyPopups.duration.min,
                        upper: settings.oskKeyPopups.duration.max,
                        step_increment: 1,
                        page_increment: 10,
                    }),
                })
            ]
        }));
    }
}

export { OskKeyPopupPage };
