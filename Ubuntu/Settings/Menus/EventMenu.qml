/*
 * Copyright 2013 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by Andrea Cimitan <andrea.cimitan@canonical.com>
 */

import QtQuick 2.0
import Ubuntu.Components 0.1 as Components
import Ubuntu.Settings.Components 0.1 as USC
import Ubuntu.Components.ListItems 0.1 as ListItems

ListItems.Standard {
    id: menu

    property alias iconSource: iconVisual.source
    property alias time: dateLabel.text
    property alias eventColor: iconVisual.color

    USC.IconVisual {
        id: iconVisual
        source: "image://theme/calendar"
        visible: status == Image.Ready

        height: Math.min(units.gu(5), parent.height - units.gu(1))
        width: height

        Component.onCompleted: {
            icon = iconVisual;
            anchors.verticalCenter = parent.verticalCenter
        }
    }

    control: Components.Label {
        id: dateLabel
        color: Theme.palette.normal.backgroundText

        Connections {
            target: menu.__mouseArea
            onClicked: {
                menu.clicked();
            }
        }
    }
}
