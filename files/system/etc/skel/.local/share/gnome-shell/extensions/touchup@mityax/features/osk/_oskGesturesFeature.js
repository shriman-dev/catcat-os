import St from 'gi://St';
import Clutter from 'gi://Clutter';
import ExtensionFeature from '../../utils/extensionFeature.js';
import { GestureRecognizer, GestureRecognizerEvent } from '../../utils/ui/gestureRecognizer.js';
import { settings } from '../../settings.js';
import { findAllActorsBy } from '../../utils/utils.js';
import Graphene from 'gi://Graphene';

/** Maximum distance around a key that's still pressable */
const KEY_PRESS_MAX_DISTANCE = 8; // in logical pixels
class OSKGesturesFeature extends ExtensionFeature {
    constructor(pm, keyboard) {
        super(pm);
        if (keyboard) {
            this.onNewKeyboard(keyboard);
        }
    }
    onNewKeyboard(keyboard) {
        const recognizer = new GestureRecognizer({
            onGestureProgress: state => {
                if (state.hasStrongMovement
                    && state.firstMotionDirection?.direction === 'down'
                    && settings.osk.gestures.swipeToClose.enabled.get()) {
                    keyboard.gestureProgress(keyboard.height - state.totalMotionDelta.y);
                }
            },
            onGestureCompleted: state => {
                if (state.hasStrongMovement
                    && state.firstMotionDirection?.direction === 'down'
                    && state.lastMotionDirection?.direction === 'down'
                    && settings.osk.gestures.swipeToClose.enabled.get()) {
                    keyboard.gestureCancel();
                }
                else if (keyboard._gestureInProgress
                    && settings.osk.gestures.swipeToClose.enabled.get()) {
                    // The following line is a required hack to make the keyboard animate back up; since the
                    // keyboard's gesture functionality is only intended for opening the keyboard, not for closing,
                    // let alone canceling closing it. Thus, when the swipe-to-close gesture is cancelled, we tell the
                    // keyboard it's not open yet, which perfectly imitates the state it'd be in had we opened it
                    // using the gesture as normal instead of swipe-closing and then cancelling.
                    keyboard._keyboardVisible = false;
                    keyboard.gestureActivate();
                }
            },
        });
        let currentKey = null;
        const onEvent = (evt) => {
            const state = recognizer.push(GestureRecognizerEvent.fromClutterEvent(evt));
            if (state.hasGestureJustStarted) {
                currentKey = this._selectKey(keyboard, state.pressCoordinates);
                if (currentKey
                    && settings.osk.gestures.extendKeys.enabled.get()
                    && !currentKey.keyButton.get_transformed_extents().contains_point(new Graphene.Point(state.pressCoordinates))) {
                    // @ts-ignore
                    currentKey?.keyButton.emit("touch-event", evt);
                }
            }
            else if (state.hasStrongMovement) {
                // Cancel keypress:
                if (currentKey) {
                    // @ts-ignore
                    currentKey._pressed = false; // this prevents the key from being activated
                    currentKey.cancel(); // this is used by the shell when swiping the emoji pager to cancel keypress; basically exactly what we want here
                    currentKey = null;
                }
            }
            else if (state.hasGestureJustEnded) {
                if (currentKey
                    && settings.osk.gestures.extendKeys.enabled.get()
                    && !currentKey.keyButton.get_transformed_extents().contains_point(new Graphene.Point(state.pressCoordinates))) {
                    currentKey?.keyButton.emit("touch-event", evt);
                }
                currentKey = null;
            }
        };
        this.pm.connectTo(keyboard, 'captured-event', (_, evt) => {
            if (!GestureRecognizerEvent.isTouch(evt)) {
                return Clutter.EVENT_PROPAGATE;
            }
            onEvent(evt);
            return Clutter.EVENT_PROPAGATE; // Clutter.EVENT_STOP;
        });
    }
    /**
     * Returns the key on the keyboard closest to the given position, unless the position is more than
     * [KEY_PRESS_MAX_DISTANCE] off the key.
     */
    _selectKey(keyboard, point) {
        const maxDist = KEY_PRESS_MAX_DISTANCE * St.ThemeContext.get_for_stage(global.stage).scaleFactor;
        const graphenePoint = new Graphene.Point(point);
        const visibleKeys = findAllActorsBy(keyboard, (k) => k.mapped && k.constructor.name === 'Key');
        const hitKey = visibleKeys.find(key => key
            .get_transformed_extents()
            .contains_point(graphenePoint));
        if (hitKey)
            return hitKey;
        const nearestKey = visibleKeys.find(key => key
            .get_transformed_extents()
            .inset(-maxDist, -maxDist) // enlarge ("outset") the rectangle by [maxDist] in all directions
            .contains_point(graphenePoint));
        return nearestKey ?? null;
    }
}

export { OSKGesturesFeature as default };
