import St from 'gi://St';
import Clutter from 'gi://Clutter';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import { NotificationMessageGroup } from 'resource:///org/gnome/shell/ui/messageList.js';
import * as MessageTray from 'resource:///org/gnome/shell/ui/messageTray.js';
import { findActorBy } from '../../utils/utils.js';
import { Ref as Ref$1 } from '../../utils/ui/widgets.js';
import ExtensionFeature from '../../utils/extensionFeature.js';
import { GestureRecognizer, GestureRecognizerEvent } from '../../utils/ui/gestureRecognizer.js';

var Ref = Ref$1;
class NotificationGesturesFeature extends ExtensionFeature {
    unpatchOnTrayClose = [];
    calendarMessageList;
    constructor(pm) {
        super(pm);
        const self = this;
        this.calendarMessageList = findActorBy(global.stage, a => a.constructor.name == 'CalendarMessageList');
        this.createMessageTrayPatches(self);
        this.createMessageListPatches(self);
    }
    createMessageTrayPatches(self) {
        // Patch already existing message tray notification:
        // @ts-ignore
        if (Main.messageTray._banner !== null) {
            // @ts-ignore
            self.unpatchOnTrayClose.push(self.patchNotification(Main.messageTray._banner, true));
        }
        // Patch future new notifications added to the tray:
        this.pm.appendToMethod(MessageTray.MessageTray.prototype, '_showNotification', function () {
            self.unpatchOnTrayClose.push(self.patchNotification(this._banner, true));
        });
        // When the tray is hidden, un-patch the message and container to avoid
        // double callback invocations:
        this.pm.appendToMethod(MessageTray.MessageTray.prototype, '_hideNotification', function () {
            self.unpatchOnTrayClose.forEach(p => p.disable());
            self.unpatchOnTrayClose = [];
        });
        // Patch the message tray `_updateState` function such that it does not expand the banner on hover:
        this.pm.patchMethod(MessageTray.MessageTray.prototype, '_updateState', function (orig) {
            // we achieve this by making it seem to the function that the banner is already expanded:
            const originalValue = this._banner?.expanded;
            if (this._banner)
                this._banner.expanded = true;
            orig();
            if (this._banner)
                this._banner.expanded = originalValue;
        });
    }
    createMessageListPatches(self) {
        // Setup listeners for existing notification groups in the message list:
        this.calendarMessageList?._messageView.messages.forEach(notificationGroup => {
            // Patch each notification inside the group:
            for (let child of notificationGroup.get_children()) {
                // each notification is wrapped in a [St.Bin], thus we use `.get_first_child()` on it:
                if (child.get_first_child() != null) {
                    self.patchNotification(child.get_first_child(), false);
                }
            }
        });
        // New message added to a [NotificationMessageGroup]:
        this.pm.appendToMethod(NotificationMessageGroup.prototype, '_addNotification', function (notification) {
            self.patchNotification(this._notificationToMessage.get(notification), false);
        });
    }
    patchNotification(message, isTray) {
        return this.pm.patch(() => {
            // Make message unreactive to prevent immediate notification activation on any event:
            message.reactive = false; // (this is necessary as message inherits from St.Button which conflicts with complex reactivity as we want it)
            // Prevent the insensitive styling from being applied:
            message.remove_style_pseudo_class('insensitive');
            // Each message is wrapped by a single bin, which we use for reactivity:
            const container = message.get_parent();
            container.reactive = true;
            container.trackHover = true;
            const notificationGroup = container.get_parent();
            // This is updated in each call to `onMoveHorizontally` and tracks which actor to move: the
            // [notificationGroup] or the [message]:
            let horizontalMoveActor = null;
            // Track and recognize touch and mouse events:
            const gestureHelper = new SwipeGesturesHelper({
                actor: container,
                scrollView: !isTray ? this.calendarMessageList?._scrollView : undefined,
                onHover: (isTouch) => {
                    message.add_style_pseudo_class('hover');
                    // Expand the message when hovering with the pointer:
                    if (isTray && !isTouch && !message.expanded) {
                        message.expand(true);
                    }
                },
                onHoverEnd: () => message.remove_style_pseudo_class('hover'),
                onMoveHorizontally: (x) => {
                    horizontalMoveActor = notificationGroup.expanded || isTray ? message : notificationGroup;
                    if (message.canClose()) {
                        horizontalMoveActor.translationX = x;
                        const actorWidth = horizontalMoveActor.get_transformed_size()[0];
                        horizontalMoveActor.opacity = 255 - 255 * Math.min(1, Math.abs(x) / actorWidth * 1.3);
                    }
                    else {
                        horizontalMoveActor.translationX = Math.sign(x) * Math.log(Math.abs(x)) ** 3;
                    }
                },
                onMoveVertically: (y) => {
                    if (isTray) {
                        message.translationY = Math.min(y, 0);
                    }
                },
                onScrollScrollView: (deltaY) => this.scrollNotificationList(deltaY),
                onEaseBackPosition: () => {
                    gestureHelper.easeBackPositionOf(horizontalMoveActor);
                    // @ts-ignore
                    horizontalMoveActor.ease({
                        opacity: 255,
                        duration: 200,
                    });
                },
                onActivate: () => 
                // @ts-ignore
                message.notification.activate(),
                onExpand: () => {
                    if (!message.expanded) {
                        message.expand(true);
                    }
                },
                onCollapse: () => {
                    if (isTray) {
                        // @ts-ignore
                        message.ease({
                            y: -message.height,
                            rotationZ: 90,
                            duration: 100,
                            mode: Clutter.AnimationMode.EASE_OUT,
                            // @ts-ignore
                            onComplete: () => Main.messageTray._hideNotification(false),
                        });
                        return { easeBackPosition: false };
                    }
                    else if (message.expanded) {
                        message.unexpand(true);
                    }
                },
                onClose: (swipeDirection) => {
                    if (message.canClose()) {
                        // @ts-ignore
                        horizontalMoveActor?.ease({
                            translationX: swipeDirection == 'right' ? message.width : -message.width,
                            opacity: 0,
                            duration: 150,
                            mode: Clutter.AnimationMode.EASE_OUT,
                            onComplete: () => message.emit("close"),
                        });
                    }
                    else {
                        gestureHelper.easeBackPositionOf(horizontalMoveActor);
                    }
                },
            });
            // Use [Ref]s for the cleanup in order to skip cleanup on already
            // destroyed actors easily:
            let messageRef = new Ref(message);
            let containerRef = new Ref(container);
            const undo = () => {
                // Undo all the changes:
                containerRef.apply(c => {
                    gestureHelper.destroy();
                    c.reactive = false;
                    c.trackHover = false;
                });
                messageRef.apply(m => {
                    m.translationX = 0;
                    m.reactive = true;
                });
            };
            message.connect('destroy', () => undo());
            return undo;
        });
    }
    scrollNotificationList(delta) {
        const vadj = this.calendarMessageList?._scrollView?.get_vadjustment();
        if (vadj) {
            vadj.value -= delta;
        }
    }
}
/**
 * A helper to handle the abstractable parts of notification gestures, i.e. connecting to raw events of
 * an arbitrary [Clutter.Actor] and translating them into actor position translations (move to follow the
 * users' finger) and, upon gesture finishing, user intents (activate, close, expand, collapse, ...)
 */
