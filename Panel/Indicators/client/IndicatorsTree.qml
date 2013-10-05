/*
 * Copyright 2013 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 *      Nick Dedekind <nick.dededkind@canonical.com>
 */

import QtQuick 2.0
import Ubuntu.Components 0.1
import Unity.Indicators 0.1 as Indicators
import QMenuModel 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem

Page {
    id: page
    anchors.fill: parent

    property string busName: unityModel.busName
    property string actionsObjectPath
    property var menuObjectPaths: undefined
    readonly property string device: "phone"

    property string deviceMenuObjectPath: menuObjectPaths.hasOwnProperty(device) ? menuObjectPaths[device] : ""

    function start() {
    }

    UnityMenuModel {
        id: unityModel
        busName: page.busName
        actions: { "indicator": page.actionsObjectPath }
        menuObjectPath: page.deviceMenuObjectPath
    }

    Indicators.RootActionState {
        menu: unityModel
    }

    Indicators.ModelPrinter {
        id: printer
        model: unityModel
    }

    Flickable {
        anchors.fill: parent
        contentHeight: all_data.height
        clip:true
        Text {
            id: all_data
            color: "white"
            text: printer.text
        }
    }
}
