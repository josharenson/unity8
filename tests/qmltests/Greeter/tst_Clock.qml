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
import "../../../Greeter"
import Ubuntu.Components 0.1
import QMenuModel 0.1
import Unity.Test 0.1 as UT

Rectangle {
    width: units.gu(60)
    height: units.gu(40)
    color: "black"

    Clock {
        id: clock
        anchors {
            top: parent.top
            topMargin: units.gu(2)
            horizontalCenter: parent.horizontalCenter
        }
    }

    UnityMenuModel {
        id: menuModel
    }

    SignalSpy {
        id: updateSpy
        target: clock
        signalName: "currentDateChanged"
    }

    UT.UnityTestCase {
        name: "Clock"

        function init() {
            var cachedModel = findChild(clock, "timeModel");
            verify(cachedModel !== undefined);
            cachedModel.model = menuModel;
            var state = findInvisibleChild(clock, "timeState");
            state.rightLabel = "foo";
        }

        function cleanup() {
            var state = findInvisibleChild(clock, "timeState");
            state.rightLabel = "foo";

            updateSpy.clear();
        }

        function test_customDate() {
            var dateObj = new Date("October 13, 1975 11:13:00");
            var dateString = Qt.formatDate(dateObj, Qt.DefaultLocaleLongDate);
            var timeString = Qt.formatTime(dateObj);

            var state = findInvisibleChild(clock, "timeState");
            state.rightLabel = "bar";
            state.updated();
            clock.currentDate = dateObj;
            var dateLabel = findChild(clock, "dateLabel");
            compare(dateLabel.text, dateString, "Not the expected date");
            var timeLabel = findChild(clock, "timeLabel");
            compare(timeLabel.text, timeString, "Not the expected time");
        }

        function test_dateUpdate() {
            var dateObj = new Date("October 13, 1975 11:13:00")
            var dateString = Qt.formatDate(dateObj, Qt.DefaultLocaleLongDate);
            var timeString = Qt.formatTime(dateObj);

            clock.enabled = false;
            var timeModel = findInvisibleChild(clock, "timeModel");

            compare(timeModel.menuObjectPath, "", "Clock shouldn't be connected to Indicators when not active.");

            var state = findInvisibleChild(clock, "timeState");
            state.updated();
            state.rightLabel = "bar";
            clock.currentDate = dateObj;

            var dateLabel = findChild(clock, "dateLabel");
            compare(dateLabel.text, dateString, "Not the expected date");
            var timeLabel = findChild(clock, "timeLabel");
            compare(timeLabel.text, timeString, "Not the expected time");

            clock.enabled = true;

            verify(timeModel.menuObjectPath != "", "Should be connected to Indicators.");
        }

        function test_triggerUpdate() {
            var state = findInvisibleChild(clock, "timeState");
            state.updated();

            updateSpy.wait();
        }

        function test_currentTime() {
            var state = findInvisibleChild(clock, "timeState");
            state.rightLabel = "bar";
            state.updated();

            var dateObj = clock.currentDate;
            var dateString = Qt.formatDate(dateObj, Qt.DefaultLocaleLongDate);
            var timeString = Qt.formatTime(dateObj);

            var dateLabel = findChild(clock, "dateLabel");
            compare(dateLabel.text, dateString, "Not the expected date");
            var timeLabel = findChild(clock, "timeLabel");
            compare(timeLabel.text, timeString, "Not the expected time");
        }
    }
}
