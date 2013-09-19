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
import AccountsService 0.1
import Ubuntu.Components 0.1
import LightDM 0.1 as LightDM
import "../Components"

MouseArea {
    id: root
    anchors.fill: parent

    property bool ready: wallpaper.source == "" || wallpaper.status == Image.Ready || wallpaper.status == Image.Error
    property bool leftTeaserPressed: teasingMouseArea.pressed &&
                                     teasingMouseArea.mouseX < teasingMouseArea.width / 2
    property bool rightTeaserPressed: teasingMouseArea.pressed &&
                                     teasingMouseArea.mouseX > teasingMouseArea.width / 2

    signal selected(int uid)
    signal unlocked(int uid)

    Rectangle {
        // In case wallpaper fails to load
        id: wallpaperBackup
        anchors.fill: parent
        color: "black"
    }

    property url backgroundValue: AccountsService.backgroundFile != undefined && AccountsService.backgroundFile.length > 0 ? AccountsService.backgroundFile : greeter.defaultBackground
    onBackgroundValueChanged: wallpaper.source = backgroundValue

    CrossFadeImage {
        id: wallpaper
        objectName: "wallpaper"
        anchors.fill: parent
        fadeInFirst: false
    }

    // See Shell.qml's backgroundSettings treatment for why we need a separate
    // Image, but it boils down to avoiding binding loop detection.
    Image {
        source: wallpaper.source
        height: 0
        width: 0
        sourceSize.height: 0
        sourceSize.width: 0
        onStatusChanged: {
            if (status == Image.Error && source != greeter.defaultBackground) {
                wallpaper.source = greeter.defaultBackground
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.4
    }

    Clock {
        id: clock
        visible: narrowMode

        anchors {
            top: parent.top
            topMargin: units.gu(2)
            horizontalCenter: parent.horizontalCenter
        }
    }

    MouseArea {
        id: teasingMouseArea
        anchors.fill: parent
    }

    Loader {
        id: loginLoader
        objectName: "loginLoader"
        anchors {
            left: parent.left
            leftMargin: Math.min(parent.width * 0.16, units.gu(20))
            verticalCenter: parent.verticalCenter
        }
        width: units.gu(29)
        height: parent.height

        // TODO: Once we have a system API for determining which mode we are
        // in, tablet/phone/desktop, that should be used instead of narrowMode.
        source: greeter.narrowMode ? "" : "LoginList.qml"

        onLoaded: {
            item.currentIndex = greeterContentLoader.currentIndex;
            selected(item.currentIndex);
            item.resetAuthentication();
        }

        Binding {
            target: loginLoader.item
            property: "model"
            value: greeterContentLoader.model
        }

        Connections {
            target: loginLoader.item

            onSelected: {
                root.selected(uid);
            }

            onUnlocked: {
                root.unlocked(uid);
            }

            onCurrentIndexChanged: {
                if (greeterContentLoader.currentIndex !== loginLoader.item.currentIndex) {
                    greeterContentLoader.currentIndex = loginLoader.item.currentIndex;
                }
            }
        }
    }

    Infographics {
        id: infographics
        height: narrowMode ? parent.height : 0.75 * parent.height
        model: greeterContentLoader.infographicModel

        Component.onCompleted: infographics.updateUsername(greeterContentLoader.currentIndex)

        Connections {
            target: root
            onSelected: infographics.updateUsername(uid)
        }

        function updateUsername(uid) {
            greeterContentLoader.infographicModel.username = greeterContentLoader.model.data(uid, LightDM.UserRoles.NameRole)
            greeterContentLoader.infographicModel.readyForDataChangeSlot();
        }

        anchors {
            verticalCenter: parent.verticalCenter
            left: narrowMode ? root.left : loginLoader.right
            right: root.right
        }
    }
}
