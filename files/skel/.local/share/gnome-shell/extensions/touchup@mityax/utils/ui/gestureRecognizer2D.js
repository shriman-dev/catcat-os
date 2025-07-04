import Clutter from 'gi://Clutter';
import St from 'gi://St';
import { assert } from '../logging.js';

/**
 * The `GestureRecognizer2D` class is responsible for recognizing and processing 2D gestures,
 * such as swipes and holds, within a UI. It tracks movement patterns over time, analyzing
 * changes in direction, speed, and pauses to identify specific gestures. The class supports
 * touch and pointer events, allowing it to be used in a variety of input contexts.
 *
 * Key features:
 * - Tracks complex gestures by building up a series of swipe and hold patterns.
 * - Determines high-level metadata of swipe gestures (see `SwipePattern` for all fields).
 * - Provides access to recorded gesture patterns for further processing or analysis.
 * - All information can be retrieved and analyzed while the gesture is ongoing already,
 *   however, until the gesture is completed, recorded patterns and their fields might
 *   change in retrospective as new events become available.
 * - The methods and getters of this class provide basic high-level information about the
 *   current gesture, while the individual patterns provide details about a part of it.
 * - Use `GestureRecognizer2D.toString()` for debugging.
 *
 * Example:
 * ```typescript
 * const recognizer = new GestureRecognizer2D();
 *
 * myActor.connect('touch-event', (e) => {
 *     recognizer.pushEvent(e);
 *
 *     // make the actor follow the user's finger:
 *     myActor.translationX = recognizer.totalMotionDelta.x;
 *
 *     if (recognizer.gestureHasJustFinished) {
 *         // `recognizer.toString` constructs a nicely readable representation of `recognizer.getPatterns`:
 *         console.log("The user did this: ", recognizer.toString());
 *
 *         if (recognizer.secondaryMove?.swipeDirection === 'right') onDiscard();
 *         if (recognizer.secondaryMove?.swipeDirection === 'left') onArchive();
 *     }
 * });
 * ```
 */
