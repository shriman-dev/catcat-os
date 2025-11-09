/**
 * Base class for each feature of this extension.
 */
class ExtensionFeature {
    pm;
    constructor(patchManager) {
        this.pm = patchManager;
    }
    destroy() {
        this.pm.destroy();
    }
}

export { ExtensionFeature as default };
