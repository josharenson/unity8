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
import "../../../qml/Dash"
import "../../../qml/Components"
import Ubuntu.Components 0.1
import Unity 0.2
import Unity.Test 0.1 as UT
import Utils 0.1

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

    Scopes {
        id: scopesModel
    }

    DashContent {
        id: dashContent
        anchors.fill: parent

        model: SortFilterProxyModel {
            model: scopesModel
        }
        scopes : scopesModel
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
        id: loadedSpy
        signalName: "loaded"
    }

    UT.UnityTestCase {
        name: "DashContent"
        when: scopesModel.loaded && windowShown

        function loadScopes() {
            scopeLoadedSpy.clear();
            scopesModel.load();
            tryCompare(scopeLoadedSpy, "count", 4);
        }

        function init() {
            scopesModel.clear();
            loadScopes();
        }

        function cleanup() {
            movementStartedSpy.clear();
            loadedSpy.clear();
            dashContent.visible = true;

            var dashContentList = findChild(dashContent, "dashContentList");
            verify(dashContentList != undefined);
            scopesModel.clear();
            // wait for dash to empty scopes.
            tryCompare(dashContentList, "count", 0);
        }

        function test_current_index() {
            var dashContentList = findChild(dashContent, "dashContentList");
            verify(dashContentList != undefined)

            scopesModel.clear();
            compare(dashContentList.count, 0, "DashContent should have 0 items when it starts");
            tryCompare(dashContentList, "currentIndex", -1);

            loadScopes();

            verify(dashContentList.currentIndex >= 0);
        }

        function test_current_index_after_reset() {
            var dashContentList = findChild(dashContent, "dashContentList");
            verify(dashContentList != undefined)

            scopesModel.clear();
            compare(dashContentList.count, 0, "DashContent should have 0 items after clearing");
            // pretend we're running after a model reset
            dashContentList.currentIndex = 27;

            loadScopes();

            verify(dashContentList.currentIndex >= 0 && dashContentList.currentIndex < 5);
        }

        function test_show_header_on_list_movement() {
            var dashContentList = findChild(dashContent, "dashContentList");
            verify(dashContentList !== null);
            var scope = findChild(dashContent, "MockScope1 loader");
            waitForRendering(scope);

            var categoryListView = findChild(scope, "categoryListView");
            waitForRendering(categoryListView);

            categoryListView.contentY = units.gu(15);
            tryCompare(categoryListView, "contentY", units.gu(15));

            var startX = dashContentList.width/2;
            var startY = dashContentList.height/2;
            touchFlick(dashContentList, startX - units.gu(2), startY, startX, startY);
            tryCompare(categoryListView, "contentY", units.gu(15) - categoryListView.pageHeader.height);
        }

        function test_set_current_scope_reset() {
            var dashContentList = findChild(dashContent, "dashContentList");
            verify(dashContentList, "Couldn't find dashContentList");
            var scope = findChild(dashContent, "MockScope1 loader");

            tryCompare(scope, "status", Loader.Ready);

            var categoryListView = findChild(dashContentList, "categoryListView");
            categoryListView.contentY = units.gu(10);

            compare(dashContentList.currentItem.item.objectName,  "MockScope1")
            compare(categoryListView.contentY, units.gu(10));

            dashContent.setCurrentScopeAtIndex(0, false, true);

            compare(dashContentList.currentItem.item.objectName,  "MockScope1")
            compare(categoryListView.contentY,  0);
        }

        // This tests that setting the current scope index will end up at the correct index even if
        // the scopes are loaded asynchrounsly.
        function test_set_current_scope_index_async() {
            scopesModel.clear();
            verify(scopesModel.loaded == false);

            tryCompare(dashContent, "currentIndex", -1);
            var next_index = 1

            dashContent.setCurrentScopeAtIndex(next_index, true, false);
            scopesModel.load();
            tryCompare(dashContent, "currentIndex", next_index);
            verify(scopesModel.loaded == true);

            // test greater than scope count.
            var currentScopeIndex = dashContent.currentIndex;
            dashContent.setCurrentScopeAtIndex(8, true, false);
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
                {tag: "index0", index: 0, objectName: "MockScope1"},
                {tag: "index1", index: 1, objectName: "MockScope2"},
                {tag: "index2", index: 2, objectName: "clickscope"},
                {tag: "index3", index: 3, objectName: "MockScope5"}
            ]
        }

        function test_scope_mapping(data) {
            dashContent.setCurrentScopeAtIndex(data.index, true, false);
            tryCompareFunction(get_current_item_object_name, data.objectName)
            var scopeView = findChild(dashContent, data.objectName);
            var pageHeader = findChild(scopeView, "innerPageHeader");
            compare(pageHeader.title, scopesModel.getScope(data.index).name);
        }

        function test_is_active_data() {
            return [
                {tag: "select 0", select: 0, visible: true, active0: true, active1: false, active2: false, active3: false},
                {tag: "select 2", select: 2, visible: true, active0: false, active1: false, active2: true, active3: false},
                {tag: "invisible", select: 0, visible: false, active0: false, active1: false, active2: false, active3: false},
            ]
        }

        function test_is_active(data) {
            var dashContentList = findChild(dashContent, "dashContentList");

            dashContent.setCurrentScopeAtIndex(data.select, true, false);
            dashContent.visible = data.visible;

            tryCompare(scopesModel.getScope(0), "isActive", data.active0);
            tryCompare(scopesModel.getScope(1), "isActive", data.active1);
            tryCompare(scopesModel.getScope(2), "isActive", data.active2);
        }

        function checkFlickMovingAndNotInteractive()
        {
            var dashContentList = findChild(dashContent, "dashContentList");

            if (dashContentList.currentItem.moving && !dashContentList.interactive)
                return true;

            var startX = dashContentList.width/2;
            var startY = dashContentList.height/2;
            touchFlick(dashContentList, startX, startY, startX, startY - units.gu(40));

            return dashContentList.currentItem.moving && !dashContentList.interactive;
        }

        function test_hswipe_disabled_vswipe() {
            var dashContentList = findChild(dashContent, "dashContentList");

            tryCompare(dashContentList, "interactive", true);

            tryCompareFunction(checkFlickMovingAndNotInteractive, true);
        }

        function test_carouselAspectRatio() {
            tryCompareFunction(function() {
                                    var scope = findChild(dashContent, "MockScope1 loader");
                                    if (scope != null) {
                                        var dashCategory1 = findChild(scope, "dashCategory1");
                                        if (dashCategory1 != null) {
                                            var tile = findChild(dashCategory1, "carouselDelegate1");
                                            return tile != null;
                                        }
                                    }
                                    return false;
                                },
                                true);

            var scope = findChild(dashContent, "MockScope1 loader");
            var dashCategory1 = findChild(scope, "dashCategory1");
            var cardTool = findChild(dashCategory1, "cardTool");
            var carouselLV = findChild(dashCategory1, "listView");
            verify(carouselLV.tileWidth / carouselLV.tileHeight == cardTool.components["art"]["aspect-ratio"]);
        }

        function test_departments() {
            var dashDepartments = findChild(dashContent, "dashDepartments");
            compare(dashDepartments.visible, true);
            compare(dashDepartments.showList, false);
            waitForRendering(dashDepartments);
            mouseClick(dashDepartments, 0, 0);
            compare(dashDepartments.showList, true);

            var departmentListView = findChild(dashDepartments, "departmentListView");
            compare(departmentListView.count, 1);
            tryCompare(departmentListView.currentItem.department, "loaded", true);

            waitForRendering(departmentListView);
            waitForRendering(departmentListView.currentItem);

            var allButton = findChild(dashDepartments, "allButton");
            compare(allButton.visible, false);

            var department = findChild(dashDepartments, "department0child3");
            mouseClick(department, 0, 0);
            compare(dashDepartments.showList, false);
            tryCompare(dashDepartments.currentDepartment, "departmentId", "middle3");
            tryCompare(departmentListView.currentItem.department, "departmentId", "root");

            mouseClick(dashDepartments, 0, 0);
            compare(dashDepartments.showList, true);
            waitForRendering(departmentListView);
            waitForRendering(departmentListView.currentItem);
            compare(allButton.visible, true);

            mouseClick(allButton, 0, 0);
            compare(dashDepartments.showList, false);
            tryCompare(dashDepartments.currentDepartment, "departmentId", "root");
            tryCompare(departmentListView.currentItem.department, "departmentId", "root");

            mouseClick(dashDepartments, 0, 0);
            compare(dashDepartments.showList, true);
            waitForRendering(departmentListView);
            waitForRendering(departmentListView.currentItem);
            compare(allButton.visible, false);

            department = findChild(dashDepartments, "department0child2");
            mouseClick(department, 0, 0);
            compare(dashDepartments.showList, true);
            tryCompare(dashDepartments.currentDepartment, "departmentId", "middle2");
            tryCompare(departmentListView.currentItem.department, "departmentId", "middle2");

            var departmentList1 = findChild(dashDepartments, "department1");
            allButton = findChild(departmentList1, "allButton");
            var backButton = findChild(findChild(departmentList1, "department1"), "backButton");
            compare(allButton.visible, true);
            compare(backButton.visible, true);

            tryCompare(departmentListView, "contentX", departmentList1.x);
            waitForRendering(departmentListView);
            mouseClick(allButton, 0, 0);
            compare(dashDepartments.showList, false);
            tryCompare(dashDepartments.currentDepartment, "departmentId", "middle2");
            tryCompare(departmentListView.currentItem.department, "departmentId", "middle2");

            mouseClick(dashDepartments, 0, 0);
            compare(dashDepartments.showList, true);
            waitForRendering(departmentListView);
            waitForRendering(departmentListView.currentItem);
            compare(allButton.visible, true);
            compare(backButton.visible, true);

            tryCompare(departmentList1.department, "loaded", true);
            department = findChild(dashDepartments, "department1child2");
            mouseClick(department, 0, 0);
            compare(dashDepartments.showList, false);
            tryCompare(dashDepartments.currentDepartment, "departmentId", "childmiddle22");
            tryCompare(departmentListView.currentItem.department, "departmentId", "middle2");

            mouseClick(dashDepartments, 0, 0);
            compare(dashDepartments.showList, true);
            waitForRendering(departmentListView);
            waitForRendering(departmentListView.currentItem);

            tryCompare(departmentList1.department, "loaded", true);
            department = findChild(dashDepartments, "department1child3");
            mouseClick(department, 0, 0);
            compare(dashDepartments.showList, false);
            tryCompare(dashDepartments.currentDepartment, "departmentId", "childmiddle23");
            tryCompare(departmentListView.currentItem.department, "departmentId", "middle2");

            mouseClick(dashDepartments, 0, 0);
            compare(dashDepartments.showList, true);
            waitForRendering(departmentListView);
            waitForRendering(departmentListView.currentItem);
            mouseClick(backButton, 0, 0);

            tryCompare(dashDepartments.currentDepartment, "departmentId", "root");
            tryCompare(departmentListView.currentItem.department, "departmentId", "root");
            compare(dashDepartments.showList, true);
            mouseClick(dashDepartments, 0, 0);
            compare(dashDepartments.showList, false);

            mouseClick(dashDepartments, 0, 0);
            compare(dashDepartments.showList, true);
            tryCompare(departmentListView.currentItem.department, "loaded", true);
            department = findChild(dashDepartments, "department0child2");
            mouseClick(department, 0, 0);
            compare(dashDepartments.showList, true);
            departmentList1 = findChild(dashDepartments, "department1");
            compare(departmentList1.department.loaded, false);
            tryCompare(dashDepartments.currentDepartment, "departmentId", "middle2");
            allButton = findChild(departmentList1, "allButton");
            tryCompare(dashDepartments.currentDepartment, "departmentId", "middle2");
            mouseClick(allButton, 0, 0);
            tryCompare(dashDepartments.currentDepartment, "departmentId", "middle2");
        }
    }
}
