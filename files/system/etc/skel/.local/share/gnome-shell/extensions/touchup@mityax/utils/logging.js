import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
import { logFile } from '../config.js';

/**
 * Log the given arguments to the console and the logfile (if given), together with a timestamp.
 *
 * Note: This function is **not** optimized for speed (!)
 */
function log(...text) {
    if (text.length < 1)
        return '';
    console.log("[touchup] ", ...text.map(item => {
        if (item && item instanceof Error) {
            console.error(item, item.message || '', "\n", item.stack);
        }
        return repr(item);
    }));
    let msg = text.map(item => {
        return item && item instanceof Error
            ? `Error (${item}): ` + (item.message || '')
            : repr(item);
    }).join(" ");
    // If the last item is an error, we append its stack trace to the log message:
    if (text.at(-1) instanceof Error && text.at(-1).stack) {
        msg += '\n' + text.at(-1).stack.trim();
    }
    if (logFile) {
        const stream = Gio.File.new_for_path(logFile).append_to(Gio.FileCreateFlags.NONE, null);
        // @ts-ignore
        stream.write_bytes(new GLib.Bytes(`${new Date().toISOString()}: ${msg}\n`), null);
    }
    for (let cb of logCallbacks.values()) {
        cb(msg);
    }
    return msg;
}
/**
 * Tries to convert anything into a string representation that provides suitable debugging
 * information to developers
 */
function repr(item) {
    if (item === '')
        return "<empty string>";
    if (typeof item === 'symbol')
        return `<#${item.description}>`;
    if (['number', 'string'].indexOf(typeof item) !== -1)
        return `${item}`;
    let json;
    try {
        if (typeof item === 'object' || Array.isArray(item)) {
            json = JSON.stringify(item);
        }
    }
    catch (e) { }
    if (item && typeof item === 'object' && item.constructor && item.constructor.name) {
        if (item instanceof Error) {
            return `<${item.constructor.name} object ${item.message ? '– "' + item.message + '"' : ' (no error message)'}>`;
        }
        else if (item instanceof Gio.IOErrorEnum) {
            return `<Gio.IOErrorEnum {code: ${item.code}, message: ${item.message}}>`;
        }
        else if (json) {
            return `<${item.constructor.name} object ${json.length > 300 ? json.substring(0, 300) + ' [...]' : json}>`;
        }
        else {
            return `<${item.constructor.name} object (not stringifyable)>`;
        }
    }
    return json || `${item}`;
}
const logCallbacks = new Map();
/**
 * Throw an error if the given condition is not true.
 *
 * This is a no-op in release builds.
 */
function assert(condition, message) {
}

export { assert, log, repr };
