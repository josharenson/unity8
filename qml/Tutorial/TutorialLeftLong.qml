/*
 * Copyright (C) 2016 Canonical, Ltd.
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
import "." as LocalComponents

TutorialPage {
    id: root

    property var launcher

    // Unlike other tutorials, this one can't be skipped before we show it, so
    // only set opacityOverride if we're already shown.
    opacityOverride: shown ? 1 - launcher.dragDistance / (launcher.panelWidth * 3) : 1

    mouseArea {
        anchors.leftMargin: launcher.dragAreaWidth
    }

    background {
        sourceSize.height: 1916
        sourceSize.width: 1080
        source: Qt.resolvedUrl("graphics/background1.png")
        mirror: true
    }

    arrow {
        anchors.left: root.left
        anchors.leftMargin: units.gu(2)
        anchors.verticalCenter: root.verticalCenter
        rotation: 180
    }

    label {
        text: i18n.tr("Long swipe from the left edge to open the Application Drawer")
        anchors.left: arrow.right
        anchors.leftMargin: units.gu(3)
        anchors.right: root.right
        anchors.rightMargin: units.gu(4)
        anchors.verticalCenter: arrow.verticalCenter
    }
}
