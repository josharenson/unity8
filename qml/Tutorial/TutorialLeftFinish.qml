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

import QtQuick 2.4
import Ubuntu.Components 1.3
import "." as LocalComponents

TutorialPage {
    id: root

    property var launcher

    title: i18n.tr("These are the shortcuts to favorite apps")
    text: i18n.tr("Tap here to continue.")
    fullTextWidth: true

    // Make sure launcher is shown, even after screen is locked/unlocked
    onPausedChanged: if (!paused) launcher.switchToNextState("visible")

    foreground {
        children: [
            LocalComponents.Tick {
                objectName: "tick"
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: root.textBottom + units.gu(3)
                }
                onClicked: root.hide()
            }
        ]
    }
}
