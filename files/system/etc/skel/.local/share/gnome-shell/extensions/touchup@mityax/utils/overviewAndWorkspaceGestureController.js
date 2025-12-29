import { clamp } from './utils.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

class OverviewAndWorkspaceGestureController {
    _monitorIndex;
    _baseDistX = 900;
    _baseDistY = global.screenHeight;
    _initialWorkspaceProgress = 0;
    _initialOverviewProgress = 0;
    _currentOverviewProgress = 0;
    _currentWorkspaceProgress = 0;
    _isOverviewGestureRunning = false;
    _isWorkspaceGestureRunning = false;
    //@ts-ignore
    _wsController = Main.wm._workspaceAnimation;
    _idleRunner;
    constructor(props) {
        this._monitorIndex = props?.monitorIndex;
    }
    /**
     * This function is optional; if it has not been called before `gestureUpdate` the gesture
     * will begin automatically.
     */
    gestureBegin() {
        this.gestureUpdate({ overviewProgress: 0, workspaceProgress: 0 });
    }
    gestureUpdate(props) {
        if (props.overviewProgress) {
            if (!this._isOverviewGestureRunning) {
                Main.overview._gestureBegin({
                    confirmSwipe: (baseDistance, points, progress, cancelProgress) => {
                        this._baseDistY = baseDistance;
                        // The following tenary expression is needed to fix a bug (presumably in Gnome Shell's
                        // OverviewControls) that causes a `progress` of 1 to be passed to this callback on the first
                        // gesture begin, even though the overview is not visible:
                        this._initialOverviewProgress = Main.overview._visible ? progress : 0;
                        this._currentOverviewProgress = this._initialOverviewProgress;
                    }
                });
                this._isOverviewGestureRunning = true;
            }
            else {
                this._currentOverviewProgress = this._initialOverviewProgress + props.overviewProgress;
                Main.overview._gestureUpdate({}, this._currentOverviewProgress);
            }
        }
        if (props.workspaceProgress) {
            if (!this._isWorkspaceGestureRunning) {
                this._wsController._switchWorkspaceBegin({
                    confirmSwipe: (baseDistance, points, progress, cancelProgress) => {
                        this._baseDistX = baseDistance;
                        this._initialWorkspaceProgress = progress;
                        this._currentWorkspaceProgress = this._initialWorkspaceProgress;
                    }
                }, this._monitorIndex ?? Main.layoutManager.primaryIndex);
                this._isWorkspaceGestureRunning = true;
            }
            else {
                this._currentWorkspaceProgress = this._initialWorkspaceProgress + props.workspaceProgress;
                this._wsController._switchWorkspaceUpdate({}, this._currentWorkspaceProgress);
            }
        }
    }
    gestureEnd(props) {
        // Overview toggling:
        try {
            if (this._isOverviewGestureRunning) {
                if (props.direction === 'up') {
                    Main.overview._gestureEnd({}, 300, clamp(Math.round(this._currentOverviewProgress + 0.5), 1, 2));
                }
                else if (props.direction === 'down') {
                    Main.overview._gestureEnd({}, 300, clamp(Math.round(this._currentOverviewProgress - 0.5), 0, 1));
                }
                else {
                    Main.overview._gestureEnd({}, 300, clamp(Math.round(this._currentOverviewProgress), 0, 2));
                }
            }
        }
        catch (e) {
        }
        // Workspace switching:
        if (this._isWorkspaceGestureRunning) {
            // TODO: debug occasional cases of non-ending gesture
            if (props.direction === 'left' || props.direction === 'right') {
                this._wsController._switchWorkspaceEnd({}, 500, Math.round(this._currentWorkspaceProgress + (props.direction == 'left' ? 0.5 : -0.5)));
            }
            else {
                this._wsController._switchWorkspaceEnd({}, 500, Math.round(this._currentWorkspaceProgress));
            }
        }
        this._isOverviewGestureRunning = false;
        this._isWorkspaceGestureRunning = false;
    }
    gestureCancel() {
        this._wsController._switchWorkspaceEnd({}, 500, this._initialWorkspaceProgress);
        Main.overview._gestureEnd({}, 300, 0);
        this._isOverviewGestureRunning = false;
        this._isWorkspaceGestureRunning = false;
    }
    get monitorIndex() {
        return this._monitorIndex ?? null;
    }
    set monitorIndex(value) {
        this._monitorIndex = value ?? undefined;
    }
    get baseDistY() {
        return this._baseDistY;
    }
    get baseDistX() {
        return this._baseDistX;
    }
    get currentWorkspaceProgress() {
        return this._currentWorkspaceProgress;
    }
    get currentOverviewProgress() {
        return this._currentOverviewProgress;
    }
    get initialWorkspaceProgress() {
        return this._initialWorkspaceProgress;
    }
    get initialOverviewProgress() {
        return this._initialOverviewProgress;
    }
}

export { OverviewAndWorkspaceGestureController as default };
