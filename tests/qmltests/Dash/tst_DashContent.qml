﻿/*
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
import "../../../Dash"
import Ubuntu.Components 0.1
import Unity 0.1
import Unity.Test 0.1 as UT

Item {
    id: shell
    width: units.gu(40)
    height: units.gu(80)

    property ListModel searchHistory: ListModel {}

    property var scopeStatus: {
        'MockScope1': { 'movementStarted': 0, 'positionedAtBeginning': 0 },
        'MockScope2': { 'movementStarted': 0, 'positionedAtBeginning': 0 },
        'home.scope': { 'movementStarted': 0, 'positionedAtBeginning': 0 },
        'applications.scope': { 'movementStarted': 0, 'positionedAtBeginning': 0 },
        'MockScope5': { 'movementStarted': 0, 'positionedAtBeginning': 0 }
    }

    Scopes {
        id: scopesModel
    }

    DashContent {
        id: dashContent
        anchors.fill: parent

        model: scopesModel
        scopes : scopesModel

        scopeMapper : scopeDelegateMapper
    }

    ScopeDelegateMapper {
        id: scopeDelegateMapper
        scopeDelegateMapping: {
            "MockScope1": "../tests/qmltests/Dash/qml/fake_scopeView1.qml",
            "MockScope2": "../tests/qmltests/Dash/qml/fake_scopeView2.qml",
            "home.scope": "../tests/qmltests/Dash/qml/fake_scopeView3.qml",
            "applications.scope": "../tests/qmltests/Dash/qml/fake_scopeView4.qml"
        }
        genericScope: "../tests/qmltests/Dash/qml/fake_generic_scopeView.qml"
    }

    function clear_scope_status() {
        scopeStatus["MockScope1"].movementStarted = 0;
        scopeStatus["MockScope1"].positionedAtBeginning = 0;

        scopeStatus["MockScope2"].movementStarted = 0;
        scopeStatus["MockScope2"].positionedAtBeginning = 0;

        scopeStatus["home.scope"].movementStarted = 0;
        scopeStatus["home.scope"].positionedAtBeginning = 0;

        scopeStatus["applications.scope"].movementStarted = 0;
        scopeStatus["applications.scope"].positionedAtBeginning = 0;

        scopeStatus["MockScope5"].movementStarted = 0;
        scopeStatus["MockScope5"].positionedAtBeginning = 0;
    }

    SignalSpy {
        id: scopeLoadedSpy
        target: dashContent
        signalName: "scopeLoaded"
    }

    SignalSpy {
        id: movementStartedSpy
        target: dashContent
        signalName: "movementStarted"
    }

    SignalSpy {
        id: contentEndReachedSpy
        target: dashContent
        signalName: "contentEndReached"
    }

    UT.UnityTestCase {
        name: "DashContent"
        when: windowShown

        function init() {
            scopeLoadedSpy.clear();
            movementStartedSpy.clear();
            contentEndReachedSpy.clear()
            clear_scope_status();

            // clear, wait for dahs to empty and load scopes.
            var dashContentList = findChild(dashContent, "dashContentList");
            verify(dashContentList != undefined)
            scopesModel.clear();
            tryCompare(dashContentList, "count", 0);
            scopesModel.load();
        }

        function test_movement_started_signal() {
            dashContent.setCurrentScopeAtIndex(3, true, false);

            var dashContentList = findChild(dashContent, "dashContentList");
            verify(dashContentList != undefined)

            tryCompare(scopeLoadedSpy, "count", 5);

            dashContentList.movementStarted();

            compare(movementStartedSpy.count, 1, "DashContent should have emitted movementStarted signal when content list did.");
            compare(scopeStatus["MockScope1"].movementStarted, 1, "MockScope1 should have emitted movementStarted signal when content list did.");
            compare(scopeStatus["MockScope2"].movementStarted, 1, "MockScope2 should have emitted movementStarted signal when content list did.");
            compare(scopeStatus["home.scope"].movementStarted, 1, "home.scope should have emitted movementStarted signal when content list did.");
            compare(scopeStatus["applications.scope"].movementStarted, 1, "applications.scope should have emitted movementStarted signal when content list did.");
            compare(scopeStatus["MockScope5"].movementStarted, 1, "MockScope5 should have emitted movementStarted signal when content list did.");
        }

        function test_positioned_at_beginning_signal() {
            dashContent.setCurrentScopeAtIndex(3, true, false);

            tryCompare(scopeLoadedSpy, "count", 5);

            dashContent.positionedAtBeginning();
            compare(scopeStatus["MockScope1"].positionedAtBeginning, 1, "MockScope1 should have emitted positionedAtBeginning signal when DashContent did.");
            compare(scopeStatus["MockScope2"].positionedAtBeginning, 1, "MockScope2 should have emitted positionedAtBeginning signal when DashContent did.");
            compare(scopeStatus["home.scope"].positionedAtBeginning, 1, "home.scope should have emitted positionedAtBeginning signal when DashContent did.");
            compare(scopeStatus["applications.scope"].positionedAtBeginning, 1, "applications.scope should have emitted positionedAtBeginning signal when DashContent did.");
            compare(scopeStatus["MockScope5"].positionedAtBeginning, 1, "MockScope5 should have emitted positionedAtBeginning signal when DashContent did.");
        }

        function test_scope_loaded() {
            tryCompare(scopeLoadedSpy, "count", 5);
        }

        function test_content_end_reached() {
            var dashContentList = findChild(dashContent, "dashContentList");
            verify(dashContentList != undefined);

            tryCompare(scopeLoadedSpy, "count", 5);
            dashContent.setCurrentScopeAtIndex(0, true, false);
            dashContentList.currentItem.item.endReached();

            compare(contentEndReachedSpy.count, 1);
        }

        // This tests that setting the current scope index will end up at the correct index even if
        // the scopes are loaded asynchrounsly.
        function test_set_current_scope_index_async() {
            verify(scopesModel.loaded == false);

            // next index is 1 if current is -1, otherwise it's current + 1
            var next_index = ((dashContent.currentIndex == -1 ? 0 : dashContent.currentIndex) + 1) % 5

            dashContent.setCurrentScopeAtIndex(next_index, true, false);
            tryCompare(dashContent, "currentIndex", next_index);
            verify(scopesModel.loaded == true);

            // test greater than scope count.
            var currentScopeIndex = dashContent.currentIndex;
            dashContent.setCurrentScopeAtIndex(scopesModel.count, true, false);
            compare(dashContent.currentIndex, currentScopeIndex, "Scope should not change if changing to greater index than count");
        }

        function get_current_item_object_name() {
            var dashContentList = findChild(dashContent, "dashContentList");
            verify(dashContentList != undefined);

            if (dashContentList.currentItem != undefined) {
                if (dashContentList.currentItem.item != undefined)
                    return dashContentList.currentItem.item.objectName;
            }

            return "";
        }

        function test_scope_mapping_data() {
            return [
                {tag: "index0", index: 0, objectName: "fake_scopeView1"},
                {tag: "index1", index: 1, objectName: "fake_scopeView2"},
                {tag: "index2", index: 2, objectName: "fake_scopeView3"},
                {tag: "index3", index: 3, objectName: "fake_scopeView4"},
                {tag: "index4", index: 4, objectName: "fake_generic_scopeView"}
            ]
        }

        function test_scope_mapping(data) {
            dashContent.setCurrentScopeAtIndex(data.index, true, false);
            tryCompareFunction(get_current_item_object_name, data.objectName)
        }

    }
}
