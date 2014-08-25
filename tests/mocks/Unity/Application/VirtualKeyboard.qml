/*
 * Copyright 2014 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0

Item {
    implicitWidth: units.gu(40)
    implicitHeight: units.gu(70)

    anchors.fill: parent

    property alias screenshotSource: screenshotImage.source

    property bool landscape: width > height

    Image {
        id: screenshotImage
        height: landscape ? parent.height * 0.4 : width * 0.6
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        MultiPointTouchArea {
            anchors.fill: parent
        }
    }
}
