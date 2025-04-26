import GObject from 'gi://GObject';

import {gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';

import {Label} from './baseLabel.js';

export const TextLabel = GObject.registerClass(
class AzClockTextLabel extends Label {
    setStyle() {
        super.setStyle();
        const text = this._settings.get_string('text');
        this.text = text;
        this.clutter_text.set_markup(this.text);
        this.queue_relayout();
    }
});
