/**
 * Copyright (C) 2013-2015 OpenMediaVault Plugin Developers
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

// require("js/omv/WorkspaceManager.js")
// require("js/omv/form/field/SharedFolderComboBox.js")
// require("js/omv/workspace/form/Panel.js")

Ext.define('OMV.module.admin.service.webdav.Settings', {
    extend: 'OMV.workspace.form.Panel',
    uses: [
        'OMV.form.field.SharedFolderComboBox'
    ],

    rpcService: 'WebDAV',
    rpcGetMethod: 'getSettings',
    rpcSetMethod: 'setSettings',

    getButtonItems: function() {
        var items = this.callParent(arguments);

        items.push({
            id: this.getId() + '-show',
            xtype: 'button',
            text: _('Show'),
            icon: 'images/search.png',
            iconCls: Ext.baseCSSPrefix + 'btn-icon-16x16',
            scope: this,
            handler: function() {
                window.open('/webdav/', '_blank');
            }
        });

        return items;
    },

    getFormItems: function() {
        var me = this;
        return [{
            xtype: 'fieldset',
            title: _('General settings'),
            fieldDefaults: {
                labelSeparator: ''
            },
            items: [{
                xtype: 'checkbox',
                name: 'enable',
                fieldLabel: _('Enable'),
                checked: false
            }, {
                xtype: 'sharedfoldercombo',
                name: 'sharedfolderref',
                fieldLabel: _('Shared folder'),
                allowNone: false
            }, {
                xtype: 'numberfield',
                name: 'upload_max',
                fieldLabel: _('Filesize upload limit (MiB)'),
                minValue: 1,
                value: 2
            }]
        }];
    }
});

OMV.WorkspaceManager.registerPanel({
    id: 'settings',
    path: '/service/webdav',
    text: _('Settings'),
    position: 10,
    className: 'OMV.module.admin.service.webdav.Settings'
});
