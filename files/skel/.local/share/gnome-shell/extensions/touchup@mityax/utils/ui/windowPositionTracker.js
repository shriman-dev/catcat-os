import Meta from 'gi://Meta';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import { Delay } from '../delay.js';

class WindowPositionTracker {
    _signalIds = new Map();
    _updateDelay;
    callback;
    constructor(callback) {
        this.callback = callback;
        this._signalIds.set(Main.overview, [
            Main.overview.connect('showing', this._update.bind(this)),
            Main.overview.connect('hiding', this._update.bind(this)),
            Main.overview.connect('shown', this._update.bind(this)),
            Main.overview.connect('hidden', this._update.bind(this)),
        ]);
        this._signalIds.set(Main.sessionMode, [
            Main.sessionMode.connect('updated', this._update.bind(this))
        ]);
        for (const metaWindowActor of global.get_window_actors()) {
            this._onWindowActorAdded(metaWindowActor.get_parent(), metaWindowActor);
        }
        this._signalIds.set(global.windowGroup, [
            global.windowGroup.connect('child-added', this._onWindowActorAdded.bind(this)),
            global.windowGroup.connect('child-removed', this._onWindowActorRemoved.bind(this))
        ]);
        // Use a delayed version of _updateTransparent to let the shell catch up
        this._signalIds.set(global.windowManager, [
            global.windowManager.connect('switch-workspace', this._updateDelayed.bind(this))
        ]);
        this._update();
    }
    _onWindowActorAdded(container, metaWindowActor) {
        this._signalIds.set(metaWindowActor, [
            metaWindowActor.connect('notify::allocation', this._update.bind(this)),
            metaWindowActor.connect('notify::visible', this._update.bind(this))
        ]);
    }
    _onWindowActorRemoved(container, metaWindowActor) {
        for (const signalId of this._signalIds.get(metaWindowActor) ?? []) {
            metaWindowActor.disconnect(signalId);
        }
        this._signalIds.delete(metaWindowActor);
        this._update();
    }
    _update() {
        if (!Main.layoutManager.primaryMonitor) {
            return;
        }
        // Get all the windows in the active workspace that are in the primary monitor and visible.
        const workspaceManager = global.workspaceManager;
        const activeWorkspace = workspaceManager.get_active_workspace();
        const windows = activeWorkspace.list_windows().filter((metaWindow) => {
            return metaWindow.is_on_primary_monitor()
                && metaWindow.showing_on_its_workspace()
                && !metaWindow.is_hidden()
                && metaWindow.get_window_type() !== Meta.WindowType.DESKTOP
                && !metaWindow.skipTaskbar;
        });
        this.callback(windows);
    }
    _updateDelayed() {
        this._updateDelay = Delay.ms(100).then(() => {
            this._update();
        });
    }
    destroy() {
        for (const [actor, signalIds] of this._signalIds) {
            for (const signalId of signalIds) {
                actor.disconnect(signalId);
            }
        }
        this._signalIds.clear();
        this._updateDelay?.cancel();
    }
}

export { WindowPositionTracker as default };
