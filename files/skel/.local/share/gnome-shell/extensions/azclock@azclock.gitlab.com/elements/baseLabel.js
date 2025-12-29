import Clutter from 'gi://Clutter';
import GObject from 'gi://GObject';
import Graphene from 'gi://Graphene';
import Pango from 'gi://Pango';
import St from 'gi://St';

import {gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';

import * as Utils from '../utils.js';

export const Label = GObject.registerClass(
class AzClockLabel extends St.Label {
    _init(settings, extension) {
        super._init({
            y_align: Clutter.ActorAlign.CENTER,
            pivot_point: new Graphene.Point({x: 0.5, y: 0.5}),
        });

        this._settings = settings;
        this._extension = extension;

        this.clutter_text.set({
            ellipsize: Pango.EllipsizeMode.NONE,
        });

        this._settings.connectObject('changed', () => this.setStyle(), this);
        this.connect('notify::mapped', () => this.setStyle());

        this.connect('destroy', () => this._onDestroy());
    }

    setStyle() {
        if (!this.mapped)
            return;

        const [shadowEnabled, shadowColor, shadowX, shadowY,
            shadowSpread, shadowBlur] = this._settings.get_value('shadow').deepUnpack();

        const [customFontEnabled, customFontFamily] = this._settings.get_value('font-family-override').deepUnpack();

        const textColor = this._settings.get_string('foreground-color');
        const textSize = this._settings.get_int('font-size');

        const textAlignmentX = this._settings.get_enum('text-align-x');
        const textAlignmentY = this._settings.get_enum('text-align-y');
        const lineAlignmentEnum = this._settings.get_enum('line-alignment');

        let textLineAlignment = 'left';
        if (lineAlignmentEnum === Clutter.ActorAlign.START)
            textLineAlignment = 'left';
        else if (lineAlignmentEnum === Clutter.ActorAlign.CENTER)
            textLineAlignment =  'center';
        else if (lineAlignmentEnum === Clutter.ActorAlign.END)
            textLineAlignment =   'right';

        const [marginTop, marginRight, marginBottom, marginLeft] = this._settings.get_value('margin').deepUnpack();
        const [paddingTop, paddingRight, paddingBottom, paddingLeft] = this._settings.get_value('padding').deepUnpack();

        const showBorder = this._settings.get_boolean('show-border');
        const borderColor = this._settings.get_string('border-color');
        const borderWidth = this._settings.get_int('border-width');
        const borderRadius = this._settings.get_int('border-radius');

        const showBackground = this._settings.get_boolean('show-background');
        const backgroundColor = this._settings.get_string('background-color');

        const margin = `margin: ${marginTop}px ${marginRight}px ${marginBottom}px ${marginLeft}px;`;
        const padding = `padding: ${paddingTop}px ${paddingRight}px ${paddingBottom}px ${paddingLeft}px;`;

        let textStyle = `color: ${textColor}; ${margin} ${padding}`;

        if (showBackground) {
            textStyle += `background-color: ${backgroundColor};
                            border-radius: ${borderRadius}px;`;
        }

        if (showBorder) {
            textStyle += `border-width: ${borderWidth}px;
                            border-color: ${borderColor};`;
        }

        if (shadowEnabled)
            textStyle += `text-shadow: ${shadowX}px ${shadowY}px ${shadowBlur}px ${shadowSpread}px ${shadowColor};`;

        if (customFontEnabled) {
            const fontStyleEnum = this._settings.get_enum('font-style');
            const fontStyle = Utils.fontStyleEnumToString(fontStyleEnum);
            const fontWeight = this._settings.get_int('font-weight');

            textStyle += `font-family: "${customFontFamily}";`;

            if (fontWeight)
                textStyle += `font-weight: ${fontWeight};`;
            if (fontStyle)
                textStyle += `font-style: ${fontStyle};`;
        }

        if (textLineAlignment)
            textStyle += `text-align: ${textLineAlignment};`;

        this.style = `${textStyle} font-size: ${textSize}pt; font-feature-settings: "tnum";`;

        this.x_align = textAlignmentX;
        this.y_align = textAlignmentY;
        this.queue_relayout();
    }

    _onDestroy() {
        this._settings.disconnectObject(this);
        this._settings = null;
        this._extension = null;
    }
});
