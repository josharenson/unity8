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
import QtTest 1.0
import ".."
import "../../../Notifications"
import Ubuntu.Components 0.1
import Unity.Test 0.1
import Unity.Notifications 1.0

Row {
    id: rootRow

    Component {
        id: mockNotification

        QtObject {
            function invokeAction(actionId) {
                mockModel.actionInvoked(actionId)
            }
        }
    }

    ListModel {
        id: mockModel

        signal actionInvoked(string actionId)

        function getRaw(id) {
            return mockNotification.createObject(mockModel)
        }
    }

    function addSnapDecisionNotification() {
        var n = {
            type: Notification.SnapDecision,
            hints: {"x-canonical-private-button-tint": "true"},
            summary: "Tom Ato",
            body: "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.",
            icon: "../graphics/avatars/funky.png",
            secondaryIcon: "../graphics/applicationIcons/facebook.png",
            actions: [{ id: "ok_id", label: "Ok"},
                      { id: "cancel_id", label: "Cancel"},
                      { id: "notreally_id", label: "Not really"},
                      { id: "noway_id", label: "No way"},
                      { id: "nada_id", label: "Nada"}]
        }

        mockModel.append(n)
    }

    function addEphemeralNotification() {
        var n = {
            type: Notification.Ephemeral,
            summary: "Cole Raby",
            body: "I did not expect it to be that late.",
            icon: "../graphics/avatars/amanda.png",
            secondaryIcon: "../graphics/applicationIcons/facebook.png",
            actions: []
        }

        mockModel.append(n)
    }

    function addEphemeralNonShapedIconNotification() {
        var n = {
            type: Notification.Ephemeral,
            hints: {"x-canonical-non-shaped-icon": "true"},
            summary: "Contacts",
            body: "Synchronised contacts-database with cloud-storage.",
            icon: "../graphics/applicationIcons/contacts-app.png",
            secondaryIcon: "",
            actions: []
        }

        mockModel.append(n)
    }

    function addEphemeralIconSummaryNotification() {
        var n = {
            type: Notification.Ephemeral,
            summary: "Photo upload completed",
            body: "",
            icon: "",
            secondaryIcon: "../graphics/applicationIcons/facebook.png",
            actions: []
        }

        mockModel.append(n)
    }

    function addInteractiveNotification() {
        var n = {
            type: Notification.Interactive,
            summary: "Interactive notification",
            body: "This is a notification that can be clicked",
            icon: "../graphics/avatars/anna_olsson.png",
            secondaryIcon: "",
            actions: [{ id: "reply_id", label: "Dummy"}],
        }

        mockModel.append(n)
    }

    function clearNotifications() {
        mockModel.clear()
    }

    function remove1stNotification() {
        if (mockModel.count > 0)
            mockModel.remove(0)
    }

    Rectangle {
        id: notificationsRect

        width: units.gu(40)
        height: units.gu(71)

        MouseArea{
            id: clickThroughCatcher

            anchors.fill: parent
        }

        Notifications {
            id: notifications

            anchors.fill: parent
            anchors.margins: units.gu(1)
            model: mockModel
        }
    }

    Rectangle {
        id: interactiveControls

        width: units.gu(30)
        height: units.gu(81)
        color: "grey"

        Column {
            spacing: units.gu(1)
            anchors.fill: parent
            anchors.margins: units.gu(1)

            Button {
                width: parent.width
                text: "add a snap-decision"
                onClicked: addSnapDecisionNotification()
            }

            Button {
                width: parent.width
                text: "add an ephemeral"
                onClicked: addEphemeralNotification()
            }

            Button {
                width: parent.width
                text: "add an non-shaped-icon-summary-body"
                onClicked: addEphemeralNonShapedIconNotification()
            }

            Button {
                width: parent.width
                text: "add an icon-summary"
                onClicked: addEphemeralIconSummaryNotification()
            }

            Button {
                width: parent.width
                text: "add an interactive"
                onClicked: addInteractiveNotification()
            }

            Button {
                width: parent.width
                text: "remove 1st notification"
                onClicked: remove1stNotification()
            }

            Button {
                width: parent.width
                text: "clear model"
                onClicked: clearNotifications()
            }
        }
    }

    UnityTestCase {
        id: root
        name: "NotificationRendererTest"
        when: windowShown

        function test_NotificationRenderer_data() {
            return [
            {
                tag: "Snap Decision with secondary icon and button-tint",
                type: Notification.SnapDecision,
                hints: {"x-canonical-private-button-tint": "true"},
                summary: "Tom Ato",
                body: "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.",
                icon: "../graphics/avatars/funky.png",
                secondaryIcon: "../graphics/applicationIcons/facebook.png",
                actions: [{ id: "ok_id", label: "Ok"},
                          { id: "cancel_id", label: "Cancel"},
                          { id: "notreally_id", label: "Not really"},
                          { id: "noway_id", label: "No way"},
                          { id: "nada_id", label: "Nada"}],
                summaryVisible: true,
                bodyVisible: true,
                interactiveAreaEnabled: false,
                iconVisible: true,
                shapedIcon: true,
                nonShapedIcon: false,
                secondaryIconVisible: true,
                buttonRowVisible: true,
                buttonTinted: true
            },
            {
                tag: "Ephemeral notification - icon-summary layout",
                type: Notification.Ephemeral,
                hints: {"x-canonical-private-button-tint": "false"},
                summary: "Photo upload completed",
                body: "",
                icon: "",
                secondaryIcon: "../graphics/applicationIcons/facebook.png",
                actions: [],
                summaryVisible: true,
                bodyVisible: false,
                interactiveAreaEnabled: false,
                iconVisible: false,
                shapedIcon: false,
                nonShapedIcon: false,
                secondaryIconVisible: true,
                buttonRowVisible: false,
                buttonTinted: false
            },
            {
                tag: "Ephemeral notification - check suppression of secondary icon for icon-summary layout",
                type: Notification.Ephemeral,
                hints: {"x-canonical-private-button-tint": "false"},
                summary: "New comment successfully published",
                body: "",
                icon: "",
                secondaryIcon: "../graphics/applicationIcons/facebook.png",
                actions: [],
                summaryVisible: true,
                bodyVisible: false,
                interactiveAreaEnabled: false,
                iconVisible: false,
                shapedIcon: false,
                nonShapedIcon: false,
                secondaryIconVisible: true,
                buttonRowVisible: false,
                buttonTinted: false
            },
            {
                tag: "Interactive notification",
                type: Notification.Interactive,
                hints: {"x-canonical-private-button-tint": "false"},
                summary: "Interactive notification",
                body: "This is a notification that can be clicked",
                icon: "../graphics/avatars/amanda.png",
                secondaryIcon: "",
                actions: [{ id: "reply_id", label: "Dummy"}],
                summaryVisible: true,
                bodyVisible: true,
                interactiveAreaEnabled: true,
                iconVisible: true,
                shapedIcon: true,
                nonShapedIcon: false,
                secondaryIconVisible: false,
                buttonRowVisible: false,
                buttonTinted: false
            },
            {
                tag: "Snap Decision without secondary icon and no button-tint",
                type: Notification.SnapDecision,
                hints: {"x-canonical-private-button-tint": "false"},
                summary: "Bro Coly",
                body: "At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.",
                icon: "../graphics/avatars/anna_olsson.png",
                secondaryIcon: "",
                actions: [{ id: "accept_id", label: "Accept"},
                          { id: "reject_id", label: "Reject"}],
                summaryVisible: true,
                bodyVisible: true,
                interactiveAreaEnabled: false,
                iconVisible: true,
                shapedIcon: true,
                nonShapedIcon: false,
                secondaryIconVisible: false,
                buttonRowVisible: true,
                buttonTinted: false
            },
            {
                tag: "Ephemeral notification",
                type: Notification.Ephemeral,
                hints: {"x-canonical-private-button-tint": "false"},
                summary: "Cole Raby",
                body: "I did not expect it to be that late.",
                icon: "../graphics/avatars/funky.png",
                secondaryIcon: "../graphics/applicationIcons/facebook.png",
                actions: [],
                summaryVisible: true,
                bodyVisible: true,
                interactiveAreaEnabled: false,
                iconVisible: true,
                shapedIcon: true,
                nonShapedIcon: false,
                secondaryIconVisible: true,
                buttonRowVisible: false,
                buttonTinted: false
            },
            {
                tag: "Ephemeral notification with non-shaped icon",
                type: Notification.Ephemeral,
                hints: {"x-canonical-private-button-tint": "false",
                        "x-canonical-non-shaped-icon": "true"},
                summary: "Contacts",
                body: "Synchronised contacts-database with cloud-storage.",
                icon: "../graphics/applicationIcons/contacts-app.png",
                secondaryIcon: "",
                actions: [],
                summaryVisible: true,
                bodyVisible: true,
                interactiveAreaEnabled: false,
                iconVisible: true,
                shapedIcon: false,
                nonShapedIcon: true,
                secondaryIconVisible: false,
                buttonRowVisible: false,
                buttonTinted: false
            }
            ]
        }

        SignalSpy {
            id: clickThroughSpy

            target: clickThroughCatcher
            signalName: "clicked"
        }

        SignalSpy {
            id: actionSpy

            target: mockModel
            signalName: "actionInvoked"
        }

        function cleanup() {
            clickThroughSpy.clear()
            actionSpy.clear()
        }

        function test_NotificationRenderer(data) {
            // populate model with some mock notifications
            mockModel.append(data)

            // make sure the view is properly updated before going on
            notifications.forceLayout();
            waitForRendering(notifications);

            var notification = findChild(notifications, "notification" + (mockModel.count - 1))
            verify(notification !== undefined, "notification wasn't found");

            var icon = findChild(notification, "icon")
            var shapedIcon = findChild(notification, "shapedIcon")
            var nonShapedIcon = findChild(notification, "nonShapedIcon")
            var interactiveArea = findChild(notification, "interactiveArea")
            var secondaryIcon = findChild(notification, "secondaryIcon")
            var summaryLabel = findChild(notification, "summaryLabel")
            var bodyLabel = findChild(notification, "bodyLabel")
            var buttonRow = findChild(notification, "buttonRow")
            waitForRendering(buttonRow)

            compare(icon.visible, data.iconVisible, "avatar-icon visibility is incorrect")
            compare(shapedIcon.visible, data.shapedIcon, "shaped-icon visibility is incorrect")
            compare(nonShapedIcon.visible, data.nonShapedIcon, "non-shaped-icon visibility is incorrect")
            compare(interactiveArea.enabled, data.interactiveAreaEnabled, "check for interactive area")

            if(data.interactiveAreaEnabled) {
                mouseClick(notification, notification.width / 2, notification.height / 2)
                actionSpy.wait()
                compare(actionSpy.signalArguments[0][0], data.actions[0]["id"], "got wrong id for interactive action")
                compare(clickThroughSpy.count, 0, "click on interactive notification fell through")
            } else {
                mouseClick(notification, notification.width / 2, notification.height / 2)
                clickThroughSpy.wait()
            }

            compare(secondaryIcon.visible, data.secondaryIconVisible, "secondary-icon visibility is incorrect")
            compare(summaryLabel.visible, data.summaryVisible, "summary-text visibility is incorrect")
            compare(bodyLabel.visible, data.bodyVisible, "body-text visibility is incorrect")
            compare(buttonRow.visible, data.buttonRowVisible, "button visibility is incorrect")

            if(data.buttonRowVisible) {
                var buttonCancel = findChild(buttonRow, "button1")
                var buttonAccept = findChild(buttonRow, "button0")

                waitForRendering(notification)

                // only test the left/cancel-button if two actions have been passed in
                if (data.actions.length == 2) {
                    mouseClick(buttonCancel, buttonCancel.width / 2, buttonCancel.height / 2)
                    actionSpy.wait()
                    compare(actionSpy.signalArguments[0][0], data.actions[1]["id"], "got wrong id for negative action")
                    actionSpy.clear()
                }

                // check the tinting of the positive/right button
                verify(buttonAccept.gradient === data.buttonTinted ? UbuntuColors.orangeGradient : UbuntuColors.greyGradient, "button has the wrong color-tint")

                // click the positive/right button
                mouseClick(buttonAccept, buttonAccept.width / 2, buttonAccept.height / 2)
                actionSpy.wait()
                compare(actionSpy.signalArguments[0][0], data.actions[0]["id"], "got wrong id positive action")
                actionSpy.clear()

                // check if there's more than one negative choice
                if (data.actions.length > 2) {
                    var initialHeight = notification.height

                    // click to expand
                    mouseClick(buttonCancel, buttonCancel.width / 2, buttonCancel.height / 2)
                    waitForRendering(notification)
                    actionSpy.clear()

                    // test the additional buttons
                    for (var i = 2; i < data.actions.length; i++) {
                        waitForRendering(notification)
                        var buttonColumn = findChild(notification, "buttonColumn")
                        var button = findChild(buttonColumn, "button" + i)
                        mouseClick(button, button.width / 2, button.height / 2)
                        actionSpy.wait()
                        compare(actionSpy.signalArguments[0][0], data.actions[i]["id"], "got wrong id for additional negative action")
                        actionSpy.clear()
                    }

                    // click to collapse
                    mouseClick(buttonCancel, buttonCancel.width / 2, buttonCancel.height / 2)
                    waitForRendering(notification)
                    tryCompare(notification, "height", initialHeight)
                } else {
                    mouseClick(buttonCancel, buttonCancel.width / 2, buttonCancel.height / 2)
                    actionSpy.wait()
                    compare(actionSpy.signalArguments[0][0], data.actions[1]["id"], "got wrong id for negative action")
                }
            }
        }
    }
}
