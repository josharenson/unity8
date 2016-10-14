/*
 * Copyright (C) 2014,2015 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3

/*! This preview widget shows either one button, two buttons or one button
 *  and a combo button depending on the number of items in widgetData["actions"].
 *  For each of the items we recognize the fields "label", "icon" and "id".
 */

PreviewWidget {
    id: root

    implicitHeight: row.height + units.gu(1)
    readonly property var actions: root.widgetData ? root.widgetData["actions"] : null
    readonly property real maxButtonWidth: (width - units.gu(1)) / 2

    Row {
        id: row
        anchors.right: parent.right

        spacing: units.gu(1)

        Loader {
            id: loader
            objectName: "loader"
            readonly property bool button: root.actions && root.actions.length == 2
            readonly property bool combo: root.actions && root.actions.length > 2
            source: button ? "PreviewActionButton.qml" : (combo ? "PreviewActionCombo.qml" : "")
            width: Math.min(root.maxButtonWidth, implicitWidth)
            onLoaded: {
                if (button) {
                    item.data = Qt.binding(function() { return root.actions[1]; });
                } else if (combo) {
                    item.model = Qt.binding(function() { return root.actions.slice(1); });
                }
            }
            Binding {
                target: loader.item
                property: "strokeColor"
                value: root.scopeStyle ? root.scopeStyle.foreground : theme.palette.normal.baseText
            }
            Connections {
                target: loader.item
                onTriggeredAction: {
                    root.triggered(root.widgetId, actionData.id, actionData);
                }
            }
        }

        PreviewActionButton {
            data: visible ? root.actions[0] : null
            visible: root.actions && root.actions.length > 0
            onTriggeredAction: root.triggered(root.widgetId, actionData.id, actionData)
            width: Math.min(root.maxButtonWidth, implicitWidth)
            color: root.scopeStyle ? root.scopeStyle.previewButtonColor : theme.palette.normal.positive
        }
    }
}
