/*
 * Copyright (C) 2014 Canonical, Ltd.
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

Item {
    id: root
    property var navigation: null
    property var currentNavigation: null
    property var scopeStyle: null
    signal enterNavigation(var newNavigationId, bool hasChildren)
    signal goBackToParentClicked()
    signal allNavigationClicked()

    readonly property int itemHeight: units.gu(5)
    readonly property color foregroundColor: root.scopeStyle ? root.scopeStyle.foreground : "grey"
    implicitHeight: flickable.contentHeight

    Rectangle {
        color: !root.scopeStyle || Qt.colorEqual(root.scopeStyle.background, "transparent") ? "white" : root.scopeStyle.background
        anchors.fill: parent
    }

    clip: true

    Behavior on height {
        UbuntuNumberAnimation {
            id: heightAnimation
            duration: UbuntuAnimation.SnapDuration
        }
    }

    Flickable {
        id: flickable

        anchors.fill: parent

        flickableDirection: Flickable.VerticalFlick
        contentHeight: column.height
        contentWidth: width

        Column {
            id: column
            width: parent.width

            // TODO: check if SDK ListItems could be used here
            // and if not make them be useful since this is a quite common pattern

            AbstractButton {
                id: backButton
                objectName: "backButton"
                width: parent.width
                visible: navigation && !navigation.isRoot || false
                height: itemHeight

                onClicked: root.goBackToParentClicked();

                Icon {
                    id: backImage
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: units.gu(2)
                    }
                    name: "back"
                    height: units.gu(2)
                    width: height
                    color: root.foregroundColor
                }

                Label {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: backImage.right
                        leftMargin: units.gu(0.5)
                    }
                    text: navigation ? navigation.parentLabel : ""
                    color: root.foregroundColor
                }

                Rectangle {
                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                        leftMargin: units.gu(2)
                        rightMargin: units.gu(2)
                    }
                    color: root.foregroundColor
                    opacity: 0.2
                    height: units.dp(1)
                }
            }

            AbstractButton {
                id: allButton
                objectName: "allButton"
                width: parent.width
                visible: navigation && (!navigation.isRoot || (root.currentNavigation && !root.currentNavigation.isRoot && root.currentNavigation.parentNavigationId == navigation.navigationId)) || false
                height: itemHeight

                Label {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: units.gu(2)
                    }
                    text: navigation ? (navigation.allLabel != "" ? navigation.allLabel : navigation.label) : ""
                    font.bold: true
                    color: root.foregroundColor
                }

                Rectangle {
                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                        leftMargin: units.gu(2)
                        rightMargin: units.gu(2)
                    }
                    color: root.foregroundColor
                    opacity: 0.2
                    height: units.dp(1)
                }

                onClicked: root.allNavigationClicked();
            }

            Repeater {
                model: navigation && navigation.loaded ? navigation : null
                clip: true
                delegate: AbstractButton {
                    objectName: root.objectName + "child" + index
                    height: root.itemHeight
                    width: root.width

                    onClicked: root.enterNavigation(navigationId, hasChildren)

                    Label {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            leftMargin: units.gu(2)
                        }
                        text: label
                        color: root.foregroundColor
                    }

                    Icon {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            right: parent.right
                            rightMargin: units.gu(2)
                        }
                        height: units.gu(2)
                        width: height
                        name: hasChildren ? "go-next" : "tick"
                        color: root.foregroundColor
                        visible: hasChildren || isActive
                    }

                    Rectangle {
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                            leftMargin: units.gu(2)
                            rightMargin: units.gu(2)
                        }
                        color: root.foregroundColor
                        opacity: 0.1
                        height: units.dp(1)
                        visible: index != navigation.count - 1
                    }
                }
            }
        }
    }
}
