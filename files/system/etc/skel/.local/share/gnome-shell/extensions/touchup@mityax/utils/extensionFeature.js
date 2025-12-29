/**
 * Base class for each feature of this extension.
 */
class ExtensionFeature {
    pm;
    _subFeatures = [];
    constructor(patchManager) {
        this.pm = patchManager;
    }
    /**
     * Adds a sub-feature to this extension feature and optionally binds (= automatically creates and destroys) it
     * to the given setting.
     *
     * If no setting is given, the sub-feature is created immediately and destroyed when this extension feature
     * is destroyed.
     *
     * @param featureName The sub-feature's name in kebab-case (used for debugging purposes mainly)
     * @param creator A function to create an instance of the sub-feature, using the given [PatchManager]
     * @param setting An optional setting to bind the sub-feature to.
     */
    addSubFeature(featureName, creator, setting) {
        let p = this.pm.registerPatch(() => {
            // Create the feature:
            let feature = creator(this.pm.fork(featureName));
            this._subFeatures.push(feature);
            return () => {
                // Destroy the feature on unpatch:
                feature?.destroy();
                // And remove it from the list:
                const idx = this._subFeatures.findIndex(f => f === feature);
                if (idx !== -1)
                    this._subFeatures.splice(idx, 1);
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
    getSubFeature(type) {
        return this._subFeatures.find(f => f instanceof type) ?? null;
    }
    destroy() {
        this.pm.destroy();
        // Destroy all sub-features (this has been done already by the PatchManager, but is explicitly done
        // here again to not make things unnecessarily complicated for reviewers):
        this._subFeatures.forEach(f => f.destroy());
        this._subFeatures.splice(0); // clear the array
    }
}

export { ExtensionFeature as default };
