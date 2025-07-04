import { PatchManager } from './utils/patchManager.js';
import NavigationBarFeature from './features/navigationBar/navigationBarFeature.js';
import OskKeyPopupsFeature from './features/osk/oskKeyPopupsFeature.js';
import { NotificationGesturesFeature } from './features/notifications/notificationGesturesFeature.js';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';
import { initSettings, uninitSettings } from './features/preferences/backend.js';
import { FloatingScreenRotateButtonFeature } from './features/screenRotateUtils/floatingScreenRotateButtonFeature.js';
import { Delay } from './utils/delay.js';
import { assetsGResourceFile } from './config.js';
import { settings } from './settings.js';
import Gio from 'gi://Gio';
import DonationsFeature from './features/donations/donationsFeature.js';
import { TouchModeService } from './services/touchModeService.js';

class TouchUpExtension extends Extension {
    static instance;
    pm;
    features = [];
    enable() {
        // This is the root patch manager of which all other patch managers are descendents:
        this.pm = new PatchManager("root");
        // Load assets:
        this.pm.patch(() => {
            const assets = Gio.resource_load(this.dir.get_child(assetsGResourceFile).get_path());
            Gio.resources_register(assets);
            return () => Gio.resources_unregister(assets);
        }, 'load-and-register-assets');
        // Initialize settings:
        this.pm.patch(() => {
            initSettings(this.getSettings());
            return () => uninitSettings();
        }, 'init-settings');
        TouchUpExtension.instance = this;
        // This is the entry point for all services (= small supplementary ExtensionFeature's, that other
        // features need to work):
        this.defineServices();
        // This is the entry point for all features of this extension:
        this.defineFeatures();
        // Sync ui on touch-mode and monitor changes:
        this.getFeature(TouchModeService)?.onChanged.connect(() => this.syncUI());
        this.pm.connectTo(global.backend.get_monitor_manager(), 'monitors-changed', () => this.syncUI());
        this.syncUI();
    }
    syncUI() {
        this.getFeature(TouchModeService).isTouchModeActive;
        // TODO: uncomment:
    }
    defineServices() {
        this.defineFeature('touch-mode-service', pm => new TouchModeService(pm));
    }
    defineFeatures() {
        this.defineFeature('navigation-bar', pm => new NavigationBarFeature(pm), settings.navigationBar.enabled);
        this.defineFeature('osk-key-popups', pm => new OskKeyPopupsFeature(pm), settings.oskKeyPopups.enabled);
        this.defineFeature('floating-screen-rotate-button', pm => new FloatingScreenRotateButtonFeature(pm), settings.screenRotateUtils.floatingScreenRotateButtonEnabled);
        this.defineFeature('notification-gestures', pm => new NotificationGesturesFeature(pm), settings.notificationGestures.enabled);
        this.defineFeature('donations', pm => new DonationsFeature(pm));
    }
    /**
     * A utility method to define [ExtensionFeature]s that are optionally automatically enabled/disabled
     * depending on the given [setting] and are mapped to a class attribute using [assign].
     *
     * Note that the [assign] callback can (and will upon feature or extension disabling) be
     * called with `undefined' as its value; this is intended behavior and the callback should
     * unset the reference it assigned before in this case.
     *
     * All features are created in a patch and are therefore automatically disabled and set to
     * `undefined` when the extension is disabled.
     *
     * For example usages see [defineFeatures] above.
     */
    defineFeature(featureName, create, setting) {
        let p = this.pm.registerPatch(() => {
            // Create the feature:
            let feature = create(this.pm.fork(featureName));
            this.features.push(feature);
            return () => {
                // Destroy the feature on unpatch:
                this.features = this.features.filter(f => f != feature);
                feature?.destroy();
            };
        }, `enable-feature(${featureName})`);
        if (setting) {
            // Enable the feature initially if setting is set to true:
            if (setting.get())
                p.enable();
            // Connect to setting changes:
            this.pm.connectTo(setting, 'changed', value => {
                if (value) {
                    p.enable();
                    this.syncUI();
                }
                else {
                    p.disable();
                }
            });
        }
        else {
            p.enable();
        }
    }
    disable() {
        // Cancel any pending delays:
        Delay.getAllPendingDelays().forEach(d => d.cancel());
        // Destroy the root PatchManager and with that all its descendents:
        this.pm?.destroy();
        this.pm = undefined;
        // Destroy all features (this has been done already by the PatchManager, but is explicitly done here
        // again to not make things unnecessarily complicated for reviewers):
        this.features.forEach(f => f.destroy());
        this.features = [];
        TouchUpExtension.instance = undefined;
    }
    getFeature(type) {
        return this.features.find(f => f instanceof type) ?? null;
    }
}

export { TouchUpExtension as default };
