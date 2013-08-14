/*
 * Copyright 2013 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 *      Renato Araujo Oliveira Filho <renato@canonical.com>
 *      Olivier Tilloy <olivier.tilloy@canonical.com>
 */

import QtQuick 2.0
import Ubuntu.Components 0.1
import Unity.IndicatorsLegacy 0.1 as Indicators

Indicators.BasicMenuItem {
    id: heroMessage

    property variant actionsDescription: null
    property alias heroMessageHeader: __heroMessageHeader
    property real collapsedHeight: heroMessageHeader.y + heroMessageHeader.bodyBottom + units.gu(2)
    property real expandedHeight: collapsedHeight

    color: "#221e1c"

    removable: state !== "expanded"
    implicitHeight: collapsedHeight

    Indicators.MenuAction {
        id: menuAction
        actionGroup: heroMessage.actionGroup
        action: menu ? menu.action : ""
    }

    HeroMessageHeader {
        id: __heroMessageHeader

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        avatar: menu && (menu.extra.canonical_icon.length > 0) ? "image://gicon/" + encodeURI(menu.extra.canonical_icon) : "qrc:/indicators/artwork/messaging/default_contact.png"
        icon: menu && (menu.extra.canonical_app_icon.length > 0) ? "image://gicon/" + encodeURI(menu.extra.canonical_app_icon) : ""
        appIcon: icon

        state: heroMessage.state

        onAppIconClicked:  {
            if (menuAction.valid) {
                deactivateMenu();
                action.activate(true);
            }
        }
    }

    onClicked: {
        if (menuActivated) {
            deactivateMenu();
        } else {
            activateMenu();
        }
    }

    Indicators.HLine {
        id: __topHLine
        anchors.top: parent.top
        color: "#403b37"
    }

    Indicators.HLine {
        id: __bottomHLine
        anchors.bottom: parent.bottom
        color: "#060606"
    }

    states: State {
        name: "expanded"
        when: menuActivated

        PropertyChanges {
            target: heroMessage
            color: "#333130"
            implicitHeight: heroMessage.expandedHeight
        }
        PropertyChanges {
            target: __topHLine
            opacity: 0.0
        }
        PropertyChanges {
            target: __bottomHLine
            opacity: 0.0
        }
    }

    transitions: Transition {
        ParallelAnimation {
            NumberAnimation {
                properties: "opacity,implicitHeight"
                duration: 200
                easing.type: Easing.OutQuad
            }
            ColorAnimation {}
        }
    }

    onItemRemoved: {
        if (menuAction.valid) {
            menuAction.activate(false);
        }
    }
}
