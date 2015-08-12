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
import Ubuntu.Components 0.1
import Unity 0.2
import "../Components"
import "Previews" as Previews

Item {
    id: root

    property int initialIndex: -1
    property var scope: null
    property var scopeStyle: null
    property string categoryId

    property alias showSignatureLine: header.showSignatureLine

    property alias open: previewListView.open
    property alias model: previewListView.model
    property alias currentIndex: previewListView.currentIndex
    property alias currentItem: previewListView.currentItem
    property alias count: previewListView.count

    readonly property bool processing: currentItem && (!currentItem.previewModel.loaded
                                                       || currentItem.previewModel.processingAction)

    signal backClicked()

    PageHeader {
        id: header
        objectName: "pageHeader"
        width: parent.width
        title: root.scope ? root.scope.name : ""
        showBackButton: true
        searchEntryEnabled: false
        scopeStyle: root.scopeStyle

        onBackClicked: root.backClicked()
    }

    ListView  {
        id: previewListView
        objectName: "listView"
        anchors {
            top: header.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        orientation: ListView.Horizontal
        highlightRangeMode: ListView.StrictlyEnforceRange
        snapMode: ListView.SnapOneItem
        boundsBehavior: Flickable.DragAndOvershootBounds
        highlightMoveDuration: 250
        flickDeceleration: units.gu(625)
        maximumFlickVelocity: width * 5
        cacheBuffer: 0

        property bool open: false

        onOpenChanged: {
            if (!open) {
                // Cancel any pending preview requests or actions
                if (previewListView.currentItem && previewListView.currentItem.previewData !== undefined) {
                    previewListView.currentItem.previewData.cancelAction();
                }
                root.scope.cancelActivation();
                model = undefined;
            }
        }

        onCountChanged: {
            if (count > 0 && initialIndex >= 0) {
                currentIndex = initialIndex;
                initialIndex = -1;
            }
        }

        delegate: Previews.Preview {
            id: preview
            objectName: "preview" + index
            height: previewListView.height
            width: previewListView.width

            isCurrent: ListView.isCurrentItem

            previewModel: {
                var previewStack = root.scope.preview(result, root.categoryId);
                return previewStack.getPreviewModel(0);
            }
            scopeStyle: root.scopeStyle
        }
    }

    MouseArea {
        id: processingMouseArea
        objectName: "processingMouseArea"
        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
            bottom: parent.bottom
        }

        enabled: root.processing
    }
}
