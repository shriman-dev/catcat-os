import GLib from 'gi://GLib';

class IdleRunner {
    callback;
    idleId = null;
    _priority;
    lastRun = null;
    constructor(callback, priority = GLib.PRIORITY_DEFAULT_IDLE) {
        this.callback = callback;
        this._priority = priority;
    }
    /**
     * An idle runner that is automatically stopped after the callback has been called once.
     *
     * Note that `start` still needs to be called to start the idle runner. If start is called multiple
     * times, the callback will run once per invocation.
     */
    static once(cb, priority = GLib.PRIORITY_DEFAULT_IDLE) {
        return new IdleRunner((stop) => {
            cb();
            stop();
        }, priority);
    }
    /**
     * Start the idle runner if it is not running already.
     */
    start() {
        if (this.idleId !== null)
            return;
        const iid = GLib.idle_add(this._priority, () => {
            let now = Date.now();
            let dt = this.lastRun != null ? now - this.lastRun : null;
            this.lastRun = now;
            this.callback(this.stop.bind(this), dt);
            return this.idleId === iid ? GLib.SOURCE_CONTINUE : GLib.SOURCE_REMOVE;
        });
        this.idleId = iid;
    }
    /**
     * Stop running the idle callback. Can be resumed using `start()`.
     */
    stop() {
        if (this.idleId !== null) {
            GLib.source_remove(this.idleId);
            this.idleId = null;
            this.lastRun = null;
        }
    }
}

export { IdleRunner };
