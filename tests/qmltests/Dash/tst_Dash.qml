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
import "../../../qml/Dash"
import Ubuntu.Components 0.1
import Unity.Test 0.1 as UT

// TODO We don't have any tests for the overlay scope functionality.

Item {
    id: shell
    width: units.gu(40)
    height: units.gu(80)

    // BEGIN To reduce warnings
    // TODO I think it we should pass down these variables
    // as needed instead of hoping they will be globally around
    property var greeter: null
    property var panel: null
    // BEGIN To reduce warnings


    Dash {
        id: dash
        anchors.fill: parent
        showScopeOnLoaded: "MockScope2"
    }

    UT.UnityTestCase {
        name: "Dash"
        when: windowShown

        readonly property Item dashContent: findChild(dash, "dashContent");
        readonly property var scopes: dashContent.scopes

        function init() {
            // clear and reload the scopes.
            scopes.clear();
            var dashContentList = findChild(dash, "dashContentList");
            verify(dashContentList != undefined);
            tryCompare(dashContentList, "count", 0);
            scopes.load();
            tryCompare(dashContentList, "currentIndex", 0);
        }

        function get_scope_data() {
            return [
                        { tag: "MockScope1", visualIndex: 0 },
                        { tag: "MockScope2", visualIndex: 1 },
                        { tag: "clickscope", visualIndex: 2 },
                        { tag: "MockScope5", visualIndex: 3 },
            ]
        }

        function test_show_scope_on_load_data() {
            return get_scope_data()
        }

        function test_show_scope_on_load(data) {
            var dashContentList = findChild(dash, "dashContentList");

            dash.showScopeOnLoaded = data.tag
            scopes.clear();
            tryCompare(dashContentList, "count", 0);
            scopes.load();
            tryCompare(scopes, "loaded", true);
            tryCompare(dashContentList, "count", 5);

            verify(dashContentList != undefined);
            tryCompare(dashContentList, "currentIndex", data.visualIndex);
        }

        function test_setCurrentScope() {
            var dashContentList = findChild(dash, "dashContentList");
            var startX = dash.width - units.gu(1);
            var startY = dash.height / 2;
            var stopX = units.gu(1)
            var stopY = startY;
            var retry = 0;
            while (dashContentList.currentIndex != 2 && retry <= 5) {
                mouseFlick(dash, startX, startY, stopX, stopY)
                waitForRendering(dashContentList)
                retry++;
            }
            compare(dashContentList.currentIndex, 2);
            var dashCommunicatorService = findInvisibleChild(dash, "dashCommunicatorService");
            dashCommunicatorService.mockSetCurrentScope("clickscope", true, true);
            tryCompare(dashContentList, "currentIndex", 1)
        }

        function test_processing_indicator() {
            tryCompare(scopes, "loaded", true);

            var processingIndicator = findChild(dash, "processingIndicator");
            verify(processingIndicator, "Can't find the processing indicator.");

            verify(!processingIndicator.visible, "Processing indicator should be visible.");

            tryCompareFunction(function() {
                return scopes.getScope(dashContent.currentIndex) != null;
            }, true);
            var currentScope = scopes.getScope(dashContent.currentIndex);
            verify(currentScope, "Can't find the current scope.");

            currentScope.setSearchInProgress(true);
            tryCompare(processingIndicator, "visible", true);

            currentScope.setSearchInProgress(false);
            tryCompare(processingIndicator, "visible", false);
        }
    }
}
