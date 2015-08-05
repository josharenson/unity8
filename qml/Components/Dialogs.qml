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

import QtQuick 2.0
import QtQuick.Layouts 1.1

import Unity.Application 0.1
import Unity.Session 0.1
import Ubuntu.Components 1.1
import LightDM 0.1 as LightDM

Item {
    id: root

    // to be set from outside, useful mostly for testing purposes
    property var unitySessionService: DBusUnitySessionService
    property var closeAllApps: function() {
        while (true) {
            var app = ApplicationManager.get(0);
            if (app === null) {
                break;
            }
            ApplicationManager.stopApplication(app.appId);
        }
    }

    signal powerOffClicked();

    function showPowerDialog() {
        d.showPowerDialog();
    }

    QtObject {
        id: d // private stuff
        objectName: "dialogsPrivate"


        function showPowerDialog() {
            if (!dialogLoader.active) {
                dialogLoader.sourceComponent = powerDialogComponent;
                dialogLoader.active = true;
                dialogLoader.item.forceActiveFocus();
            }
        }
    }
    Loader {
        id: dialogLoader
        objectName: "dialogLoader"
        anchors.fill: parent
        active: false
    }

    Component {
        id: logoutDialogComponent
        ShellDialog {
            id: logoutDialog
            title: i18n.ctr("Title: Lock/Log out dialog", "Log out")
            text: i18n.tr("Are you sure you want to log out?")
            Button {
                text: i18n.ctr("Button: Lock the system", "Lock")
                onClicked: {
                    LightDM.Greeter.showGreeter()
                    logoutDialog.hide();
                }
            }
            Button {
                text: i18n.ctr("Button: Log out from the system", "Log Out")
                onClicked: {
                    unitySessionService.logout();
                    logoutDialog.hide();
                }
            }
            Button {
                text: i18n.tr("Cancel")
                onClicked: {
                    logoutDialog.hide();
                }
            }
        }
    }

    Component {
        id: shutdownDialogComponent
        ShellDialog {
            id: shutdownDialog
            title: i18n.ctr("Title: Reboot/Shut down dialog", "Shut down")
            text: i18n.tr("Are you sure you want to shut down?")
            Button {
                text: i18n.ctr("Button: Reboot the system", "Reboot")
                onClicked: {
                    root.closeAllApps();
                    unitySessionService.reboot();
                    shutdownDialog.hide();
                }
            }
            Button {
                text: i18n.ctr("Button: Shut down the system", "Shut down")
                onClicked: {
                    root.closeAllApps();
                    unitySessionService.shutdown();
                    shutdownDialog.hide();
                }
            }
            Button {
                text: i18n.tr("Cancel")
                onClicked: {
                    shutdownDialog.hide();
                }
            }
        }
    }

    Component {
        id: rebootDialogComponent
        ShellDialog {
            id: rebootDialog
            title: i18n.ctr("Title: Reboot dialog", "Reboot")
            text: i18n.tr("Are you sure you want to reboot?")
            Button {
                text: i18n.tr("No")
                onClicked: {
                    rebootDialog.hide();
                }
            }
            Button {
                text: i18n.tr("Yes")
                onClicked: {
                    root.closeAllApps();
                    unitySessionService.reboot();
                    rebootDialog.hide();
                }
            }
        }
    }

    Component {
        id: powerDialogComponent
        ShellDialog {
            id: powerDialog
            Label {
                horizontalAlignment: Text.AlignLeft
                text: i18n.ctr("Title: Power off/Restart dialog", "Power")
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                fontSize: "large"
                color: UbuntuColors.darkGrey
                visible: (text !== "")
            }

            Label {
                horizontalAlignment: Text.AlignLeft
                text: i18n.tr("Are you sure you would like to power off?")
                fontSize: "medium"
                color: UbuntuColors.darkGrey
                wrapMode: Text.Wrap
                visible: (text !== "")
            }

            RowLayout {
                spacing: units.gu(2)

                Button {
                    Layout.fillWidth: true
                    text: i18n.ctr("Button: Power off the system", "Power off")
                    onClicked: {
                        root.closeAllApps();
                        powerDialog.hide();
                        root.powerOffClicked();
                    }
                    color: UbuntuColors.red
                }

                Button {
                    Layout.fillWidth: true
                    text: i18n.ctr("Button: Restart the system", "Restart")
                    onClicked: {
                        root.closeAllApps();
                        unitySessionService.reboot();
                        powerDialog.hide();
                    }
                    color: UbuntuColors.lightGrey
                }
            }

            Label {
                text: i18n.tr("Cancel")
                color: UbuntuColors.coolGrey
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        powerDialog.hide();
                    }
                }
            }
        }
    }

    Connections {
        target: root.unitySessionService

        onLogoutRequested: {
            // Display a dialog to ask the user to confirm.
            if (!dialogLoader.active) {
                dialogLoader.sourceComponent = logoutDialogComponent;
                dialogLoader.active = true;
            }
        }

        onShutdownRequested: {
            // Display a dialog to ask the user to confirm.
            if (!dialogLoader.active) {
                dialogLoader.sourceComponent = shutdownDialogComponent;
                dialogLoader.active = true;
            }
        }

        onRebootRequested: {
            // Display a dialog to ask the user to confirm.
            if (!dialogLoader.active) {
                dialogLoader.sourceComponent = rebootDialogComponent;
                dialogLoader.active = true;
            }
        }

        onLogoutReady: {
            root.closeAllApps();
            Qt.quit();
            unitySessionService.endSession();
        }
    }

}
