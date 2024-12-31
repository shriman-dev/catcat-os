import Clutter from 'gi://Clutter';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import GWeather from 'gi://GWeather';
import Shell from 'gi://Shell';
import St from 'gi://St';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

import * as Animation from 'resource:///org/gnome/shell/ui/animation.js';
import * as AppFavorites from 'resource:///org/gnome/shell/ui/appFavorites.js';
import {EventEmitter} from 'resource:///org/gnome/shell/misc/signals.js';
import * as DND from 'resource:///org/gnome/shell/ui/dnd.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {PopupAnimation} from 'resource:///org/gnome/shell/ui/boxpointer.js';

import {AppIcon, ShowAppsIcon} from './appIcon.js';
import * as Enums from './enums.js';
import {NotificationsMonitor} from './notificationsMonitor.js';
import {Panel} from './panel.js';
import * as Utils from './utils.js';
import {TaskbarManager} from './taskbarManager.js';
import * as Theming from './theming.js';
import * as UnityLauncherAPI from './unityLauncherAPI.js';
import {WindowPreviewMenuManager} from './windowPreview.js';

const WeatherPosition = {
    OFF: 0,
    LEFT: 1,
    RIGHT: 2,
};

function getDropTarget(box, x) {
    const visibleItems = box.get_children();
    for (const item of visibleItems) {
        const childBox = item.allocation.copy();
        childBox.set_origin(childBox.x1 % box.width, childBox.y1);
        if (x < childBox.x1 || x > childBox.x2)
            continue;

        return {item, index: visibleItems.indexOf(item)};
    }

    return {item: null, index: -1};
}

