import GObject from 'gi://GObject';

import {formatDateWithCFormatString} from 'resource:///org/gnome/shell/misc/dateUtils.js';
import {gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';

import {Label} from './baseLabel.js';
import * as Utils from '../utils.js';

export const DigitalClock = GObject.registerClass(
class AzClockDigitalClock extends Label {
    setStyle() {
        super.setStyle();
        const dateFormat = this._settings.get_string('date-format');
        this._dateFormat = dateFormat;
    }

    updateClock() {
        const date = new Date();

        const dateFormat = this._dateFormat;
        const elementDate = Utils.getClockDate(this._settings, date);

        if (dateFormat) {
            this.text = formatDateWithCFormatString(elementDate, dateFormat);
            this.clutter_text.set_markup(this.text);
        }

        this.queue_relayout();
    }
});
