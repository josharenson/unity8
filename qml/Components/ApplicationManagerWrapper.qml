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
import Unity.Application 0.1

Item {
    id: root

    property alias mainStageApplications: mainStageModel
    property alias sideStageApplications: sideStageModel
    property variant mainStageFocusedApplication: null
    property variant sideStageFocusedApplication: null
    property bool sideStageEnabled: true
    property bool keyboardVisible: ApplicationManager.keyboardVisible
    property int keyboardHeight: ApplicationManager.keyboardHeight

    property bool fake: ApplicationManager.fake ? ApplicationManager.fake : false

    signal focusRequested(string appId)

    ApplicationsModelStageFiltered {
        id: mainStageModel
        stage: ApplicationInfo.MainStage
    }

    ApplicationsModelStageFiltered {
        id: sideStageModel
        stage: ApplicationInfo.SideStage
    }

    Connections {
        target: ApplicationManager
        onFocusedApplicationIdChanged: {
            var app = ApplicationManager.findApplication(ApplicationManager.focusedApplicationId)
            if (!app) { //nothing at all focused, so clear all
                mainStageFocusedApplication = null;
                sideStageFocusedApplication = null;
            } else {
                if (app.stage == ApplicationInfo.MainStage) {
                    mainStageFocusedApplication = app;
                    // possible the side stage app being unfocused fired this signal, so check for it
                    if (sideStageFocusedApplication && !sideStageFocusedApplication.focused)
                        sideStageFocusedApplication = null;
                } else {
                    sideStageFocusedApplication = app;
                    // possible the main stage app being unfocused fired this signal, so check for it
                    if (mainStageFocusedApplication && !mainStageFocusedApplication.focused)
                        mainStageFocusedApplication = null;
                }
            }
        }

        onFocusRequested: {
            // if no side stage enabled, override application's stage parameter
            var app = ApplicationManager.findApplication(appId);
            if (app && app.stage === ApplicationInfo.SideStage && !sideStageEnabled) {
                app.stage = ApplicationInfo.MainStage;
            }

            root.focusRequested(appId);
        }
    }

    function activateApplication(desktopFile, argument) {
        var appId;

        // HACK: Applications identified sometimes with with appId, but mostly with desktopFile.
        // TODO: convert entire shell to use appId only.
        if (desktopFile.indexOf(".desktop") >= 0) {
            appId = desktopFileToAppId(desktopFile);
        } else {
            appId = desktopFile;
        }

        var application = ApplicationManager.findApplication(appId);
        if (application !== null) {
            return application;
        }

        var execFlags = sideStageEnabled ? ApplicationManager.NoFlag : ApplicationManager.ForceMainStage;

        if (argument) {
            return ApplicationManager.startApplication(appId, execFlags, [argument]);
        } else {
            return ApplicationManager.startApplication(appId, execFlags);
        }
    }

    function stopApplication(application) {
        var appId;

        // HACK: Applications identified sometimes with with appId, but mostly with desktopFile.
        // TODO: convert entire shell to use appId only.
        if (typeof application == "string") {
            appId = application;
        } else {
            appId = desktopFileToAppId(application.desktopFile);
        }

        ApplicationManager.stopApplication(appId);
    }

    function focusApplication(application) {
        if (application == null || application == undefined) {
            return;
        }

        ApplicationManager.focusApplication(application.appId);
    }

    function unfocusCurrentApplication() {
        ApplicationManager.unfocusCurrentApplication();
        mainStageFocusedApplication = null;
        sideStageFocusedApplication = null;
    }

    function moveRunningApplicationStackPosition(from, to, stage) {
        if (from == to || from < 0 || to < 0) return;

        if (stage == ApplicationInfo.SideStage) {
            sideStageModel.move(from, to);
        } else {
            mainStageModel.move(from, to);
        }
    }

    function getApplicationFromDesktopFile(desktopFile, stage) {
        var appId;

        // HACK: Applications identified sometimes with with appId, but mostly with desktopFile.
        // TODO: convert entire shell to use appId only.
        if (desktopFile.indexOf(".desktop") >= 0) {
            appId = desktopFileToAppId(desktopFile);
        } else {
            appId = desktopFile;
        }

        for (var i = 0, len = ApplicationManager.count; i < len; i++ ) {
            var app = ApplicationManager.get(i);

            // if stage not specified, return whichever app running on either stage
            if (app.appId == appId && (stage == undefined || app.stage == stage)) {
                return app;
            }
        }
    }

    function desktopFileToAppId(desktopFile) {
        var right = desktopFile.lastIndexOf(".desktop");
        var left = desktopFile.lastIndexOf("/");
        if (left == -1 || right == -1 || left == right) {
            console.log("ApplicationManagerWrapper: unable to extract appId from '" + desktopFile + "'");
            return "";
        }
        return desktopFile.substring(left+1, right);
    }
}