var AppDisplayBox = GObject.registerClass(
class azTaskbarAppDisplayBox extends St.ScrollView {
    _init(monitor) {
        super._init({
            style_class: 'hfade',
            enable_mouse_scrolling: false,
        });
        this.set_policy(St.PolicyType.EXTERNAL, St.PolicyType.NEVER);
        this.set_offscreen_redirect(Clutter.OffscreenRedirect.ALWAYS);
        this.clip_to_allocation = true;
        this._shownInitially = false;

        this._settings = TaskbarManager.settings;

        this._monitor = monitor;
        this.showAppsIcon = new ShowAppsIcon(this._settings);
        this._workId = Main.initializeDeferredWork(this, this._redisplay.bind(this));

        this.menuManager = new WindowPreviewMenuManager(this);

        this._appSystem = Shell.AppSystem.get_default();
        this.appIconsCache = new Map();
        this.peekInitialWorkspaceIndex = -1;

        this.mainBox = new St.BoxLayout({
            x_expand: true,
            y_expand: true,
            x_align: Clutter.ActorAlign.FILL,
            y_align: Clutter.ActorAlign.FILL,
        });
        this.mainBox._delegate = this;
        this.mainBox.set_offscreen_redirect(Clutter.OffscreenRedirect.ALWAYS);

        Utils.addChildToParent(this, this.mainBox);

        this._setConnections();
        // If appDisplayBox position is moved in the main panel, updateIconGeometry
        this.connect('notify::position', () => this._updateIconGeometry());
        this.connect('destroy', () => this._destroy());
        this._connectWorkspaceSignals();
    }

    _setConnections() {
        this._disconnectWorkspaceSignals();
        this._clearConnections();

        this._settings.connectObject('changed::isolate-workspaces', () => this._queueRedisplay(), this);
        this._settings.connectObject('changed::show-running-apps', () => this._queueRedisplay(), this);
        this._settings.connectObject('changed::favorites', () => this._queueRedisplay(), this);
        this._settings.connectObject('changed::show-apps-button', () => this._queueRedisplay(), this);
        this._settings.connectObject('changed::favorites-on-all-monitors', () => this._queueRedisplay(), this);

        AppFavorites.getAppFavorites().connectObject('changed', () => this._queueRedisplay(), this);

        this._appSystem.connectObject('app-state-changed', () => this._queueRedisplay(), this);
        this._appSystem.connectObject('installed-changed', () => {
            AppFavorites.getAppFavorites().reload();
            this._queueRedisplay();
        }, this);

        global.window_manager.connectObject('switch-workspace', () => {
            this._connectWorkspaceSignals();
            this._queueRedisplay();
        }, this);

        global.display.connectObject('window-entered-monitor', this._queueRedisplay.bind(this), this);
        global.display.connectObject('window-left-monitor', this._queueRedisplay.bind(this), this);
        global.display.connectObject('restacked', this._queueRedisplay.bind(this), this);

        Main.layoutManager.connectObject('startup-complete', this._queueRedisplay.bind(this), this);
    }

    _clearConnections() {
        this._settings.disconnectObject(this);
        AppFavorites.getAppFavorites().disconnectObject(this);
        this._appSystem.disconnectObject(this);
        global.window_manager.disconnectObject(this);
        global.display.disconnectObject(this);
        Main.layoutManager.disconnectObject(this);
    }

    _createAppItem(newApp, monitorIndex) {
        const {app, isFavorite, needsDestroy} = newApp;
        const appID = `${app.get_id()} - ${monitorIndex}`;

        const item = this.appIconsCache.get(appID);

        // If a favorited app is running when extension starts,
        // the corresponding AppIcon may initially be created with isFavorite = false.
        // Check if isFavorite changed, and create new AppIcon if true.
        const favoriteChanged = item && item.isFavorite !== isFavorite;

        if (item && !favoriteChanged) {
            item.isSet = !needsDestroy;
            return item;
        } else if (item && favoriteChanged) {
            this.appIconsCache.delete(appID);
            item.destroy();
        }

        const appIcon = new AppIcon(this, app, monitorIndex, isFavorite);
        appIcon.isSet = true;
        this.appIconsCache.set(appID, appIcon);
        return appIcon;
    }

    handleDragOver(source, actor, x, _y, _time) {
        const dropTarget = getDropTarget(this.mainBox, x);
        const dropTargetItem = dropTarget.item;
        const {index} = dropTarget;

        if (!dropTargetItem)
            return DND.DragMotionResult.NO_DROP;

        source.dragMonitorIndex = dropTargetItem.monitorIndex ?? -1;
        source.dragPos = index;
        const inFavoriteRange = source.dragPos >= (source.firstFavIndex - 1) &&
                                source.dragPos <= source.lastFavIndex &&
                                dropTargetItem.monitorIndex === source.monitorIndex;

        const id = source.app.get_id();
        const favorites = AppFavorites.getAppFavorites().getFavoriteMap();
        let noDrop = id in favorites;

        if (source.app.is_window_backed() || !global.settings.is_writable('favorite-apps'))
            noDrop = true;

        if (dropTargetItem instanceof AppIcon && dropTargetItem !== source) {
            if (inFavoriteRange && noDrop && !source.isFavorite)
                return DND.DragMotionResult.NO_DROP;

            // 1. If drop target location not on same monitor as source, but in fav range.
            // 2. else if source has been moved to favorite range from different monitor,
            // return to last location.
            if (!source.isFavorite && inFavoriteRange) {
                if (!source.lastPositionIndex)
                    source.lastPositionIndex = this.mainBox.get_children().indexOf(source);
                this.mainBox.remove_child(source);
                this.mainBox.insert_child_at_index(source, index);
            } else if (dropTargetItem.monitorIndex !== source.monitorIndex &&
                    !inFavoriteRange && source.lastPositionIndex) {
                this.mainBox.remove_child(source);
                this.mainBox.insert_child_at_index(source, source.lastPositionIndex);
                source.lastPositionIndex = null;
            } else if (dropTargetItem.monitorIndex === source.monitorIndex) {
                this.mainBox.remove_child(source);
                this.mainBox.insert_child_at_index(source, index);
            }
        }

        if (inFavoriteRange)
            source.add_style_class_name('azTaskbar-favorite');
        else
            source.remove_style_class_name('azTaskbar-favorite');

        if (source.isFavorite || !inFavoriteRange)
            return DND.DragMotionResult.NO_DROP;

        return DND.DragMotionResult.COPY_DROP;
    }

    acceptDrop(source, _actor, x, _y, _time) {
        if (!(source instanceof AppIcon))
            return false;

        const dropTarget = getDropTarget(this.mainBox, x);
        const dropTargetItem = dropTarget.item;

        const id = source.app.get_id();
        const appFavorites = AppFavorites.getAppFavorites();
        const favorites = appFavorites.getFavoriteMap();
        const srcIsFavorite = id in favorites;
        const favPos = source.dragPos - source.firstFavIndex;
        const inFavoriteRange = source.dragPos >= (source.firstFavIndex - 1) &&
                                source.dragPos <= source.lastFavIndex;

        if (!srcIsFavorite && dropTargetItem.monitorIndex !== source.monitorIndex && !inFavoriteRange)
            return false;

        const appIcons = this.mainBox.get_children().filter(actor => {
            if (actor instanceof AppIcon)
                return true;
            return false;
        });

        let position = 0;
        for (let i = 0, l = appIcons.length; i < l; ++i) {
            const appIcon = appIcons[i];
            const windows = appIcon.getInterestingWindows();

            for (let j = 0; j < windows.length; j++)
                windows[j]._azTaskbarPosition = position++;
        }

        if (source.isFavorite) {
            if (source.dragPos > source.lastFavIndex || source.dragPos < source.firstFavIndex - 1)
                appFavorites.removeFavorite(id);
            else
                appFavorites.moveFavoriteToPos(id, favPos);
        } else if (inFavoriteRange) {
            if (srcIsFavorite)
                appFavorites.moveFavoriteToPos(id, favPos);
            else
                appFavorites.addFavoriteAtPos(id, favPos);
        }

        this._queueRedisplay();

        return true;
    }

    /**
     * _getAppStableSequence(), _sortWindowsCompareFunction(), _getWindowStableSequence(),
     * _sortAppsCompareFunction(), _getRunningApps(), _getAppInfos(), _createAppInfos()
     * methods borrowed from Dash to Panel extension
     */

    _getAppStableSequence(app, monitor) {
        const windows = Utils.getInterestingWindows(this._settings, app.get_windows(), monitor);

        return windows.reduce((prevWindow, window) => {
            return Math.min(prevWindow, this._getWindowStableSequence(window));
        }, Infinity);
    }

    _sortWindowsCompareFunction(windowA, windowB) {
        return this._getWindowStableSequence(windowA) - this._getWindowStableSequence(windowB);
    }

    _getWindowStableSequence(window) {
        return '_azTaskbarPosition' in window ? window._azTaskbarPosition : window.get_stable_sequence();
    }

    _sortAppsCompareFunction(appA, appB, monitor) {
        return this._getAppStableSequence(appA, monitor) -
               this._getAppStableSequence(appB, monitor);
    }

    _getRunningApps() {
        const tracker = Shell.WindowTracker.get_default();
        const windows = global.get_window_actors();
        const apps = [];

        for (let i = 0, l = windows.length; i < l; ++i) {
            const app = tracker.get_window_app(windows[i].metaWindow);

            if (app && apps.indexOf(app) < 0)
                apps.push(app);
        }

        return apps;
    }

    _getAppInfos(showFavorites, showRunningApps, monitorIndex) {
        // get the user's favorite apps
        const favoriteApps = showFavorites ? AppFavorites.getAppFavorites().getFavorites() : [];

        // find the apps that should be in the taskbar: the favorites first, then add the running apps
        const runningApps = showRunningApps ? this._getRunningApps().sort((a, b) => this._sortAppsCompareFunction(a, b, monitorIndex)) : [];

        return this._createAppInfos(favoriteApps.concat(runningApps.filter(app => favoriteApps.indexOf(app) < 0)), monitorIndex)
                    .filter(appInfo => appInfo.windows.length || favoriteApps.indexOf(appInfo.app) >= 0);
    }

    _createAppInfos(apps, monitorIndex) {
        const favoriteApps = AppFavorites.getAppFavorites().getFavorites();
        return apps.map(app => ({
            app,
            isFavorite: favoriteApps.indexOf(app) >= 0,
            windows: Utils.getInterestingWindows(this._settings, app.get_windows(), monitorIndex).sort(this._sortWindowsCompareFunction.bind(this)),
        }));
    }

    _queueRedisplay() {
        Main.queueDeferredWork(this._workId);
    }

    _redisplay() {
        const appIconsOnTaskbar = [];

        this.mainBox.get_children().forEach(actor => {
            if (actor instanceof AppIcon) {
                actor.isSet = false;
                appIconsOnTaskbar.push({
                    app: actor.app,
                    isFavorite: actor.isFavorite,
                });
            } else if (actor instanceof ShowAppsIcon) {
                this.mainBox.remove_child(actor);
            } else {
                this.mainBox.remove_child(actor);
                actor.destroy();
            }
        });

        const monitorIndex = this._monitor.index;
        const favsOnAllMonitors = this._settings.get_boolean('favorites-on-all-monitors');
        const isPrimaryMonitor = monitorIndex === Main.layoutManager.primaryIndex;
        const panelsOnAllMonitors = this._settings.get_boolean('panel-on-all-monitors');
        const showRunningApps = this._settings.get_boolean('show-running-apps');
        let showFavorites = this._settings.get_boolean('favorites');
        if (panelsOnAllMonitors && showFavorites)
            showFavorites = favsOnAllMonitors ? true : isPrimaryMonitor;

        const animate = this._shownInitially;
        if (!this._shownInitially)
            this._shownInitially = true;

        const expectedAppsInfo = this._getAppInfos(showFavorites, showRunningApps, monitorIndex);
        const expectedApps = expectedAppsInfo.map(appInfo => appInfo.app);

        appIconsOnTaskbar.forEach(appIcon => {
            const {app} = appIcon;
            const index = expectedApps.indexOf(app);
            if (index < 0) {
                const appID = `${app.get_id()} - ${monitorIndex}`;
                const item = this.appIconsCache.get(appID);
                if (item && !item.animatingOut) {
                    this.appIconsCache.delete(appID);
                    item.animateOutAndDestroy();
                }
            }
        });

        for (let j = 0; j < expectedAppsInfo.length; j++) {
            const appIconInfo = expectedAppsInfo[j];
            const item = this._createAppItem(appIconInfo, monitorIndex);
            const parent = item.get_parent();

            if (parent) {
                if (item.opacity !== 255)
                    item.animateIn(animate);
            } else if (!parent) {
                item.opacity = 0;
                this.mainBox.insert_child_at_index(item, j);
                item.animateIn(animate);
            }

            if (item.isSet)
                item.updateAppIcon();
        }

        const [showAppsButton, showAppsButtonPosition] = this._settings.get_value('show-apps-button').deep_unpack();
        if (showAppsButton) {
            if (showAppsButtonPosition === Enums.ShowAppsButtonPosition.LEFT)
                this.mainBox.insert_child_at_index(this.showAppsIcon, 0);
            else
                this.mainBox.add_child(this.showAppsIcon);
            this.showAppsIcon.updateIcon();
            this.showAppsIcon.animateIn(animate);
        }

        this.mainBox.queue_relayout();
    }

    _connectWorkspaceSignals() {
        const currentWorkspace = global.workspace_manager.get_active_workspace();

        if (this._lastWorkspace === currentWorkspace)
            return;

        this._disconnectWorkspaceSignals();

        this._lastWorkspace = currentWorkspace;

        this._workspaceWindowAddedId = this._lastWorkspace.connect('window-added',
            () => this._queueRedisplay());
        this._workspaceWindowRemovedId = this._lastWorkspace.connect('window-removed',
            () => this._queueRedisplay());
    }

    _disconnectWorkspaceSignals() {
        if (this._lastWorkspace) {
            this._lastWorkspace.disconnect(this._workspaceWindowAddedId);
            this._lastWorkspace.disconnect(this._workspaceWindowRemovedId);

            this._lastWorkspace = null;
        }
    }

    updateIcon() {
        this.appIconsCache.forEach((appIcon, _appID) => {
            if (appIcon.isSet)
                appIcon.updateIcon();
        });
    }

    _updateIconGeometry() {
        this.appIconsCache.forEach((appIcon, _appID) => {
            if (appIcon.isSet)
                appIcon.updateIconGeometry();
        });
    }

    removeWindowPreviewCloseTimeout() {
        if (this._windowPreviewCloseTimeoutId > 0) {
            GLib.source_remove(this._windowPreviewCloseTimeoutId);
            this._windowPreviewCloseTimeoutId = 0;
        }
    }

    setWindowPreviewCloseTimeout() {
        if (this._windowPreviewCloseTimeoutId > 0)
            return;

        this._windowPreviewCloseTimeoutId = GLib.timeout_add(GLib.PRIORITY_DEFAULT,
            this._settings.get_int('window-previews-hide-timeout'), () => {
                const activePreview = this.menuManager.activeMenu;
                if (activePreview)
                    activePreview.close(PopupAnimation.FULL);

                this._windowPreviewCloseTimeoutId = 0;
                return GLib.SOURCE_REMOVE;
            });
    }

    _destroy() {
        this._disconnectWorkspaceSignals();
        this.removeWindowPreviewCloseTimeout();

        this._clearConnections();
        this.showAppsIcon.destroy();
        this.appIconsCache.forEach((appIcon, appID) => {
            appIcon.stopAllAnimations();
            appIcon.destroy();
            this.appIconsCache.delete(appID);
        });
        this.appIconsCache = null;
    }
});