class GestureRecognizer2D {
    /**
     * A sufficient time with movements less than this amount of (logical) pixels may lead to a hold
     * pattern being recognized.
     */
    static PAUSE_TOLERANCE = 12; // delta_pixels
    /**
     * Swipe patterns with less than this distance will be merged with the patterns following them.
     * Should the only recognized pattern have less movement than this, [isTab] will return true.
     */
    static MIN_SWIPE_DISTANCE = 10; // delta_pixels
    /**
     * The number of milliseconds no (actually: less than [PAUSE_TOLERANCE]) movements needs to take
     * place for a hold pattern to be recognized.
     */
    static SIGNIFICANT_PAUSE = 500; // milliseconds
    scaleFactor = St.ThemeContext.get_for_stage(global.stage).scaleFactor;
    recordedPatterns = [];
    lastEvent = null;
    lastAngle = -1;
    currentStrokeDx = 0;
    currentStrokeDy = 0;
    currentStrokeDt = 0;
    totalDx = 0;
    totalDy = 0;
    pauseTime = 0;
    pauseDx = 0;
    pauseDy = 0;
    _isDuringGesture = false;
    /**
     * Push an event to the recognizer for processing.
     */
    pushEvent(event) {
        // Reset if event is the beginning of a sequence:
        if (event.type() == Clutter.EventType.TOUCH_BEGIN ||
            event.type() == Clutter.EventType.BUTTON_PRESS ||
            event.type() == Clutter.EventType.PAD_BUTTON_PRESS) {
            this.resetAndStartGesture();
        }
        if (this._isDuringGesture) {
            this.processEvent(event);
            this.lastEvent = event;
        }
        if (event.type() == Clutter.EventType.TOUCH_END ||
            event.type() == Clutter.EventType.TOUCH_CANCEL ||
            event.type() == Clutter.EventType.BUTTON_RELEASE ||
            event.type() == Clutter.EventType.PAD_BUTTON_RELEASE) {
            this._isDuringGesture = false;
        }
    }
    /**
     * Manually clear the recognizers state and notify it that a new gesture has started.
     *
     * This function only needs to be called in contexts where no sequence-start
     * events, such as touch down or button press are pushed to the recognizer. This
     * is normally not the case, but for example within a Clutter.Gesture the sequence
     * start events are not available.
     */
    resetAndStartGesture() {
        this.recordedPatterns = [];
        this.lastEvent = null;
        this.lastAngle = -1;
        this.currentStrokeDx = 0;
        this.currentStrokeDy = 0;
        this.currentStrokeDt = 0;
        this.totalDx = 0;
        this.totalDy = 0;
        this.pauseTime = 0;
        this.pauseDx = 0;
        this.pauseDy = 0;
        this._isDuringGesture = true;
    }
    /**
     * True if a gesture is currently being performed (i.e. a finger
     * is down or a pointer button clicked).
     */
    get isDuringGesture() {
        return this._isDuringGesture;
    }
    /**
     * Returns true if the last gesture was a single tap gesture.
     *
     * Should only be called after a gesture is complete.
     */
    wasTap(allowLongTap = false) {
        assert(!this.isDuringGesture);
        return (
        // If no pattern has been recognized, this is a tap:
        this.recordedPatterns.length === 0
            // Extremely short swipes are also classified as a tap:
            || (this.recordedPatterns.length === 1
                && this.recordedPatterns[0].type == 'swipe'
                && this.recordedPatterns[0].swipeDistance < GestureRecognizer2D.MIN_SWIPE_DISTANCE * this.scaleFactor)
            // If requested, also let long taps pass:
            || (allowLongTap
                && this.wasLongTap()));
    }
    /**
     * Returns true if the last gesture was a long-tap gesture (default: longer than [SIGNIFICANT_PAUSE]).
     *
     * Should only be called after a gesture is complete.
     */
    wasLongTap(minDuration) {
        assert(!this.isDuringGesture);
        return (this.recordedPatterns.length === 1
            && this.recordedPatterns[0].type === 'hold'
            && this.recordedPatterns[0].duration > (minDuration ?? GestureRecognizer2D.SIGNIFICANT_PAUSE));
    }
    /**
     * Get the patterns that where recognized during the gesture, in
     * chronological order.
     */
    getPatterns() {
        return [...this.recordedPatterns];
    }
    /**
     * The current total motion delta, i.e. the offset between the
     * current pointer/finger location and the starting point of the
     * gesture.
     */
    get totalMotionDelta() {
        return { x: this.totalDx, y: this.totalDy };
    }
    /**
     * The first pattern recorded so far.
     */
    get primaryPattern() {
        return this.recordedPatterns.at(0) ?? null;
    }
    /**
     * The pattern of the first stroke, i.e. the first `SwipePattern`. This
     * can already be retrieved for incomplete strokes, but it's properties
     * might change.
     *
     * If the primary move cannot (yet) be determined, `null` is returned.
     */
    get primaryMove() {
        let pattern = this.recordedPatterns
            .find((p) => p.type == 'swipe');
        return pattern ? { ...pattern } : null;
    }
    /**
     * The pattern of the last stroke, i.e. the last `SwipePattern`. This
     * can already be retrieved for incomplete strokes, but it's properties
     * might change.
     *
     * If the primary move cannot (yet) be determined, `null` is returned.
     */
    get secondaryMove() {
        let pattern = this.recordedPatterns
            .findLast((p) => p.type == 'swipe');
        return pattern ? { ...pattern } : null;
    }
    /**
     * Get whether the current event sequence is a touch event sequence
     * or a pointer sequence.
     */
    get isTouchGesture() {
        switch (this.lastEvent?.type()) {
            case Clutter.EventType.TOUCH_BEGIN:
            case Clutter.EventType.TOUCH_UPDATE:
            case Clutter.EventType.TOUCH_CANCEL:
            case Clutter.EventType.TOUCH_END:
                return true;
            default:
                return false;
        }
    }
    /**
     * Get whether the currently performed gesture is already certain to not be
     * a tap or long tap.
     */
    get isCertainlyMovement() {
        const d = Math.sqrt(this.totalMotionDelta.x ** 2 + this.totalMotionDelta.y ** 2);
        return d >= GestureRecognizer2D.MIN_SWIPE_DISTANCE * this.scaleFactor;
    }
    /**
     * true, if the last pushed event was a sequence-end event, e.g. touch end
     * or button release.
     */
    get gestureHasJustFinished() {
        return (this.lastEvent?.type() == Clutter.EventType.TOUCH_END ||
            this.lastEvent?.type() == Clutter.EventType.TOUCH_CANCEL ||
            this.lastEvent?.type() == Clutter.EventType.BUTTON_RELEASE ||
            this.lastEvent?.type() == Clutter.EventType.PAD_BUTTON_RELEASE);
    }
    processEvent(event) {
        if (this.lastEvent !== null) {
            // Compute deltas:
            const dx = event.get_coords()[0] - this.lastEvent.get_coords()[0], dy = event.get_coords()[1] - this.lastEvent.get_coords()[1], dt = event.get_time() - this.lastEvent.get_time();
            const d = Math.sqrt(dx ** 2 + dy ** 2);
            //debugLog(`event: \tdx=${dx.toFixed(1)}\tdy=${dy.toFixed(1)}\tdt=${dt} ms\t|\t` +
            //    `speed=${(d / dt).toFixed(4)} px/ms\tangle=${this.angleBetween(dx, dy).toFixed(1)} deg`)
            // If there is absolutely no movement and no time since last event, skip event (e.g. touch-release event):
            if (d === 0 && dt === 0)
                return;
            // Check for a significant pause ("hold"):
            if (this.checkForSignificantPause(dt, dx, dy, ...event.get_coords()))
                return;
            // Check for significant angle change (if there's enough movement in this event):
            if (this.pauseTime === 0 && d > GestureRecognizer2D.PAUSE_TOLERANCE * this.scaleFactor) {
                if (this.checkForSignificantAngleChange(dx, dy, dt))
                    return;
            }
            this.currentStrokeDx += dx;
            this.currentStrokeDy += dy;
            this.currentStrokeDt += dt;
            this.totalDx += dx;
            this.totalDy += dy;
            // If the swipe has ended with a pause, we don't fire:
            if (this.currentStrokeDx == 0 && this.currentStrokeDy == 0)
                return;
            // Construct `SwipePattern`:
            const distance = Math.sqrt(this.currentStrokeDx ** 2 + this.currentStrokeDy ** 2);
            const angle = this.angleBetween(this.currentStrokeDx, this.currentStrokeDy);
            const direction = this.directionForAngle(angle);
            this.pushPattern({
                type: 'swipe',
                deltaX: this.currentStrokeDx,
                deltaY: this.currentStrokeDy,
                swipeDistance: distance,
                swipeAngle: angle,
                swipeSpeed: distance / this.currentStrokeDt,
                swipeDirection: direction,
                swipeAxis: this.axisForDirection(direction),
                totalTime: this.currentStrokeDt,
            });
        }
    }
    checkForSignificantAngleChange(dx, dy, dt) {
        const lastAngle = this.lastAngle;
        const currentAngle = this.angleBetween(dx, dy);
        this.lastAngle = currentAngle;
        // If there has already been computed a previous angle, compute difference to current angle:
        if (lastAngle !== -1) {
            //if (Math.abs(angleDiff) > GestureRecognizer2D.SIGNIFICANT_ANGLE_CHANGE) {
            if (this.directionForAngle(currentAngle) != this.directionForAngle(lastAngle)) {
                // Significant angle change detected
                //debugLog(`  - angle change! (${angleDiff} deg, dx=${dx}, dy=${dy})`)
                this.currentStrokeDx = dx;
                this.currentStrokeDy = dy;
                this.currentStrokeDt = dt;
                return true;
            }
        }
        return false;
    }
    checkForSignificantPause(dt, dx, dy, x, y) {
        if (Math.sqrt(this.pauseDx ** 2 + this.pauseDy ** 2) >= GestureRecognizer2D.PAUSE_TOLERANCE * this.scaleFactor) {
            this.pauseTime = this.pauseDx = this.pauseDy = 0;
        }
        else {
            this.pauseTime += dt;
            this.pauseDx += dx;
            this.pauseDy += dy;
            // debugLog(` - pause since ${Math.round(this.pauseTime)}ms (dx=${this.pauseDx}, dy=${this.pauseDy})`)
        }
        if (this.pauseTime >= GestureRecognizer2D.SIGNIFICANT_PAUSE) {
            this.currentStrokeDx = this.currentStrokeDy = this.currentStrokeDt = 0; // Significant pause detected
            // debugLog(`  - significant pause! (${this.pauseTime} ms > ${GestureRecognizer2D.SIGNIFICANT_PAUSE} ms; d=${Math.sqrt(this.pauseDx ** 2 + this.pauseDy ** 2)})`)
            this.pushPattern({
                type: 'hold',
                x: x,
                y: y,
                duration: this.pauseTime,
            });
            this.pauseTime = this.pauseDx = this.pauseDy = 0;
            return true;
        }
        return false;
    }
    pushPattern(pattern) {
        let ignorePattern = false;
        let lastPattern = this.recordedPatterns.at(-1);
        if (pattern.type == 'hold') {
            // "eat up" all previous swipe patterns if they don't have enough movement. This is
            // done instead of not adding the patterns in the first place in order to improve
            // reactivity in scenarios where an actor immediately follows the gesture:
            while ((lastPattern = this.recordedPatterns.at(-1)) &&
                lastPattern.type == 'swipe' &&
                lastPattern.swipeDistance < GestureRecognizer2D.PAUSE_TOLERANCE) {
                pattern.duration += lastPattern.totalTime;
                this.recordedPatterns.pop();
            }
            // two `HoldPattern`s in a row add up:
            if (lastPattern?.type == 'hold') {
                lastPattern.duration += pattern.duration;
                ignorePattern = true;
            }
        }
        else if (pattern.type == 'swipe') {
            // "eat up" all previous swipe patterns if they don't have enough movement. This is
            // done instead of not adding the patterns in the first place in order to improve
            // reactivity in scenarios where an actor immediately follows the gesture:
            while ((lastPattern = this.recordedPatterns.at(-1)) &&
                lastPattern.type == 'swipe' &&
                lastPattern.swipeDistance < GestureRecognizer2D.MIN_SWIPE_DISTANCE * this.scaleFactor) {
                pattern.deltaX += lastPattern.deltaX;
                pattern.deltaY += lastPattern.deltaY;
                pattern.totalTime += lastPattern.totalTime;
                pattern.swipeDistance += Math.sqrt(pattern.deltaX ** 2 + pattern.deltaY ** 2);
                pattern.swipeSpeed = pattern.swipeDistance / pattern.totalTime;
                pattern.swipeAngle = this.angleBetween(pattern.deltaX, pattern.deltaY);
                pattern.swipeDirection = this.directionForAngle(pattern.swipeAngle);
                this.recordedPatterns.pop();
            }
            // two `SwipePattern`s with the same direction are joined:
            if (lastPattern?.type == 'swipe' && lastPattern.swipeDirection === pattern.swipeDirection) {
                lastPattern.deltaX = pattern.deltaX;
                lastPattern.deltaY = pattern.deltaY;
                lastPattern.totalTime = pattern.totalTime;
                lastPattern.swipeDistance = Math.sqrt(lastPattern.deltaX ** 2 + lastPattern.deltaY ** 2);
                lastPattern.swipeSpeed = lastPattern.swipeDistance / lastPattern.totalTime;
                lastPattern.swipeAngle = this.angleBetween(lastPattern.deltaX, lastPattern.deltaY);
                ignorePattern = true;
            }
        }
        if (!ignorePattern) {
            this.recordedPatterns.push(pattern);
        }
    }
    // up = 0, right = 90, down = 180, left = 270
    angleBetween(dx, dy) {
        return (Math.atan2(dy, dx) * 180 / Math.PI + 450) % 360;
    }
    directionForAngle(angle) {
        if (315 <= angle || angle <= 45) {
            return 'up';
        }
        else if (45 <= angle && angle <= 135) {
            return 'right';
        }
        else if (135 <= angle && angle <= 225) {
            return 'down';
        }
        else {
            return 'left';
        }
    }
    axisForDirection(direction) {
        if (direction === 'up' || direction === 'down') {
            return 'vertical';
        }
        return 'horizontal';
    }
    /**
     * Returns a human-readable representation of the recorded patterns
     */
    toString() {
        let s = [];
        for (let p of this.recordedPatterns) {
            switch (p.type) {
                case "hold":
                    s.push(`hold ${(p.duration / 1000).toFixed(2)}s`);
                    break;
                case "swipe":
                    s.push(`swipe ${p.swipeDirection} (${Math.round(p.swipeAngle)}°, ${Math.round(p.swipeDistance)}px)`);
            }
        }
        return `<${this.constructor.name} ` +
            `(gesture ${this.isDuringGesture ? 'ongoing' : 'completed'}` +
            `${this.wasLongTap() ? ', is-long-tap' : this.wasTap() ? ', is-tap' : ''}) ` +
            `patterns: [ ${s.join(' • ')} ]>`;
    }
}

export { GestureRecognizer2D };
