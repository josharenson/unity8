/*
 * Copyright (C) 2014-2016 Canonical, Ltd.
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
import Ubuntu.Components 1.3
import Unity.Application 0.1
import "../Components/PanelState"
import "../Components"
import Utils 0.1
import Ubuntu.Gestures 0.1
import GlobalShortcut 1.0

AbstractStage {
    id: root
    anchors.fill: parent

    // functions to be called from outside
    function updateFocusedAppOrientation() { /* TODO */ }
    function updateFocusedAppOrientationAnimated() { /* TODO */}
    function pushRightEdge(amount) {
        if (spread.state === "") {
            edgeBarrier.push(amount);
        }
    }

    mainApp: ApplicationManager.focusedApplicationId
            ? ApplicationManager.findApplication(ApplicationManager.focusedApplicationId)
            : null

    Connections {
        target: ApplicationManager
        onApplicationAdded: {
            if (spread.state == "altTab") {
                spread.state = "";
            }

            ApplicationManager.focusApplication(appId);
        }

        onApplicationRemoved: {
            priv.focusNext();
        }

        onFocusRequested: {
            var delegate = priv.appDelegate(appId);
            delegate.restore();

            if (spread.state == "altTab") {
                spread.cancel();
            }
        }
    }

    GlobalShortcut {
        id: closeWindowShortcut
        shortcut: Qt.AltModifier|Qt.Key_F4
        onTriggered: priv.closeApplication(priv.focusedAppDelegate, priv.focusedAppId)
        active: priv.focusedAppId !== ""
    }

    GlobalShortcut {
        id: showSpreadShortcut
        shortcut: Qt.MetaModifier|Qt.Key_W
        onTriggered: spread.state = "altTab"
    }

    GlobalShortcut {
        id: minimizeAllShortcut
        shortcut: Qt.MetaModifier|Qt.ControlModifier|Qt.Key_D
        onTriggered: priv.minimizeAllWindows()
    }

    GlobalShortcut {
        id: maximizeWindowShortcut
        shortcut: Qt.MetaModifier|Qt.ControlModifier|Qt.Key_Up
        onTriggered: priv.focusedAppDelegate.maximize()
        active: priv.focusedAppDelegate !== null
    }

    GlobalShortcut {
        id: maximizeWindowLeftShortcut
        shortcut: Qt.MetaModifier|Qt.ControlModifier|Qt.Key_Left
        onTriggered: priv.focusedAppDelegate.maximizeLeft()
        active: priv.focusedAppDelegate !== null
    }

    GlobalShortcut {
        id: maximizeWindowRightShortcut
        shortcut: Qt.MetaModifier|Qt.ControlModifier|Qt.Key_Right
        onTriggered: priv.focusedAppDelegate.maximizeRight()
        active: priv.focusedAppDelegate !== null
    }

    GlobalShortcut {
        id: minimizeRestoreShortcut
        shortcut: Qt.MetaModifier|Qt.ControlModifier|Qt.Key_Down
        onTriggered: priv.focusedAppDelegate.maximized || priv.focusedAppDelegate.maximizedLeft || priv.focusedAppDelegate.maximizedRight
                     ? priv.focusedAppDelegate.restoreFromMaximized() : priv.focusedAppDelegate.minimize()
        active: priv.focusedAppDelegate !== null
    }

    QtObject {
        id: priv

        readonly property string focusedAppId: ApplicationManager.focusedApplicationId
        readonly property var focusedAppDelegate: {
            var index = indexOf(focusedAppId);
            return index >= 0 && index < appRepeater.count ? appRepeater.itemAt(index) : null
        }
        onFocusedAppDelegateChanged: updateForegroundMaximizedApp();

        property int foregroundMaximizedAppZ: -1
        property int foregroundMaximizedAppIndex: -1 // for stuff like drop shadow and focusing maximized app by clicking panel

        function updateForegroundMaximizedApp() {
            var tmp = -1;
            var tmpAppId = -1;
            for (var i = appRepeater.count - 1; i >= 0; i--) {
                var item = appRepeater.itemAt(i);
                if (item && item.visuallyMaximized) {
                    tmpAppId = i;
                    tmp = Math.max(tmp, item.normalZ);
                }
            }
            foregroundMaximizedAppZ = tmp;
            foregroundMaximizedAppIndex = tmpAppId;
        }

        function indexOf(appId) {
            for (var i = 0; i < ApplicationManager.count; i++) {
                if (ApplicationManager.get(i).appId == appId) {
                    return i;
                }
            }
            return -1;
        }

        function minimizeAllWindows() {
            for (var i = 0; i < appRepeater.count; i++) {
                var appDelegate = appRepeater.itemAt(i);
                if (appDelegate && !appDelegate.minimized) {
                    appDelegate.minimize();
                }
            }

            ApplicationManager.unfocusCurrentApplication(); // no app should have focus at this point
        }

        function focusNext() {
            ApplicationManager.unfocusCurrentApplication();
            for (var i = 0; i < appRepeater.count; i++) {
                var appDelegate = appRepeater.itemAt(i);
                if (appDelegate && !appDelegate.minimized) {
                    ApplicationManager.focusApplication(appDelegate.appId);
                    return;
                }
            }
        }

        function appDelegate(appId) {
            var appIndex = indexOf(appId);
            return appRepeater.itemAt(appIndex);
        }

        function closeApplication(delegate, appId) {
            var del = delegate || appDelegate(appId);
            del.state = "closing";
        }
    }

    Connections {
        target: PanelState
        onClose: {
            priv.closeApplication(priv.focusedAppDelegate, ApplicationManager.focusedApplicationId)
        }
        onMinimize: priv.focusedAppDelegate && priv.focusedAppDelegate.minimize();
        onMaximize: priv.focusedAppDelegate // don't restore minimized apps when double clicking the panel
                    && priv.focusedAppDelegate.restoreFromMaximized();
        onFocusMaximizedApp: if (priv.foregroundMaximizedAppIndex != -1) {
                                 ApplicationManager.focusApplication(appRepeater.itemAt(priv.foregroundMaximizedAppIndex).appId);
                             }
    }

    Binding {
        target: PanelState
        property: "buttonsVisible"
        value: priv.focusedAppDelegate !== null && priv.focusedAppDelegate.maximized // FIXME for Locally integrated menus
               && spread.state == ""
    }

    Binding {
        target: PanelState
        property: "title"
        value: {
            if (priv.focusedAppDelegate !== null && spread.state == "") {
                if (priv.focusedAppDelegate.maximized)
                    return priv.focusedAppDelegate.title
                else
                    return priv.focusedAppDelegate.appName
            }
            return ""
        }
        when: priv.focusedAppDelegate
    }

    Binding {
        target: PanelState
        property: "dropShadow"
        value: priv.focusedAppDelegate && !priv.focusedAppDelegate.maximized && priv.foregroundMaximizedAppIndex !== -1
    }

    Component.onDestruction: {
        PanelState.title = "";
        PanelState.buttonsVisible = false;
        PanelState.dropShadow = false;
    }

    FocusScope {
        id: appContainer
        objectName: "appContainer"
        anchors.fill: parent
        focus: spread.state !== "altTab"

        CrossFadeImage {
            id: wallpaper
            anchors.fill: parent
            source: root.background
            sourceSize { height: root.height; width: root.width }
            fillMode: Image.PreserveAspectCrop
        }

        Repeater {
            id: appRepeater
            model: ApplicationManager
            objectName: "appRepeater"

            delegate: FocusScope {
                id: appDelegate
                objectName: "appDelegate_" + appId
                // z might be overriden in some cases by effects, but we need z ordering
                // to calculate occlusion detection
                property int normalZ: ApplicationManager.count - index
                z: normalZ
                y: PanelState.panelHeight
                focus: appId === priv.focusedAppId
                width: decoratedWindow.width
                height: decoratedWindow.height
                property alias requestedWidth: decoratedWindow.requestedWidth
                property alias requestedHeight: decoratedWindow.requestedHeight

                QtObject {
                    id: appDelegatePrivate
                    property bool maximized: false
                    property bool maximizedLeft: false
                    property bool maximizedRight: false
                    property bool minimized: false
                }
                readonly property alias maximized: appDelegatePrivate.maximized
                readonly property alias maximizedLeft: appDelegatePrivate.maximizedLeft
                readonly property alias maximizedRight: appDelegatePrivate.maximizedRight
                readonly property alias minimized: appDelegatePrivate.minimized

                readonly property string appId: model.appId
                property bool animationsEnabled: true
                property alias title: decoratedWindow.title
                readonly property string appName: model.name
                property bool visuallyMaximized: false
                property bool visuallyMinimized: false

                onFocusChanged: {
                    if (focus && ApplicationManager.focusedApplicationId !== appId) {
                        ApplicationManager.focusApplication(appId);
                    }
                }

                onVisuallyMaximizedChanged: priv.updateForegroundMaximizedApp()

                visible: !visuallyMinimized &&
                         !greeter.fullyShown &&
                         (priv.foregroundMaximizedAppZ === -1 || priv.foregroundMaximizedAppZ <= z) ||
                         (spread.state == "altTab" && index === spread.highlightedIndex)

                Binding {
                    target: ApplicationManager.get(index)
                    property: "requestedState"
                    // TODO: figure out some lifecycle policy, like suspending minimized apps
                    //       if running on a tablet or something.
                    // TODO: If the device has a dozen suspended apps because it was running
                    //       in staged mode, when it switches to Windowed mode it will suddenly
                    //       resume all those apps at once. We might want to avoid that.
                    value: ApplicationInfoInterface.RequestedRunning // Always running for now
                }

                function maximize(animated) {
                    animationsEnabled = (animated === undefined) || animated;
                    appDelegatePrivate.minimized = false;
                    appDelegatePrivate.maximized = true;
                    appDelegatePrivate.maximizedLeft = false;
                    appDelegatePrivate.maximizedRight = false;
                }
                function maximizeLeft() {
                    appDelegatePrivate.minimized = false;
                    appDelegatePrivate.maximized = false;
                    appDelegatePrivate.maximizedLeft = true;
                    appDelegatePrivate.maximizedRight = false;
                }
                function maximizeRight() {
                    appDelegatePrivate.minimized = false;
                    appDelegatePrivate.maximized = false;
                    appDelegatePrivate.maximizedLeft = false;
                    appDelegatePrivate.maximizedRight = true;
                }
                function minimize(animated) {
                    animationsEnabled = (animated === undefined) || animated;
                    appDelegatePrivate.minimized = true;
                }
                function restoreFromMaximized(animated) {
                    animationsEnabled = (animated === undefined) || animated;
                    appDelegatePrivate.minimized = false;
                    appDelegatePrivate.maximized = false;
                    appDelegatePrivate.maximizedLeft = false;
                    appDelegatePrivate.maximizedRight = false;
                }
                function restore(animated) {
                    animationsEnabled = (animated === undefined) || animated;
                    appDelegatePrivate.minimized = false;
                    if (maximized)
                        maximize();
                    else if (maximizedLeft)
                        maximizeLeft();
                    else if (maximizedRight)
                        maximizeRight();
                    ApplicationManager.focusApplication(appId);
                }

                states: [
                    State {
                        name: "closing"
                        PropertyChanges { // freeze the values
                            target: appDelegate; explicit: true; restoreEntryValues: false;
                            x: appDelegate.x; y: appDelegate.y
                            requestedWidth: appDelegate.width; requestedHeight: appDelegate.height
                        }
                    },
                    State {
                        name: "fullscreen"; when: decoratedWindow.fullscreen
                        extend: "maximized"
                        PropertyChanges {
                            target: appDelegate;
                            y: -PanelState.panelHeight
                        }
                    },
                    State {
                        name: "normal";
                        when: !appDelegate.maximized && !appDelegate.minimized
                              && !appDelegate.maximizedLeft && !appDelegate.maximizedRight
                        PropertyChanges {
                            target: appDelegate;
                            visuallyMinimized: false;
                            visuallyMaximized: false
                        }
                    },
                    State {
                        name: "maximized"; when: appDelegate.maximized && !appDelegate.minimized
                        PropertyChanges {
                            target: appDelegate;
                            x: 0; y: 0;
                            requestedWidth: root.width; requestedHeight: root.height;
                            visuallyMinimized: false;
                            visuallyMaximized: true
                        }
                    },
                    State {
                        name: "maximizedLeft"; when: appDelegate.maximizedLeft && !appDelegate.minimized
                        PropertyChanges { target: appDelegate; x: 0; y: PanelState.panelHeight;
                            requestedWidth: root.width/2; requestedHeight: root.height - PanelState.panelHeight }
                    },
                    State {
                        name: "maximizedRight"; when: appDelegate.maximizedRight && !appDelegate.minimized
                        PropertyChanges { target: appDelegate; x: root.width/2; y: PanelState.panelHeight;
                            requestedWidth: root.width/2; requestedHeight: root.height - PanelState.panelHeight }
                    },
                    State {
                        name: "minimized"; when: appDelegate.minimized
                        PropertyChanges {
                            target: appDelegate;
                            x: -appDelegate.width / 2;
                            scale: units.gu(5) / appDelegate.width;
                            opacity: 0
                            visuallyMinimized: true;
                            visuallyMaximized: false
                        }
                    }
                ]
                transitions: [
                    Transition {
                        to: "normal"
                        enabled: appDelegate.animationsEnabled
                        PropertyAction { target: appDelegate; properties: "visuallyMinimized,visuallyMaximized" }
                        UbuntuNumberAnimation { target: appDelegate; properties: "x,y,requestedWidth,requestedHeight" }
                        NumberAnimation {
                            target: appDelegate
                            property: 'scale'
                            from: 0.85
                            to: 1
                            duration: UbuntuAnimation.SnapDuration
                            easing: UbuntuAnimation.StandardEasing
                        }
                        NumberAnimation {
                            target: appDelegate
                            property: 'opacity'
                            from: 0
                            to: 1
                            duration: UbuntuAnimation.SnapDuration
                            easing: UbuntuAnimation.StandardEasing
                        }
                    },
                    Transition {
                        to: "minimized"
                        enabled: appDelegate.animationsEnabled
                        PropertyAction { target: appDelegate; property: "visuallyMaximized" }
                        SequentialAnimation {
                            UbuntuNumberAnimation { target: appDelegate; properties: "x,y,opacity,requestedWidth,requestedHeight,scale" }
                            PropertyAction { target: appDelegate; property: "visuallyMinimized" }
                            ScriptAction {
                                script: {
                                    if (appDelegate.minimized) {
                                        priv.focusNext();
                                    }
                                }
                            }
                        }
                    },
                    Transition {
                        to: "closing"
                        SequentialAnimation {
                            PropertyAction { target: appDelegate; properties: "x,y,requestedWidth,requestedHeight" }
                            ParallelAnimation {
                                NumberAnimation {
                                    target: appDelegate
                                    property: 'scale'
                                    from: 1
                                    to: 0.85
                                    duration: UbuntuAnimation.SnapDuration
                                    easing: UbuntuAnimation.StandardEasingReverse
                                }
                                NumberAnimation {
                                    target: appDelegate
                                    property: 'opacity'
                                    from: 1
                                    to: 0
                                    duration: UbuntuAnimation.SnapDuration
                                    easing: UbuntuAnimation.StandardEasingReverse
                                }
                            }
                            ScriptAction {
                                script: {
                                    ApplicationManager.stopApplication(appId);
                                }
                            }
                        }
                    },
                    Transition {
                        to: "*" //maximized and fullscreen
                        enabled: appDelegate.animationsEnabled
                        PropertyAction { target: appDelegate; property: "visuallyMinimized" }
                        SequentialAnimation {
                            UbuntuNumberAnimation { target: appDelegate; properties: "x,y,opacity,requestedWidth,requestedHeight,scale" }
                            PropertyAction { target: appDelegate; property: "visuallyMaximized" }
                        }
                    }
                ]

                Binding {
                    id: previewBinding
                    target: appDelegate
                    property: "z"
                    value: ApplicationManager.count + 1
                    when: index == spread.highlightedIndex && blurLayer.ready
                }

                WindowResizeArea {
                    objectName: "windowResizeArea"
                    target: appDelegate
                    minWidth: units.gu(10)
                    minHeight: units.gu(10)
                    borderThickness: units.gu(2)
                    windowId: model.appId // FIXME: Change this to point to windowId once we have such a thing
                    screenWidth: root.width
                    screenHeight: root.height

                    onPressed: { ApplicationManager.focusApplication(model.appId) }
                }

                DecoratedWindow {
                    id: decoratedWindow
                    objectName: "decoratedWindow"
                    anchors.left: appDelegate.left
                    anchors.top: appDelegate.top
                    application: ApplicationManager.get(index)
                    active: ApplicationManager.focusedApplicationId === model.appId
                    focus: true

                    onClose: priv.closeApplication(appDelegate, model.appId)
                    onMaximize: appDelegate.maximized || appDelegate.maximizedLeft || appDelegate.maximizedRight
                                ? appDelegate.restoreFromMaximized() : appDelegate.maximize()
                    onMinimize: appDelegate.minimize()
                    onDecorationPressed: { ApplicationManager.focusApplication(model.appId) }
                }
            }
        }
    }

    BlurLayer {
        id: blurLayer
        anchors.fill: parent
        source: appContainer
        visible: false
    }

    Rectangle {
        id: spreadBackground
        anchors.fill: parent
        color: "#55000000"
        visible: false
    }

    MouseArea {
        id: eventEater
        anchors.fill: parent
        visible: spreadBackground.visible
        enabled: visible
    }

    EdgeBarrier {
        id: edgeBarrier

        // NB: it does its own positioning according to the specified edge
        edge: Qt.RightEdge

        onPassed: { spread.show(); }
        material: Component {
            Item {
                Rectangle {
                    width: parent.height
                    height: parent.width
                    rotation: 90
                    anchors.centerIn: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(0.16,0.16,0.16,0.7)}
                        GradientStop { position: 1.0; color: Qt.rgba(0.16,0.16,0.16,0)}
                    }
                }
            }
        }
    }

    DirectionalDragArea {
        direction: Direction.Leftwards
        anchors { top: parent.top; right: parent.right; bottom: parent.bottom }
        width: units.gu(1)
        onDraggingChanged: { if (dragging) { spread.show(); } }
    }

    DesktopSpread {
        id: spread
        objectName: "spread"
        anchors.fill: parent
        workspace: appContainer
        focus: state == "altTab"
        altTabPressed: root.altTabPressed
    }
}
