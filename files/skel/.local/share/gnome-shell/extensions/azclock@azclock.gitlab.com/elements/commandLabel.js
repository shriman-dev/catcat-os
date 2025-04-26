import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';

import {gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';

import {Label} from './baseLabel.js';

Gio._promisify(Gio.Subprocess.prototype, 'communicate_utf8_async');

export const CommandLabel = GObject.registerClass(
class AzClockCommandLabel extends Label {
    _init(settings, extension) {
        super._init(settings, extension);
        this._settings.connectObject('changed::command', () => this._refreshCommand(), this);
        this._settings.connectObject('changed::polling-interval', () => this._refreshCommand(), this);
        this._refreshCommand();
    }

    _setErrorState() {
        this._removePollingInterval();
        this.text = _('error');
        this.clutter_text.set_markup(this.text);
    }

    _refreshCommand() {
        this._removePollingInterval();
        this._executeCommand();
        this._startPollingInterval();
    }

    _startPollingInterval() {
        const pollingInterval = this._settings.get_int('polling-interval');
        const interval = Math.max(pollingInterval, 250);
        this._pollingIntervalId = GLib.timeout_add(GLib.PRIORITY_HIGH, interval, () => {
            this._executeCommand();
            return GLib.SOURCE_CONTINUE;
        });
    }

    _removePollingInterval() {
        if (this._pollingIntervalId) {
            GLib.source_remove(this._pollingIntervalId);
            this._pollingIntervalId = null;
        }
    }

    _executeCommand() {
        const command = this._settings.get_string('command');
        this._execCommand(command).then(() => this.queue_relayout());
    }

    async _execCommand(command, input = null, cancellable = null) {
        if (!command || command.length === 0) {
            this._setErrorState();
            console.log('Desktop Widgets - Error executing command. No command detected.');
            return;
        }
        try {
            const argv = ['bash', '-c', command];

            let flags = Gio.SubprocessFlags.STDOUT_PIPE |
                Gio.SubprocessFlags.STDERR_PIPE;

            if (input !== null)
                flags |= Gio.SubprocessFlags.STDIN_PIPE;

            const proc = Gio.Subprocess.new(argv, flags);

            const [stdout, stderr] = await proc.communicate_utf8_async(input, cancellable);

            if (!proc.get_successful() || stderr) {
                this._setErrorState();
                const status = proc.get_exit_status();
                console.log(`Desktop Widgets - Error executing command "${command}": ${stderr ? stderr.trim() : GLib.strerror(status)}`);
                return;
            }

            const response = stdout.trim();

            if (!response) {
                this._setErrorState();
                console.log(`Desktop Widgets - Error executing command "${command}": no output.`);
                return;
            }

            this.text = response;
            this.clutter_text.set_markup(this.text);
        } catch (err) {
            this._setErrorState();
            console.log(`Desktop Widgets - Error executing command "${command}": ${err}`);
        }
    }

    _onDestroy() {
        this._removePollingInterval();
        super._onDestroy();
    }
});
