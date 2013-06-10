/*
 * Copyright 2013 Canonical Ltd.
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
import Ubuntu.Application 0.1
import "../../../../Dash/Apps"
import Unity.Test 0.1 as UT

Item {
    width: units.gu(50)
    height: units.gu(40)

    QtObject {
        id: fakeApplicationManager

        property bool sideStageEnabled: false

        function stopProcess(application) {
            fakeRunningAppsModel.remove(application)
        }
    }

    QtObject {
        id: shell
        property bool dashShown: true
        property bool stageScreenshotsReady: false
        property var applicationManager: fakeApplicationManager

        function activateApplication(desktopFile) {
        }
    }

    ApplicationListModel { id: fakeRunningAppsModel }

    ApplicationInfo {
        id: phoneApp
        name: "Phone"
        icon: "phone-app"
        exec: "/usr/bin/phone-app"
        stage: ApplicationInfo.MainStage
        desktopFile: "phone.desktop"
        imageQml: "import QtQuick 2.0\n" +
                  "Rectangle { \n" +
                  "    anchors.fill:parent \n" +
                  "    color:'darkgreen' \n" +
                  "    Text { anchors.centerIn: parent; text: 'PHONE' } \n" +
                  "}"
    }

    ApplicationInfo {
        id: calendarApp
        name: "Calendar"
        icon: "calendar-app"
        exec: "/usr/bin/calendar-app"
        stage: ApplicationInfo.MainStage
        desktopFile: "calendar.desktop"
        imageQml: "import QtQuick 2.0\n" +
                  "Rectangle { \n" +
                  "    anchors.fill:parent \n" +
                  "    color:'darkblue' \n" +
                  "    Text { anchors.centerIn: parent; text: 'CALENDAR'\n" +
                  "           color:'white'} \n" +
                  "}"
    }

    function resetRunningApplications() {
        fakeRunningAppsModel.clear()
        fakeRunningAppsModel.add(phoneApp)
        fakeRunningAppsModel.add(calendarApp)
    }

    Component.onCompleted: {
        resetRunningApplications()
    }

    // The component under test
    RunningApplicationsGrid {
        id: runningApplicationsGrid
        anchors.fill: parent
        firstModel: fakeRunningAppsModel
    }

    UT.UnityTestCase {
        name: "RunningApplicationsGrid"
        when: windowShown

        function init() {
            runningApplicationsGrid.terminationModeEnabled = false
            resetRunningApplications()
        }

        property var calendarTile
        property var phoneTile

        property var isCalendarLongPressed: false
        function onCalendarLongPressed() {isCalendarLongPressed = true}

        property var isPhoneLongPressed: false
        function onPhoneLongPressed() {isPhoneLongPressed = true}

        // Tiles should go to termination mode when any one of them is long-pressed.
        // Long-pressing when they're in termination mode brings them back to activation mode
        function test_enterTerminationMode() {
            calendarTile = findChild(runningApplicationsGrid, "runningAppTile Calendar")
            verify(calendarTile != undefined)
            calendarTile.onPressAndHold.connect(onCalendarLongPressed)

            phoneTile = findChild(runningApplicationsGrid, "runningAppTile Phone")
            verify(phoneTile != undefined)
            phoneTile.onPressAndHold.connect(onPhoneLongPressed)

            compare(calendarTile.terminationModeEnabled, false)
            compare(phoneTile.terminationModeEnabled, false)
            compare(runningApplicationsGrid.terminationModeEnabled, false)

            isCalendarLongPressed = false
            waitForRendering(runningApplicationsGrid)
            mousePress(calendarTile, calendarTile.width/2, calendarTile.height/2)
            tryCompareFunction(checkSwitchToTerminationModeAfterLongPress, true)

            mouseRelease(calendarTile, calendarTile.width/2, calendarTile.height/2)

            compare(calendarTile.terminationModeEnabled, true)
            compare(phoneTile.terminationModeEnabled, true)
            compare(runningApplicationsGrid.terminationModeEnabled, true)

            isPhoneLongPressed = false
            mousePress(phoneTile, phoneTile.width/2, phoneTile.height/2)
            tryCompareFunction(checkSwitchToActivationModeAfterLongPress, true)

            mouseRelease(phoneTile, phoneTile.width/2, phoneTile.height/2)

            compare(calendarTile.terminationModeEnabled, false)
            compare(phoneTile.terminationModeEnabled, false)
            compare(runningApplicationsGrid.terminationModeEnabled, false)

            calendarTile.onPressAndHold.disconnect(onCalendarLongPressed)
            phoneTile.onPressAndHold.disconnect(onPhoneLongPressed)
        }

        // Checks that components swicth to termination mode after (and only after) a long
        // press happens on Calendar tile.
        function checkSwitchToTerminationModeAfterLongPress() {
            compare(calendarTile.terminationModeEnabled, isCalendarLongPressed)
            compare(phoneTile.terminationModeEnabled, isCalendarLongPressed)
            compare(runningApplicationsGrid.terminationModeEnabled, isCalendarLongPressed)

            return isCalendarLongPressed &&
                calendarTile.terminationModeEnabled &&
                phoneTile.terminationModeEnabled &&
                runningApplicationsGrid.terminationModeEnabled
        }

        // Checks that components swicth to activation mode after (and only after) a long
        // press happens on Phone tile.
        function checkSwitchToActivationModeAfterLongPress() {
            compare(calendarTile.terminationModeEnabled, !isPhoneLongPressed)
            compare(phoneTile.terminationModeEnabled, !isPhoneLongPressed)
            compare(runningApplicationsGrid.terminationModeEnabled, !isPhoneLongPressed)

            return isPhoneLongPressed &&
                !calendarTile.terminationModeEnabled &&
                !phoneTile.terminationModeEnabled &&
                !runningApplicationsGrid.terminationModeEnabled
        }

        // While on termination mode, clicking a running application tile causes the
        // corresponding application to be terminated.
        function test_clickTileToTerminateApp() {
            runningApplicationsGrid.terminationModeEnabled = true

            var calendarTile = findChild(runningApplicationsGrid, "runningAppTile Calendar")
            verify(calendarTile != undefined)

            verify(fakeRunningAppsModel.contains(calendarApp))
            waitForRendering(runningApplicationsGrid) //ensure populating animation has stopped

            mouseClick(calendarTile, calendarTile.width/2, calendarTile.height/2)

            verify(!fakeRunningAppsModel.contains(calendarApp))

            // The tile for the Calendar app should eventually vanish since the
            // application has been terminated
            tryCompareFunction(checkCalendarTileExists, false)
        }

        function checkCalendarTileExists() {
            return findChild(runningApplicationsGrid, "runningAppTile Calendar")
                    != undefined
        }
    }
}
