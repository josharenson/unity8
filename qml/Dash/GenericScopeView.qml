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
import Ubuntu.Components 1.1
import Utils 0.1
import Unity 0.2
import Dash 0.1
import "../Components"
import "../Components/ListItems" as ListItems

FocusScope {
    id: scopeView

    readonly property bool navigationShown: pageHeaderLoader.item ? pageHeaderLoader.item.bottomItem[0].openList : false
    property bool forceNonInteractive: false
    property var scope: null
    property SortFilterProxyModel categories: categoryFilter
    property bool isCurrent: false
    property alias moving: categoryView.moving
    property bool hasBackAction: false
    property bool enableHeightBehaviorOnNextCreation: false
    property var categoryView: categoryView
    property bool showPageHeader: true
    readonly property alias subPageShown: subPageLoader.subPageShown
    property int paginationCount: 0
    property int paginationIndex: 0
    property alias pageHeaderTotallyVisible: categoryView.pageHeaderTotallyVisible
    property var holdingList: null

    property var scopeStyle: ScopeStyle {
        style: scope ? scope.customizations : {}
    }

    readonly property bool processing: scope ? scope.searchInProgress || subPageLoader.processing : false

    signal backClicked()

    onScopeChanged: {
        floatingSeeLess.companionBase = null;
    }

    function positionAtBeginning() {
        categoryView.positionAtBeginning()
    }

    function showHeader() {
        categoryView.showHeader()
    }

    function closePreview() {
        subPageLoader.closeSubPage()
    }

    function itemClicked(index, result, item, itemModel, resultsModel, limitedCategoryItemCount) {
        if (itemModel.uri.indexOf("scope://") === 0 || scope.id === "clickscope") {
            // TODO Technically it is possible that calling activate() will make the scope emit
            // previewRequested so that we show a preview but there's no scope that does that yet
            // so it's not implemented
            scope.activate(result)
        } else {
            if (scope.preview(result)) {
                openPreview(index, resultsModel, limitedCategoryItemCount);
            }
        }
    }

    function itemPressedAndHeld(index, result, itemModel, resultsModel, limitedCategoryItemCount) {
        if (itemModel.uri.indexOf("scope://") !== 0) {
            if (scope.preview(result)) {
                openPreview(index, resultsModel, limitedCategoryItemCount);
            }
        }
    }

    function openPreview(index, resultsModel, limitedCategoryItemCount) {
        if (limitedCategoryItemCount > 0) {
            previewLimitModel.model = resultsModel;
            previewLimitModel.limit = limitedCategoryItemCount;
            subPageLoader.model = previewLimitModel;
        } else {
            subPageLoader.model = resultsModel;
        }
        subPageLoader.initialIndex = -1;
        subPageLoader.initialIndex = index;
        subPageLoader.openSubPage("preview");
    }

    Binding {
        target: scope
        property: "isActive"
        value: isCurrent && !subPageLoader.open
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
        if (pageHeaderLoader.item && showPageHeader) {
            pageHeaderLoader.item.resetSearch();
        }
        subPageLoader.closeSubPage();
    }

    Binding {
        target: scopeView.scope
        property: "searchQuery"
        value: pageHeaderLoader.item ? pageHeaderLoader.item.searchQuery : ""
        when: isCurrent && showPageHeader
    }

    Binding {
        target: pageHeaderLoader.item
        property: "searchQuery"
        value: scopeView.scope ? scopeView.scope.searchQuery : ""
        when: isCurrent && showPageHeader
    }

    Connections {
        target: scopeView.scope
        onShowDash: subPageLoader.closeSubPage()
        onHideDash: subPageLoader.closeSubPage()
    }

    Rectangle {
        id: colorBackground
        anchors.fill: parent
        color: scopeView.scopeStyle ? scopeView.scopeStyle.background : "transparent"
        visible: color != "transparent"
    }

    ScopeListView {
        id: categoryView
        objectName: "categoryListView"
        interactive: !forceNonInteractive

        x: subPageLoader.open ? -width : 0
        visible: x != -width
        Behavior on x { UbuntuNumberAnimation { } }
        width: parent.width
        height: floatingSeeLess.visible ? parent.height - floatingSeeLess.height + floatingSeeLess.yOffset
                                        : parent.height
        clip: height != parent.height

        model: scopeView.categories
        forceNoClip: subPageLoader.open
        pixelAligned: true

        property string expandedCategoryId: ""
        property int runMaximizeAfterSizeChanges: 0

        readonly property bool pageHeaderTotallyVisible: scopeView.showPageHeader &&
            ((headerItemShownHeight == 0 && categoryView.contentY <= categoryView.originY) || (headerItemShownHeight == pageHeaderLoader.item.height))

        onExpandedCategoryIdChanged: {
            var firstCreated = firstCreatedIndex();
            var shrinkingAny = false;
            var shrinkHeightDifference = 0;
            for (var i = 0; i < createdItemCount(); ++i) {
                var baseItem = item(firstCreated + i);
                if (baseItem.expandable) {
                    var shouldExpand = baseItem.category === expandedCategoryId;
                    if (shouldExpand != baseItem.expanded) {
                        var animate = false;
                        if (!subPageLoader.open) {
                            var animateShrinking = !shouldExpand && baseItem.y + baseItem.item.collapsedHeight + baseItem.seeAllButton.height < categoryView.height;
                            var animateGrowing = shouldExpand && baseItem.y + baseItem.height < categoryView.height;
                            animate = shrinkingAny || animateShrinking || animateGrowing;
                        }

                        if (!shouldExpand) {
                            shrinkingAny = true;
                            shrinkHeightDifference = baseItem.item.expandedHeight - baseItem.item.collapsedHeight;
                        }

                        if (shouldExpand && !subPageLoader.open) {
                            if (!shrinkingAny) {
                                categoryView.maximizeVisibleArea(firstCreated + i, baseItem.item.expandedHeight + baseItem.seeAllButton.height);
                            } else {
                                // If the space that shrinking is smaller than the one we need to grow we'll call maximizeVisibleArea
                                // after the shrink/grow animation ends
                                var growHeightDifference = baseItem.item.expandedHeight - baseItem.item.collapsedHeight;
                                if (growHeightDifference > shrinkHeightDifference) {
                                    runMaximizeAfterSizeChanges = 2;
                                } else {
                                    runMaximizeAfterSizeChanges = 0;
                                }
                            }
                        }

                        baseItem.expand(shouldExpand, animate);
                    }
                }
            }
        }

        delegate: DashCategoryBase {
            id: baseItem
            objectName: "dashCategory" + category

            property Item seeAllButton: seeAll

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
                count: results ? results.count : 0
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

            onHeightChanged: rendererLoader.updateRanges();
            onYChanged: rendererLoader.updateRanges();

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
                        duration: UbuntuAnimation.FastDuration
                        onRunningChanged: {
                            if (!running) {
                                heightBehaviour.enabled = false
                                if (categoryView.runMaximizeAfterSizeChanges > 0) {
                                    categoryView.runMaximizeAfterSizeChanges--;
                                    if (categoryView.runMaximizeAfterSizeChanges == 0) {
                                        var firstCreated = categoryView.firstCreatedIndex();
                                        for (var i = 0; i < categoryView.createdItemCount(); ++i) {
                                            var baseItem = categoryView.item(firstCreated + i);
                                            if (baseItem.category === categoryView.expandedCategoryId) {
                                                categoryView.maximizeVisibleArea(firstCreated + i, baseItem.item.expandedHeight + baseItem.seeAllButton.height);
                                                break;
                                            }
                                        }
                                    }
                                }
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
                        case "horizontal-list": return "CardHorizontalList.qml";
                        case "grid":
                        default: return "CardGrid.qml";
                    }
                }

                onLoaded: {
                    if (item.enableHeightBehavior !== undefined && item.enableHeightBehaviorOnNextCreation !== undefined) {
                        item.enableHeightBehavior = scopeView.enableHeightBehaviorOnNextCreation;
                        scopeView.enableHeightBehaviorOnNextCreation = false;
                    }
                    item.model = Qt.binding(function() { return results })
                    item.objectName = Qt.binding(function() { return categoryId })
                    item.scopeStyle = scopeView.scopeStyle;
                    if (baseItem.expandable) {
                        var shouldExpand = baseItem.category === categoryView.expandedCategoryId;
                        baseItem.expand(shouldExpand, false /*animate*/);
                    }
                    updateRanges();
                    if (scope && scope.id === "clickscope" && (categoryId === "predefined" || categoryId === "local")) {
                        // Yeah, hackish :/
                        cardTool.artShapeSize = Qt.size(units.gu(8), units.gu(7.5));
                    }
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
                        scopeView.itemClicked(index, result, item, itemModel, target.model, categoryItemCount());
                    }

                    onPressAndHold: {
                        scopeView.itemPressedAndHeld(index, result, itemModel, target.model, categoryItemCount());
                    }

                    function categoryItemCount() {
                        var categoryItemCount = -1;
                        if (!rendererLoader.expanded && !seeAllLabel.visible && target.collapsedItemCount > 0) {
                            categoryItemCount = target.collapsedItemCount;
                        }
                        return categoryItemCount;
                    }
                }
                Connections {
                    target: categoryView
                    onOriginYChanged: rendererLoader.updateRanges();
                    onContentYChanged: rendererLoader.updateRanges();
                    onHeightChanged: rendererLoader.updateRanges();
                    onContentHeightChanged: rendererLoader.updateRanges();
                }
                Connections {
                    target: scopeView
                    onIsCurrentChanged: rendererLoader.updateRanges();
                }
                Connections {
                    target: holdingList
                    onMovingChanged: if (!moving) rendererLoader.updateRanges();
                }

                function updateRanges() {
                    if (holdingList && holdingList.moving) {
                        return;
                    }

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

                    if (item && item.hasOwnProperty("visibleRangeBegin")) {
                        item.visibleRangeBegin = Math.max(-baseItem.y, 0)
                        item.visibleRangeEnd = item.visibleRangeBegin + Math.min(categoryView.height, rendererLoader.height)
                    }

                    if (item && item.hasOwnProperty("displayMarginBeginning")) {
                        // TODO do we need item.originY here, test 1300302 once we have a silo
                        // and we can run it on the phone
                        if (scopeView.isCurrent) {
                            // 1073741823 is s^30 -1. A quite big number so that you have "infinite" display margin, but not so
                            // big so that if you add if with itself you're outside the 2^31 int range
                            item.displayMarginBeginning = 1073741823;
                            item.displayMarginEnd = 1073741823;
                        } else if (baseItem.y + baseItem.height <= 0) {
                            // Not visible (item at top of the list viewport)
                            item.displayMarginBeginning = -baseItem.height;
                            item.displayMarginEnd = 0;
                        } else if (baseItem.y >= categoryView.height) {
                            // Not visible (item at bottom of the list viewport)
                            item.displayMarginBeginning = 0;
                            item.displayMarginEnd = -baseItem.height;
                        } else {
                            item.displayMarginBeginning = Math.round(-Math.max(-baseItem.y, 0));
                            item.displayMarginEnd = -Math.round(Math.max(baseItem.height - seeAll.height -
                                                                         categoryView.height + baseItem.y, 0));
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
                height: baseItem.expandable && !baseItem.headerLink ? seeAllLabel.font.pixelSize + units.gu(4) : 0
                visible: height != 0

                onClicked: {
                    if (categoryView.expandedCategoryId !== baseItem.category) {
                        categoryView.expandedCategoryId = baseItem.category;
                        floatingSeeLess.companionBase = baseItem;
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
                    color: scopeStyle ? scopeStyle.foreground : Theme.palette.normal.baseText
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

        DashBackground {
            anchors.fill: parent
            fillMode: Image.TileVertically
            visible: !colorBackground.visible
            z: -1
        }

        sectionProperty: "name"
        sectionDelegate: ListItems.Header {
            objectName: "dashSectionHeader" + (delegate ? delegate.category : "")
            readonly property var delegate: categoryView.item(delegateIndex)
            width: categoryView.width
            height: section != "" ? units.gu(5) : 0
            text: section
            color: scopeStyle ? scopeStyle.foreground : Theme.palette.normal.baseText
            iconName: delegate && delegate.headerLink ? "go-next" : ""
            onClicked: {
                if (delegate.headerLink) scopeView.scope.performQuery(delegate.headerLink);
            }
        }

        pageHeader: scopeView.showPageHeader ? pageHeaderLoader : null
        Loader {
            id: pageHeaderLoader
            width: parent.width
            sourceComponent: scopeView.showPageHeader ? pageHeaderComponent : undefined
            Component {
                id: pageHeaderComponent
                PageHeader {
                    objectName: "scopePageHeader"
                    width: parent.width
                    title: scopeView.scope ? scopeView.scope.name : ""
                    searchHint: scopeView.scope && scopeView.scope.searchHint || i18n.tr("Search")
                    showBackButton: scopeView.hasBackAction
                    searchEntryEnabled: true
                    settingsEnabled: scopeView.scope && scopeView.scope.settings && scopeView.scope.settings.count > 0 || false
                    favoriteEnabled: scopeView.scope && scopeView.scope.id !== "clickscope"
                    favorite: scopeView.scope && scopeView.scope.favorite
                    scopeStyle: scopeView.scopeStyle
                    paginationCount: scopeView.paginationCount
                    paginationIndex: scopeView.paginationIndex

                    bottomItem: DashNavigation {
                        scope: scopeView.scope
                        anchors { left: parent.left; right: parent.right }
                        windowHeight: scopeView.height
                        windowWidth: scopeView.width
                        scopeStyle: scopeView.scopeStyle
                    }

                    onBackClicked: scopeView.backClicked()
                    onSettingsClicked: subPageLoader.openSubPage("settings")
                    onFavoriteClicked: scopeView.scope.favorite = !scopeView.scope.favorite
                }
            }
        }
    }

    Item {
        id: pullToRefreshClippingItem
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height - pullToRefresh.contentY + (pageHeaderLoader.item ? pageHeaderLoader.item.bottomItem[0].height - pageHeaderLoader.item.height : 0)
        clip: true

        PullToRefresh {
            id: pullToRefresh
            objectName: "pullToRefresh"
            target: categoryView

            readonly property real contentY: categoryView.contentY - categoryView.originY
            y: -contentY - units.gu(5)

            onRefresh: {
                refreshing = true
                scopeView.scope.refresh()
            }
            anchors.left: parent.left
            anchors.right: parent.right

            Connections {
                target: scopeView
                onProcessingChanged: if (!scopeView.processing) pullToRefresh.refreshing = false
            }

            style: PullToRefreshScopeStyle {
                anchors.fill: parent
                activationThreshold: units.gu(14)
            }
        }
    }

    AbstractButton {
        id: floatingSeeLess
        objectName: "floatingSeeLess"

        property Item companionTo: companionBase ? companionBase.seeAllButton : null
        property Item companionBase: null
        property bool showBecausePosition: false
        property real yOffset: 0

        anchors {
            left: categoryView.left
            right: categoryView.right
        }
        y: parent.height - height + yOffset
        height: seeLessLabel.font.pixelSize + units.gu(4)
        visible: companionTo && showBecausePosition

        onClicked: categoryView.expandedCategoryId = "";

        function updateVisibility() {
            var companionPos = companionTo.mapToItem(floatingSeeLess, 0, 0);
            showBecausePosition = companionPos.y > 0;

            var posToBase = floatingSeeLess.mapToItem(companionBase, 0, -yOffset).y;
            yOffset = Math.max(0, companionBase.item.collapsedHeight - posToBase);
            yOffset = Math.min(yOffset, height);

            if (!showBecausePosition && categoryView.expandedCategoryId === "") {
                companionBase = null;
            }
        }

        Label {
            id: seeLessLabel
            text: i18n.tr("See less")
            anchors {
                centerIn: parent
                verticalCenterOffset: units.gu(-0.5)
            }
            fontSize: "small"
            font.weight: Font.Bold
            color: scopeStyle ? scopeStyle.foreground : Theme.palette.normal.baseText
        }

        Connections {
            target: floatingSeeLess.companionTo ? categoryView : null
            onContentYChanged: floatingSeeLess.updateVisibility();
        }

        Connections {
            target: floatingSeeLess.companionTo
            onYChanged: floatingSeeLess.updateVisibility();
        }
    }

    LimitProxyModel {
        id: previewLimitModel
    }

    Loader {
        id: subPageLoader
        objectName: "subPageLoader"
        visible: x != width
        width: parent.width
        height: parent.height
        anchors.left: categoryView.right

        property bool open: false
        property var scope: scopeView.scope
        property var scopeStyle: scopeView.scopeStyle
        property int initialIndex: -1
        property var model: null

        readonly property bool processing: item && item.processing || false
        readonly property int count: item && item.count || 0
        readonly property int currentIndex: item && item.currentIndex || 0
        readonly property var currentItem: item && item.currentItem || null

        property string subPage: ""
        readonly property bool subPageShown: visible && status === Loader.Ready

        function openSubPage(page) {
            subPage = page;
        }

        function closeSubPage() {
            open = false;
        }

        source: switch(subPage) {
            case "preview": return "PreviewListView.qml";
            case "settings": return "ScopeSettingsPage.qml";
            default: return "";
        }

        onLoaded: {
            item.scope = Qt.binding(function() { return subPageLoader.scope; } )
            item.scopeStyle = Qt.binding(function() { return subPageLoader.scopeStyle; } )
            if (subPage == "preview") {
                item.open = Qt.binding(function() { return subPageLoader.open; } )
                item.initialIndex = Qt.binding(function() { return subPageLoader.initialIndex; } )
                item.model = Qt.binding(function() { return subPageLoader.model; } )
            }
            open = true;
        }

        onOpenChanged: pageHeaderLoader.item.unfocus()

        onVisibleChanged: if (!visible) subPage = ""

        Connections {
            target: subPageLoader.item
            onBackClicked: subPageLoader.closeSubPage()
        }
    }
}
