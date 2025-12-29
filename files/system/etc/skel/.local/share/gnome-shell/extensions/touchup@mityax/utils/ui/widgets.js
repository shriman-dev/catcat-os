import St from 'gi://St';
import GObject from 'gi://GObject';
import { filterObject } from '../utils.js';
import Clutter from 'gi://Clutter';
import { Delay } from '../delay.js';

/**
 * The [Widgets] module provides subclasses for most St.Widgets, that offer an easier, briefer and more elegant
 * way to create complex user interfaces - in a nested declarative way:
 *
 * ```
 * const myWidget = new Widgets.Column({
 *   children: [
 *     new Widgets.Label("Hello World"),
 *     new Widgets.Bin({height: 10}),   // some spacing
 *     new Widgets.Button({
 *       label: "Clicke me please!",
 *
 *       // Use the [css] helper function to elegantly define inline styles:
 *       style: css({
 *         color: 'red',
 *         borderRadius: '10px',
 *       }),
 *
 *       // All widget events are translated to callback properties automatically:
 *       onClick: () => debugLog("I've been clicked!")
 *     }),
 *     new Widgets.Icon({
 *       iconName: 'emblem-ok-symbolic',
 *
 *       // There are some special callbacks:
 *       onCreated: (icon) => icon.ease({ scale: 1.5 })
 *     }),
 *   ],
 * });
 * ```
 *
 * Keep in mind that while this structure is nested and looks a lot like typical declarative
 * frameworks (e.g. Flutter), there is no inherent declarative reactivity here – the UI is
 * defined once and needs to be manipulated imperatively (or rebuilt and replaced manually).
 */
/**
 * Helper class to manage references to [Clutter.Actor] instances.
 *
 * If the referenced actor is destroyed, the reference will be
 * automatically set to `null`.
 */
