/*
 * Copyright 2014,2015 Canonical Ltd.
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

import QtQuick 2.4
import QtTest 1.0
import Ubuntu.Components 1.3
import "../../../../qml/Dash/Previews"
import Unity.Test 0.1 as UT

Rectangle {
    id: root
    width: units.gu(40)
    height: units.gu(80)
    color: theme.palette.selected.background

    property string longText: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.\nPhasellus a mi vitae augue rhoncus lobortis ut rutrum metus.\nCurabitur tortor leo, tristique sed mollis quis, condimentum venenatis nibh.\nLorem ipsum dolor sit amet, consectetur adipiscing elit.\nPhasellus a mi vitae augue rhoncus lobortis ut rutrum metus.\nCurabitur tortor leo, tristique sed mollis quis, condimentum venenatis nibh."
    property string longText2: "This is a very very very long text. 1 This is a very very very long text. 2 This is a very very very long text. 3 This is a very very very long text. 4 This is a very very very long text. 5 This is a very very very long text. 6 This is a very very very long text. 7 This is a very very very long text. 8 This is a very very very long text. 9 This is a very very very long text. 10 This is a very very very long text. 11 This is a very very very long text."
    property string shortText: "This is a short text :)"

    property var tableData: {
        "values": [ [ "Long Label 1", "Value 1"],  [ "Label 2", "Long Value 2"],  [ "Label 3", "Value 3"],  [ "Label 4", "Value 4"],  [ "Label 5", "Value 5"] ]
    }

    property var actionsData: {
        "actions": [ {"label": "Some Label", "id": "someid"} ]
    }

    property var audioData: {
        "tracks": [ { title: "Some track name", length: "30", source: "/not/existing/path/testsound1" } ]
    }

    property var commentData: {
        "author": "Claire Thompson",
        "comment": "C.",
        "source": "../../../tests/graphics/avatars/amanda.png"
    }

    property var commentInputData: {
        "submit-label": "TestSubmitLabel"
    }

    property var galleryData: {
        "sources": [
                    "../../../tests/graphics/avatars/amanda@12.png",
                    "../../../tests/graphics/avatars/funky@12.png",
                    "../../../tests/graphics/clock@18.png",
                    "../../graphics/borked"
                   ]
    }

    property var headerData: {
        "title": "THE TITLE",
        "subtitle": "Something catchy"
    }

    property var iconActionsData: {
        "actions": [ {"label": "10", "id": "s", "icon": Qt.resolvedUrl("../artwork/avatar@12.png") } ]
    }

    property var imageData: {
        "source": "../../../tests/graphics/avatars/amanda@12.png",
        "zoomable": false
    }

    property var progressData: {
        "type": "progress",
        "source": { "dbus-name" : "somename", "dbus-object": "somestring" }
    }

    property var ratingInputData: {
        "visible": "both",
        "required": "both"
    }

    property var ratingEditData: {
        "visible": "both",
        "required": "both",
        author: "Some dude",
        rating: 4.5,
        review: "Very cool app"
    }

    property var reviewsData: {
        "reviews": [ { author: "Some dude", rating: 4.5, review: "Very cool app" } ]
    }

    property var videoData: {
        "source": "",
        "screenshot": "../../../tests/qmltests/Components/tst_LazyImage/square.png"
    }

    ListModel {
        id: widgetsModel
    }

    ListModel {
        id: allWidgetsModel
    }

    property var widgetData: {
        "title": "Title here",
        "collapsed-widgets": 2,
        "widgets": widgetsModel
    }

    property var widgetData1: {
        "title": "Title here1",
        "collapsed-widgets": 2,
        "widgets": widgetsModel,
        "expanded": true
    }

    property var widgetData2: {
        "title": "Title here2",
        "collapsed-widgets": 2,
        "widgets": widgetsModel,
        "expanded": false
    }

    property var allWidgetsData: {
        "title": "Title here",
        "collapsed-widgets": 0,
        "widgets": allWidgetsModel
    }

    Component.onCompleted: {
        widgetsModel.append({"type": "text", "widgetId": "text1", "properties": { "text": longText }});
        widgetsModel.append({"type": "table", "widgetId": "table1", "properties": tableData });
        widgetsModel.append({"type": "text", "widgetId": "text3", "properties": { "text": shortText }});
        widgetsModel.append({"type": "text", "widgetId": "text4", "properties": { "text": longText2 }});

        allWidgetsModel.append({"type": "actions", "widgetId": "actions1", "properties": actionsData });
        allWidgetsModel.append({"type": "audio", "widgetId": "audio1", "properties": audioData });
        allWidgetsModel.append({"type": "comment", "widgetId": "comment1", "properties": commentData });
        allWidgetsModel.append({"type": "comment-input", "widgetId": "comment-input1", "properties": commentInputData });
        // "expandable" For now we're not testing inception of expandables
        allWidgetsModel.append({"type": "gallery", "widgetId": "gallery1", "properties": galleryData });
        allWidgetsModel.append({"type": "header", "widgetId": "header1", "properties": headerData });
        allWidgetsModel.append({"type": "icon-actions", "widgetId": "icon-actions1", "properties": iconActionsData } );
        allWidgetsModel.append({"type": "image", "widgetId": "image1", "properties": imageData });
        allWidgetsModel.append({"type": "progress", "widgetId": "progress1", "properties": progressData });
        allWidgetsModel.append({"type": "rating-input", "widgetId": "rating-input1", "properties": ratingInputData });
        allWidgetsModel.append({"type": "rating-edit", "widgetId": "rating-edit1", "properties": ratingEditData });
        allWidgetsModel.append({"type": "reviews", "widgetId": "reviews1", "properties": reviewsData });
        allWidgetsModel.append({"type": "table", "widgetId": "table1", "properties": tableData });
        allWidgetsModel.append({"type": "text", "widgetId": "text1", "properties": { "text": longText }});
        allWidgetsModel.append({"type": "video", "widgetId": "video1", "properties": videoData });
    }

    PreviewWidgetFactory {
        id: previewExpandable
        anchors { left: parent.left; right: parent.right }
        widgetType: "expandable"
        widgetData: root.widgetData
    }

    PreviewWidgetFactory {
        id: previewExpandable1
        anchors { left: parent.left; right: parent.right; top: previewExpandable.bottom  }
        widgetType: "expandable"
        widgetData: root.widgetData1
    }

    PreviewWidgetFactory {
        id: previewExpandable2
        anchors { left: parent.left; right: parent.right; top: previewExpandable1.bottom  }
        widgetType: "expandable"
        widgetData: root.widgetData2
    }

    PreviewWidgetFactory {
        id: previewWidgetFactory
        anchors { left: parent.left; right: parent.right; top: previewExpandable2.bottom  }
        opacity: 0
    }

    UT.UnityTestCase {
        name: "PreviewExpandableTest"
        when: windowShown

        function checkInitialState()
        {
            compare(previewExpandable.expanded, false);

            var repeater = findChild(previewExpandable, "repeater")
            compare(repeater.count, 4)

            compare (repeater.itemAt(0).visible, true);
            compare (repeater.itemAt(1).visible, true);
            compare (repeater.itemAt(2).visible, false);
            compare (repeater.itemAt(3).visible, false);
            compare (repeater.itemAt(0).expanded, false);
            compare (repeater.itemAt(1).expanded, false);
        }

        function init() {
            previewExpandable.widgetType = "";
            previewExpandable.widgetType = "expandable";
            previewExpandable.widgetData = widgetData;
            checkInitialState();
        }

        function test_expand_collapse() {
            var expandButton = findChild(previewExpandable, "expandButton")
            mouseClick(expandButton);

            var repeater = findChild(previewExpandable, "repeater")
            compare(repeater.count, 4)

            compare (repeater.itemAt(0).visible, true);
            compare (repeater.itemAt(1).visible, true);
            compare (repeater.itemAt(2).visible, true);
            compare (repeater.itemAt(3).visible, true);
            compare (repeater.itemAt(0).expanded, true);
            compare (repeater.itemAt(1).expanded, true);
            compare (repeater.itemAt(2).expanded, true);
            compare (repeater.itemAt(3).expanded, true);

            mouseClick(expandButton);

            checkInitialState();
        }

        function test_expand_collapse_when_assigned() {
            previewExpandable.widgetData = widgetData1;

            var repeater = findChild(previewExpandable, "repeater")
            compare(repeater.count, 4)

            compare (repeater.itemAt(0).visible, true);
            compare (repeater.itemAt(1).visible, true);
            compare (repeater.itemAt(2).visible, true);
            compare (repeater.itemAt(3).visible, true);
            compare (repeater.itemAt(0).expanded, true);
            compare (repeater.itemAt(1).expanded, true);
            compare (repeater.itemAt(2).expanded, true);
            compare (repeater.itemAt(3).expanded, true);
        }

        function test_collapsed_when_assigned() {
            previewExpandable.widgetData = widgetData2;

            var repeater = findChild(previewExpandable, "repeater")
            compare(repeater.count, 4)

            compare (repeater.itemAt(0).visible, true);
            compare (repeater.itemAt(1).visible, true);
            compare (repeater.itemAt(2).visible, false);
            compare (repeater.itemAt(3).visible, false);
            compare (repeater.itemAt(0).expanded, false);
            compare (repeater.itemAt(1).expanded, false);
            compare (repeater.itemAt(2).expanded, false);
            compare (repeater.itemAt(3).expanded, false);
        }

        function test_expand_when_initialized() {
            var repeater = findChild(previewExpandable1, "repeater")
            compare(repeater.count, 4)

            compare (repeater.itemAt(0).visible, true);
            compare (repeater.itemAt(1).visible, true);
            compare (repeater.itemAt(2).visible, true);
            compare (repeater.itemAt(3).visible, true);
            compare (repeater.itemAt(0).expanded, true);
            compare (repeater.itemAt(1).expanded, true);
            compare (repeater.itemAt(2).expanded, true);
            compare (repeater.itemAt(3).expanded, true);
        }

        function test_collapse_when_initialized() {
            var repeater = findChild(previewExpandable2, "repeater")
            compare(repeater.count, 4)

            compare (repeater.itemAt(0).visible, true);
            compare (repeater.itemAt(1).visible, true);
            compare (repeater.itemAt(2).visible, false);
            compare (repeater.itemAt(3).visible, false);
            compare (repeater.itemAt(0).expanded, false);
            compare (repeater.itemAt(1).expanded, false);
            compare (repeater.itemAt(2).expanded, false);
            compare (repeater.itemAt(3).expanded, false);
        }

        function waitForLazyImage(obj)
        {
            if (UT.Util.isInstanceOf(obj, "LazyImage")) {
                tryCompareFunction(function() { return obj.state != "default" && obj.state != "loading"; }, true);
                for (var i in obj.transitions) {
                    tryCompare(obj.transitions[i], "running", false);
                }
            }

            for (var i in obj.children) {
                waitForLazyImage(obj.children[i]);
            }
        }

        function test_all_widgets_height() {
            previewExpandable.widgetData = allWidgetsData;

            var repeater = findChild(previewExpandable, "repeater")
            for (var i = 0; i < repeater.count; ++i) {
                tryCompare(repeater.itemAt(i), "height", 0);
            }

            var expandButton = findChild(previewExpandable, "expandButton")
            mouseClick(expandButton);

            var repeater = findChild(previewExpandable, "repeater")
            for (var i = 0; i < repeater.count; ++i) {
                previewWidgetFactory.active = false;
                wait(0); // spin the event loop otherwise we get warnings because the previous item from the
                         // widget factory has still not been deleted and we change the widgetData
                previewWidgetFactory.widgetData = allWidgetsModel.get(i).properties;
                previewWidgetFactory.widgetType = allWidgetsModel.get(i).type;
                previewWidgetFactory.active = true;

                waitForRendering(repeater.itemAt(i));
                waitForRendering(previewWidgetFactory);

                waitForLazyImage(previewWidgetFactory);
                waitForLazyImage(repeater.itemAt(i));

                UT.Util.waitForBehaviors(previewWidgetFactory);
                UT.Util.waitForBehaviors(repeater.itemAt(i));

                // Check the item inside the expandable has the same height
                // as the one straight from the factory
                verify(repeater.itemAt(i).height > 0);
                compare(repeater.itemAt(i).height, previewWidgetFactory.height);
            }

            mouseClick(expandButton);
            compare(previewExpandable.expanded, false);
            for (var i = 0; i < repeater.count; ++i) {
                tryCompare(repeater.itemAt(i), "height", 0);
            }
        }
    }
}
