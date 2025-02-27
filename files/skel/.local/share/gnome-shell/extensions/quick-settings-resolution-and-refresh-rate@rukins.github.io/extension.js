import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';

import * as FileUtils from "./fileUtils.js";
import { ResolutionIndicator, RefreshRateIndicator } from "./indicators.js";
import { ResolutionMenuToggle, RefreshRateMenuToggle } from "./menuToggles.js";


const DISPLAY_CONFIG_OBJECT_PATH = "/org/gnome/Mutter/DisplayConfig";
const DISPLAY_CONFIG_INTERFACE = "org.gnome.Mutter.DisplayConfig";

export const MonitorConfigParameters = Object.freeze({
    RESOLUTION: "resolutions",
    REFRESH_RATE: "refreshRates"
});

export default class QuickSettingsResolutionAndRefreshRateExtension extends Extension {

    _settings = null;

    _monitorsConfigCache = {};
    _monitorsConfigSerialCache = null;
    _monitorsConfigProxy = null;

    _monitorsConfigChangedSignalId = null;

    constructor(metadata) {
        super(metadata);
    }

    async enable() {
        this._settings = this.getSettings();

        const MonitorsConfigProxyWrapper = Gio.DBusProxy.makeProxyWrapper(
            FileUtils.loadXML(
                DISPLAY_CONFIG_INTERFACE, GLib.build_filenamev([this.metadata.path])
            )
        );

        await MonitorsConfigProxyWrapper.newAsync(
            Gio.DBus.session,
            DISPLAY_CONFIG_INTERFACE,
            DISPLAY_CONFIG_OBJECT_PATH
        ).then(
            proxy => {
                this._monitorsConfigProxy = proxy;
            }
        ).catch(
            e => {
                // TODO: add notifier for errors
            }
        );

        this._resolutionMenuToggle = new ResolutionMenuToggle(this);
        this._resolutionIndicator = new ResolutionIndicator(this);
        this._resolutionIndicator.quickSettingsItems.push(this._resolutionMenuToggle);

        this._refreshRateMenuToggle = new RefreshRateMenuToggle(this);
        this._refreshRateIndicator = new RefreshRateIndicator(this);
        this._refreshRateIndicator.quickSettingsItems.push(this._refreshRateMenuToggle);

        Main.panel.statusArea.quickSettings.addExternalIndicator(this._resolutionIndicator);
        Main.panel.statusArea.quickSettings.addExternalIndicator(this._refreshRateIndicator);

        this._monitorsConfigChangedSignalId = this._monitorsConfigProxy.connectSignal("MonitorsChanged", () => {
            this._updateMonitorsConfig();
        });

        this._settings.bind(
            "add-resolution-toggle-menu",
            this._resolutionMenuToggle,
            "visible",
            Gio.SettingsBindFlags.DEFAULT
        );
        this._settings.bind(
            "add-refresh-rate-toggle-menu",
            this._refreshRateMenuToggle,
            "visible",
            Gio.SettingsBindFlags.DEFAULT
        );

        this._updateMonitorsConfig();
    }

    disable() {
        this._resolutionIndicator?.quickSettingsItems.forEach(item => item.destroy());
        this._resolutionIndicator?.destroy();
        this._resolutionIndicator = null;
        this._resolutionMenuToggle = null;

        this._refreshRateIndicator?.quickSettingsItems.forEach(item => item.destroy());
        this._refreshRateIndicator?.destroy();
        this._refreshRateIndicator = null;
        this._refreshRateMenuToggle = null;

        if (this._monitorsConfigChangedSignalId) {
            this._monitorsConfigProxy.disconnectSignal(this._monitorsConfigChangedSignalId);
            this._monitorsConfigChangedSignalId = null;
        }

        this._settings = null;

        this._monitorsConfigCache = null;
        this._monitorsConfigSerialCache = null;
        this._monitorsConfigProxy = null;

        this.MonitorsConfigProxyWrapper = null;
    }

    get monitorsConfig() {
        return this._monitorsConfigCache;
    }

    get monitorsConfigSerial() {
        return this._monitorsConfigSerialCache;
    }

