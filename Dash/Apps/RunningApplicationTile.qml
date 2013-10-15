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
import Unity.Application 0.1
import "../../Components/"
import "../../Components/ListItems"

AbstractButton {
    id: root
    property var application
    property bool __sideStageEnabled: shell.applicationManager.sideStageEnabled

    signal requestedApplicationActivation(var application)
    signal requestedApplicationTermination(var application)
    signal requestedActivationMode()
    signal requestedTerminationMode()

    // Was: childrenRect.height
    // To avoid "binding loop" warning
    height: shapedApplicationImage.height + labelContainer.height

    width: shapedApplicationImage.width

    property bool terminationModeEnabled: false

    onClicked: {
        if (!terminationModeEnabled)
            requestedApplicationActivation(application)
    }

    onPressAndHold: {
        if (terminationModeEnabled) {
            requestedActivationMode()
        } else {
            requestedTerminationMode()
        }
    }

    function updateScreenshotFromCache() {
        applicationImage.updateFromCache();
    }

    // FIXME: should use UbuntuShape from SDK
    UbuntuShapeForItem {
        id: shapedApplicationImage
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
        }

        // FIXME: width and height should be defined according to the
        // application window's aspect ratio.
        width: (application.stage === ApplicationInfo.MainStage && __sideStageEnabled) ?
            units.gu(22) : units.gu(11)
        height: (__sideStageEnabled) ? units.gu(22) : units.gu(19)
        radius: "medium"
        image: applicationImage
    }

    ApplicationImage {
        id: applicationImage
        source: ApplicationManager.findApplication((application) ? application.appId : "")
        width: shapedApplicationImage.width
        height: shapedApplicationImage.height
    }

    UbuntuShape {
        id: borderPressed

        anchors.fill: shapedApplicationImage
        radius: "medium"
        borderSource: "radius_pressed.sci"
        opacity: root.pressed ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }
    }

    // FIXME: label code duplicated with Tile
    Item {
        id: labelContainer
        anchors {
            left: parent.left
            right: parent.right
            top: shapedApplicationImage.bottom
        }
        height: units.gu(2)

        Label {
            id: label
            anchors {
                baseline: parent.bottom
                left: parent.left
                right: parent.right
                leftMargin: units.gu(1)
                rightMargin: units.gu(1)
            }
            text: (application) ? application.name : ""

            color: Theme.palette.selected.backgroundText
            opacity: 0.9
            style: Text.Raised
            styleColor: "black"
            fontSize: "small"
            elide: Text.ElideMiddle
            horizontalAlignment: Text.AlignHCenter
        }
    }

    CloseIcon {
        objectName: "closeIcon " + model.name
        anchors {
            left: shapedApplicationImage.left
            leftMargin: -units.gu(1)
            top: parent.top
            topMargin: -units.gu(1)
        }
        height: units.gu(6)
        width: units.gu(6)
        id: closeIcon
        enabled: root.terminationModeEnabled

        MouseArea {
            anchors { fill: parent; margins: -units.gu(1) }
            onClicked: requestedApplicationTermination(application)
        }
    }
}
