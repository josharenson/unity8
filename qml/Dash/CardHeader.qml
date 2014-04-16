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
    id: root
    property url mascot: ""
    property alias title: titleLabel.text
    property var subtitle

    property alias titleWeight: titleLabel.font.weight
    property alias titleSize: titleLabel.fontSize

    // FIXME: Saviq, used to scale fonts down in Carousel
    property real fontScale: 1.0

    property alias headerAlignment: titleLabel.horizontalAlignment

    property bool inOverlay: false
    property bool useMascotShape: true
    property color fontColor: Theme.palette.selected.backgroundText

    visible: mascot != "" || title
    implicitHeight: row.height > 0 ? row.height + row.margins * 2 : 0

    Row {
        id: row
        objectName: "outerRow"

        property real margins: units.gu(1)

        spacing: mascotShapeLoader.active || mascotImageLoader.active || inOverlay ? margins : 0
        anchors {
            top: parent.top; left: parent.left; right: parent.right
            margins: margins
            leftMargin: spacing
            rightMargin: spacing
        }

        Loader {
            id: mascotShapeLoader
            objectName: "mascotShapeLoader"

            active: useMascotShape && mascotImageLoader.item && mascotImageLoader.item.status === Image.Ready
            visible: active
            anchors.verticalCenter: parent.verticalCenter
            // TODO karni: Icon aspect-ratio is 8:7.5. Revisit these values to avoid fraction of pixels.
            width: units.gu(6)
            height: units.gu(5.625)
            readonly property int maxSize: Math.max(width, height) * 4

            sourceComponent: UbuntuShape {
                image: mascotImageLoader.item
            }
        }

        Loader {
            id: mascotImageLoader
            active: root.mascot != ""
            visible: active && !useMascotShape && item.status === Image.Ready
            anchors.verticalCenter: parent.verticalCenter
            sourceComponent: Image {
                objectName: "mascotImage"

                source: root.mascot
                width: source ? mascotShapeLoader.width : 0
                height: mascotShapeLoader.height

                sourceSize { width: mascotShapeLoader.maxSize; height: mascotShapeLoader.maxSize }
                fillMode: Image.PreserveAspectCrop
                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter
            }
        }

        Column {
            objectName: "column"
            width: parent.width - x
            spacing: units.dp(2)
            anchors.verticalCenter: parent.verticalCenter

            Label {
                id: titleLabel
                objectName: "titleLabel"
                anchors { left: parent.left; right: parent.right }
                elide: Text.ElideRight
                font.weight: Font.Normal
                fontSize: "small"
                wrapMode: Text.Wrap
                maximumLineCount: 2
                font.pixelSize: Math.round(FontUtils.sizeToPixels(fontSize) * fontScale)
                color: fontColor
            }

            Loader {
                active: titleLabel.text && root.subtitle
                anchors { left: parent.left; right: parent.right }
                sourceComponent: Label {
                    id: subtitleLabel
                    objectName: "subtitleLabel"
                    elide: Text.ElideRight
                    fontSize: "small"
                    font.weight: Font.Light
                    font.pixelSize: Math.round(FontUtils.sizeToPixels(fontSize) * fontScale)
                    color: fontColor
                    text: root.subtitle
                }
            }
        }
    }
}
