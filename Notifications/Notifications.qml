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
import "../Components"

ListView {
    id: notificationList

    objectName: "notificationList"
    interactive: false

    spacing: units.gu(.5)
    delegate: Notification {
        objectName: "notification" + index
        anchors {
            left: parent.left
            right: parent.right
        }
        type: model.type
        hints: model.hints
        iconSource: model.icon
        secondaryIconSource: model.secondaryIcon
        summary: model.summary
        body: model.body
        actions: model.actions
        notificationId: model.id
        notification: notificationList.model.getRaw(notificationId)

        // make sure there's no opacity-difference between the several
        // elements in a notification
        layer.enabled: add.running || remove.running || populate.running
    }

    populate: Transition {
        UbuntuNumberAnimation {
            property: "opacity"
            to: 1
            duration: UbuntuAnimation.SnapDuration
        }
    }

    add: Transition {
        UbuntuNumberAnimation {
            property: "opacity"
            to: 1
            duration: UbuntuAnimation.SnapDuration
        }
    }

    remove: Transition {
        UbuntuNumberAnimation {
            property: "opacity"
            to: 0
        }
    }

    displaced: Transition {
        UbuntuNumberAnimation {
            properties: "x,y"
        }
    }
}
