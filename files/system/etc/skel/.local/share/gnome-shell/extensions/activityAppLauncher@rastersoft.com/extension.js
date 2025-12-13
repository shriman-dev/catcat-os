import GioUnix from 'gi://GioUnix'
import St from 'gi://St'
import GMenu from 'gi://GMenu'
import GObject from 'gi://GObject'
import Clutter from 'gi://Clutter'
import Shell from 'gi://Shell'

import * as AppDisplay from 'resource:///org/gnome/shell/ui/appDisplay.js'
import * as Main from 'resource:///org/gnome/shell/ui/main.js'
import * as Favorites from 'resource:///org/gnome/shell/ui/appFavorites.js'

import {Extension, gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';

const ButtonType = Object.freeze({
    Windows: 0,
    AllApps: 1,
    Favorites: 2,
    Frequents: 3,
    Group: 4
});

// Version 12

var BaseConstraint = GObject.registerClass(
class BaseConstraint extends Clutter.Constraint {
    _init(props) {
        super._init(props);
        this._element = null;
        this._settings = null;
    }

    set_element(element, settings) {
        this._element = element;
        this._settings = settings;
    }

    vfunc_update_allocation(actor, actorBox) {
        const prefSize = this._element.get_preferred_size();
        let x = 0;
        let y = Main.panel.height;
        const [stageWidth, stageHeight] = Main.layoutManager.overviewGroup.get_transformed_size();
        if (this._settings.get_boolean('show-centered')) {
            y = Math.max(y, Math.floor((stageHeight - prefSize[3]) / 2));
        }
        const dash = Main.overview._overview.dash;
        const [dashX, dashY] = dash.get_transformed_position();
        const [dashWidth, dashHeight] = dash.get_transformed_size();
        if (dashWidth < dashHeight) { // vertical dash
            if (dashX < (stageWidth/2)) { // dash is at the left
                x = dashWidth;
            }
        } else { // horizontal dash
            if (dashY < (stageHeight/2)) { // dash is at the top
                y += dashHeight;
            }
        }
        actorBox.init_rect(x, y, prefSize[2], prefSize[3]);
    }
});

export default class ActivityAppLauncher extends Extension {
    constructor(data) {
        super(data);
        this._startupPreparedId = 0;
        this._appsInnerContainer = null;
        this.selected = null;
    }

    enable() {
        // Wait until startup completed
        if (Main.layoutManager._startingUp) {
            this._startupPreparedId = Main.layoutManager.connect('startup-complete', () => {
                this._doEnable();
            });
        } else {
            this._doEnable();
        }
    }

    _doEnable() {
        // Does all the enabling work, after the startup process has been completed
        if (this._startupPreparedId != 0) {
            Main.layoutManager.disconnect(this._startupPreparedId);
            this._startupPreparedId = 0;
        }
        this._appSys = Shell.AppSystem.get_default();
        this._settings = this.getSettings();

        // Add the categories menu in the overview container
        this._appsInnerContainer = new St.BoxLayout({
            vertical: true,
            x_align: Clutter.ActorAlign.START,
            y_align: Clutter.ActorAlign.CENTER,
            x_expand: false,
            y_expand: true
        });
        this._constraint = new BaseConstraint();
        this._constraint.set_element(this._appsInnerContainer, this._settings);
        this._appsInnerContainer.add_constraint(this._constraint);
        Main.layoutManager.overviewGroup.add_child(this._appsInnerContainer);
        this._appsInnerContainer.show();
        this._show();
        let activityAppLauncherObject = this; // to have it available inside the new functions
        this._appDisplay = Main.overview._overview.controls.appDisplay;

        //--------- BEGIN GNOME SHELL MONKEY PATCHING

        // Replace the ordering function in the applications list object
        this._oldCompareItemsFunc = this._appDisplay._compareItems;
        let oldCompareItemsFunc = this._oldCompareItemsFunc;
        this._appDisplay._compareItems = function (a, b) {
            if (activityAppLauncherObject.selected === null) {
                return oldCompareItemsFunc.bind(this)(a, b);
            }
            return a.name.localeCompare(b.name);
        }

        // Replace the application list loading function in the applications list object
        this._oldLoadAppsFunc = this._appDisplay._loadApps;
        let oldLoadAppsFunc = this._oldLoadAppsFunc;
        this._appDisplay._loadApps = function () {
            if (activityAppLauncherObject.selected === null) {
                return oldLoadAppsFunc.bind(this)();
            }
            let appIcons = [];
            this._appInfoList = Shell.AppSystem.get_default().get_installed().filter(appInfo => {
                try {
                    appInfo.get_id(); // catch invalid file encodings
                } catch (e) {
                    return false;
                }
                if (!this._parentalControlsManager.shouldShowApp(appInfo)) {
                    return false;
                }

                // the objects obtained with GMenu.tree don't contain
                // the should_show() method, so it is a must to map the
                // objects obtained with Shell.AppSystem with the ones to show.
                for (let app of activityAppLauncherObject.selected) {
                    if (app === null) {
                            continue;
                    }
                    if (app.get_id() == appInfo.get_id()) {
                        return true;
                    }
                }
                return false;
            });

            let apps = this._appInfoList.map(app => app.get_id());

            let appSys = Shell.AppSystem.get_default();

            this._folderIcons = [];

            // Allow dragging of the icon only if the Dash would accept a drop to
            // change favorite-apps. There are no other possible drop targets from
            // the app picker, so there's no other need for a drag to start,
            // at least on single-monitor setups.
            // This also disables drag-to-launch on multi-monitor setups,
            // but we hope that is not used much.
            const isDraggable =
                global.settings.is_writable('favorite-apps') ||
                global.settings.is_writable('app-picker-layout');
            apps.forEach(appId => {
                let icon = this._items.get(appId);
                if (!icon) {
                    let app = appSys.lookup_app(appId);
                    icon = new AppDisplay.AppIcon(app, { isDraggable });
                    icon.connect('notify::pressed', () => {
                        if (icon.pressed)
                            this.updateDragFocus(icon);
                    });
                }
                appIcons.push(icon);
            });
            return appIcons;
        }.bind(this._appDisplay);

        //------------ END GNOME SHELL MONKEY PATCHING

        this._favorites = Favorites.getAppFavorites();
        this._usage = Shell.AppUsage.get_default();
        this.showingId = Main.overview.connect('showing', () => { this._show(); });
        this.hidingId = Main.overview.connect('hiding', () => { this._hide(); });
    }

    disable() {
        // Restore everything inside Gnome Shell
        Main.layoutManager.overviewGroup.remove_child(this._appsInnerContainer);
        this._appDisplay._loadApps = this._oldLoadAppsFunc;
        this._appDisplay._compareItems = this._oldCompareItemsFunc;
        this._oldLoadAppsFunc = null;
        this._oldCompareItemsFunc = null;
        this._appsInnerContainer = null;
        this._constraint = null;

        // Disconnect the signals
        if (this.showingId) {
            Main.overview.disconnect(this.showingId);
            this.showingId = 0;
        }
        if (this.hidingId) {
            Main.overview.disconnect(this.hidingId);
            this.hidingId = 0;
        }
        if (this._startupPreparedId != 0) {
            Main.layoutManager.disconnect(this._startupPreparedId);
            this._startupPreparedId = 0;
        }
        this._appSys = null;
        this._settings = null;
        this._appsInnerContainer = null;
        this.selected = null;
        this._favorites = null;
        this._usage = null;
    }

    _hide() {
        this.selected = null;
        this._appsInnerContainer.destroy_all_children();
    }

    _show() {
        this.selected = null;
        this._fillCategories();
    }

    _fillCategories() {
        this.selected = null;
        this._appsInnerContainer.destroy_all_children();

        this._appsInnerContainer.buttons = [];
        this._appsInnerContainer.appClass = [];

        const tree = new GMenu.Tree({ menu_basename: 'applications.menu' });
        tree.load_sync();
        const root = tree.get_root_directory();
        const categoryMenuItem = new AALCathegory_Menu_Item(this, ButtonType.Windows, _("Windows"), null);
        this._appsInnerContainer.add_child(categoryMenuItem);
        this._appsInnerContainer.buttons.push(categoryMenuItem);

        const allAppsMenuItem = new AALCathegory_Menu_Item(this, ButtonType.AllApps, _("All apps"), null);
        this._appsInnerContainer.add_child(allAppsMenuItem);
        this._appsInnerContainer.buttons.push(allAppsMenuItem);

        if (this._settings.get_boolean("show-favorites")) {
            let favoritesMenuItem = new AALCathegory_Menu_Item(this, ButtonType.Favorites, _("Favorites"), null);
            this._appsInnerContainer.add_child(favoritesMenuItem);
            this._appsInnerContainer.buttons.push(favoritesMenuItem);
        }

        if (this._settings.get_boolean("show-frequent")) {
            let mostUsedMenuItem = new AALCathegory_Menu_Item(this, ButtonType.Frequents, _("Frequent"), null);
            this._appsInnerContainer.add_child(mostUsedMenuItem);
            this._appsInnerContainer.buttons.push(mostUsedMenuItem);
        }

        const iter = root.iter();
        let nextType;
        while ((nextType = iter.next()) != GMenu.TreeItemType.INVALID) {
            if (nextType == GMenu.TreeItemType.DIRECTORY) {
                const dir = iter.get_directory();
                if (!dir.get_is_nodisplay()) {
                    const childrens = this._fillCategories2(dir, []);
                    if (childrens.length != 0) {
                        const item = { dirItem: dir, dirChilds: childrens };
                        this._appsInnerContainer.appClass.push(item);
                    }
                }
            }
        }
        for (var i = 0; i < this._appsInnerContainer.appClass.length; i++) {
            const categoryMenuItem = new AALCathegory_Menu_Item(this, ButtonType.Group, this._appsInnerContainer.appClass[i].dirItem.get_name(), this._appsInnerContainer.appClass[i].dirChilds);
            this._appsInnerContainer.add_child(categoryMenuItem);
            this._appsInnerContainer.buttons.push(categoryMenuItem);
        }
    }

    _fillCategories2(dir, childrens) {
        const iter = dir.iter();
        let nextType;

        while ((nextType = iter.next()) != GMenu.TreeItemType.INVALID) {
            if (nextType == GMenu.TreeItemType.ENTRY) {
                const entry = iter.get_entry();
                const fileId = entry.get_desktop_file_id();
                const appInfo = GioUnix.DesktopAppInfo.new(fileId);
                if (!appInfo.get_nodisplay()) {
                    const app = this._appSys.lookup_app(fileId);
                    childrens.push(app);
                }
            } else if (nextType == GMenu.TreeItemType.DIRECTORY) {
                childrens = this._fillCategories2(iter.get_directory(), childrens);
            }
        }
        return childrens;
    }

    _clickedCathegory(button) {
        for (var i = 0; i < this._appsInnerContainer.buttons.length; i++) {
            var tmpbutton = this._appsInnerContainer.buttons[i];
            if (button == tmpbutton) {
                tmpbutton.checked = true;
            } else {
                tmpbutton.checked = false;
            }
        }

        switch (button.launcherType) {
            case ButtonType.Group:
                this.selected = button.launchers;
                break;
            case ButtonType.Windows:
            case ButtonType.AllApps:
                this.selected = null;
                break;
            case ButtonType.Favorites:
                this.selected = this._favorites.getFavorites();
                break;
            case ButtonType.Frequents:
                this.selected = this._usage.get_most_used();
                break;
        }

        if (button.launcherType == ButtonType.Windows) {
            Main.overview.dash.showAppsButton.checked = false;
        } else {
            // Remove all the icons from the grid and insert them again, alphabetically sorted
            [...this._appDisplay.getAllItems()].forEach(icon => {
                this._appDisplay._removeItem(icon);
                icon.destroy();
            });
            this._appDisplay._loadApps().sort(this._appDisplay._compareItems.bind(this._appDisplay)).forEach(icon => {
                this._appDisplay._addItem(icon, -1, -1);
            });
            Main.overview.dash.showAppsButton.checked = true;
        }
    }
}

const AALCathegory_Menu_Item = GObject.registerClass({
    GTypeName: 'AALCathegory_Menu_Item',
}, class AALCathegory_Menu_Item extends St.Button {
    _init(topClass, type, cathegory, launchers) {
        this.topClass = topClass;
        this.cat = cathegory;
        this.launchers = launchers;
        this.launcherType = type;
        super._init({
            label: cathegory,
            style_class: "world-clocks-button button activityAppLauncherButton",
            toggle_mode: true,
            can_focus: true,
            track_hover: true
        });
        this.connect("clicked", () => {
            this.topClass._clickedCathegory(this);
        });
        this.show();
    }
});
