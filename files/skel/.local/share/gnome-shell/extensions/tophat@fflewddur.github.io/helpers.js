// Copyright (C) 2024 Todd Kulesza <todd@dropline.net>
import * as Config from 'resource:///org/gnome/shell/misc/config.js';
export const GnomeMajorVer = parseInt(Config.PACKAGE_VERSION.split('.')[0]);
export var DisplayType;
(function (DisplayType) {
    DisplayType[DisplayType["Chart"] = 0] = "Chart";
    DisplayType[DisplayType["Numeric"] = 1] = "Numeric";
    DisplayType[DisplayType["Both"] = 2] = "Both";
})(DisplayType || (DisplayType = {}));
const ONE_MB_IN_B = 1000000;
const TEN_MB_IN_B = 10000000;
const ONE_GB_IN_B = 1000000000;
const TEN_GB_IN_B = 10000000000;
const ONE_TB_IN_B = 1000000000000;
const TEN_TB_IN_B = 10000000000000;
/**
 * Convert a number of bytes to a more logical human-readable string (e.g., 1024 -> 1 K).
 *
 * @param {number} bytes - Number of bytes to convert
 * @param {string} [unit='bytes']  - Either bytes or bits
 * @param {boolean} [imprecise=false] - Reduce precision to 0
 */
export function bytesToHumanString(bytes, unit = 'bytes', imprecise = false) {
    let quantity = bytes;
    let precision = 1;
    if (imprecise) {
        precision = 0;
    }
    let suffix = 'B';
    if (unit === 'bits') {
        quantity *= 8;
        suffix = 'b';
    }
    if (quantity < 1) {
        return `0 K${suffix}`;
    }
    else if (quantity < 1000) {
        // Indicate activity, but don't clutter the UI w/ # of bytes
        return `< 1 K${suffix}`;
    }
    else if (quantity < ONE_MB_IN_B) {
        return `${(quantity / 1000).toFixed(0)} K${suffix}`;
    }
    else if (quantity < TEN_MB_IN_B) {
        // Show one decimal of precision for < 100 MB
        return `${(quantity / ONE_MB_IN_B).toFixed(precision)} M${suffix}`;
    }
    else if (quantity < ONE_GB_IN_B) {
        return `${(quantity / ONE_MB_IN_B).toFixed(0)} M${suffix}`;
    }
    else if (quantity < TEN_GB_IN_B) {
        return `${(quantity / ONE_GB_IN_B).toFixed(precision)} G${suffix}`;
    }
    else if (quantity < ONE_TB_IN_B) {
        return `${(quantity / ONE_GB_IN_B).toFixed(0)} G${suffix}`;
    }
    else if (quantity < TEN_TB_IN_B) {
        return `${(quantity / ONE_TB_IN_B).toFixed(precision)} T${suffix}`;
    }
    else {
        return `${(quantity / ONE_TB_IN_B).toFixed(0)} T${suffix}`;
    }
}
/**
 * Round up to the nearest power of 10 (or half that).
 *
 * @param {number} bytes - Value of bytes to round
 */
export function roundMax(bytes) {
    let result = Math.pow(10, Math.ceil(Math.log10(bytes)));
    while (result / 2 > bytes && result > 20000) {
        result /= 2;
    }
    return result;
}
export function getDisplayTypeSetting(settings, key) {
    let t = DisplayType.Both;
    switch (settings.get_string(key)) {
        case 'chart':
            t = DisplayType.Chart;
            break;
        case 'numeric':
            t = DisplayType.Numeric;
            break;
        case 'both':
            t = DisplayType.Both;
            break;
    }
    return t;
}
