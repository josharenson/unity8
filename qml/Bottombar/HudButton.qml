/*
 * Copyright (C) 2013 Canonical, Ltd.
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

import QtQuick 2.0
import Ubuntu.Components 0.1

Item {
    id: item

    property bool mouseOver

    property int bottomMargin: units.gu(2)

    signal clicked()

    readonly property real scaleOnMouseOver: 1.2

    width: hudButton.width * scaleOnMouseOver
    height: hudButton.height * scaleOnMouseOver

    Item {
        id: hudButton

        anchors.centerIn: parent
        height: units.gu(12)
        width: height
        opacity: item.mouseOver || abstractButton.pressed ? 1 : 0.7
        scale: item.mouseOver || abstractButton.pressed ? scaleOnMouseOver : 1
        Behavior on opacity {NumberAnimation{duration: 200; easing.type: Easing.OutQuart}}
        Behavior on scale {NumberAnimation{duration: 200; easing.type: Easing.OutQuart}}

        AbstractButton {
            id: abstractButton
            anchors.fill: parent
            style: Image {
                anchors.fill: parent
                source: "graphics/hud_invoke_button_active.png"
            }

            onClicked: item.clicked()
        }

        Image {
            width: units.gu(4)
            height: width
            source: "graphics/hud.png"
            anchors.centerIn: parent
            fillMode: Image.PreserveAspectFit
        }
    }
}