class Ref {
    _destroySignalId;
    /**
     * Create a reference with an optional initial value.
     */
    constructor(initialValue) {
        this.set(initialValue ?? null);
    }
    /**
     * Get the actor the reference points to, or `null` if the actor has been
     * destroyed or unset.
     */
    get current() {
        return this._value;
    }
    /**
     * Update the reference to point to the given actor, unset the reference if
     * `null` is passed.
     */
    set(value) {
        if (this._destroySignalId !== undefined && this._value) {
            this._value.disconnect(this._destroySignalId);
        }
        this._value = value;
        this._destroySignalId = value?.connect('destroy', () => this.set(null));
    }
    /**
     * Convenience method to call the given function or closure on the referenced
     * actor only if there is a referenced actor at the moment.
     *
     * Example:
     * ```typescript
     * const myRef = new Ref(myWidget);
     *
     * // Set the widget's opacity only if it has not been destroyed or in another way unset yet:
     * myRef.apply(w => w.opacity = 0.8);
     * ```
     */
    apply(fn) {
        if (this.current) {
            fn(this.current);
        }
    }
    _value = null;
}
function filterConfig(config, filterOut) {
    filterOut ??= [
        'ref', 'children', 'child', 'onCreated', 'constraints', /^(on|notify)[A-Z]/,
    ];
    return filterObject(config, 
    //@ts-ignore
    entry => typeof entry[0] === "string" && (!filterOut.some((filter) => filter instanceof RegExp
        ? filter.test(entry[0])
        : filter === entry[0])));
}
function initWidget(w, props) {
    if (props.ref)
        props.ref.set(w);
    props.constraints?.forEach(c => w.add_constraint(c));
    // Automatically connect signals from the constructor (e.g. `onClicked` or `notifySize`):
    for (const [key, value] of Object.entries(props)) {
        if (/^(on|notify)[A-Z]/.test(key) && typeof value === "function" && key !== "onCreated") {
            const signalName = key.replace(/^on/, "").replace(/^notify/, 'notify::')
                .replace(/(\w)([A-Z])/g, "$1-$2").toLowerCase();
            w.connect(signalName, value);
        }
    }
    const onCreatedRes = props.onCreated?.(w);
    if (onCreatedRes)
        w.connect('destroy', onCreatedRes);
}
class Button extends St.Button {
    static {
        GObject.registerClass(this);
    }
    constructor(config) {
        super(filterConfig(config));
        initWidget(this, filterConfig(config, config.onLongPress ? ['onLongPress', 'onClicked'] : []));
        if (config.onLongPress) {
            this._setupLongPress(config.onLongPress, config.onClicked);
        }
        if (config.child)
            this.child = config.child;
    }
    // A simple long press implementation, that is triggered after holding the button for 500ms
    // and cancelled when moving up earlier or when moving the finger too much.
    _setupLongPress(onLongPress, onClicked) {
        const pressEvents = [Clutter.EventType.TOUCH_BEGIN, Clutter.EventType.BUTTON_PRESS, Clutter.EventType.PAD_BUTTON_PRESS];
        const releaseEvents = [Clutter.EventType.TOUCH_END, Clutter.EventType.BUTTON_RELEASE, Clutter.EventType.PAD_BUTTON_RELEASE];
        const cancelEvents = [Clutter.EventType.TOUCH_CANCEL, Clutter.EventType.LEAVE];
        let downAt;
        const handleEvent = (_, evt) => {
            if (pressEvents.includes(evt.type())) {
                let thisDownAt = downAt = { t: evt.get_time(), x: evt.get_coords()[0], y: evt.get_coords()[1] };
                Delay.ms(500).then(() => {
                    if (this.pressed && downAt?.t === thisDownAt.t && downAt?.x === thisDownAt.x && downAt?.y === thisDownAt.y) {
                        // Long press detected!
                        onLongPress(this);
                        downAt = undefined;
                    }
                });
            }
            else if (releaseEvents.includes(evt.type()) && downAt) {
                if (evt.get_time() - downAt.t < 500)
                    onClicked?.(this); // Normal click detected!
                downAt = undefined;
            }
            else if (cancelEvents.includes(evt.type())) {
                downAt = undefined; // Click/long press cancelled
            }
            else if (evt.type() == Clutter.EventType.TOUCH_UPDATE && downAt) {
                let dist = Math.sqrt((evt.get_coords()[0] - downAt.x) ** 2 + (evt.get_coords()[1] - downAt.y) ** 2);
                if (dist > 15 * St.ThemeContext.get_for_stage(global.stage).scaleFactor) {
                    downAt = undefined; // Long press cancelled, finger moved too much
                }
            }
        };
        this.connect('touch-event', handleEvent);
        this.connect('button-press-event', handleEvent);
        this.connect('button-release-event', handleEvent);
        this.connect('leave-event', handleEvent);
    }
}
class Icon extends St.Icon {
    static {
        GObject.registerClass(this);
    }
    constructor(config) {
        super(filterConfig(config));
        initWidget(this, config);
    }
}
class Label extends St.Label {
    static {
        GObject.registerClass(this);
    }
    constructor(config) {
        super(filterConfig(config));
        initWidget(this, config);
    }
}
class Bin extends St.Bin {
    static {
        GObject.registerClass(this);
    }
    constructor(config) {
        super(filterConfig(config));
        initWidget(this, config);
        if (config.child)
            this.set_child(config.child);
    }
}
class Box extends St.BoxLayout {
    static {
        GObject.registerClass(this);
    }
    constructor(config) {
        super(filterConfig(config));
        initWidget(this, config);
        config.children?.forEach(c => this.add_child(c));
    }
}
class Row extends St.BoxLayout {
    static {
        GObject.registerClass(this);
    }
    constructor(config) {
        super({
            ...filterConfig(config),
            vertical: false,
        });
        initWidget(this, config);
        config.children?.forEach(c => this.add_child(c));
    }
}
class Column extends St.BoxLayout {
    static {
        GObject.registerClass(this);
    }
    constructor(config) {
        super({
            ...filterConfig(config),
            vertical: true,
        });
        initWidget(this, config);
        config.children?.forEach(c => this.add_child(c));
    }
}
class ScrollView extends St.ScrollView {
    static {
        GObject.registerClass(this);
    }
    constructor(config) {
        super({
            ...filterConfig(config)
        });
        initWidget(this, config);
        if (config.child) {
            if ('vadjustment' in config.child) {
                this.set_child(config.child);
            }
            else {
                const s = new St.BoxLayout();
                s.add_child(config.child);
                this.set_child(s);
            }
        }
    }
}

export { Bin, Box, Button, Column, Icon, Label, Ref, Row, ScrollView };
