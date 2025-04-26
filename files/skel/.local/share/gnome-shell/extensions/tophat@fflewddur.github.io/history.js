// Copyright (C) 2024 Todd Kulesza <todd@dropline.net>
// This file is part of TopHat.
// TopHat is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// TopHat is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with TopHat. If not, see <https://www.gnu.org/licenses/>.
import Clutter from 'gi://Clutter';
import GObject from 'gi://GObject';
import St from 'gi://St';
import { gettext as _ } from 'resource:///org/gnome/shell/extensions/extension.js';
import { MaxHistoryLen } from './vitals.js';
export var HistoryStyle;
(function (HistoryStyle) {
    HistoryStyle[HistoryStyle["SINGLE"] = 0] = "SINGLE";
    HistoryStyle[HistoryStyle["DUAL"] = 1] = "DUAL";
})(HistoryStyle || (HistoryStyle = {}));
export const HistoryChart = GObject.registerClass(class HistoryChart extends St.Bin {
    chartStyle;
    grid;
    lm;
    chart;
    chartAlt;
    bars;
    barsAlt;
    priorActivity;
    priorActivityAlt;
    priorMax = 0;
    chartHeight = 0;
    chartHeightAlt = 0;
    yLabelTop;
    yLabelMiddle;
    yLabelBottom;
    xLabelNow;
    xLabelThen;
    constructor(style = HistoryStyle.SINGLE) {
        super();
        this.chartStyle = style;
        this.grid = new St.Widget({
            layout_manager: new Clutter.GridLayout({
                orientation: Clutter.Orientation.VERTICAL,
            }),
        });
        this.add_child(this.grid);
        this.lm = this.grid.layout_manager;
        this.bars = new Array(MaxHistoryLen);
        for (let i = 0; i < MaxHistoryLen; i++) {
            this.bars[i] = new St.Widget({
                name: 'HistoryBar',
                x_expand: true,
                y_expand: false,
                y_align: Clutter.ActorAlign.END,
                style_class: 'chart-bar',
                height: 0,
            });
        }
        this.chart = new St.BoxLayout({ style_class: 'chart' });
        if (this.chartStyle === HistoryStyle.DUAL) {
            this.barsAlt = new Array(MaxHistoryLen);
            for (let i = 0; i < MaxHistoryLen; i++) {
                this.barsAlt[i] = new St.Widget({
                    name: 'HistoryBarAlt',
                    x_expand: true,
                    y_expand: false,
                    y_align: Clutter.ActorAlign.START,
                    style_class: 'chart-bar chart-bar-alt',
                    height: 0,
                });
            }
            this.chartAlt = new St.BoxLayout({
                style_class: 'chart chart-stacked-bottom',
            });
        }
        else {
            this.barsAlt = null;
            this.chartAlt = null;
        }
        this.priorActivity = null;
        this.priorActivityAlt = null;
        this.yLabelTop = new St.Label();
        this.yLabelMiddle = new St.Label();
        this.yLabelBottom = new St.Label();
        this.xLabelNow = new St.Label();
        this.xLabelThen = new St.Label();
        // When the menus are closed, the chart's height changes
        // but no notify::height signal is emitted. We cache this
        // value so we always know what the actual, visible height
        // of the chart will be.
        // TODO(fflewddur): Investigate if I'm just holding this wrong
        this.chart.connect('notify::height', (w) => {
            this.chartHeight = w.height;
            if (this.chartStyle === HistoryStyle.SINGLE && this.priorActivity) {
                this.update(this.priorActivity);
            }
            else if (this.priorActivityAlt && this.chartAlt) {
                this.chartHeightAlt = this.chartAlt.height;
                this.updateAlt(this.priorActivityAlt, this.priorMax);
            }
        });
        if (this.chartAlt) {
            this.chartAlt.connect('notify::height', (w) => {
                this.chartHeightAlt = w.height;
                if (!this.priorActivityAlt) {
                    return;
                }
                this.updateAlt(this.priorActivityAlt, this.priorMax);
            });
        }
        this.build();
    }
    refresh() {
        if (this.chartStyle === HistoryStyle.SINGLE && this.priorActivity) {
            this.update(this.priorActivity);
        }
        else if (this.chartStyle === HistoryStyle.DUAL &&
            this.priorActivityAlt) {
            this.updateAlt(this.priorActivityAlt, this.priorMax);
        }
    }
    setYLabelTop(s) {
        this.yLabelTop.text = s;
    }
    setYLabelMiddle(s) {
        this.yLabelMiddle.text = s;
    }
    setYLabelBottom(s) {
        this.yLabelBottom.text = s;
    }
    setThen(s) {
        this.xLabelThen.text = s;
    }
    update(usage) {
        for (let i = 0; i < this.bars.length; i++) {
            this.bars[i].height =
                this.chartHeight * usage[usage.length - i - 1].val();
        }
        this.priorActivity = usage;
    }
    updateAlt(usage, max) {
        if (!this.chartAlt || !this.barsAlt) {
            console.warn('[TopHat] chartAlt is null');
            return;
        }
        for (let i = 0; i < this.bars.length; i++) {
            let height = 0;
            let heightAlt = 0;
            if (max) {
                height =
                    this.chartHeight * (usage[usage.length - i - 1].valAlt() / max);
                heightAlt =
                    this.chartHeightAlt * (usage[usage.length - i - 1].val() / max);
            }
            this.bars[i].height = height;
            this.barsAlt[i].height = heightAlt;
        }
        this.priorActivityAlt = usage;
        this.priorMax = max;
    }
    setColor(color) {
        for (const bar of this.bars) {
            bar.set_style(`background-color:${color}`);
        }
        if (this.barsAlt) {
            for (const barAlt of this.barsAlt) {
                barAlt.set_style(`background-color:${color}`);
            }
        }
    }
    build() {
        let chartRowSpan = 2;
        if (this.barsAlt) {
            chartRowSpan = 1;
        }
        this.lm.attach(this.chart, 0, 0, 2, chartRowSpan);
        for (const bar of this.bars) {
            this.chart.add_child(bar);
        }
        if (this.barsAlt && this.chartAlt) {
            this.lm.attach(this.chartAlt, 0, 1, 2, chartRowSpan);
            for (const bar of this.barsAlt) {
                this.chartAlt.add_child(bar);
            }
            this.chart.add_style_class_name('chart-stacked-top');
        }
        const vbox = new St.BoxLayout({ vertical: true, y_expand: true });
        this.lm.attach(vbox, 2, 0, 1, 2);
        this.yLabelTop.text = '100%';
        this.yLabelTop.y_align = Clutter.ActorAlign.START;
        this.yLabelTop.y_expand = true;
        this.yLabelTop.add_style_class_name('chart-label');
        vbox.add_child(this.yLabelTop);
        this.yLabelMiddle.text = '50%';
        this.yLabelMiddle.y_align = Clutter.ActorAlign.CENTER;
        this.yLabelMiddle.y_expand = true;
        this.yLabelMiddle.add_style_class_name('chart-label');
        vbox.add_child(this.yLabelMiddle);
        this.yLabelBottom.text = '0%';
        this.yLabelBottom.y_align = Clutter.ActorAlign.END;
        this.yLabelBottom.y_expand = true;
        this.yLabelBottom.add_style_class_name('chart-label');
        vbox.add_child(this.yLabelBottom);
        this.xLabelThen.add_style_class_name('chart-label-then');
        this.lm.attach(this.xLabelThen, 0, 2, 1, 1);
        this.xLabelNow.text = _('now');
        this.xLabelNow.add_style_class_name('chart-label-now');
        this.lm.attach(this.xLabelNow, 1, 2, 1, 1);
        const label = new St.Label({ text: '' });
        this.lm.attach(label, 2, 2, 1, 1);
    }
    destroy() {
        this.grid.destroy();
        super.destroy();
    }
});
