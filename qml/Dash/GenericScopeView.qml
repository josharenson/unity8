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
        pixelAligned: true

        property string expandedCategoryId: ""

        delegate: ListItems.Base {
            id: baseItem
            objectName: "dashCategory" + category
            highlightWhenPressed: false
            showDivider: false

            readonly property bool expandable: {
                if (categoryView.model.count === 1) return false;
                if (cardTool.template && cardTool.template["collapsed-rows"] === 0) return false;
                if (item && item.expandedHeight > item.collapsedHeight) return true;
                return false;
            }
            property bool expanded: false
            readonly property string category: categoryId
            readonly property string headerLink: model.headerLink
            readonly property var item: rendererLoader.item

            function expand(expand, animate) {
                heightBehaviour.enabled = animate;
                expanded = expand;
            }

            CardTool {
                id: cardTool
                objectName: "cardTool"
                count: results.count
                template: model.renderer
                components: model.components
                viewWidth: parent.width
            }

            onExpandableChanged: {
                // This can happen with the VJ that doesn't know how height it will be on creation
                // so doesn't set expandable until a bit too late for onLoaded
                if (expandable) {
                    var shouldExpand = baseItem.category === categoryView.expandedCategoryId;
                    baseItem.expand(shouldExpand, false /*animate*/);
                }
            }

            onHeightChanged: rendererLoader.updateDelegateCreationRange();
            onYChanged: rendererLoader.updateDelegateCreationRange();

            Loader {
                id: rendererLoader
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: name != "" ? 0 : units.gu(2)
                }

                Behavior on height {
                    id: heightBehaviour
                    enabled: false
                    animation: UbuntuNumberAnimation {
                        onRunningChanged: {
                            if (!running) {
                                heightBehaviour.enabled = false
                            }
                        }
                    }
                }

                readonly property bool expanded: baseItem.expanded || !baseItem.expandable
                height: expanded ? item.expandedHeight : item.collapsedHeight

                source: {
                    switch (cardTool.categoryLayout) {
                        case "carousel": return "CardCarousel.qml";
                        case "vertical-journal": return "CardVerticalJournal.qml";
                        case "running-apps": return "Apps/RunningApplicationsGrid.qml";
                        case "grid":
                        default: return "CardGrid.qml";
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
                    if (baseItem.expandable) {
                        var shouldExpand = categoryId === categoryView.expandedCategoryId;
                        baseItem.expand(shouldExpand, false /*animate*/);
                    }
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
                        if (scopeView.scope.id === "scopes" || scopeView.scope.id == "clickscope") {
                            // TODO Technically it is possible that calling activate() will make the scope emit
                            // previewRequested so that we show a preview but there's no scope that does that yet
                            // so it's not implemented
                            scopeView.scope.activate(result)
                        } else {
                            openPreview(index);
                        }
                    }
                    onPressAndHold: openPreview(index)

                    function openPreview(index) {
                        if (!rendererLoader.expanded && !seeAllLabel.visible && target.collapsedItemCount > 0) {
                            previewLimitModel.model = target.model;
                            previewLimitModel.limit = target.collapsedItemCount;
                            previewListView.model = previewLimitModel;
                        } else {
                            previewListView.model = target.model;
                        }
                        previewListView.currentIndex = -1;
                        previewListView.currentIndex = index;
                        previewListView.open = true;
                    }
                }
                Connections {
                    target: categoryView
                    onExpandedCategoryIdChanged: {
                        collapseAllButExpandedCategory();
                    }
                    function collapseAllButExpandedCategory() {
                        var item = rendererLoader.item;
                        if (baseItem.expandable) {
                            var shouldExpand = categoryId === categoryView.expandedCategoryId;
                            if (shouldExpand != baseItem.expanded) {
                                // If the filter animation will be seen start it, otherwise, just flip the switch
                                var shrinkingVisible = !shouldExpand && y + item.collapsedHeight + seeAll.height < categoryView.height;
                                var growingVisible = shouldExpand && y + height < categoryView.height;
                                if (!previewListView.open || shouldExpand) {
                                    var animate = shrinkingVisible || growingVisible;
                                    baseItem.expand(shouldExpand, animate)
                                    if (shouldExpand && !previewListView.open) {
                                        categoryView.maximizeVisibleArea(index, item.expandedHeight + seeAll.height);
                                    }
                                }
                            }
                        }
                    }
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
                            item.displayMarginEnd = -Math.max(baseItem.height - seeAll.height
                                                              - categoryView.height + baseItem.y, 0)
                        }
                    }
                }
            }

            AbstractButton {
                id: seeAll
                objectName: "seeAll"
                anchors {
                    top: rendererLoader.bottom
                    left: parent.left
                    right: parent.right
                }
                height: seeAllLabel.visible ? seeAllLabel.font.pixelSize + units.gu(6) : 0

                onClicked: {
                    if (categoryView.expandedCategoryId != baseItem.category) {
                        categoryView.expandedCategoryId = baseItem.category;
                    } else {
                        categoryView.expandedCategoryId = "";
                    }
                }

                Label {
                    id: seeAllLabel
                    text: baseItem.expanded ? i18n.tr("See less") : i18n.tr("See all")
                    anchors {
                        centerIn: parent
                        verticalCenterOffset: units.gu(-0.5)
                    }
                    fontSize: "small"
                    font.weight: Font.Bold
                    color: scopeStyle ? scopeStyle.foreground : "grey"
                    visible: baseItem.expandable && !baseItem.headerLink
                }
            }

            Image {
                visible: index != 0
                anchors {
                    top: parent.top
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
                    bottom: seeAll.bottom
                    left: parent.left
                    right: parent.right
                }
                fillMode: Image.Stretch
                source: "graphics/dash_divider_top_darkgrad.png"
                z: -1
            }
        }

        sectionProperty: "name"
        sectionDelegate: ListItems.Header {
            objectName: "dashSectionHeader" + (delegate ? delegate.category : "")
            readonly property var delegate: categoryView.item(delegateIndex)
            width: categoryView.width
            height: section != "" ? units.gu(5) : 0
            text: section
            color: scopeStyle ? scopeStyle.foreground : "grey"
            iconName: delegate && delegate.headerLink ? "go-next" : ""
            onClicked: {
                if (delegate.headerLink) scopeView.scope.performQuery(delegate.headerLink);
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

    LimitProxyModel {
        id: previewLimitModel
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

        onOpenChanged: {
            pageHeader.unfocus();
        }
    }

}