var PanelBox = GObject.registerClass(
class azTaskbarPanelBox extends St.BoxLayout {
    _init(monitor) {
        super._init({
            name: 'panelBox',
            vertical: true,
        });

        this._settings = TaskbarManager.settings;

        this.monitor = monitor;
        this.panel = new Panel(monitor);
        this.add_child(this.panel);

        Main.layoutManager.addChrome(this, {
            affectsStruts: true,
            trackFullscreen: true,
        });
    }

    get index() {
        return this.monitor.index;
    }
});

var PanelManager = class azTaskbarPanelManager {
    constructor(monitor) {
        this._monitor = monitor;
        this._settings = TaskbarManager.settings;

        if (monitor !== Main.layoutManager.primaryMonitor) {
            this._panelBox = new PanelBox(monitor);
            this._panel = this.panelBox.panel;
        } else {
            this._panelBox = Main.layoutManager.panelBox;
            this._panelBox.panel = Main.panel;
            this._panel = Main.panel;
        }

        this._appDisplayBox = new AppDisplayBox(monitor);
        this._dateMenu = this._panel.statusArea.dateMenu;
        this._clockDisplay = this._dateMenu._clockDisplay;
        this._clock = this._dateMenu._clock;
        this._weatherClient = this._dateMenu._weatherItem._weatherClient;
        // the original clockDisplay's parent
        this._origDateMenuBox = this._clockDisplay.get_parent();
        this._hasWeatherWidget = false;

        // this.panelBox.connectObject('notify::allocation', this.setSizeAndPosition.bind(this), this);
        this._settings.connectObject('changed::override-panel-clock-format', () => this._updateDateFormat(), this);
        this._clockDisplay.connectObject('notify::text', () => this._updateDateFormat(), this);
        this._settings.connectObject('changed::clock-position-in-panel', () => this._setClockPosition(), this);
        this._settings.connectObject('changed::clock-position-offset', () => this._setClockPosition(), this);
        this._settings.connectObject('changed::clock-font-size', () => this._setClockFontSize(), this);
        this._settings.connectObject('changed::show-weather-by-clock', () => this._establishWeatherWidget(), this);

        this.setAppsPosition();
        this._updateDateFormat();
        this._setClockPosition();
        this._setClockFontSize();
        this._establishWeatherWidget();
    }

    get isMainPanel() {
        return this.panel === Main.panel;
    }

    get panel() {
        return this._panel;
    }

    get panelBox() {
        return this._panelBox;
    }

    get appDisplayBox() {
        return this._appDisplayBox;
    }

    _establishWeatherWidget() {
        const weatherPosition = this._settings.get_enum('show-weather-by-clock');

        if (weatherPosition === WeatherPosition.OFF && this._hasWeatherWidget)
            this._destroyWeatherWidget();
        else if (weatherPosition !== WeatherPosition.OFF && this._hasWeatherWidget)
            this._moveWeatherWidget(weatherPosition);
        else if (weatherPosition !== WeatherPosition.OFF && !this._hasWeatherWidget)
            this._createWeatherWidget(weatherPosition);
    }

    _destroyWeatherWidget() {
        if (this._updateWeatherTimeoutId) {
            GLib.source_remove(this._updateWeatherTimeoutId);
            this._updateWeatherTimeoutId = null;
        }

        // Weather Widget hasn't been created or was previously destroyed
        if (!this._hasWeatherWidget)
            return;

        // put the clockDisplay back to its original parent
        this._customDateMenuBox.remove_child(this._clockDisplay);
        this._clockDisplay.set_style_class_name('clock');
        this._origDateMenuBox.insert_child_at_index(this._clockDisplay, 1);

        this._weatherClient.disconnectObject(this);
        this._customDateMenuBox.destroy();
        this._customDateMenuBox = null;
        this._weatherTemp = null;
        this._hasWeatherWidget = false;
    }

    _moveWeatherWidget(weatherPosition) {
        this._customDateMenuBox.remove_child(this._weatherBox);
        this._customDateMenuBox.remove_child(this._clockDisplay);
        if (weatherPosition === WeatherPosition.LEFT) {
            this._customDateMenuBox.add_child(this._weatherBox);
            this._customDateMenuBox.add_child(this._clockDisplay);
        } else {
            this._customDateMenuBox.add_child(this._clockDisplay);
            this._customDateMenuBox.add_child(this._weatherBox);
        }
    }

    _createWeatherWidget(weatherPosition) {
        this._weatherClient.update();
        this._hasWeatherWidget = true;
        this._weatherClient.connectObject('changed', this._syncWeather.bind(this), this);

        this._origDateMenuBox.remove_child(this._clockDisplay);
        this._clockDisplay.remove_style_class_name('clock');

        this._customDateMenuBox = new St.BoxLayout({
            vertical: false,
            style_class: 'clock',
            style: 'spacing: 8px;',
        });
        this._weatherBox = new St.BoxLayout({
            vertical: false,
        });
        this._weatherIcon = new St.Icon({
            icon_size: 16,
            y_align: Clutter.ActorAlign.CENTER,
            visible: false,
        });
        this._weatherTemp = new St.Label({
            y_align: Clutter.ActorAlign.CENTER,
            visible: false,
            style: this._clockDisplay.style,
        });
        this._spinner = new Animation.Spinner(16, {
            animate: false,
            hideOnStop: true,
        });
        this._weatherBox.add_child(this._spinner);
        this._weatherBox.add_child(this._weatherIcon);
        this._weatherBox.add_child(this._weatherTemp);
        this._spinner.play();

        if (weatherPosition === WeatherPosition.LEFT) {
            this._customDateMenuBox.add_child(this._weatherBox);
            this._customDateMenuBox.add_child(this._clockDisplay);
        } else {
            this._customDateMenuBox.add_child(this._clockDisplay);
            this._customDateMenuBox.add_child(this._weatherBox);
        }

        this._origDateMenuBox.insert_child_at_index(this._customDateMenuBox, 1);

        this._syncWeather();

        // Update the weather every 5 minutes
        this._updateWeatherTimeoutId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 300, () => {
            this._weatherClient.update();
            return GLib.SOURCE_CONTINUE;
        });
    }

    _syncWeather() {
        if (!(this._weatherClient.available && this._weatherClient.hasLocation)) {
            this._weatherBox.hide();
            this._weatherIcon.hide();
            this._weatherTemp.hide();
            this._spinner.stop();
            return;
        }

        const {info} = this._weatherClient;

        if (this._weatherClient.loading) {
            this._weatherBox.show();
            this._weatherIcon.hide();
            this._weatherTemp.hide();
            this._spinner.play();
            return;
        }

        if (info.is_valid()) {
            this._weatherBox.show();
            this._spinner.stop();
            const [, tempValue] = info.get_value_temp(GWeather.TemperatureUnit.DEFAULT);
            const tempPrefix = Math.round(tempValue) >= 0 ? ' ' : '';

            this._weatherIcon.icon_name = info.get_symbolic_icon_name();
            this._weatherTemp.text = `${tempPrefix}${Math.round(tempValue)}°`;
            this._weatherIcon.show();
            this._weatherTemp.show();
            return;
        }

        // no valid weather
        this._weatherBox.hide();
        this._weatherIcon.hide();
        this._weatherTemp.hide();
        this._spinner.stop();
    }

    _updateDateFormat() {
        const formattedDate = Utils.getFormattedDate(this._settings);
        if (formattedDate)
            this._clockDisplay.text = formattedDate;
        else
            this._clockDisplay.text = this._clock.clock;
    }

    setAppsPosition() {
        const position = this._settings.get_enum('position-in-panel');
        const offset = this._settings.get_int('position-offset');

        this._setElementPosition(this.appDisplayBox, position, offset);
    }

    _setClockPosition() {
        const position = this._settings.get_enum('clock-position-in-panel');
        const offset = this._settings.get_int('clock-position-offset');

        if (position === Enums.PanelPosition.LEFT || position === Enums.PanelPosition.RIGHT)
            this._dateMenu.style = '-natural-hpadding: 0px; -minimum-hpadding: 0px;';
        else
            this._dateMenu.style = '';

        this._setElementPosition(this._dateMenu, position, offset);
    }

    _setClockFontSize() {
        const [clockSizeOverride, clockSize] = this._settings.get_value('clock-font-size').deep_unpack();

        if (!clockSizeOverride) {
            this._clockDisplay.style = 'text-align: center';
            if (this._weatherTemp)
                this._weatherTemp.style = this._clockDisplay.style;
            return;
        }

        this._clockDisplay.style = `font-size: ${clockSize}px; text-align: center`;
        if (this._weatherTemp)
            this._weatherTemp.style = this._clockDisplay.style;
    }

    _setElementPosition(element, position, offset) {
        element = element.container ?? element;

        const parent = element.get_parent();
        if (parent)
            parent.remove_child(element);

        if (position === Enums.PanelPosition.LEFT) {
            this.panel._leftBox.insert_child_at_index(element, offset);
        } else if (position === Enums.PanelPosition.CENTER) {
            this.panel._centerBox.insert_child_at_index(element, offset);
        } else if (position === Enums.PanelPosition.RIGHT) {
            const nChildren = this.panel._rightBox.get_n_children();
            const order = Math.clamp(nChildren - offset, 0, nChildren);
            this.panel._rightBox.insert_child_at_index(element, order);
        }
    }

    // Based on code from Just Perfection extension
    setSizeAndPosition() {
        const panelLocation = this._settings.get_enum('panel-location');
        this.panelBox.set_size(this._monitor.width, -1);

        if (panelLocation === Enums.PanelLocation.TOP) {
            if (this._workareasChangedId) {
                global.display.disconnect(this._workareasChangedId);
                this._workareasChangedId = null;
            }
            this.panelBox.set_position(this._monitor.x, this._monitor.y);
            Main.layoutManager.uiGroup.remove_style_class_name('azTaskbar-bottom-panel');
            return;
        }

        const bottomY = this._monitor.y + this._monitor.height - this.panelBox.height;
        this.panelBox.set_position(this._monitor.x, bottomY);
        Main.layoutManager.uiGroup.add_style_class_name('azTaskbar-bottom-panel');

        if (!this._workareasChangedId) {
            this._workareasChangedId = global.display.connect('workareas-changed', () => {
                const newBottomY = this._monitor.y + this._monitor.height - this.panelBox.height;
                this.panelBox.set_position(this._monitor.x, newBottomY);
                Main.layoutManager.uiGroup.add_style_class_name('azTaskbar-bottom-panel');
            });
        }
    }

    destroy() {
        this._destroyWeatherWidget();

        this._clockDisplay.disconnectObject(this);
        this.panelBox.disconnectObject(this);
        this._settings.disconnectObject(this);

        if (this._workareasChangedId) {
            global.display.disconnect(this._workareasChangedId);
            this._workareasChangedId = null;
        }

        if (!this.isMainPanel) {
            this.panel.disable();
            this.panelBox.destroy();
        } else {
            this._clockDisplay.text = this._clock.clock;
            this._clockDisplay.style = '';

            this._setElementPosition(this._dateMenu, Enums.PanelPosition.CENTER, 0);

            this._appDisplayBox.destroy();
        }
    }
};

