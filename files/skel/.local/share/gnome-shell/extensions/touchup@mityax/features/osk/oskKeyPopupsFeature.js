import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as Keyboard from 'resource:///org/gnome/shell/ui/keyboard.js';
import { findActorBy } from '../../utils/utils.js';
import * as BoxPointer from 'resource:///org/gnome/shell/ui/boxpointer.js';
import St from 'gi://St';
import { log } from '../../utils/logging.js';
import ExtensionFeature from '../../utils/extensionFeature.js';
import { settings } from '../../settings.js';
import { Delay } from '../../utils/delay.js';

class OskKeyPopupsFeature extends ExtensionFeature {
    keyPrototype;
    boxPointers = new Map();
    constructor(pm) {
        super(pm);
        const self = this;
        this.pm.appendToMethod(Keyboard.Keyboard.prototype, 'open', function (..._) {
            // Only do this once (this patch is only responsible for retrieving the `Key` prototype,
            // which is key (pun intended) to create the OSK popups):
            if (!self.keyPrototype) {
                self.keyPrototype = self._extractKeyPrototype(this);
                if (!self.keyPrototype) {
                    log("Could not extract Key prototype, thus not patching OSK key popups.");
                }
                else {
                    self._patchKeyMethods(self.keyPrototype);
                }
            }
        });
    }
    _patchKeyMethods(keyProto) {
        const self = this;
        // Show the key popup on key press:
        this.pm.appendToMethod(keyProto, '_press', function (button, commitString) {
            if (!self.boxPointers.get(this) && commitString && commitString.trim().length > 0) {
                self.pm.patch(() => {
                    const bp = self._buildBoxPointer(this, commitString);
                    Main.layoutManager.addTopChrome(bp);
                    self.boxPointers.set(this, bp);
                    // @ts-ignore
                    bp.connect('destroy', () => self.boxPointers.delete(this));
                    return () => bp.destroy();
                });
            }
            // @ts-ignore
            self.boxPointers.get(this)?.open(BoxPointer.PopupAnimation.FULL);
            Delay.ms(2000).then(() => {
                // @ts-ignore
                self.boxPointers.get(this)?.close(BoxPointer.PopupAnimation.FULL);
            });
        });
        // Hide the key popup a few ms after a key has been released:
        this.pm.appendToMethod(keyProto, '_release', function (button, commitString) {
            Delay.ms(settings.oskKeyPopups.duration.get()).then(() => {
                // @ts-ignore
                self.boxPointers.get(this)?.close(BoxPointer.PopupAnimation.FULL);
            });
        });
        // Hide the key popup when the key's subkeys (umlauts etc.) popup is shown:
        this.pm.appendToMethod(keyProto, '_showSubkeys', function () {
            // @ts-ignore
            self.boxPointers.get(this)?.close();
        });
        // Destroy the key popup/boxpointer when the key is destroyed:
        this.pm.appendToMethod(keyProto, '_onDestroy', function () {
            // @ts-ignore
            self.boxPointers.get(this)?.destroy();
        });
    }
    _buildBoxPointer(key, commitString) {
        const bp = new BoxPointer.BoxPointer(St.Side.BOTTOM, {
            styleClass: 'key-container',
        });
        bp.add_style_class_name('keyboard-subkeys');
        bp.setPosition(key.keyButton, 0.5);
        if (key._icon && key.iconName) {
            bp.bin.set_child(new St.Icon({
                styleClass: 'keyboard-key',
                name: key.iconName,
                width: key.keyButton.allocation.get_width(),
                height: key.keyButton.allocation.get_height(),
            }));
        }
        else {
            bp.bin.set_child(new St.Button({
                styleClass: 'keyboard-key',
                label: key.keyButton.get_label() || commitString,
                width: key.keyButton.allocation.get_width(),
                height: key.keyButton.allocation.get_height(),
            }));
        }
        return bp;
    }
    _extractKeyPrototype(keyboard) {
        let r = findActorBy(keyboard._aspectContainer, a => a.constructor.name === 'Key' && !!Object.getPrototypeOf(a));
        return r !== null
            ? Object.getPrototypeOf(r)
            : null;
    }
}

export { OskKeyPopupsFeature as default };
