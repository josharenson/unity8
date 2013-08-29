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
import Ubuntu.Gestures 0.1
import LightDM 0.1 as LightDM
import "../Components"
import "../Components/Math.js" as MathLocal

Showable {
    id: greeter
    enabled: shown
    created: greeterContentLoader.status == Loader.Ready && greeterContentLoader.item.ready

    // 1 when fully shown and 0 when fully hidden
    property real showProgress: MathLocal.clamp((width + x) / width, 0, 1)

    showAnimation: StandardAnimation { property: "x"; to: 0 }
    hideAnimation: StandardAnimation { property: "x"; to: -width }

    property alias dragHandleWidth: dragHandle.width
    property alias model: greeterContentLoader.model
    property bool locked: shown && !LightDM.Greeter.promptless

    readonly property bool narrowMode: !multiUser && width <= units.gu(60)
    readonly property bool multiUser: LightDM.Users.count > 1

    readonly property bool leftTeaserPressed: greeterContentLoader.status == Loader.Ready &&
                                              greeterContentLoader.item.leftTeaserPressed
    readonly property bool rightTeaserPressed: greeterContentLoader.status == Loader.Ready &&
                                               greeterContentLoader.item.rightTeaserPressed

    readonly property int currentIndex: greeterContentLoader.currentIndex

    signal selected(int uid)
    signal unlocked(int uid)

    onRightTeaserPressedChanged: {
        if (rightTeaserPressed && !locked) {
            teasingTimer.start();
        }
    }

    Loader {
        id: greeterContentLoader
        objectName: "greeterContentLoader"
        anchors.fill: parent
        property var model: LightDM.Users
        property int currentIndex: 0
        property var infographicModel: LightDM.Infographic

        source: required ? "GreeterContent.qml" : ""

        Connections {
            target: greeterContentLoader.item

            onSelected: {
                greeter.selected(uid);
                greeterContentLoader.currentIndex = uid;
            }
            onUnlocked: greeter.unlocked(uid);
        }
    }

    Timer {
        id: teasingTimer
        interval: 200
    }

    states: [
        State {
            name: "teasing"
            when: teasingTimer.running
            PropertyChanges {
                target: greeter
                x: -units.gu(2)
            }
        }
    ]
    transitions: [
        Transition {
            from: "*"
            to: "*"
            NumberAnimation {
                target: greeter
                property: "x"
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
    ]

    DragHandle {
        id: dragHandle

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right

        // no need for requiring a directional drag since we are covering the screen
        // anyway (i.e., no change user could be trying to interact with some other
        // UI element)
        distanceThreshold: 0

        enabled: greeter.narrowMode || !greeter.locked

        direction: Direction.Leftwards
    }
}
