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

import QtQuick 2.1
import DashViews 0.1

Item {
    id: root
    signal add(int height)
    signal remove()

    ListViewWithPageHeader {
        id: lvwph
        model: listModel
        height: parent.height
        width: parent.width - controls.width

        delegate: VerticalJournal {
            id: vj
            model: vjModel
            columnWidth: 100
            columnSpacing: 10
            rowSpacing: 10
            width: parent.width
            height: implicitHeight > 100 ? implicitHeight : 100
            delegateCreationBegin: lvwph.contentY
            delegateCreationEnd: lvwph.contentY + lvwph.height

            delegate: Rectangle {
                width: 100
                color: "red";
                height: modelHeight
                border.width: 3

                Text {
                    text: index + "\ny: " + parent.y + "\nheight: " + parent.height
                    x: 10
                    y: 10
                }
            }
        }
    }

    Rectangle {
        id: controls
        height: parent.height
        width: 100
        anchors.right: parent.right
        color: "gray"
        opacity: 0.4

        Rectangle {
            id: addButton
            height: 50
            width: parent.width
            color: "blue"
            Text {
                text: "Add"
                anchors.centerIn: parent
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.add(addField.text)
            }
        }
        TextInput {
            id: addField
            anchors.top: addButton.bottom
            height: 30
            width: parent.width
        }
        Rectangle {
            anchors.top: addField.bottom
            height: 50
            width: parent.width
            color: "red"
            Text {
                text: "Remove"
                anchors.centerIn: parent
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.remove()
            }
        }
    }
}