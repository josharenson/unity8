/*
 * Copyright 2014 Canonical Ltd.
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
import "../../../../qml/Dash/Previews"
import Unity.Test 0.1 as UT
import Unity 0.1 as Unity

Rectangle {
    id: root
    width: units.gu(60)
    height: units.gu(80)
    color: Theme.palette.selected.background

    Item {
        id: shell

        anchors.fill: parent
        property var applicationManager: null
    }

    Unity.FakePreviewModel {
        id: mockPreviewModel
    }

    Preview {
        id: preview
        anchors.fill: parent

        previewModel: mockPreviewModel
    }

    SignalSpy {
        id: triggeredSpy
        target: mockPreviewModel
        signalName: "actionTriggered"
    }

    UT.UnityTestCase {
        name: "Preview"
        when: windowShown

        function test_triggered() {
            waitForRendering(preview);
            var widget = findChild(preview, "widget-3");

            compare(typeof widget, "object", "Could not find the widget object.");

            widget.triggered(widget.widgetId, "mockAction", {"mock": "data"});

            triggeredSpy.wait();

            var args = triggeredSpy.signalArguments[0];

            compare(args[0], "widget-3", "Widget id not passed correctly.");
            compare(args[1], "mockAction", "Action id not passed correctly.");
            compare(args[2]["mock"], "data", "Data not passed correctly.");
        }

        function test_showProcessing() {
            waitForRendering(preview);
            var widget = findChild(preview, "widget-3");
            widget.triggered(widget.widgetId, "mockAction", {"mock": "data"});

            var processing = findChild(preview, "processingMouseArea");

            tryCompare(processing, "enabled", true);

            preview.previewModelChanged();

            tryCompare(processing, "enabled", false);
        }

        function test_containOnFocus() {
            waitForRendering(preview);
            tryCompareFunction(function () { return findChild(preview, "widget-9") != null }, true);
            var widget = findChild(preview, "widget-9");

            var bottomLeft = preview.mapFromItem(widget, 0, widget.height);
            verify(bottomLeft.y > preview.height);

            widget.forceActiveFocus();

            tryCompareFunction(function () {
                var bottomLeft = preview.mapFromItem(widget, 0, widget.height);
                return bottomLeft.y <= preview.height
            }, true);
        }

        function test_containOnGrow() {
            waitForRendering(preview);
            tryCompareFunction(function () { return findChild(preview, "widget-13") != null }, true);
            var widget = findChild(preview, "widget-13");

            var bottomLeft = preview.mapFromItem(widget, 0, widget.height);
            verify(bottomLeft.y > preview.height);

            root.height += units.gu(50);

            tryCompareFunction(function () {
                var bottomLeft = preview.mapFromItem(widget, 0, widget.height);
                return bottomLeft.y <= preview.height
            }, true);
        }
    }
}
