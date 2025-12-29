import WindowPositionTracker from '../../../utils/ui/windowPositionTracker.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import Signal from '../../../utils/signal.js';

/**
 * Class that handles commons for all navigation bar types
 */
class BaseNavigationBar {
    windowPositionTracker;
    _visible = false;
    _reserveSpace = true;
    actor;
    onVisibilityChanged = new Signal();
    onReserveSpaceChanged = new Signal();
    constructor({ reserveSpace }) {
        this._reserveSpace = reserveSpace;
        this.actor = this._buildActor();
    }
    get monitor() {
        return this._monitor;
    }
    get isVisible() {
        return this._visible;
    }
    get reserveSpace() {
        return this._reserveSpace;
    }
    show() {
        if (this.isVisible)
            return;
        this._addActor();
        this._visible = true;
        this.onVisibilityChanged.emit(true);
        this.reallocate();
        this._createWindowPositionTracker();
    }
    hide() {
        if (!this.isVisible)
            return;
        this._removeActor();
        this.windowPositionTracker?.destroy();
        this.windowPositionTracker = undefined;
        this._visible = false;
        this.onVisibilityChanged.emit(false);
    }
    setMonitor(monitorIndex) {
        this._monitor = Main.layoutManager.monitors[monitorIndex];
        this.reallocate();
    }
    setReserveSpace(reserveSpace) {
        if (reserveSpace != this._reserveSpace) {
            this._reserveSpace = reserveSpace;
            this._removeActor();
            this._addActor();
            this.onReserveSpaceChanged.emit(reserveSpace);
        }
    }
    reallocate() {
        // FIXME: find touch-enabled monitor, keyword: ClutterInputDevice
        this._monitor ??= Main.layoutManager.primaryMonitor;
        this.onBeforeReallocate();
        this.actor.set_position(this.monitor.x, this.monitor.y + this.monitor.height - this.actor.height);
        this.actor.set_width(this.monitor.width);
    }
    _addActor() {
        Main.layoutManager.addTopChrome(this.actor, {
            affectsStruts: this.reserveSpace,
            trackFullscreen: true,
            affectsInputRegion: true,
        });
    }
    _removeActor() {
        Main.layoutManager.removeChrome(this.actor);
    }
    onBeforeReallocate() { }
    _createWindowPositionTracker() {
        let lastIsWindowNear = false;
        this.windowPositionTracker = new WindowPositionTracker(windows => {
            if (this.actor.realized) {
                // Check if at least one window is near enough to the navigation bar:
                const top = this.actor.get_transformed_position()[1];
                const isWindowNear = windows.some((metaWindow) => {
                    const windowBottom = metaWindow.get_frame_rect().y + metaWindow.get_frame_rect().height;
                    return windowBottom >= top;
                });
                if (isWindowNear !== lastIsWindowNear) {
                    this.onIsWindowNearChanged(isWindowNear);
                }
                lastIsWindowNear = isWindowNear;
            }
        });
    }
    destroy() {
        this.actor.destroy();
        this.windowPositionTracker?.destroy();
        this._visible = false;
    }
}

export { BaseNavigationBar as default };
