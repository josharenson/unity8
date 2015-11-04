/*
 * Copyright (C) 2013-2015 Canonical, Ltd.
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

import QtQuick 2.2
import Ubuntu.Components 1.1
import Unity.Application 0.1
import "../Components"
import "../Components/PanelState"
import ".."

Item {
    id: root
    readonly property real panelHeight: indicatorArea.y + d.indicatorHeight
    property alias indicators: __indicators
    property alias callHint: __callHint
    property bool fullscreenMode: false
    property real indicatorAreaShowProgress: 1.0
    property bool locked: false

    opacity: fullscreenMode && indicators.fullyClosed ? 0.0 : 1.0

    Rectangle {
        id: darkenedArea
        property real darkenedOpacity: 0.6
        anchors {
            fill: parent
            topMargin: panelHeight
        }
        color: "black"
        opacity: indicators.unitProgress * darkenedOpacity
        visible: !indicators.fullyClosed

        MouseArea {
            anchors.fill: parent
            onClicked: if (indicators.fullyOpened) indicators.hide();
            hoverEnabled: true // should also eat hover events, otherwise they will pass through
        }
    }

    Item {
        id: indicatorArea
        objectName: "indicatorArea"

        anchors.fill: parent

        Behavior on anchors.topMargin {
            UbuntuNumberAnimation {}
        }

        transform: Translate {
            y: indicators.state === "initial"
                ? (1.0 - indicatorAreaShowProgress) * -d.indicatorHeight
                : 0
        }

        BorderImage {
            id: dropShadow
            anchors {
                fill: indicators
                leftMargin: -units.gu(1)
                bottomMargin: -units.gu(1)
            }
            visible: !indicators.fullyClosed
            source: "graphics/rectangular_dropshadow.sci"
        }

        Rectangle {
            id: indicatorAreaBackground
            color: callHint.visible ? "green" : "#333333"
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: indicators.minimizedPanelHeight

            Behavior on color { ColorAnimation { duration: UbuntuAnimation.FastDuration } }
        }

        PanelSeparatorLine {
            id: orangeLine
            anchors {
                top: indicatorAreaBackground.bottom
                left: parent.left
                right: indicators.left
            }
            saturation: 1 - indicators.unitProgress

            // Don't let input event pass trough
            MouseArea { anchors.fill: parent }
        }

        Image {
            anchors {
                top: indicators.top
                bottom: indicators.bottom
                right: indicators.left
                topMargin: indicatorArea.anchors.topMargin + indicators.minimizedPanelHeight
            }
            width: units.dp(2)
            source: "graphics/VerticalDivider.png"
        }

        MouseArea {
            anchors {
                top: parent.top
                left: parent.left
                right: indicators.left
            }
            height: indicators.minimizedPanelHeight
            hoverEnabled: true
            onClicked: { if (callHint.visible) { callHint.showLiveCall(); } }
            onDoubleClicked: PanelState.maximize()

            // WindowControlButtons inside the mouse area, otherwise QML doesn't grok nested hover events :/
            // cf. https://bugreports.qt.io/browse/QTBUG-32909
            WindowControlButtons {
                id: windowControlButtons
                objectName: "panelWindowControlButtons"
                anchors {
                    left: parent.left
                    top: parent.top
                    leftMargin: units.gu(1)
                    topMargin: units.gu(0.5)
                    bottomMargin: units.gu(0.5)
                }
                height: indicators.minimizedPanelHeight - anchors.topMargin - anchors.bottomMargin
                visible: PanelState.buttonsVisible && parent.containsMouse && !root.locked && !callHint.visible
                active: PanelState.buttonsVisible
                onClose: PanelState.close()
                onMinimize: PanelState.minimize()
                onMaximize: PanelState.maximize()
            }
        }

        IndicatorsMenu {
            id: __indicators
            objectName: "indicators"

            anchors {
                top: parent.top
                right: parent.right
            }

            shown: false
            width: root.width - (windowControlButtons.visible ? windowControlButtons.width + titleLabel.width : 0)
            minimizedPanelHeight: units.gu(3)
            expandedPanelHeight: units.gu(7)
            openedHeight: root.height - indicatorOrangeLine.height

            overFlowWidth: {
                if (callHint.visible) {
                    return Math.max(root.width - (callHint.width + units.gu(2)), 0)
                }
                return root.width
            }
            enableHint: !callHint.active && !fullscreenMode
            showOnClick: !callHint.visible
            panelColor: indicatorAreaBackground.color

            onShowTapped: {
                if (callHint.active) {
                    callHint.showLiveCall();
                }
            }

            hideDragHandle {
                anchors.bottomMargin: -indicatorOrangeLine.height
            }
        }

        Label {
            id: titleLabel
            objectName: "windowDecorationTitle"
            anchors {
                left: parent.left
                top: parent.top
                leftMargin: units.gu(1)
                topMargin: units.gu(0.5)
                bottomMargin: units.gu(0.5)
            }
            color: PanelState.buttonsVisible ? "#ffffff" : "#5d5d5d"
            height: indicators.minimizedPanelHeight - anchors.topMargin - anchors.bottomMargin
            visible: !windowControlButtons.visible && !root.locked && !callHint.visible
            verticalAlignment: Text.AlignVCenter
            fontSize: "medium"
            font.weight: Font.Normal
            text: PanelState.title
        }

        // TODO here would the LIM come

        PanelSeparatorLine {
            id: indicatorOrangeLine
            anchors {
                top: indicators.bottom
                left: indicators.left
                right: indicators.right
            }
        }

        ActiveCallHint {
            id: __callHint
            anchors {
                top: parent.top
                left: parent.left
            }
            height: indicators.minimizedPanelHeight
            visible: active && indicators.state == "initial"
        }
    }

    QtObject {
        id: d
        objectName: "panelPriv"
        readonly property real indicatorHeight: indicators.minimizedPanelHeight + indicatorOrangeLine.height
    }

    states: [
        State {
            name: "onscreen" //fully opaque and visible at top edge of screen
            when: !fullscreenMode
            PropertyChanges {
                target: indicatorArea;
                anchors.topMargin: 0
            }
        },
        State {
            name: "offscreen" //pushed off screen
            when: fullscreenMode
            PropertyChanges {
                target: indicatorArea;
                anchors.topMargin: indicators.state === "initial" ? -d.indicatorHeight : 0
            }
            PropertyChanges {
                target: indicators.showDragHandle;
                anchors.bottomMargin: -units.gu(1)
            }
        }
    ]
}
