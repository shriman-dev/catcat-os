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

import * as utils from '../utils.js';
import {ItemClass} from '../ItemClass.js';

const ConfigWidgetFactory = await utils.importInPrefsOnly('./ConfigWidgetFactory.js');
const _                   = await utils.importGettext();

// We import the ClipboardManager optionally. When this file is included from the daemon
// side, it is available and can be used in the activation code of the action defined
// below. If this file is included via the pref.js, they will not be available. But this
// is not a problem, as the preferences will not call the createItem() methods below; they
// are merely interested in the action's name, icon and description.
const ClipboardManager =
    await utils.importInShellOnly('../extension/ClipboardManager.js');

//////////////////////////////////////////////////////////////////////////////////////////
// The insert-text action pastes some text to the current cursor position.              //
// See common/ItemRegistry.js for a description of the action's format.                 //
//////////////////////////////////////////////////////////////////////////////////////////

export function getInsertTextAction() {
  return {

    // There are two fundamental item types in Fly-Pie: Actions and Menus. Actions have an
    // onSelect() method which is called when the user selects the item, Menus can have
    // child Actions or Menus.
    class: ItemClass.ACTION,

    // This will be shown in the add-new-item-popover of the settings dialog.
    name: _('Insert Text'),

    // This is also used in the add-new-item-popover.
    icon: 'flypie-action-insert-text-symbolic-#975',

    // Translators: Please keep this short.
    // This is the (short) description shown in the add-new-item-popover.
    subtitle: _('Types some text automatically.'),

    // This is the (long) description shown when an item of this type is selected.
    description: _(
        'The <b>Insert Text</b> action copies the given text to the clipboard and then simulates a Ctrl+V. This can be useful if you realize that you often write the same things.'),

    // Items of this type have an additional text configuration parameter which is the
    // text
    // which is to be inserted.
    config: {
      // This is used as data for newly created items of this type.
      defaultData: {text: ''},

      // This is called whenever an item of this type is selected in the menu editor. It
      // returns a Gtk.Widget which will be shown in the sidebar of the menu editor. The
      // currently configured data object will be passed as first parameter and *should*
      // be an object containing a single "text" property. To stay backwards compatible
      // with Fly-Pie 4, we have to also handle the case where the text is given as a
      // simple string value. The second parameter is a callback which is fired whenever
      // the user changes something in the widgets.
      getWidget(data, updateCallback) {
        let text = '';
        if (typeof data === 'string') {
          text = data;
        } else if (data.text != undefined) {
          text = data.text;
        }

        return ConfigWidgetFactory.createTextWidget(
            _('Text'), _('This text will be inserted.'), null, text, (text) => {
              updateCallback({text: text});
            });
      }
    },

    // This will be called whenever a menu is opened containing an item of this kind.
    // The data parameter *should* be an object containing a single "text" property. To
    // stay backwards compatible with Fly-Pie 4, we have to also handle the case where
    // the text is given as a simple string value.
    createItem: (data) => {
      let text = '';
      if (typeof data === 'string') {
        text = data;
      } else if (data.text != undefined) {
        text = data.text;
      }

      const clipboardManager = ClipboardManager.getInstance();

      // The onSelect() function will be called when the user selects this action.
      return {
        onSelect: () => {
          clipboardManager.pasteItem(
              {type: 'text/plain;charset=utf-8', data: new TextEncoder().encode(text)});
        }
      };
    }
  };
}
