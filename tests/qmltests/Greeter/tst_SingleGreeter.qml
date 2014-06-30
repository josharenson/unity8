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
import ".."
import "../../../qml/Greeter"
import AccountsService 0.1
import LightDM 0.1 as LightDM
import Ubuntu.Components 0.1
import Unity.Test 0.1 as UT

Item {
    width: units.gu(60)
    height: units.gu(80)

    Greeter {
        id: greeter
        width: parent.width
        height: parent.height
        x: 0; y: 0

        property int minX: 0

        onXChanged: {
            if (x < minX) {
                minX = x;
            }
        }
    }

    Component {
        id: greeterComponent
        Greeter {
            SignalSpy {
                objectName: "selectedSpy"
                target: parent
                signalName: "selected"
            }
        }
    }

    SignalSpy {
        id: unlockSpy
        target: greeter
        signalName: "unlocked"
    }

    SignalSpy {
        id: teaseSpy
        target: greeter
        signalName: "tease"
    }

    SignalSpy {
        id: triggeredSpy
        signalName: "triggered"
    }

    UT.UnityTestCase {
        name: "SingleGreeter"
        when: windowShown

        property var infographics: findChild(greeter, "infographics")

        function cleanup() {
            AccountsService.statsWelcomeScreen = true
        }

        function test_properties() {
            compare(greeter.multiUser, false)
            compare(greeter.narrowMode, true)
        }

        function test_teasingArea_data() {
            return [
                {tag: "left", posX: units.gu(2), leftPressed: true, rightPressed: false},
                {tag: "right", posX: greeter.width - units.gu(2), leftPressed: false, rightPressed: true}
            ]
        }

        function test_teasingArea(data) {
            teaseSpy.clear()
            mouseClick(greeter, data.posX, greeter.height - units.gu(1))
            teaseSpy.wait()
            tryCompare(teaseSpy, "count", 1)
        }

        function test_infographics_integration() {
            triggeredSpy.target = infographics;
            triggeredSpy.clear();

            teaseSpy.clear();
            mouseClick(infographics, infographics.width/2, infographics.height/2);
            compare(triggeredSpy.count, 0);
            teaseSpy.wait();

            mouseDoubleClick(infographics, infographics.width/2, infographics.height/2);
            triggeredSpy.wait();

            // FIXME Cimi: the doubleclick seems to screw the dragHandle... the next click is ignored
            mouseClick(infographics, infographics.width/2, infographics.height/2);
        }

        function test_initial_selected_signal() {
            var greeterObj = greeterComponent.createObject(this)
            var spy = findChild(greeterObj, "selectedSpy")
            spy.wait()
            tryCompare(spy, "count", 1)
            greeterObj.destroy()
        }
    }
}
