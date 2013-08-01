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
import "../Components"
import "../Components/ListItems" as ListItems
import "Music"

ScopeView {
    id: scopeView

    property var categoryNames: [
        i18n.tr("Featured"),
        i18n.tr("Recent"),
        i18n.tr("New Releases"),
        i18n.tr("Top Charting")
    ]

    onIsCurrentChanged: {
        pageHeader.resetSearch();
    }

    onMovementStarted: categoryView.showHeader()

    Binding {
        target: scopeView.scope
        property: "searchQuery"
        value: pageHeader.searchQuery
    }

    Connections {
        target: panel
        onSearchClicked: if (isCurrent) {
            pageHeader.triggerSearch()
            categoryView.showHeader()
        }
    }

    function getRenderer(categoryId) {
        switch (categoryId) {
            case "featured": return "Music/MusicCarousel.qml"
            default: return "Music/MusicFilterGrid.qml"
        }
    }

    ScopeListView {
        id: categoryView
        anchors.fill: parent
        model: scopeView.categories

        onAtYEndChanged: if (atYEnd) endReached()
        onMovingChanged: if (moving && atYEnd) endReached()

        delegate: ListItems.Base {
            id: base
            highlightWhenPressed: false

            property string categoryId: model.categoryId

            Loader {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                source: scopeView.getRenderer(base.categoryId)
                onLoaded: {
                    item.model = results
                }
            }
        }

        sectionProperty: "name"
        sectionDelegate: ListItems.Header {
            width: categoryView.width
            text: i18n.tr(section)
        }
        pageHeader: PageHeader {
            id: pageHeader
            width: categoryView.width
            text: i18n.tr("Music")
            searchEntryEnabled: true
            searchHistory: scopeView.searchHistory
        }
    }
}
