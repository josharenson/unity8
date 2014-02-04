/*
 * Copyright (C) 2013 Canonical, Ltd.
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
import Ubuntu.Components 0.1
import Unity.Test 0.1 as UT
import "../../../qml/Dash"


Rectangle {
    width: units.gu(40)
    height: units.gu(72)
    color: "lightgrey"

    CardHeader {
        id: cardHeader
        anchors { left: parent.left; right: parent.right }
    }

    Rectangle {
        anchors.fill: cardHeader
        color: "lightblue"
        opacity: 0.5
    }

    UT.UnityTestCase {
        id: testCase
        name: "CardHeader"

        when: windowShown

        property Item mascot: findChild(cardHeader, "mascotShape")
        property Item titleLabel: findChild(cardHeader, "titleLabel")
        property Item subtitleLabel: findChild(cardHeader, "subtitleLabel")
        property Item prices: findChild(cardHeader, "prices")
        property Item oldPriceLabel: findChild(cardHeader, "oldPriceLabel")
        property Item outerRow: findChild(cardHeader, "outerRow")
        property Item column: findChild(cardHeader, "column")

        function initTestCase() {
            verify(typeof testCase.mascot === "object", "Couldn't find mascot object.");
            verify(typeof testCase.titleLabel === "object", "Couldn't find titleLabel object.");
            verify(typeof testCase.subtitleLabel === "object", "Couldn't find subtitleLabel object.");
            verify(typeof testCase.prices === "object", "Couldn't find prices object.");
            verify(typeof testCase.oldPriceLabel === "object", "Couldn't find oldPriceLabel object.");
        }

        function cleanup() {
            cardHeader.mascot = "";
            cardHeader.title = "";
            cardHeader.subtitle = "";
            cardHeader.price = "";
            cardHeader.oldPrice = "";
            cardHeader.altPrice = "";
        }

        function test_mascot_data() {
            return [
                        { tag: "Empty", source: "", visible: false },
                        { tag: "Invalid", source: "bad_path", visible: false },
                        { tag: "Valid", source: Qt.resolvedUrl("artwork/avatar.png"), visible: true },
            ]
        }

        function test_mascot(data) {
            cardHeader.mascot = data.source;
            tryCompare(testCase.mascot, "visible", data.visible);
        }

        function test_labels_data() {
            return [
                        { tag: "Empty", visible: false },
                        { tag: "Title only", title: "Foo", visible: true },
                        { tag: "Subtitle only", subtitle: "Bar", visible: false },
                        { tag: "Both", title: "Foo", subtitle: "Bar", visible: true },
            ]
        }

        function test_labels(data) {
            cardHeader.title = data.title !== undefined ? data.title : "";
            cardHeader.subtitle = data.subtitle !== undefined ? data.subtitle : "";
            tryCompare(cardHeader, "visible", data.visible);
        }

        function test_prices_data() {
            return [
                        { tag: "Main", main: "$1.25", visible: true },
                        { tag: "Alt", alt: "€1.00", visible: false },
                        { tag: "Old", old: "€2.00", visible: false },
                        { tag: "Main and Alt", main: "$1.25", alt: "€1.00", visible: true },
                        { tag: "Main and Old", main: "$1.25", old: "$2.00", visible: true, oldAlign: Text.AlignRight },
                        { tag: "Alt and Old", alt: "€1.00", old: "$2.00", visible: false },
                        { tag: "All", main: "$1.25", alt: "€1.00", old: "$2.00", visible: true, oldAlign: Text.AlignHCenter },
            ]
        }

        function test_prices(data) {
            cardHeader.price = data.main !== undefined ? data.main : "";
            cardHeader.oldPrice = data.old !== undefined ? data.old : "";
            cardHeader.altPrice = data.alt !== undefined ? data.alt : "";
            tryCompare(cardHeader, "visible", data.visible);
            if (data.hasOwnProperty("oldAlign")) {
                compare(testCase.oldPriceLabel.horizontalAlignment, data.oldAlign, "Old price label is aligned wrong.")
            }
        }

        function test_dimensions_data() {
            return [
                { tag: "Column width", object: column, width: cardHeader.width },
                { tag: "Column width with mascot", object: column, width: cardHeader.width - mascot.width - outerRow.margins * 3, mascot: "artwork/avatar.png" },
                { tag: "Header height", object: cardHeader, height: function() { return subtitleLabel.y + subtitleLabel.height + outerRow.margins * 2 } },
            ]
        }

        function test_dimensions(data) {
            if (data.hasOwnProperty("mascot")) {
                cardHeader.mascot = data.mascot;
            }

            if (data.hasOwnProperty("width")) {
                tryCompare(data.object, "width", data.width);
            }

            if (data.hasOwnProperty("height")) {
                tryCompareFunction(function() { return data.object.height === data.height() }, true);
            }
        }
    }
}
