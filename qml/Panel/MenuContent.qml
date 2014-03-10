/*
 * Copyright (C) 2013, 2014 Canonical, Ltd.
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
import Unity.Indicators 0.1 as Indicators
import Utils 0.1
import "../Components"

// FIXME : We dont want to use MainView.
// Need a regular Item which can have tabs with local header.
// https://bugs.launchpad.net/ubuntu-ui-toolkit/+bug/1211704
MainView {
    id: content

    property QtObject indicatorsModel: null
    property bool __contentActive: false
    readonly property int currentMenuIndex: tabs.selectedTabIndex
    backgroundColor: "#221e1c" // FIXME not in palette yet
    property int contentReleaseInterval: 20000
    property bool activeHeader: false
    property real headerHeight: tabs.tabBar.height

    width: units.gu(40)
    height: units.gu(42)

    signal expand
    signal continueHint
    signal resetHint

    function setCurrentMenuIndex(index, animate) {
        if (tabs.selectedTabIndex !== index) {
            if (tabs.selectedTabIndex === -1 || !animate) {
                tabs.tabBar.animate = false;
            }
            tabs.selectedTabIndex = index;
            tabs.tabBar.animate = true;
        }
    }

    function activateContent() {
        contentReleaseTimer.stop();
        __contentActive = true;
    }

    function releaseContent() {
        if (__contentActive) {
            contentReleaseTimer.restart();
        }
    }

    onActiveHeaderChanged: {
        tabs.tabBar.selectionMode = activeHeader;
        tabs.tabBar.alwaysSelectionMode = activeHeader;
    }

    Tabs {
        id: tabs
        objectName: "tabs"
        anchors.fill: parent

        PassthroughMouseArea {
            parent: tabs.tabBar
            anchors.fill: parent

            enabled: activeHeader
            onClicked: expand()
        }

        Connections {
            target: tabs.tabBar
            onPressedChanged: {
                if (tabs.tabBar.pressed) {
                    continueHint();
                } else {
                    resetHint();
                }
            }
        }

        Repeater {
            id: repeater
            model: content.indicatorsModel ? content.indicatorsModel : null
            objectName: "tabsRepeater"

            // FIXME: This is needed because tabs dont handle repeaters well.
            // Due to the child ordering happening after child insertion.
            // QTBUG-32438
            onItemAdded: {
                parent.childrenChanged();
            }

            Tab {
                id: tab
                objectName: model.identifier

                page: Page {
                    Loader {
                        id: loader
                        clip: true
                        anchors.fill: parent
                        source: pageSource
                        asynchronous: true

                        readonly property bool indexActive: index >= 0 && index < menuActivator.count && menuActivator.content[index].active
                        readonly property bool contentActive: content.__contentActive && indexActive

                        onContentActiveChanged: {
                            if (contentActive && item) {
                                item.start()
                            } else if (!contentActive && item) {
                                item.stop()
                            }
                        }

                        onVisibleChanged: {
                            // Reset the indicator states
                            if (!visible && item && item["reset"]) {
                                item.reset()
                            }
                        }

                        onLoaded: {
                            for(var pName in indicatorProperties) {
                                if (item.hasOwnProperty(pName)) {
                                    item[pName] = indicatorProperties[pName]
                                }
                            }
                            if (contentActive && tabs.visible) {
                                item.start()
                            }
                        }

                        Binding {
                            target: tab
                            property: "title"
                            value: loader.item && loader.item.hasOwnProperty("title") && loader.item.title !== "" ? loader.item.title : model.identifier
                        }

                        Binding {
                            target: loader.item
                            property: "objectName"
                            value: identifier + "-page"
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: contentReleaseTimer

        interval: contentReleaseInterval
        onTriggered: {
            content.__contentActive = false;
            menuActivator.clear();
        }
    }

    Indicators.MenuContentActivator {
        id:  menuActivator
        running: content.__contentActive
        baseIndex: content.currentMenuIndex
        count: indicatorsModel.count
    }
}
