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
import Dash 0.1
import "../"

/*! This preview widget shows a header
 *  The title comes in widgetData["title"]
 *  The mascot comes in widgetData["mascot"]
 *  The mascot fall back image comes in widgetData["fallback"]
 *  The subtitle comes in widgetData["subtitle"]
 *  The attributes comes in widgetData["attributes"]
 *  The emblem comes in widgetData["emblem"]
 */

PreviewWidget {
    id: root

    implicitHeight: childrenRect.height

    Item {
        id: headerRoot
        objectName: "innerPreviewHeader"
        readonly property url mascot: root.widgetData["mascot"] || fallback
        readonly property url fallback: root.widgetData["fallback"] || ""
        readonly property string title: root.widgetData["title"] || ""
        readonly property string subtitle: root.widgetData["subtitle"] || ""
        readonly property var attributes: root.widgetData["attributes"] || null
        readonly property url emblem: root.widgetData["emblem"] || ""
        readonly property color fontColor: root.scopeStyle ? root.scopeStyle.foreground : theme.palette.normal.baseText

        // Rewire the source since we may have unwired it on onStatusChanged
        onMascotChanged: if (mascotShapeLoader.item) mascotShapeLoader.item.source.source = mascot;

        implicitHeight: row.height + row.margins * 2
        width: parent.width

        Row {
            id: row
            objectName: "outerRow"

            property real margins: units.gu(1)

            spacing: mascotShapeLoader.active ? margins : 0
            anchors {
                top: parent.top; left: parent.left; right: parent.right
                margins: margins
                topMargin: 0
                leftMargin: 0
                rightMargin: spacing
            }

            Loader {
                id: mascotShapeLoader
                objectName: "mascotShapeLoader"
                active: headerRoot.mascot != ""
                visible: active

                anchors.verticalCenter: parent.verticalCenter
                // TODO karni: Icon aspect-ratio is 8:7.5. Revisit these values to avoid fraction of pixels.
                width: units.gu(6)
                height: units.gu(5.625)
                readonly property int maxSize: Math.max(width, height) * 4
                asynchronous: true

                sourceComponent: UbuntuShape {
                    objectName: "mascotShape"
                    visible: source.status === Image.Ready
                    sourceFillMode: UbuntuShape.PreserveAspectCrop
                    sourceHorizontalAlignment: UbuntuShape.AlignHCenter
                    sourceVerticalAlignment: UbuntuShape.AlignVCenter
                    aspect: UbuntuShape.Flat
                    source: Image {
                        source: headerRoot.mascot
                        width: source ? mascotShapeLoader.width : 0
                        height: mascotShapeLoader.height

                        sourceSize { width: mascotShapeLoader.maxSize; height: mascotShapeLoader.maxSize }
                        onStatusChanged: if (status === Image.Error) source = headerRoot.fallback;
                    }
                }
            }

            Column {
                objectName: "column"
                width: parent.width - x
                spacing: units.dp(2)
                anchors.verticalCenter: parent.verticalCenter

                Item {
                    anchors { left: parent.left; right: parent.right }
                    height: titleLabel.height

                    Label {
                        id: titleLabel
                        objectName: "titleLabel"
                        anchors {
                            left: parent.left;
                            right: iconLoader.right
                            rightMargin: iconLoader.width > 0 ? units.gu(0.5) : 0
                        }
                        elide: Text.ElideRight
                        fontSize: "large"
                        font.weight: Font.Light
                        wrapMode: Text.Wrap
                        color: headerRoot.fontColor
                        text: headerRoot.title
                    }

                    Loader {
                        id: iconLoader
                        active: headerRoot.emblem != ""
                        anchors {
                            bottom: titleLabel.baseline
                            right: parent.right
                        }
                        sourceComponent: Icon {
                            objectName: "emblemIcon"
                            source: headerRoot.emblem
                            color: headerRoot.fontColor
                            height: source != "" ? titleLabel.font.pixelSize : 0
                            // FIXME Workaround for bug https://bugs.launchpad.net/ubuntu/+source/ubuntu-ui-toolkit/+bug/1421293
                            width: implicitWidth > 0 && implicitHeight > 0 ? (implicitWidth / implicitHeight * height) : implicitWidth
                        }
                    }
                }

                Loader {
                    active: titleLabel.text && headerRoot.subtitle
                    anchors { left: parent.left; right: parent.right }
                    sourceComponent: Label {
                        id: subtitleLabel
                        objectName: "subtitleLabel"
                        elide: Text.ElideRight
                        fontSize: "x-small"
                        font.weight: Font.Light
                        color: headerRoot.fontColor
                        text: headerRoot.subtitle
                    }
                }

                Loader {
                    active: titleLabel.text && headerRoot.attributes
                    anchors { left: parent.left; right: parent.right }
                    sourceComponent: CardAttributes {
                        id: previewAttributes
                        objectName: "previewAttributes"
                        model: headerRoot.attributes
                    }
                }
            }
        }
    }

}
