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
import Unity.Test 0.1 as UT
import ".."
import "../../../qml/Panel"
import "../../../qml/Components"

/*
  This tests the Indicators component by using a fake model to stage data in the indicators
  A view will show with indicators at the top, as does in the shell. There is a clickable area
  marked "Click Me" which can be used to expose the indicators.
*/
Item {
    id: shell
    width: units.gu(40)
    height: units.gu(80)

    PanelBackground {
        anchors.fill: indicators
    }

    Indicators {
        id: indicators
        anchors {
            right: parent.right
        }
        width: (shell.width > units.gu(60)) ? units.gu(40) : shell.width
        y: 0
        shown: false

        openedHeight: parent.height - click_me.height
    }

    // Just a rect for clicking to open the indicators.
    Rectangle {
        id: click_me
        color: "red"
        anchors {
            bottom: shell.bottom
            left: parent.left
            right: parent.right
        }
        height: 50

        Text {
            text: "Click Me"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.fill: parent

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    if (!indicators.shown) {
                        indicators.show();
                    } else {
                        indicators.hide();
                    }
                }
            }
        }
    }

    UT.UnityTestCase {
        name: "Indicators"
        when: windowShown

        function init() {
            indicators.initialise();

            indicators.hide();
            tryCompare(indicators.hideAnimation, "running", false);
            tryCompare(indicators, "state", "initial");
        }

        // Showing the indicators should fully open the indicator panel.
        function test_show() {
            indicators.show()
            tryCompare(indicators, "fullyOpened", true);
        }

        // Test the change in the revealer lateral position changes the current panel menu to fit the position
        // of the indicator in the row.
        function test_change_revealer_lateral_position()
        {
            // tests changing the lateral position of the revealer activates the correct indicator items.

            var indicatorRow = findChild(indicators, "indicatorRow")
            var rowRepeater = findChild(indicators, "rowRepeater")

            for (var i = 0; i < rowRepeater.count; i++) {
                var indicatorItem = rowRepeater.itemAt(i);

                if (!indicatorItem.visible)
                    continue;

                var indicatorPosition = indicators.mapFromItem(indicatorItem,
                        indicatorItem.width/2, indicatorItem.height/2)

                touchFlick(indicators,
                           indicatorPosition.x, indicatorPosition.y,
                           indicatorPosition.x, indicators.openedHeight * 0.4,
                           true /* beginTouch */, false /* endTouch */)

                compare(indicatorRow.currentItem, indicatorItem,
                        "Incorrect item activated at position " + i);

                touchFlick(indicators,
                           indicatorPosition.x, indicators.openedHeight * 0.4,
                           indicatorPosition.x, indicatorPosition.y,
                           false /* beginTouch */, true /* endTouch */)

                // wait until fully closed
                tryCompare(indicators, "height", indicators.panelHeight)
            }
        }

        // values for specific state changes are subject to internal decisions, so we can't
        // determine the true height value which would cause the state to change without making
        // too many assuptyions
        // However, we can assume that a partially opened panel will not be initial, and fully
        // opened panel will be locked.

        function test_progress_changes_state_to_not_initial() {
            indicators.height = indicators.openedHeight / 2
            compare(indicators.state!="initial", true,
                    "Indicators should not be in initial state when partially opened.")
        }

        function test_progress_changes_state_to_locked() {
            indicators.height = indicators.openedHeight - indicators.panelHeight
            compare(indicators.state, "locked", "Indicators should be locked when fully opened.")
        }

        function test_partially_open() {
            indicators.height = indicators.openedHeight / 2
            compare(indicators.partiallyOpened, true,
                    "Indicator should show as partially opened when height is half of openedHeight")
            compare(indicators.fullyOpened, false,
                    "Indicator should not show as fully opened when height is half of openedHeight")
        }

        function test_fully_open() {
            indicators.height = indicators.openedHeight
            compare(indicators.partiallyOpened, false);
            compare(indicators.fullyOpened, true);
        }

        function init_invisible_indicator(identifier) {
            tryCompareFunction(function() { return findChild(indicators, identifier+"-widget") !== null }, true);
            var item = findChild(indicators, identifier+"-widget");

            item.enabled = false;
        }

        function test_row_visible_menuContent_visible_data() { return [
            {tag: "first", visible: [false, true, true, true, true] },
            {tag: "adjacent", visible: [true, false, false, true, true] },
            {tag: "bounds", visible: [false, true, true, true, false] },
            {tag: "disjoint", visible: [true, false, true, false, true] },
            {tag: "last", visible: [true, true, true, true, false] }];
        }

        function test_row_visible_menuContent_visible(data) {

            indicators.show();

            var indicatorTabs = findChild(indicators, "tabs");
            var rowRepeater = findChild(indicators, "rowRepeater")


            for (var i = 0; i< data.visible.length; i++) {
                if (data.visible[i] === false)
                    init_invisible_indicator("indicator-fake" + (i + 1));
            }

            for (i = 0; i < data.visible.length; i++) {
                var shouldBeVisible = data.visible[i];

                // check item visibility
                var indicatorItem = rowRepeater.itemAt(i);
                tryCompare(indicatorItem, "visible", shouldBeVisible);
                // check tab visibility
                tryCompareFunction(function() { return findChild(indicatorTabs, "indicator-fake" + (i + 1)) !== null }, shouldBeVisible);
            }
        }

        function test_indicator_visible_correct_tabs_data() { return [
            {tag: "current-first", currentIndex: 0, visible: [false, true, true, true, true], expected: 1 },
            {tag: "current-last", currentIndex: 4, visible: [true, true, true, true, false], expected: 3 },
            {tag: "after", currentIndex: 0, visible: [true, false, true, true, true], expected: 0 },
            {tag: "before", currentIndex: 1, visible: [false, true, true, true, true], expected: 1 }];
        }

        function test_indicator_visible_correct_tabs(data) {

            var indicatorTabs = findChild(indicators, "tabs");
            var indicatorRow = findChild(indicators, "indicatorRow");

            indicators.show();
            indicatorRow.setCurrentItem(data.currentIndex);
            tryCompare(indicators, "fullyOpened", true);

            for (var i = 0; i< data.visible.length; i++) {
                if (data.visible[i] === false)
                    init_invisible_indicator("indicator-fake" + (i + 1));
            }

            // check for current selected item
            tryCompare(indicatorRow, "currentItemIndex", data.expected);
            // check for current selected tab
            tryCompareFunction(function() { return findChild(indicatorTabs, "indicator-fake" + (data.expected + 1)) === indicatorTabs.selectedTab }, true);
        }
    }
}
