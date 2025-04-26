//////////////////////////////////////////////////////////////////////////////////////////
//                               ___            _     ___                               //
//                               |   |   \/    | ) |  |                                 //
//                           O-  |-  |   |  -  |   |  |-  -O                            //
//                               |   |_  |     |   |  |_                                //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////

// SPDX-FileCopyrightText: Simon Schneegans <code@simonschneegans.de>
// SPDX-License-Identifier: MIT

'use strict';

import GObject from 'gi://GObject';
import GLib from 'gi://GLib';
import Gtk from 'gi://Gtk';
import Gio from 'gi://Gio';

import * as utils from '../common/utils.js';

//////////////////////////////////////////////////////////////////////////////////////////
// This dialog allows selecting an icon. This can be either from the user's icon theme  //
// or a local file. Once the user selected an icon, the 'icon-set' signal is emitted.   //
// The actual string representation of the icon can then be retrieved with the          //
// get_icon() method.                                                                   //
//////////////////////////////////////////////////////////////////////////////////////////

export function registerWidget() {

  if (GObject.type_from_name('FlyPieIconSelectDialog') == null) {
    // clang-format off
      GObject.registerClass({
        GTypeName: 'FlyPieIconSelectDialog',
        Template: `resource:///ui/gtk4/iconSelectDialog.ui`,
        InternalChildren: ["stack", "iconFileChooser", "iconList", "iconView",
                          "spinner", "iconListFiltered", "filterEntry"],
        Signals: {
          'icon-set': {}
        }
      },
      class FlyPieIconSelectDialog extends Gtk.Dialog {
      // clang-format on
      _init(params = {}) {
        super._init(params);

        // Icons are loaded asynchronously. Once this is finished, the little spinner in
        // the top right of the dialog is hidden.
        this._loadIcons().then(() => {
          this._spinner.spinning = false;
        });

        // Filter the icon view based on the content of the search field.
        this._iconListFiltered.set_visible_func((model, iter) => {
          const name = model.get_value(iter, 0);
          if (name == null) {
            return false;
          }
          return name.toLowerCase().includes(this._filterEntry.text.toLowerCase());
        });

        // Refilter the icon list whenever the user types something in the search field.
        this._filterEntry.connect('notify::text', () => {
          this._iconListFiltered.refilter();
        });

        this._iconView.connect('item-activated', () => {
          this.emit('response', Gtk.ResponseType.OK);
        });
      }

      // This either returns a file path to an image file or the name of an icon from the
      // user's icon theme.
      get_icon() {
        if (this._stack.get_visible_child_name() === 'icon-theme-page') {
          const path       = this._iconView.get_selected_items()[0];
          const model      = this._iconView.get_model();
          const [ok, iter] = model.get_iter(path);
          if (ok) {
            return model.get_value(iter, 0);
          }

          return '';
        }

        const file = this._iconFileChooser.get_file();
        if (file != null) {
          return file.get_path();
        }

        return '';
      }

      // This can be used to make the dialog preselect an icon before showing it.
      set_icon(value) {
        if (typeof value === 'string') {
          const file = Gio.File.new_for_path(value);
          if (file.query_exists(null)) {
            this._stack.set_visible_child_name('custom-icon-page');
            this._iconFileChooser.set_file(file);
          } else {
            this._stack.set_visible_child_name('icon-theme-page');
          }
        }
      }

      // This loads all icons of the current icon theme to the icon list of this
      // dialog. As this takes some time, it is done asynchronously. We do not check for
      // icon theme changes for now - this could be improved in the future!
      async _loadIcons() {

        // Disable sorting for now. Else this is horribly slow...
        this._iconList.set_sort_column_id(-2, Gtk.SortType.ASCENDING);

        const icons = utils.getIconTheme().get_icon_names();

        // We add icons in batches. This number is somewhat arbitrary - if reduced to 1,
        // the icon loading takes quite long, if increased further the user interface
        // gets a bit laggy during icon loading. Five seems to be a good compromise...
        const batchSize = 5;
        for (let i = 0; i < icons.length; i += batchSize) {
          for (let j = 0; j < batchSize && i + j < icons.length; j++) {
            this._iconList.set_value(this._iconList.append(), 0, icons[i + j]);
          }

          // This is effectively a 'yield'. We wait asynchronously for the timeout (1ms)
          // to resolve, letting other events to be processed in the meantime.
          await new Promise(r => GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1, r));
        }

        // Enable sorting again!
        this._iconList.set_sort_column_id(0, Gtk.SortType.ASCENDING);
      }
    });
  }
}