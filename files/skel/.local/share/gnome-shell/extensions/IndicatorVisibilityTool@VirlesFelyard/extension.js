import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';
import { panel } from 'resource:///org/gnome/shell/ui/main.js';
import GLib from 'gi://GLib';


export default class IndicatorVisibilityToolExtension extends Extension {
    enable() {
        this._settings = this.getSettings('org.gnome.shell.extensions.IndicatorVisibilityTool');
        GLib.idle_add(GLib.PRIORITY_DEFAULT, () => {
            if (!panel.statusArea.quickSettings._system)
                return GLib.SOURCE_CONTINUE;
			
			this._signals = new Map();
            this._indicators = {
                'system-mode':        panel.statusArea.quickSettings._system,
                'unsafe-mode':        panel.statusArea.quickSettings._unsafeMode,
                'volume-output-mode': panel.statusArea.quickSettings._volumeOutput,
                'rfkill-mode':        panel.statusArea.quickSettings._rfkill,
                'bluetooth-mode':     panel.statusArea.quickSettings._bluetooth,
                'network-mode':       panel.statusArea.quickSettings._network,
                'night-light-mode':   panel.statusArea.quickSettings._nightLight,
                'thunderbolt-mode':   panel.statusArea.quickSettings._thunderbolt,
                'location-mode':      panel.statusArea.quickSettings._location,
                'volume-input-mode':  panel.statusArea.quickSettings._volumeInput,
                'camera-mode':        panel.statusArea.quickSettings._camera,
                'remote-access-mode': panel.statusArea.quickSettings._remoteAccess
            };
    
            this._settingsChangedId = this._settings.connect('changed', this._updateIndicators.bind(this));
            for (const [key, indicator] of Object.entries(this._indicators)) {
                if (indicator) {
                    const signalId = indicator.connect('notify::visible', this._updateIndicatorVisibility.bind(this, key, indicator));
                    this._signals.set(indicator, signalId);
                    this._updateIndicatorVisibility(key, indicator);
                }
            }
              
            return GLib.SOURCE_REMOVE;
        });
    }


    disable() {
        if (this._settingsChangedId) this._settings.disconnect(this._settingsChangedId);
        this._signals.forEach((signalId, indicator) => {
            if (indicator && signalId) indicator.disconnect(signalId);
        });

        this._indicators = this._settings = this._settingsChangedId = null;
        this._signals.clear();
    }


	_updateIndicators() {
		Object.entries(this._indicators || {}).forEach(([key, indicator]) => {
		    if (indicator) this._updateIndicatorVisibility(key, indicator);
		});
	}


    _updateIndicatorVisibility(key, indicator) {
        const _indicator = indicator._indicator || indicator;
        const mode = this._settings.get_string(key);

        switch (mode) {
            case 'hidden':
                _indicator.hide();
                break;
            case 'shown':
                if (!_indicator.visible || !_indicator.get_parent()) {
                    if (!_indicator.get_parent()) panel.statusArea.quickSettings.add_child(indicator);
                    _indicator.show();
                }
                break;
        }
    }
}