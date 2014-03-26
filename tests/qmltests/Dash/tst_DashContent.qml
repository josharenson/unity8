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

    property var scopeStatus: {
        'MockScope1': { 'movementStarted': 0, 'positionedAtBeginning': 0 },
        'MockScope2': { 'movementStarted': 0, 'positionedAtBeginning': 0 },
        'clickscope': { 'movementStarted': 0, 'positionedAtBeginning': 0 },
        'MockScope5': { 'movementStarted': 0, 'positionedAtBeginning': 0 }
    }

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

        scopeMapper : scopeDelegateMapper
        searchHistory: SearchHistoryModel {}
    }

    ScopeDelegateMapper {
        id: scopeDelegateMapper
        scopeDelegateMapping: {
            "MockScope1": Qt.resolvedUrl("qml/fake_scopeView1.qml"),
            "MockScope2": Qt.resolvedUrl("qml/fake_scopeView2.qml"),
            "clickscope": Qt.resolvedUrl("qml/fake_scopeView3.qml"),
        }
        genericScope: Qt.resolvedUrl("qml/fake_generic_scopeView.qml")
    }

    function clear_scope_status() {
        scopeStatus["MockScope1"].movementStarted = 0;
        scopeStatus["MockScope1"].positionedAtBeginning = 0;

        scopeStatus["MockScope2"].movementStarted = 0;
        scopeStatus["MockScope2"].positionedAtBeginning = 0;

        scopeStatus["clickscope"].movementStarted = 0;
        scopeStatus["clickscope"].positionedAtBeginning = 0;

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

    UT.UnityTestCase {
        name: "DashContent"
        when: scopesModel.loaded

        function init() {
            scopesModel.clear();
            scopeLoadedSpy.clear();
            scopesModel.load();
            tryCompare(scopeLoadedSpy, "count", 4);
        }

        function cleanup() {
            movementStartedSpy.clear();
            clear_scope_status();
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

            scopeLoadedSpy.clear();
            scopesModel.load();
            tryCompare(scopeLoadedSpy, "count", 4);

            verify(dashContentList.currentIndex >= 0);
        }

        function test_current_index_after_reset() {
            var dashContentList = findChild(dashContent, "dashContentList");
            verify(dashContentList != undefined)

            scopesModel.clear();
            compare(dashContentList.count, 0, "DashContent should have 0 items after clearing");
            // pretend we're running after a model reset
            dashContentList.currentIndex = 27;

            scopeLoadedSpy.clear();
            scopesModel.load();
            tryCompare(scopeLoadedSpy, "count", 4);

            verify(dashContentList.currentIndex >= 0 && dashContentList.currentIndex < 5);
        }

        function test_movement_started_signal() {
            dashContent.setCurrentScopeAtIndex(3, true, false);

            var dashContentList = findChild(dashContent, "dashContentList");
            verify(dashContentList != undefined)

            dashContentList.movementStarted();

            compare(movementStartedSpy.count, 1, "DashContent should have emitted movementStarted signal when content list did.");
            compare(scopeStatus["MockScope1"].movementStarted, 1, "MockScope1 should have emitted movementStarted signal when content list did.");
            compare(scopeStatus["MockScope2"].movementStarted, 1, "MockScope2 should have emitted movementStarted signal when content list did.");
            compare(scopeStatus["clickscope"].movementStarted, 1, "clickscope should have emitted movementStarted signal when content list did.");
            compare(scopeStatus["MockScope5"].movementStarted, 1, "MockScope5 should have emitted movementStarted signal when content list did.");
        }

        function test_positioned_at_beginning_signal() {
            dashContent.setCurrentScopeAtIndex(3, true, false);

            dashContent.positionedAtBeginning();
            compare(scopeStatus["MockScope1"].positionedAtBeginning, 1, "MockScope1 should have emitted positionedAtBeginning signal when DashContent did.");
            compare(scopeStatus["MockScope2"].positionedAtBeginning, 1, "MockScope2 should have emitted positionedAtBeginning signal when DashContent did.");
            compare(scopeStatus["clickscope"].positionedAtBeginning, 1, "clickscope should have emitted positionedAtBeginning signal when DashContent did.");
            compare(scopeStatus["MockScope5"].positionedAtBeginning, 1, "MockScope5 should have emitted positionedAtBeginning signal when DashContent did.");
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
                {tag: "index0", index: 0, objectName: "MockScope1"},
                {tag: "index1", index: 1, objectName: "MockScope2"},
                {tag: "index2", index: 2, objectName: "clickscope"},
                {tag: "index3", index: 3, objectName: "MockScope5"}
            ]
        }

        function test_scope_mapping(data) {
            dashContent.setCurrentScopeAtIndex(data.index, true, false);
            tryCompareFunction(get_current_item_object_name, data.objectName)
            var pageHeader = findChild(dashContent, "pageHeader");
            compare(pageHeader.scope, scopesModel.get(data.index));
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

            tryCompare(scopesModel.get(0), "isActive", data.active0);
            tryCompare(scopesModel.get(1), "isActive", data.active1);
            tryCompare(scopesModel.get(2), "isActive", data.active2);
        }

        function doFindMusicButton(parent) {
            for (var i = 0; i < parent.children.length; i++) {
                var c = parent.children[i];
                if (UT.Util.isInstanceOf(c, "AbstractButton") && parent.x >= 0) {
                    for (var ii = 0; ii < c.children.length; ii++) {
                        var cc = c.children[ii];
                        if (UT.Util.isInstanceOf(cc, "Label") && cc.text == "Music") {
                            return c;
                        }
                    }
                }
                var r = doFindMusicButton(c);
                if (r !== undefined) {
                    return r;
                }
            }
            return undefined;
        }

        function findMusicButton() {
            // We need to find a AbstractButton that has a Label child
            // with text Music and it's parent x is >= 0
            var tabbar = findChild(dashContent, "tabbar");
            return doFindMusicButton(tabbar);
        }

        function test_tabBar_index_change() {
            tryCompare(scopesModel, "loaded", true);
            var tabbar = findChild(dashContent, "tabbar");

            tryCompare(dashContent, "currentIndex", 0);
            tryCompare(tabbar, "selectedIndex", 0);
            tryCompare(tabbar, "selectionMode", false);

            mouseClick(tabbar, units.gu(5), units.gu(5))

            tryCompare(tabbar, "selectionMode", true);
            tryCompare(tabbar, "selectedIndex", 0);
            tryCompare(dashContent, "currentIndex", 0);

            var button;
            tryCompareFunction(function() { button = findMusicButton(); return button != undefined; }, true);
            waitForRendering(button);

            tryCompareFunction(function() { return button.opacity > 0; }, true);
            mouseClick(button, button.width / 2, button.height / 2)

            tryCompare(tabbar, "selectionMode", false);
            tryCompare(tabbar, "selectedIndex", 1);
            tryCompare(dashContent, "currentIndex", 1);
        }

        function test_tabBar_listens_to_index_change() {
            var tabbar = findChild(dashContent, "tabbar");
            tryCompare(dashContent, "currentIndex", 0);
            compare(tabbar.selectedIndex, 0);
            var dashContentList = findChild(dashContent, "dashContentList");
            dashContentList.currentIndex = 1;
            compare(tabbar.selectedIndex, 1);
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

        function openPreview() {
            tryCompareFunction(function() {
                                    var filterGrid = findChild(dashContent, "0");
                                    if (filterGrid != null) {
                                        var tile = findChild(filterGrid, "delegate0");
                                        return tile != null;
                                    }
                                    return false;
                                },
                                true);
            var tile = findChild(findChild(dashContent, "0"), "delegate0");
            mouseClick(tile, tile.width / 2, tile.height / 2);
            var previewListView = findChild(dashContent, "dashContentPreviewList");
            tryCompare(previewListView, "open", true);
            tryCompare(previewListView, "x", 0);
        }

        function closePreview() {
            var closePreviewMouseArea = findChild(dashContent, "dashContentPreviewList_pageHeader_backButton");
            mouseClick(closePreviewMouseArea, closePreviewMouseArea.width / 2, closePreviewMouseArea.height / 2);

            var previewListView = findChild(dashContent, "dashContentPreviewList");
            tryCompare(previewListView, "open", false);
        }

        function test_previewOpenClose() {
            tryCompare(scopeLoadedSpy, "count", 4);

            var previewListView = findChild(dashContent, "dashContentPreviewList");
            tryCompare(previewListView, "open", false);

            var categoryListView = findChild(dashContent, "categoryListView");
            categoryListView.positionAtBeginning();

            openPreview();
            closePreview();
        }

        function test_showPreviewCarousel() {
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

            tryCompare(scopeLoadedSpy, "count", 4);

            var previewListView = findChild(dashContent, "dashContentPreviewList");
            tryCompare(previewListView, "open", false);

            var scope = findChild(dashContent, "MockScope1 loader");
            var dashCategory1 = findChild(scope, "dashCategory1");
            var tile = findChild(dashCategory1, "carouselDelegate1");
            mouseClick(tile, tile.width / 2, tile.height / 2);
            tryCompare(previewListView, "open", true);
            tryCompare(previewListView, "x", 0);

            closePreview();
        }

        function test_previewCycle() {
            tryCompare(scopeLoadedSpy, "count", 4);

            var categoryListView = findChild(dashContent, "categoryListView");
            categoryListView.positionAtBeginning();

            var previewListView = findChild(dashContent, "dashContentPreviewList");
            tryCompare(previewListView, "open", false);
            var previewListViewList = findChild(dashContent, "dashContentPreviewList_listView");

            openPreview();

            // flick to the next previews
            tryCompare(previewListView, "count", 15);
            for (var i = 1; i < previewListView.count; ++i) {
                mouseFlick(previewListView, previewListView.width - units.gu(1),
                                            previewListView.height / 2,
                                            units.gu(2),
                                            previewListView.height / 2);
                tryCompare(previewListViewList, "moving", false);
                tryCompare(previewListView.currentItem, "objectName", "previewItem" + i);

            }
            closePreview();
        }
    }
}
