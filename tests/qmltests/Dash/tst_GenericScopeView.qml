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
import Unity 0.1
import ".."
import "../../../qml/Dash"
import "../../../qml/Components"
import Ubuntu.Components 0.1
import Unity.Test 0.1 as UT

Item {
    id: shell
    width: units.gu(120)
    height: units.gu(80)

    Scopes {
        id: scopes

        onLoadedChanged: {
            genericScopeView.scope = scopes.get(0)
        }
    }

    property Item applicationManager: Item {
        signal sideStageFocusedApplicationChanged()
        signal mainStageFocusedApplicationChanged()
    }

    GenericScopeView {
        id: genericScopeView
        anchors.fill: parent
        searchHistory: SearchHistoryModel {}

        UT.UnityTestCase {
            name: "GenericScopeView"
            when: scopes.loaded

            function test_isCurrent() {
                var pageHeader = findChild(genericScopeView, "pageHeader");
                var previewListView = findChild(genericScopeView, "previewListView");
                genericScopeView.isCurrent = true
                pageHeader.searchQuery = "test"
                previewListView.open = true
                genericScopeView.isCurrent = false
                tryCompare(pageHeader, "searchQuery", "")
                tryCompare(genericScopeView, "previewShown", false);
            }

            function test_showDash() {
                var previewListView = findChild(genericScopeView, "previewListView");
                previewListView.open = true;
                scopes.get(0).showDash();
                tryCompare(genericScopeView, "previewShown", false);
            }

            function test_hideDash() {
                var previewListView = findChild(genericScopeView, "previewListView");
                previewListView.open = true;
                scopes.get(0).hideDash();
                tryCompare(genericScopeView, "previewShown", false);
            }

            function openPreview() {
                var categoryListView = findChild(genericScopeView, "categoryListView");
                categoryListView.positionAtBeginning();

                var tile = findChild(findChild(genericScopeView, "0"), "delegate0");
                mouseClick(tile, tile.width / 2, tile.height / 2);
                var openEffect = findChild(genericScopeView, "openEffect");
                tryCompare(openEffect, "gap", 1);
            }

            function checkArrowPosition(index) {
                var tile = findChild(findChild(genericScopeView, "0"), "delegate" + index);
                var tileCenter = tile.x + tile.width/2;
                var pointerArrow = findChild(genericScopeView, "pointerArrow");
                var pointerArrowCenter = pointerArrow.x + pointerArrow.width/2;
                compare(pointerArrowCenter, tileCenter, "Pointer did not move to tile");
            }

            function closePreview() {
                var closePreviewMouseArea = findChild(genericScopeView, "closePreviewMouseArea");
                mouseClick(closePreviewMouseArea, closePreviewMouseArea.width / 2, closePreviewMouseArea.height / 2);

                var previewListView = findChild(genericScopeView, "previewListView");
                tryCompare(previewListView, "open", false);
                var openEffect = findChild(genericScopeView, "openEffect");
                tryCompare(openEffect, "gap", 0);

                var categoryListView = findChild(genericScopeView, "categoryListView");
                categoryListView.flick(0, units.gu(200));
                tryCompare(categoryListView, "flicking", false);
            }

            function test_previewOpenClose() {
                var previewListView = findChild(genericScopeView, "previewListView");
                tryCompare(previewListView, "open", false);

                openPreview();

                // check for it opening successfully
                var currentPreviewItem = findChild(genericScopeView, "previewLoader0");
                tryCompareFunction(function() {
                                       var parts = currentPreviewItem.source.toString().split("/");
                                       var name = parts[parts.length - 1];
                                       return name == "DashPreviewPlaceholder.qml";
                                   },
                                   true);
                tryCompareFunction(function() {
                                       var parts = currentPreviewItem.source.toString().split("/");
                                       var name = parts[parts.length - 1];
                                       return name == "GenericPreview.qml";
                                   },
                                   true);
                tryCompare(currentPreviewItem, "progress", 1);
                tryCompare(previewListView, "open", true);

                closePreview();
                tryCompare(previewListView, "open", false);
            }

            function test_hiddenPreviewOpen() {
                var categoryListView = findChild(genericScopeView, "categoryListView");
                categoryListView.positionAtBeginning();
                waitForRendering(categoryListView);
                categoryListView.flick(0, -units.gu(80));
                tryCompare(categoryListView.flicking, false);

                var tile = findChild(findChild(genericScopeView, "0"), "delegate0");
                mouseClick(tile, tile.width / 2, tile.height - 1);
                var openEffect = findChild(genericScopeView, "openEffect");
                tryCompare(openEffect, "gap", 1);

                var pageHeader = findChild(genericScopeView, "pageHeader");
                verify(openEffect.positionPx >= pageHeader.height + categoryListView.stickyHeaderHeight);
            }

            function test_previewCycle() {
                var previewListView = findChild(genericScopeView, "previewListView");
                tryCompare(previewListView, "open", false);

                openPreview();

                // wait for it to be loaded
                var currentPreviewItem = findChild(genericScopeView, "previewLoader0");
                tryCompareFunction(function() {
                                       var parts = currentPreviewItem.source.toString().split("/");
                                       var name = parts[parts.length - 1];
                                       return name == "GenericPreview.qml";
                                   },
                                   true);
                tryCompare(currentPreviewItem, "progress", 1);
                waitForRendering(currentPreviewItem);

                checkArrowPosition(0);

                // flick to the next previews

                for (var i = 1; i < previewListView.count; ++i) {

                    mouseFlick(previewListView, previewListView.width - units.gu(1),
                                                previewListView.height / 2,
                                                units.gu(2),
                                                previewListView.height / 2);

                    // wait for it to be loaded
                    var nextPreviewItem = findChild(genericScopeView, "previewLoader" + i);
                    tryCompareFunction(function() {
                                           var parts = nextPreviewItem.source.toString().split("/");
                                           var name = parts[parts.length - 1];
                                           return name == "GenericPreview.qml";
                                       },
                                       true);
                    tryCompare(nextPreviewItem, "progress", 1);
                    waitForRendering(nextPreviewItem);
                    tryCompareFunction(function() {return nextPreviewItem.item !== null}, true);

                    checkArrowPosition(i);

                    // Make sure only the new one has isCurrent set to true
                    compare(nextPreviewItem.item.isCurrent, true);

                    if (currentPreviewItem.item !== undefined && currentPreviewItem.item !== null) {
                        compare(currentPreviewItem.item.isCurrent, false);
                    }

                    currentPreviewItem = nextPreviewItem;
                }
                closePreview();
            }

            function test_show_spinner() {
                openPreview();
                var previewListView = findChild(genericScopeView, "previewListView");
                var previewLoader = findChild(genericScopeView, "previewLoader0");

                previewLoader.item.showProcessingAction = true;
                var waitingForAction = findChild(genericScopeView, "waitingForActionMouseArea");
                tryCompare(waitingForAction, "enabled", true);
                previewLoader.closePreviewSpinner();
                tryCompare(waitingForAction, "enabled", false);

                closePreview();
            }

            function test_changeScope() {
                genericScopeView.scope.searchQuery = "test"
                genericScopeView.scope = scopes.get(1)
                genericScopeView.scope = scopes.get(0)
                tryCompare(genericScopeView.scope, "searchQuery", "")
            }

            function test_filter_expand_collapse() {
                // wait for the item to be there
                tryCompareFunction(function() { return findChild(genericScopeView, "dashSectionHeader0") != undefined; }, true);

                var header = findChild(genericScopeView, "dashSectionHeader0")
                var category = findChild(genericScopeView, "dashCategory0")

                waitForRendering(header);
                verify(category.expandable);
                verify(category.filtered);

                var initialHeight = category.height;
                var middleHeight;
                mouseClick(header, header.width / 2, header.height / 2);
                tryCompareFunction(function() { middleHeight = category.height; return category.height > initialHeight; }, true);
                tryCompare(category, "filtered", false);
                verify(category.height > middleHeight);

                mouseClick(header, header.width / 2, header.height / 2);
                verify(category.expandable);
                tryCompare(category, "filtered", true);
            }

            function test_showPreviewCarousel() {
                tryCompareFunction(function() { return findChild(genericScopeView, "carouselDelegate") != undefined; }, true);
                var tile = findChild(genericScopeView, "carouselDelegate");
                mouseClick(tile, tile.width / 2, tile.height / 2);
                var openEffect = findChild(genericScopeView, "openEffect");
                tryCompare(openEffect, "gap", 1);

                // check for it opening successfully
                var previewListView = findChild(genericScopeView, "previewListView");
                var currentPreviewItem = findChild(genericScopeView, "previewLoader0");
                tryCompareFunction(function() {
                                       var parts = currentPreviewItem.source.toString().split("/");
                                       var name = parts[parts.length - 1];
                                       return name == "DashPreviewPlaceholder.qml";
                                   },
                                   true);
                tryCompareFunction(function() {
                                       var parts = currentPreviewItem.source.toString().split("/");
                                       var name = parts[parts.length - 1];
                                       return name == "GenericPreview.qml";
                                   },
                                   true);
                tryCompare(currentPreviewItem, "progress", 1);
                tryCompare(previewListView, "open", true);

                closePreview();
                tryCompare(previewListView, "open", false);
            }

            function test_filter_expand_expand() {
                // wait for the item to be there
                tryCompareFunction(function() { return findChild(genericScopeView, "dashSectionHeader2") != undefined; }, true);

                var categoryListView = findChild(genericScopeView, "categoryListView");
                categoryListView.contentY = categoryListView.height;

                var header2 = findChild(genericScopeView, "dashSectionHeader2")
                var category2 = findChild(genericScopeView, "dashCategory2")
                var category2FilterGrid = category2.children[0].children[0].children[0];
                verify(UT.Util.isInstanceOf(category2FilterGrid, "FilterGrid"));

                waitForRendering(header2);
                verify(category2.expandable);
                verify(category2.filtered);

                mouseClick(header2, header2.width / 2, header2.height / 2);
                tryCompare(category2, "filtered", false);
                tryCompare(category2FilterGrid, "filter", false);

                categoryListView.positionAtBeginning();

                var header0 = findChild(genericScopeView, "dashSectionHeader0")
                var category0 = findChild(genericScopeView, "dashCategory0")
                mouseClick(header0, header0.width / 2, header0.height / 2);
                tryCompare(category0, "filtered", false);
                tryCompare(category2, "filtered", true);
                tryCompare(category2FilterGrid, "filter", true);
            }
        }
    }
}