export default class AzTaskbar extends Extension {
    constructor(metaData) {
        super(metaData);
        this.persistentStorage = {};
    }

    enable() {
        this._taskbarManager = new TaskbarManager(this);
        this.settings = this.getSettings();

        this.remoteModel = new UnityLauncherAPI.LauncherEntryRemoteModel();
        this.notificationsMonitor = new NotificationsMonitor();

        global.azTaskbar = new EventEmitter();

        Theming.createStylesheet();

        this.settings.connectObject('changed::position-in-panel', () => this._setAppsPosition(), this);
        this.settings.connectObject('changed::position-offset', () => this._setAppsPosition(), this);
        this.settings.connectObject('changed::panel-on-all-monitors', () => this._resetPanels(), this);
        this.settings.connectObject('changed::panel-location', () => {
            this._setPanelsLocation();
            Theming.updateStylesheet();
        }, this);
        this.settings.connectObject('changed::isolate-monitors', () => this._resetPanels(), this);
        this.settings.connectObject('changed::show-panel-activities-button', () => this._setActivitiesVisibility(), this);
        this.settings.connectObject('changed::main-panel-height', () => Theming.updateStylesheet(), this);

        Main.layoutManager.connectObject('monitors-changed', () => this._resetPanels(), this);

        Main.panel.add_style_class_name('azTaskbar-panel');

        this._createPanels();
        this._setPanelsLocation();
        this._setActivitiesVisibility();
    }

