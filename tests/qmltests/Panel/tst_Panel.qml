/*
 * Copyright 2013, 2014 Canonical Ltd.
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

/*
  This tests the Panel component using a fake model to stage data in the indicators
  A view will show with indicators at the top, as does in the shell. This can be controlled
  as in the shell.
*/
Item {
    id: shell
    width: units.gu(40)
    height: units.gu(80)

    property bool searchClicked: false

    Connections {
        target: panel
        onSearchClicked: searchClicked = true
    }

    Panel {
        id: panel
        anchors.fill: parent

        indicators {
            profile: "test1"
        }
    }

    UT.UnityTestCase {
        name: "Panel"
        when: windowShown

        function get_window_data() {
            return [
                {tag: "pinned", fullscreenFlag: false, alreadyOpen: false },
                {tag: "fullscreen", fullscreenFlag: true, alreadyOpen: false },
                {tag: "pinned-alreadyOpen", fullscreenFlag: false, alreadyOpen: true },
                {tag: "fullscreen-alreadyOpen", fullscreenFlag: true, alreadyOpen: true }
            ];
        }

        function init() {
            panel.indicators.initialise();

            searchClicked = false;
            panel.indicators.hide();
            tryCompare(panel.indicators.hideAnimation, "running", false);
            tryCompare(panel.indicators, "state", "initial");
        }

        function get_indicator_item(index) {
            var indicatorRow = findChild(panel.indicators, "indicatorRow");
            verify(indicatorRow !== null);

            return findChild(indicatorRow.row, "item" + index);
        }

        function get_indicator_item_position(index) {
            var indicatorRow = findChild(panel.indicators, "indicatorRow");
            verify(indicatorRow !== null);

            var indicatorItem = get_indicator_item(index);
            verify(indicatorItem !== null);

            return panel.mapFromItem(indicatorItem, indicatorItem.width/2, indicatorItem.height/2);
        }

        // Pressing on the indicator panel should activate the indicator hints
        // and expose a portion of the conent.
        function test_hint() {
            panel.fullscreenMode = false;
            // Wait for the indicators to get into position.
            // (switches between normal and fullscreen modes are animated)
            tryCompare(panel.indicators, "y", 0);

            var indicatorItemCoord = get_indicator_item_position(0);

            touchPress(panel, indicatorItemCoord.x, panel.panelHeight / 2);

            // hint animation should be run, meaning that indicators will move downwards
            // by hintValue pixels without any drag taking place
            tryCompare(panel.indicators, "height",
                       panel.indicators.panelHeight + panel.indicators.hintValue);
            tryCompare(panel.indicators, "partiallyOpened", true);
            tryCompare(panel.indicators, "fullyOpened", false);

            touchRelease(panel, indicatorItemCoord.x, panel.panelHeight/2);
        }

        // Pressing on the top edge of the screen should have no effect if the panel
        // is hidden (!pinned), which is the case when a fullscreen app is being shown
        function test_noHintOnFullscreenMode() {
            panel.fullscreenMode = true;
            // Wait for the indicators to get into position.
            // (switches between normal and fullscreen modes are animated)
            tryCompare(panel.indicators, "y", -panel.panelHeight);

            var indicatorItemCoord = get_indicator_item_position(0);

            touchPress(panel, indicatorItemCoord.x, panel.panelHeight / 2);

            // Give some time for a hint animation to change things, if any
            wait(500);

            // no hint animation when fullscreen
            compare(panel.indicators.y, -panel.panelHeight);
            var indicatorRow = findChild(panel.indicators, "indicatorRow");
            verify(indicatorRow !== null);
            compare(indicatorRow.y, 0);
            compare(panel.indicators.height, panel.indicators.panelHeight);
            compare(panel.indicators.partiallyOpened, false,
                    "Indicator should not be partially opened when panel is pressed in" +
                    " fullscreenmode");
            compare(panel.indicators.fullyOpened, false, "Indicator should not be partially" +
                   " opened when panel is pressed in fullscreenmode");

            touchRelease(panel, indicatorItemCoord.x, panel.panelHeight/2);
        }

        function test_drag_show_data() { return get_window_data(); }

        // Dragging from a indicator item in the panel will gradually expose the
        // indicators, first by running the hint animation, then after dragging down will
        // expose more of the panel, binding it to the selected indicator and opening it's menu.
        function test_drag_show(data) {
            panel.fullscreenMode = data.fullscreenFlag;
            if (data.alreadyOpen) {
                panel.indicators.show();
                tryCompare(panel.indicators, "fullyOpened", true);
            }

           var indicatorRow = findChild(panel.indicators, "indicatorRow");
            verify(indicatorRow !== null);

            var menuContent = findChild(panel.indicators, "menuContent");
            verify(indicatorRow !== null);

            var menuContent = findChild(panel.indicators, "menuContent");
            verify(indicatorRow !== null);

            // Wait for the indicators to get into position.
            // (switches between normal and fullscreen modes are animated)
            if (data.fullscreenFlag) {
                tryCompare(panel.indicators, "y", -panel.panelHeight);
            } else {
                tryCompare(panel.indicators, "y", 0);
            }

            // do this for each indicator item
            for (var i = 0; i < indicatorRow.row.count; i++) {

                var indicatorItem = get_indicator_item(i);
                verify(indicatorItem !== null);

                if (!indicatorItem.visible)
                    continue;

                var indicatorItemCoord = get_indicator_item_position(i);

                touchPress(panel,
                           indicatorItemCoord.x, panel.panelHeight / 2);

                // 1) Drag the mouse down
                touchFlick(panel,
                           indicatorItemCoord.x, panel.panelHeight / 2,
                           indicatorItemCoord.x, panel.height * 0.8,
                           false /* beginTouch */, false /* endTouch */, units.gu(10), 20);

                // Indicators height should follow the drag, and therefore increase accordingly.
                // They should be at least half-way through the screen
                tryCompareFunction(
                    function() {return panel.indicators.height >= panel.height * 0.5},
                    true);

                touchRelease(panel, indicatorItemCoord.x, panel.height * 0.8);

                compare(indicatorRow.currentItem, indicatorItem,
                        "Incorrect item activated at position " + i);
                compare(menuContent.currentMenuIndex, i, "Menu conetent should be enabled for item at position " + i);

                // init for next indicatorItem
                if (!data.alreadyOpen) {
                    init();
                }
            }
        }

        function test_search_click_when_visible() {
            panel.fullscreenMode = false;
            panel.searchVisible = true;

            var searchIndicator = findChild(panel, "search");
            verify(searchIndicator !== null);

            tap(searchIndicator, 1, 1);

            compare(searchClicked, true,
                    "Tapping search indicator while it was enabled did not emit searchClicked signal");
        }

        function test_search_click_when_not_visible() {
            panel.fullscreenMode = false;
            panel.searchVisible = false;

            var searchIndicator = findChild(panel, "search");
            verify(searchIndicator !== null);

            tap(searchIndicator, 1, 1);

            compare(searchClicked, false,
                    "Tapping search indicator while it was not visible emitted searchClicked signal");
        }

        // Test the vertical velocity check when flicking the indicators open at an angle.
        // If the vertical velocity is above a specific point, we shouldnt change active indicators
        // if the x position changes
        function test_vertical_velocity_detector() {
            panel.fullscreenMode = false;
            panel.searchVisible = false;

            var indicatorRow = findChild(panel.indicators, "indicatorRow");
            verify(indicatorRow !== null);

            // Get the first indicator
            var indicatorItemFirst = get_indicator_item(0);
            verify(indicatorItemFirst !== null);

            var indicatorItemCoordFirst = get_indicator_item_position(0);
            var indicatorItemCoordNext = get_indicator_item_position(indicatorRow.row.count - 1);

            touchPress(panel,
                       indicatorItemCoordFirst.x, panel.panelHeight / 2);

            // 1) Drag the mouse down to hint a bit
            touchFlick(panel,
                       indicatorItemCoordFirst.x, panel.panelHeight / 2,
                       indicatorItemCoordFirst.x, panel.panelHeight * 2,
                       false /* beginTouch */, false /* endTouch */, units.gu(10), 20);

            tryCompare(indicatorRow, "currentItem", indicatorItemFirst)

            // 1) Flick mouse down to bottom
            touchFlick(panel,
                       indicatorItemCoordFirst.x, panel.panelHeight * 2,
                       indicatorItemCoordNext.x, panel.height,
                       false /* beginTouch */, true /* endTouch */,
                       units.gu(10) /* speed */, 30 /* iterations */); // more samples needed for accurate velocity

            compare(indicatorRow.currentItem, indicatorItemFirst, "First indicator should still be the current item");
        }

        function test_hideIndicatorMenu_data() {
            return [ {tag: "no-delay", delay: undefined },
                     {tag: "delayed", delay: 200 }
            ];
        }

        function test_hideIndicatorMenu(data) {
            panel.indicators.show();
            compare(panel.indicators.shown, true);

            panel.hideIndicatorMenu(data.delay);
            tryCompare(panel.indicators, "shown", false);
        }
    }
}
