/*
 * Copyright (C) 2014 Canonical, Ltd.
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

/*! \brief This component constructs the Preview UI.
 *
 *  Currently it displays all the widgets in a flickable column.
 */

Item {
    id: root

    /*! \brief Model containing preview widgets.
     *
     *  The model should expose "widgetId", "type" and "properties" roles, as well as
     *  have a triggered(QString widgetId, QString actionId, QVariantMap data) method,
     *  that's called when actions are executed in widgets.
     */
    property var previewModel

    //! \brief Should be set to true if this preview is currently displayed.
    property bool isCurrent: false

    clip: true

    Connections {
        target: shell.applicationManager
        onMainStageFocusedApplicationChanged: {
            root.close();
        }
        onSideStageFocusedApplicationChanged: {
            root.close();
        }
    }

    onPreviewModelChanged: processingMouseArea.enabled = false

    MouseArea {
        anchors.fill: parent
    }

    Row {
        id: row

        spacing: units.gu(1)
        anchors { fill: parent; margins: spacing }

        Repeater {
            model: 1

            delegate: ListView {
                id: column
                anchors { top: parent.top; bottom: parent.bottom }
                width: row.width
                spacing: row.spacing
                bottomMargin: Qt.inputMethod.visible ? Qt.inputMethod.keyboardRectangle.height : 0

                model: previewModel

                Behavior on contentY { UbuntuNumberAnimation { } }

                delegate: PreviewWidgetFactory {
                    widgetId: model.widgetId
                    widgetType: model.type
                    widgetData: model.properties
                    isCurrentPreview: root.isCurrent
                    anchors { left: parent.left; right: parent.right }

                    onTriggered: {
                        processingMouseArea.enabled = true;
                        previewModel.triggered(widgetId, actionId, data);
                    }

                    onFocusChanged: if (focus) column.positionViewAtIndex(index, ListView.Contain)

                    onHeightChanged: if (focus) column.positionViewAtIndex(index, ListView.Contain)
                }
            }
        }
    }

    MouseArea {
        id: processingMouseArea
        objectName: "processingMouseArea"
        anchors.fill: parent
        enabled: false
    }
}