class SwipeGesturesHelper {
    // Mid-gesture callbacks:
    onHover;
    onHoverEnd;
    onMoveHorizontally;
    onMoveVertically;
    onScrollScrollView;
    // Gesture finished callbacks:
    onActivate;
    onClose;
    onExpand;
    onCollapse;
    onEaseBackPosition;
    actor;
    scrollView;
    recognizer;
    _signalIds;
    /**
     * Whether the gesture currently being performed is a scroll gesture. This is set to `true` when the
     * [onScrollScrollView] callback has been called at least once during the current gesture.
     */
    isScrollGesture = false;
    constructor(props) {
        this.actor = props.actor;
        this.scrollView = props.scrollView;
        this.onHover = props.onHover;
        this.onHoverEnd = props.onHoverEnd;
        this.onMoveHorizontally = props.onMoveHorizontally;
        this.onMoveVertically = props.onMoveVertically;
        this.onScrollScrollView = props.onScrollScrollView;
        this.onActivate = props.onActivate;
        this.onClose = props.onClose;
        this.onExpand = props.onExpand;
        this.onCollapse = props.onCollapse;
        this.onEaseBackPosition = props.onEaseBackPosition || this._defaultOnEaseBackPosition;
        // Track and recognize touch and mouse events:
        this.recognizer = new GestureRecognizer();
        // Setup event handlers:
        this._signalIds = [
            this.actor.connect('touch-event', this._onEvent.bind(this)),
            this.actor.connect('button-press-event', this._onEvent.bind(this)),
            this.actor.connect('button-release-event', this._onEvent.bind(this)),
            this.actor.connect('notify::hover', this._updateHover.bind(this)),
        ];
        // To not disconnect after destruction, clear [_signalIds] when the actor is destroyed:
        this.actor.connect('destroy', () => this._signalIds = []);
    }
    _onEvent(_, e) {
        const state = this.recognizer.push(GestureRecognizerEvent.fromClutterEvent(e));
        if (state.hasGestureJustStarted) {
            this._updateHover();
        }
        if (state.isDuringGesture) {
            if (state.firstMotionDirection?.axis === 'horizontal') {
                this.onMoveHorizontally?.(state.totalMotionDelta.x);
            }
            else if (state.firstMotionDirection?.axis == 'vertical') {
                // Scroll the message list, if possible:
                const dy = state.currentMotionDelta.y;
                if (!state.startsWithHold && this.canScrollScrollView(dy > 0 ? 'up' : 'down')) {
                    this.onScrollScrollView?.(dy);
                    if (state.hasMovement) {
                        this.isScrollGesture = true;
                    }
                }
                else {
                    this.onMoveVertically?.(state.totalMotionDelta.y);
                }
            }
        }
        if (state.hasGestureJustEnded) {
            this._onGestureFinished();
            this._updateHover();
            this.isScrollGesture = false;
        }
    }
    _updateHover() {
        if (this.recognizer.currentState.isDuringGesture || (this.actor instanceof St.Widget && this.actor.hover)) {
            this.onHover?.(this.recognizer.currentState.isTouchGesture);
        }
        else {
            this.onHoverEnd?.();
        }
    }
    destroy() {
        for (let signalId of this._signalIds) {
            this.actor.disconnect(signalId);
        }
    }
    _onGestureFinished() {
        let defaultShouldEaseBack = false;
        let res = undefined;
        if (this.recognizer.currentState.isTap || !this.recognizer.currentState.isTouchGesture) {
            res = this.onActivate?.();
        }
        else {
            const lastMotion = this.recognizer.currentState.lastMotionDirection;
            if (lastMotion != null) {
                switch (lastMotion.direction) {
                    case 'up':
                        if (this.isScrollGesture)
                            break;
                        res = this.onCollapse?.();
                        defaultShouldEaseBack = true;
                        break;
                    case 'down':
                        if (this.isScrollGesture)
                            break;
                        res = this.onExpand?.();
                        defaultShouldEaseBack = true;
                        break;
                    default:
                        if (lastMotion.direction == 'right' && this.recognizer.currentState.totalMotionDelta.x > 0 ||
                            lastMotion.direction == 'left' && this.recognizer.currentState.totalMotionDelta.x < 0) {
                            res = this.onClose?.(lastMotion.direction);
                        }
                        else {
                            defaultShouldEaseBack = true;
                        }
                }
            }
        }
        if (res?.easeBackPosition || (defaultShouldEaseBack && res?.easeBackPosition != false)) {
            this.onEaseBackPosition?.();
        }
    }
    canScrollScrollView(direction = null) {
        if (!this.scrollView?.get_vscrollbar_visible())
            return false;
        const vadj = this.scrollView.get_vadjustment();
        switch (direction) {
            case 'up':
                return !!vadj && vadj.value > 0;
            case 'down':
                return !!vadj && vadj.value < vadj.upper - this.scrollView.contentBox.get_height();
        }
        return true;
    }
    _defaultOnEaseBackPosition() {
        this.easeBackPositionOf(this.actor);
    }
    easeBackPositionOf(actor) {
        // @ts-ignore
        actor.ease({
            translationX: 0,
            translationY: 0,
            duration: 200,
            mode: Clutter.AnimationMode.EASE_OUT_BACK,
        });
    }
}

export { NotificationGesturesFeature };
