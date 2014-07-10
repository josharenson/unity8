/*
 * Copyright (C) 2013-2014 Canonical, Ltd.
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
import Utils 0.1
import Unity 0.2
import Unity.Application 0.1
import Dash 0.1
import "../Components"
import "../Components/ListItems" as ListItems

FocusScope {
    id: scopeView

    property var scope: null
    property SortFilterProxyModel categories: categoryFilter
    property bool isCurrent: false
    property alias moving: categoryView.moving
    property bool hasBackAction: false
    property bool enableHeightBehaviorOnNextCreation: false
    property var categoryView: categoryView

    property var scopeStyle: ScopeStyle {
        style: scope ? scope.customizations : {}
    }

    signal backClicked()

    onScopeChanged: {
        if (scope) {
            scope.activateApplication.connect(activateApp);
        }
    }

    function activateApp(appId) {
        shell.activateApplication(appId);
    }

    function positionAtBeginning() {
        categoryView.positionAtBeginning()
    }

    function showHeader() {
        categoryView.showHeader()
    }

    function closePreview() {
        previewListView.open = false;
    }

    Binding {
        target: scope
        property: "isActive"
        value: isCurrent && !previewListView.open
    }

    SortFilterProxyModel {
        id: categoryFilter
        model: scope ? scope.categories : null
        dynamicSortFilter: true
        filterRole: Categories.RoleCount
        filterRegExp: /^0$/
        invertMatch: true
    }

    onIsCurrentChanged: {
        pageHeader.resetSearch();
        previewListView.open = false;
    }

    Binding {
        target: scopeView.scope
        property: "searchQuery"
        value: pageHeader.searchQuery
        when: isCurrent
    }

    Binding {
        target: pageHeader
        property: "searchQuery"
        value: scopeView.scope ? scopeView.scope.searchQuery : ""
        when: isCurrent
    }

    Connections {
        target: scopeView.scope
        onShowDash: previewListView.open = false;
        onHideDash: previewListView.open = false;
    }

    Rectangle {
        anchors.fill: parent
        color: scopeView.scopeStyle ? scopeView.scopeStyle.background : "transparent"
        visible: color != "transparent"
    }

    ScopeListView {
        id: categoryView
        objectName: "categoryListView"

        x: previewListView.open ? -width : 0
        Behavior on x { UbuntuNumberAnimation { } }
        width: parent.width
        height: parent.height

        model: scopeView.categories
        forceNoClip: previewListView.open

        property string expandedCategoryId: ""

        delegate: Item {
            id: baseItem
            objectName: "dashCategory" + categoryName
            //highlightWhenPressed: false
            //showDivider: false
            height: rendererLoader.height + seeMore.height
            width: parent.width
            clip: true

            Behavior on height {
                NumberAnimation {
                    // Duration and easing here match the ListViewWithPageHeader::m_contentYAnimation
                    // otherwise since both animations can run at the same time you'll get
                    // some visual weirdness.
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
            }

            readonly property string categoryName: categoryId
            readonly property string expansionUri: expansionQuery
            readonly property var item: rendererLoader.item

            CardTool {
                id: cardTool
                objectName: "cardTool"
                count: results.count
                template: model.renderer
                components: model.components
                viewWidth: parent.width
            }

            Loader {
                id: rendererLoader
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: hasSectionHeader ? 0 : units.gu(2)
                }

                source: {
                    switch (cardTool.categoryLayout) {
                        case "carousel": return "CardCarousel.qml";
                        case "vertical-journal": return "CardVerticalJournal.qml";
                        case "running-apps": return "Apps/RunningApplicationsGrid.qml";
                        case "grid":
                        default: return "CardFilterGrid.qml";
                    }
                }

                onLoaded: {
                    if (item.enableHeightBehavior !== undefined && item.enableHeightBehaviorOnNextCreation !== undefined) {
                        item.enableHeightBehavior = scopeView.enableHeightBehaviorOnNextCreation;
                        scopeView.enableHeightBehaviorOnNextCreation = false;
                    }
                    if (source.toString().indexOf("Apps/RunningApplicationsGrid.qml") != -1) {
                        // TODO: this is still a kludge :D Ideally add some kind of hook so that we
                        // can do this from DashApps.qml or think a better way that needs no special casing
                        item.model = Qt.binding(function() { return runningApps; })
                        item.canEnableTerminationMode = Qt.binding(function() { return scopeView.isCurrent })
                    } else {
                        item.model = Qt.binding(function() { return results })
                    }
                    item.objectName = Qt.binding(function() { return categoryId })
                    item.scopeStyle = scopeView.scopeStyle;
                    // TODO: Do something here with previously "seen more" categories that are now being recreated
                    updateDelegateCreationRange();
                    item.cardTool = cardTool;
                }

                Component.onDestruction: {
                    if (item.enableHeightBehavior !== undefined && item.enableHeightBehaviorOnNextCreation !== undefined) {
                        scopeView.enableHeightBehaviorOnNextCreation = item.enableHeightBehaviorOnNextCreation;
                    }
                }

                Connections {
                    target: rendererLoader.item
                    onClicked: {
                        if (scopeView.scope.id === "scopes" || (scopeView.scope.id == "clickscope" && (categoryId == "local" || categoryId == "store"))) {
                            // TODO Technically it is possible that calling activate() will make the scope emit
                            // previewRequested so that we show a preview but there's no scope that does that yet
                            // so it's not implemented
                            scopeView.scope.activate(result)
                        } else {
                            previewListView.model = target.model;
                            previewListView.currentIndex = -1
                            previewListView.currentIndex = index;
                            previewListView.open = true
                        }
                    }
                    onPressAndHold: {
                        previewListView.model = target.model;
                        previewListView.currentIndex = -1
                        previewListView.currentIndex = index;
                        previewListView.open = true
                    }
                }
                Connections {
                    target: categoryView
                    onOriginYChanged: rendererLoader.updateDelegateCreationRange();
                    onContentYChanged: rendererLoader.updateDelegateCreationRange();
                    onHeightChanged: rendererLoader.updateDelegateCreationRange();
                    onContentHeightChanged: rendererLoader.updateDelegateCreationRange();
                }

                function updateDelegateCreationRange() {
                    if (categoryView.moving) {
                        // Do not update the range if we are overshooting up or down, since we'll come back
                        // to the stable position and delete/create items without any reason
                        if (categoryView.contentY < categoryView.originY) {
                            return;
                        } else if (categoryView.contentHeight - categoryView.originY > categoryView.height &&
                                   categoryView.contentY + categoryView.height > categoryView.contentHeight) {
                            return;
                        }
                    }

                    if (item && item.hasOwnProperty("displayMarginBeginning")) {
                        // TODO do we need item.originY here, test 1300302 once we have a silo
                        // and we can run it on the phone
                        if (baseItem.y + baseItem.height <= 0) {
                            // Not visible (item at top of the list viewport)
                            item.displayMarginBeginning = -baseItem.height;
                            item.displayMarginEnd = 0;
                        } else if (baseItem.y >= categoryView.height) {
                            // Not visible (item at bottom of the list viewport)
                            item.displayMarginBeginning = 0;
                            item.displayMarginEnd = -baseItem.height;
                        } else {
                            item.displayMarginBeginning = -Math.max(-baseItem.y, 0);
                            item.displayMarginEnd = -Math.max(baseItem.height - categoryView.height + baseItem.y, 0)
                        }
                    }
                }
            }

            SeeMore {
                id: seeMore

                height: visible ? implicitHeight : 0

                canSeeMore: item && item.canGrow
                onToggled: item.canGrow ? item.grow() : item.shrink();

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                visible: item && (item.canGrow || item.canShrink)
            }

            Image {
                visible: index != 0
                anchors {
                    top: rendererLoader.top
                    left: parent.left
                    right: parent.right
                }
                fillMode: Image.Stretch
                source: "graphics/dash_divider_top_lightgrad.png"
                z: -1
            }

            Image {
                // FIXME Should not rely on model.count but view.count, but ListViewWithPageHeader doesn't expose it yet.
                visible: index != categoryView.model.count - 1
                anchors {
                    bottom: seeMore.bottom
                    left: parent.left
                    right: parent.right
                }
                fillMode: Image.Stretch
                source: "graphics/dash_divider_top_darkgrad.png"
                z: -1
            }

            onHeightChanged: rendererLoader.updateDelegateCreationRange();
            onYChanged: rendererLoader.updateDelegateCreationRange();
        }

        sectionProperty: "name"
        sectionDelegate: ListItems.Header {
            objectName: "dashSectionHeader" + (delegate ? delegate.categoryName : "")
            property var delegate: categoryView.item(delegateIndex)
            readonly property string expansionQuery: delegate && delegate.expansionUri || ""
            width: categoryView.width
            text: section
            textColor: scopeStyle ? scopeStyle.foreground : "grey"
            image: expansionQuery ? "graphics/tabbarchevron.png" : ""
            onClicked: {
                if (expansionQuery != "") {
                    scopeView.scope.performQuery(expansionQuery)
                }
            }
        }

        pageHeader: PageHeader {
            id: pageHeader
            objectName: "scopePageHeader"
            width: parent.width
            title: scopeView.scope ? scopeView.scope.name : ""
            showBackButton: scopeView.hasBackAction
            searchEntryEnabled: true
            searchInProgress: scopeView.scope ? scopeView.scope.searchInProgress : false
            scopeStyle: scopeView.scopeStyle

            bottomItem: DashDepartments {
                scope: scopeView.scope
                width: parent.width <= units.gu(60) ? parent.width : units.gu(40)
                anchors.right: parent.right
                windowHeight: scopeView.height
                windowWidth: scopeView.width
                scopeStyle: scopeView.scopeStyle
            }

            onBackClicked: scopeView.backClicked()
        }
    }

    PreviewListView {
        id: previewListView
        objectName: "previewListView"
        visible: x != width
        scope: scopeView.scope
        scopeStyle: scopeView.scopeStyle
        width: parent.width
        height: parent.height
        anchors.left: categoryView.right
    }

}
