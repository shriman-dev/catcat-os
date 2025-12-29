import Gio from 'gi://Gio';
import { PatchManager } from './utils/patchManager.js';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';
import { initSettings, uninitSettings } from './features/preferences/backend.js';
import { Delay } from './utils/delay.js';
import { assetsGResourceFile } from './config.js';
import { settings } from './settings.js';
import { TouchModeService } from './services/touchModeService.js';
import { DonationsFeature } from './features/donations/donationsFeature.js';
import { NotificationService } from './services/notificationService.js';

class TouchUpExtension extends Extension {
    static instance;
    pm;
    features = [];
    async enable() {
        TouchUpExtension.instance = this;
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
        // This is the entry point for all services (= small supplementary ExtensionFeature's, that other
        // features need to work):
        await this.defineServices();
        // This is the entry point for all features of this extension:
        await this.defineFeatures();
    }
    async defineServices() {
        await this.defineFeature('touch-mode-service', async (pm) => new TouchModeService(pm));
        await this.defineFeature('notification-service', async (pm) => new NotificationService(pm));
    }
    async defineFeatures() {
        // Optional features (that can be toggled on or off via a setting) are imported dynamically, for two reasons:
        //  - make the extension as slim as possible (users only "pay" for what they use)
        //  - make the extension more compatible with modified shells (e.g. Ubuntu or Gnome Mobile): turned off
        //    features cannot cause errors
        await this.defineFeature('navigation-bar', async (pm) => {
            const m = (await import('./features/navigationBar/navigationBarFeature.js'));
            return new m.NavigationBarFeature(pm);
        }, settings.navigationBar.enabled);
        await this.defineFeature('overview-gestures', async (pm) => {
            const m = (await import('./features/overviewGestures/overviewGesturesFeature.js'));
            return new m.OverviewGesturesFeature(pm);
        }, settings.overviewGestures.enabled);
        await this.defineFeature('notification-gestures', async (pm) => {
            const m = (await import('./features/notifications/notificationGesturesFeature.js'));
            return new m.NotificationGesturesFeature(pm);
        }, settings.notificationGestures.enabled);
        await this.defineFeature('osk', async (pm) => {
            const m = (await import('./features/osk/oskFeature.js'));
            return new m.OskFeature(pm);
        });
        await this.defineFeature('floating-screen-rotate-button', async (pm) => {
            const m = (await import('./features/screenRotateUtils/floatingScreenRotateButtonFeature.js'));
            return new m.FloatingScreenRotateButtonFeature(pm);
        }, settings.screenRotateUtils.floatingScreenRotateButtonEnabled);
        await this.defineFeature('donations', async (pm) => new DonationsFeature(pm));
    }
    /**
     * A utility method to define [ExtensionFeature]s that are optionally automatically enabled/disabled
     * depending on the given [setting].
     *
     * All features are created in a patch and are therefore automatically disabled when the extension is
     * disabled.
     *
     * For example usages see [defineFeatures] above.
     */
    async defineFeature(featureName, create, setting) {
        let resolve;
        let promise = new Promise((r) => resolve = r);
        let p = this.pm.registerPatch(() => {
            // Create the feature:
            let feature;
            create(this.pm.fork(featureName))
                .then(f => {
                feature = f;
                this.features.push(f);
            })
                .catch(e => {
                log(`Error while activating feature "${featureName}":`, e);
                setting?.set(false); // Disable the feature for future launches
                import('./utils/showFeatureInitializationErrorNotification.js')
                    .then(m => m.showFeatureInitializationFailedNotification(featureName, e));
            })
                .then(_ => resolve());
            return () => {
                // Destroy the feature on unpatch:
                this.features = this.features.filter(f => f !== feature);
                feature?.destroy();
            };
        }, `enable-feature(${featureName})`);
        if (setting) {
            // Enable the feature initially if setting is set to true:
            if (setting.get()) {
                p.enable();
            }
            else {
                // @ts-ignore
                resolve(); // if the setting is not enabled, just resolve without enabling the feature
            }
            // Connect to setting changes:
            this.pm.connectTo(setting, 'changed', value => {
                if (value) {
                    p.enable();
                }
                else {
                    p.disable();
                }
            });
        }
        else {
            p.enable();
        }
        return promise;
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