    disable() {
        const mainMonitor = Main.layoutManager.primaryMonitor;
        Main.layoutManager.panelBox.set_position(mainMonitor.x, mainMonitor.y);
        Main.layoutManager.uiGroup.remove_style_class_name('azTaskbar-bottom-panel');

        if (!Main.sessionMode.isLocked)
            Main.panel.statusArea.activities.container.show();

        Main.panel.remove_style_class_name('azTaskbar-panel');

        Theming.deleteStylesheet();

        this.remoteModel.destroy();
        delete this.remoteModel;

        this.notificationsMonitor.destroy();
        delete this.notificationsMonitor;

        this._deletePanels();
        delete global.azTaskbar;

        this._taskbarManager.destroy();
        this._taskbarManager = null;

        Main.layoutManager.disconnectObject(this);
        this.settings.disconnectObject(this);
        this.settings = null;
    }

    _setActivitiesVisibility() {
        const showActivitiesButton = this.settings.get_boolean('show-panel-activities-button');

        this._panelBoxes.forEach(panelBox => {
            if (panelBox.panel.statusArea.activities)
                panelBox.panel.statusArea.activities.container.visible = showActivitiesButton;
        });
    }

    _resetPanels() {
        this._deletePanels();
        this._createPanels();
        this._setPanelsLocation();
        this._setActivitiesVisibility();
    }

    _createPanels() {
        this._panelBoxes = [];

        if (this.settings.get_boolean('panel-on-all-monitors')) {
            Main.layoutManager.monitors.forEach(monitor => {
                const panelManager = new PanelManager(monitor);
                const {panelBox} = panelManager;

                panelBox.visible = true;
                if (monitor.inFullscreen)
                    panelBox.hide();

                this._panelBoxes.push(panelManager);
            });
            global.azTaskbar.panels = this._panelBoxes.map(pb => pb.panelBox);
            global.azTaskbar.emit('panels-created');
        } else {
            this._panelBoxes.push(new PanelManager(Main.layoutManager.primaryMonitor));
            global.azTaskbar.panels = null;
        }
    }

    _deletePanels() {
        this._panelBoxes.forEach(panelBox => {
            panelBox.destroy();
        });
        this._panelBoxes = null;
        global.azTaskbar.panels = null;
    }

    _setPanelsLocation() {
        this._panelBoxes.forEach(panelBox => panelBox.setSizeAndPosition());
    }

    _setAppsPosition() {
        this._panelBoxes.forEach(panelBox => panelBox.setAppsPosition());
    }
}
