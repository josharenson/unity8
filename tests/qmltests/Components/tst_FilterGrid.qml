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
import "../../../qml/Components"
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Components 0.1
import Unity.Test 0.1 as UT

/*
  You should see 6 green squares (from "A" to "F") and a button "View all (12)".
  Once you press that button other 6 green squares (from "G" to "L") should show up.
*/
Rectangle {
    width: gridRect.width + controls.width
    height: units.gu(50)
    color: "white"

    Column {
        id: controls
        width: units.gu(30)
        height: parent.height
        anchors.top: parent.top
        anchors.right: parent.right
        ListItem.ValueSelector {
            id: collapsedRowCountSelector
            text: "collapsedRowCount"
            values: [1,2,3,4]
            selectedIndex: 1
        }
        Row {
            spacing: units.gu(1)
            Label { anchors.verticalCenter: parent.verticalCenter
                    text: "Filter" }
            CheckBox {
                id: filterCheckBox
                checked: true
            }
        }
    }

    ListModel {
        id: fakeModel
        ListElement { name: "A" }
        ListElement { name: "B" }
        ListElement { name: "C" }
        ListElement { name: "D" }
        ListElement { name: "E" }
        ListElement { name: "F" }
        ListElement { name: "G" }
        ListElement { name: "H" }
        ListElement { name: "I" }
        ListElement { name: "J" }
        ListElement { name: "K" }
        ListElement { name: "L" }
    }

    Rectangle {
        id: gridRect
        width: units.gu(30)
        height: parent.height
        color: "grey"
        anchors.top: parent.top
        anchors.left: parent.left

        FilterGrid {
            id: filterGrid
            anchors.fill: parent
            model: fakeModel
            maximumNumberOfColumns: 3
            collapsedRowCount:
                collapsedRowCountSelector.values[collapsedRowCountSelector.selectedIndex]
            filter: filterCheckBox.checked
            minimumHorizontalSpacing: units.gu(1)
            delegateWidth: units.gu(6)
            delegateHeight: units.gu(6)
            verticalSpacing: units.gu(1)

            delegate: Rectangle {
                // So that it can be identified by countVisibleDelegates()
                property bool isGridDelegate: true

                color: "green"
                width: units.gu(6)
                height: units.gu(6)
                Text {
                    anchors.centerIn: parent
                    text: name
                }
            }
        }
    }

    UT.UnityTestCase {
        name: "FilterGrid"
        when: windowShown

        function test_turningFilterOffShowsAllElements() {
            tryCompareFunction(countVisibleDelegates, 6)

            filterCheckBox.checked = false

            tryCompareFunction(countVisibleDelegates, 12)

            // back to initial state
            filterCheckBox.checked = true
        }

        function test_collapsedRowCount() {
            for (var i = 0; i < 4; ++i) {
                collapsedRowCountSelector.selectedIndex = i
                // We have 3 elements per row.
                // row count == index + 1
                tryCompareFunction(countVisibleDelegates, 3*(i+1))
            }

            // back to initial state
            collapsedRowCountSelector.selectedIndex = 1
        }

        function countVisibleDelegates() {
            return __countVisibleDelegates(filterGrid.visibleChildren, 0)
        }

        function __countVisibleDelegates(objList, total) {
            for (var i = 0; i < objList.length; ++i) {
                var child = objList[i];
                if (child.isGridDelegate !== undefined) {
                    ++total;
                } else {
                    total = __countVisibleDelegates(child.visibleChildren, total)
                }
            }
            return total
        }
    }
}
