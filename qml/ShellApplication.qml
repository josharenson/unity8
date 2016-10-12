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
import QtQuick.Window 2.2
import Unity.Screens 0.1

Instantiator {
    id: root
    model: Screens

    ShellScreen {
        id: screen
        objectName: "screen"+index
        title: "Unity8 Shell - " + objectName
        screen: model.screen
        visibility:  applicationArguments.hasFullscreen ? Window.FullScreen : Window.Windowed
        flags: applicationArguments.hasFrameless ? Qt.FramelessWindowHint : 0

//        width: applicationArguments.hasGeometry ? applicationArguments.windowGeometry.width : screen.implicitWidth
//        height: applicationArguments.hasGeometry ? applicationArguments.windowGeometry.height : screen.implicitHeight

        Binding {
            target: screen
            property: "width"
            value: applicationArguments.windowGeometry.width
            when: applicationArguments.hasGeometry
        }

        Binding {
            target: screen
            property: "height"
            value: applicationArguments.windowGeometry.height
            when: applicationArguments.hasGeometry
        }

        primary: index == 0
    }
}
