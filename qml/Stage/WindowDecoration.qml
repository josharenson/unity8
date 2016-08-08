/*
 * Copyright (C) 2014-2016 Canonical, Ltd.
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
import Unity.Application 0.1 // For Mir singleton
import Ubuntu.Components 1.3
import "../Components"
import "../Components/PanelState"

MouseArea {
    id: root
    clip: true

    property Item target
    property alias title: titleLabel.text
    property alias maximizeButtonShown: buttons.maximizeButtonShown
    property bool active: false
    acceptedButtons: Qt.AllButtons // prevent leaking unhandled mouse events
    property alias overlayShown: buttons.overlayShown
    readonly property alias dragging: priv.dragging
    property PanelState panelState

    signal closeClicked()
    signal minimizeClicked()
    signal maximizeClicked()
    signal maximizeHorizontallyClicked()
    signal maximizeVerticallyClicked()

    onDoubleClicked: {
        if (maximizeButtonShown && mouse.button == Qt.LeftButton) {
            root.maximizeClicked();
        }
    }

    QtObject {
        id: priv
        property real distanceX
        property real distanceY
        property bool dragging
    }

    onPressedChanged: {
        if (pressed && pressedButtons == Qt.LeftButton) {
            var pos = mapToItem(root.target, mouseX, mouseY);
            priv.distanceX = pos.x;
            priv.distanceY = pos.y;
            priv.dragging = true;
        } else {
            priv.dragging = false;
            Mir.cursorName = "";
        }
    }

    onPositionChanged: {
        if (priv.dragging) {
            Mir.cursorName = "grabbing";
            var pos = mapToItem(root.target.parent, mouseX, mouseY);
            // Use integer coordinate values to ensure that target is left in a pixel-aligned
            // position. Mouse movement could have subpixel precision, yielding a fractional
            // mouse position.
            root.target.windowedX = Math.round(pos.x - priv.distanceX);
            root.target.windowedY = Math.round(Math.max(pos.y - priv.distanceY, panelState.panelHeight));
        }
    }

    // do not let unhandled wheel event pass thru the decoration
    onWheel: wheel.accepted = true;

    Rectangle {
        anchors.fill: parent
        anchors.bottomMargin: -radius
        radius: units.gu(.5)
        color: theme.palette.normal.background
    }

    Row {
        anchors {
            fill: parent
            leftMargin: overlayShown ? units.gu(5) : units.gu(1)
            rightMargin: units.gu(1)
            topMargin: units.gu(0.5)
            bottomMargin: units.gu(0.5)
        }
        Behavior on anchors.leftMargin {
            UbuntuNumberAnimation {}
        }

        spacing: units.gu(3)

        WindowControlButtons {
            id: buttons
            height: parent.height
            active: root.active
            onCloseClicked: root.closeClicked();
            onMinimizeClicked: root.minimizeClicked();
            onMaximizeClicked: root.maximizeClicked();
            onMaximizeHorizontallyClicked: root.maximizeHorizontallyClicked();
            onMaximizeVerticallyClicked: root.maximizeVerticallyClicked();
            closeButtonShown: root.target.application.appId !== "unity8-dash"
            target: root.target
        }

        Label {
            id: titleLabel
            objectName: "windowDecorationTitle"
            color: root.active ? "white" : UbuntuColors.slate
            height: parent.height
            width: parent.width - buttons.width - parent.anchors.rightMargin - parent.anchors.leftMargin
            verticalAlignment: Text.AlignVCenter
            fontSize: "medium"
            font.weight: root.active ? Font.Light : Font.Medium
            elide: Text.ElideRight
            opacity: overlayShown ? 0 : 1
            visible: opacity == 1
            Behavior on opacity {
                OpacityAnimator { duration: UbuntuAnimation.FastDuration; easing: UbuntuAnimation.StandardEasing }
            }
        }
    }
}
