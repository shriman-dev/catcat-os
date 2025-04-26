"use strict";

import GLib from "gi://GLib";

import * as Config from "./config.js";

/**
 * Output a debug message to the console if the debug config is active.
 *
 * @param {string} message The message to log.
 */
export function logDebug(message) {
  Config.debug && console.log(`[DEBUG] Bedtime Mode: ${message}`);
}

/**
 * This runs in a loop the provided function at the specified interval.
 *
 * The loop is active until the function returns true.
 * Otherwise (false/no return/other return value) the loop is stopped.
 *
 * @param {*} func The function to loop at the specified interval
 * @param {*} interval The time in milliseconds at which to call the function
 * @param  {...any} args Optional arguments to the function
 * @returns The corresponding GLib.Source object which needs be destroyed later on
 */
export function loopRun(func, interval, ...args) {
  const wrappedFunc = () => {
    return func.apply(this, args);
  };

  const loopSourceId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, interval, wrappedFunc);
  return GLib.main_context_default().find_source_by_id(loopSourceId);
}
