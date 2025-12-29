import Adw from 'gi://Adw';
import Gtk from 'gi://Gtk';
import { ExtensionPreferences } from 'resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js';

export default class IndicatorVisibilityToolPreferences extends ExtensionPreferences {
    fillPreferencesWindow(window) {
        let settings = this.getSettings('org.gnome.shell.extensions.IndicatorVisibilityTool');
        const page = new Adw.PreferencesPage();
        window.add(page);
        const group = new Adw.PreferencesGroup();
        page.add(group);

        const indicators = [
            'system-mode', 
            'unsafe-mode', 
            'volume-output-mode',
            'rfkill-mode', 
            'bluetooth-mode', 
            'network-mode',
            'night-light-mode', 
            'thunderbolt-mode', 
            'location-mode',
            'volume-input-mode', 
            'camera-mode', 
            'remote-access-mode'
        ];

        indicators.forEach((settingKey) => {            
            const actRow = new Adw.ActionRow({ title: `Set ${settingKey.replace('-mode', '').replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase())} visibility mode`});
            const box = new Gtk.Box({ orientation: Gtk.Orientation.HORIZONTAL, css_classes: ['linked'] });
            group.add(actRow);

            const defaultButton = new Gtk.ToggleButton({ label: 'Default' });
            defaultButton.connect('toggled', () => {
                if (defaultButton.active) setButtonValue('default');
            });

            box.append(defaultButton);

            const shownButton = new Gtk.ToggleButton({ label: 'Shown' });
            shownButton.connect('toggled', () => {
                if (shownButton.active) setButtonValue('shown');
            });

            box.append(shownButton);

            const hiddenButton = new Gtk.ToggleButton({ label: 'Hidden' });
            hiddenButton.connect('toggled', () => {
                if (hiddenButton.active) setButtonValue('hidden');
            });

            box.append(hiddenButton);

            const updateButtons = () => {
                const value = settings.get_string(settingKey);
                defaultButton.active = value === 'default';
                shownButton.active =   value === 'shown';
                hiddenButton.active =  value === 'hidden';
            };

            const setButtonValue = (value) => {
                settings.set_string(settingKey, value);
                updateButtons();
            };

            actRow.add_suffix(box);
            updateButtons();
        });
    }
}