    getMonitorConfigElementActivateCallback(monitorName, monitorConfigElement, monitorConfigParameter) {
        let askToUpdate = true;

        let currentSettings = this.monitorsConfig[monitorName]["currentSettings"]

        const callback = () => {
            this._monitorsConfigProxy.ApplyMonitorsConfigRemote(
                this.monitorsConfigSerial,
                (askToUpdate ? 2 : 1),
                [
                    [
                        currentSettings[0], currentSettings[1], currentSettings[2], currentSettings[3], currentSettings[4],
                        [
                            [
                                monitorName,
                                this._generateMonitorConfigStringFor(monitorName, monitorConfigElement, monitorConfigParameter),
                                {}
                            ]
                        ]
                    ]
                ],
                {},
                () => {},
            );
        };

        return callback;
    }

    // generates string in format - "{resolution.horizontally}x{resolution.vertically}@{refreshRate.value}"
    _generateMonitorConfigStringFor(monitorName, monitorConfigElement, monitorConfigParameter) {
        if (monitorConfigParameter === MonitorConfigParameters.RESOLUTION) {
            return `${monitorConfigElement.horizontally}x${monitorConfigElement.vertically}@${monitorConfigElement[MonitorConfigParameters.REFRESH_RATE][0].value}`;
        } else if (monitorConfigParameter === MonitorConfigParameters.REFRESH_RATE) {
            const currentResolutionConfig = this._getCurrentMonitorConfigElementByMonitorName(monitorName, MonitorConfigParameters.RESOLUTION);

            return `${currentResolutionConfig.horizontally}x${currentResolutionConfig.vertically}@${monitorConfigElement.value}`;
        }

        return null;
    }

    _getCurrentMonitorConfigElementByMonitorName(monitorName, monitorConfigParameter) {
        return this.monitorsConfig[monitorName][monitorConfigParameter].find(item => item.isCurrent === true);
    }

    _updateMonitorsConfig() {
        // using Remote instead of Sync because the interface freezes with Sync
        this._monitorsConfigProxy.GetCurrentStateRemote((res) => {
            const {monitorsConfig, serial} = this._parseMonitorsConfig(res);
            this._monitorsConfigCache = monitorsConfig;
            this._monitorsConfigSerialCache = serial;

            this._resolutionMenuToggle.emitMonitorsConfigUpdated();
            this._refreshRateMenuToggle.emitMonitorsConfigUpdated();
        });
    }

    _parseMonitorsConfig(data) {
        if (data.length === 0) return {};

        const serial = data[0];

        const monitorsConfig = {};
        for (let i = 0; i < data[1].length; i++) {
            let monitorDetails = data[1][i]
            let currentMonitorSettings = data[2][i]

            let monitorName = monitorDetails[0][0];

            let resolutions = [];
            monitorDetails[1].forEach((el) => {
                let isCurrent = "is-current" in el[6];
                let isPreferred = "is-preferred" in el[6];

                let resolution = {
                    "horizontally": el[1],
                    "vertically": el[2],
                    "isCurrent": isCurrent,
                    "isPreferred": isPreferred,
                    "refreshRates": []
                };
                let refreshRate = {
                    "value": el[3].toFixed(3),
                    "isCurrent": isCurrent,
                    "isPreferred": isPreferred
                };

                let savedResolution = resolutions.find(item => item["horizontally"] === resolution["horizontally"] && item["vertically"] === resolution["vertically"]);
                if (savedResolution) {
                    if (isCurrent) savedResolution["isCurrent"] = isCurrent
                    if (isPreferred) savedResolution["isPreferred"] = isPreferred

                    resolution = savedResolution
                } else {
                    resolutions.push(resolution)
                }

                let savedRefreshRate = resolution["refreshRates"].find(item => item["value"] === refreshRate["value"]);
                if (savedRefreshRate) {
                    if (isCurrent) savedRefreshRate["isCurrent"] = isCurrent
                    if (isPreferred) savedRefreshRate["isPreferred"] = isPreferred
                } else {
                    resolution["refreshRates"].push(refreshRate);
                }
            });

            monitorsConfig[monitorName] = {
                "resolutions": resolutions,
                "currentSettings": currentMonitorSettings
            };
        }

        return {
            "monitorsConfig": monitorsConfig,
            "serial": serial
        };
    }
}
