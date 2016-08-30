/*
 * Copyright 2014-2016 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import Unity.Application 0.1

FocusScope {
    id: root
    implicitWidth: surfaceContainer.implicitWidth
    implicitHeight: surfaceContainer.implicitHeight

    // to be read from outside
    property alias interactive: surfaceContainer.interactive
    property bool orientationChangesEnabled: d.supportsSurfaceResize ? d.surfaceOldEnoughToBeResized : true
    readonly property string title: surface && surface.name !== "" ? surface.name : d.name

    // overridable from outside
    property bool fullscreen: {
        if (surface) {
            return surface.state === Mir.FullscreenState;
        } else if (applicationInstance) {
            return applicationInstance.fullscreen;
        } else {
            return false;
        }
    }

    // to be set from outside
    property QtObject surface
    property QtObject applicationInstance
    property int surfaceOrientationAngle
    property alias resizeSurface: surfaceContainer.resizeSurface
    property int requestedWidth: -1
    property int requestedHeight: -1
    property real splashRotation: 0

    readonly property int minimumWidth: surface ? surface.minimumWidth : 0
    readonly property int minimumHeight: surface ? surface.minimumHeight : 0
    readonly property int maximumWidth: surface ? surface.maximumWidth : 0
    readonly property int maximumHeight: surface ? surface.maximumHeight : 0
    readonly property int widthIncrement: surface ? surface.widthIncrement : 0
    readonly property int heightIncrement: surface ? surface.heightIncrement : 0

    onSurfaceChanged: {
        // The order in which the instructions are executed here matters, to that the correct state
        // transitions in stateGroup take place.
        // More specifically, the moment surfaceContainer.surface gets updated relative to the
        // other instructions.
        if (surface) {
            surfaceContainer.surface = surface;
            d.liveSurface = surface.live;
            d.hadSurface = false;
            surfaceInitTimer.start();
        } else {
            if (d.surfaceInitialized) {
                d.hadSurface = true;
            }
            d.surfaceInitialized = false;
            surfaceContainer.surface = null;
        }
    }

    QtObject {
        id: d

        readonly property QtObject application: root.applicationInstance ? root.applicationInstance.application : null

        property bool liveSurface: false;
        property var con: Connections {
            target: root.surface
            onLiveChanged: d.liveSurface = root.surface.live
        }
        // using liveSurface instead of root.surface.live because with the latter
        // this expression is not reevaluated when root.surface changes
        readonly property bool needToTakeScreenshot: root.surface && d.surfaceInitialized && !d.liveSurface
                                                  && applicationState !== ApplicationInstanceInterface.Running
        onNeedToTakeScreenshotChanged: {
            if (needToTakeScreenshot && screenshotImage.status === Image.Null) {
                screenshotImage.take();
            }
        }

        // helpers so that we don't have to check for the existence of an application everywhere
        // (in order to avoid breaking qml binding due to a javascript exception)
        readonly property string name: application ? application.name : ""
        readonly property url icon: application ? application.icon : ""
        readonly property int applicationState: applicationInstance ? applicationInstance.state : -1
        readonly property string splashTitle: application ? application.splashTitle : ""
        readonly property url splashImage: application ? application.splashImage : ""
        readonly property bool splashShowHeader: application ? application.splashShowHeader : true
        readonly property color splashColor: application ? application.splashColor : "#00000000"
        readonly property color splashColorHeader: application ? application.splashColorHeader : "#00000000"
        readonly property color splashColorFooter: application ? application.splashColorFooter : "#00000000"

        // Whether the Application had a surface before but lost it.
        property bool hadSurface: false

        //FIXME - this is a hack to avoid the first few rendered frames as they
        // might show the UI accommodating due to surface resizes on startup.
        // Remove this when possible
        property bool surfaceInitialized: false

        readonly property bool supportsSurfaceResize:
                application &&
                ((application.supportedOrientations & Qt.PortraitOrientation)
                  || (application.supportedOrientations & Qt.InvertedPortraitOrientation))
                &&
                ((application.supportedOrientations & Qt.LandscapeOrientation)
                 || (application.supportedOrientations & Qt.InvertedLandscapeOrientation))

        property bool surfaceOldEnoughToBeResized: false

        property Item focusedSurface: promptSurfacesRepeater.count === 0 ? surfaceContainer
                                                                         : promptSurfacesRepeater.first
        onFocusedSurfaceChanged: {
            if (focusedSurface) {
                focusedSurface.focus = true;
            }
        }
    }

    Binding {
        target: d.application
        property: "initialSurfaceSize"
        value: Qt.size(root.requestedWidth, root.requestedHeight)
    }

    Timer {
        id: surfaceInitTimer
        interval: 100
        onTriggered: {
            if (root.surface && root.surface.live) {d.surfaceInitialized = true;}
        }
    }

    Timer {
        id: surfaceIsOldTimer
        interval: 1000
        onTriggered: { if (stateGroup.state === "surface") { d.surfaceOldEnoughToBeResized = true; } }
    }

    Image {
        id: screenshotImage
        objectName: "screenshotImage"
        anchors.fill: parent
        antialiasing: !root.interactive
        z: 1

        function take() {
            // Save memory by using a half-resolution (thus quarter size) screenshot.
            // Do not make this a binding, we can only take the screenshot once!
            surfaceContainer.grabToImage(
                function(result) {
                    screenshotImage.source = result.url;
                },
                Qt.size(root.width / 2, root.height / 2));
        }
    }

    Loader {
        id: splashLoader
        visible: active
        active: false
        anchors.fill: parent
        z: screenshotImage.z + 1
        sourceComponent: Component {
            Splash {
                id: splash
                title: d.splashTitle ? d.splashTitle : d.name
                imageSource: d.splashImage
                icon: d.icon
                showHeader: d.splashShowHeader
                backgroundColor: d.splashColor
                headerColor: d.splashColorHeader
                footerColor: d.splashColorFooter

                rotation: root.splashRotation
                anchors.centerIn: parent
                width: rotation == 0 || rotation == 180 ? root.width : root.height
                height: rotation == 0 || rotation == 180 ? root.height : root.width
            }
        }
    }

    SurfaceContainer {
        id: surfaceContainer
        z: splashLoader.z + 1
        requestedWidth: root.requestedWidth
        requestedHeight: root.requestedHeight
        surfaceOrientationAngle: d.application && d.application.rotatesWindowContents ? root.surfaceOrientationAngle : 0
    }

    Repeater {
        id: promptSurfacesRepeater
        objectName: "promptSurfacesRepeater"
        // show only along with the top-most application surface
        model: {
            if (root.applicationInstance && root.surface === root.applicationInstance.surfaceList.first) {
                return root.applicationInstance.promptSurfaceList;
            } else {
                return null;
            }
        }
        delegate: SurfaceContainer {
            id: promptSurfaceContainer
            interactive: index === 0 && root.interactive
            surface: model.surface
            width: root.width
            height: root.height
            isPromptSurface: true
            z: surfaceContainer.z + (promptSurfacesRepeater.count - index)
            property int index: model.index
            onIndexChanged: updateFirst()
            Component.onCompleted: updateFirst()
            function updateFirst() {
                if (index === 0) {
                    promptSurfacesRepeater.first = promptSurfaceContainer;
                }
            }
        }
        onCountChanged: {
            if (count === 0) {
                first = null;
            }
        }
        property Item first: null
    }

    // SurfaceContainer size drives ApplicationWindow size
    Binding {
        target: root; property: "width"
        value: stateGroup.state === "surface" ? surfaceContainer.width : root.requestedWidth
        when: root.requestedWidth >= 0
    }
    Binding {
        target: root; property: "height"
        value: stateGroup.state === "surface" ? surfaceContainer.height : root.requestedHeight
        when: root.requestedHeight >= 0
    }

    // ApplicationWindow size drives SurfaceContainer size
    Binding {
        target: surfaceContainer; property: "width"; value: root.width
        when: root.requestedWidth < 0
    }
    Binding {
        target: surfaceContainer; property: "height"; value: root.height
        when: root.requestedHeight < 0
    }

    StateGroup {
        id: stateGroup
        objectName: "applicationWindowStateGroup"
        states: [
            State {
                name: "void"
                when:
                     d.hadSurface && (!root.surface || !d.surfaceInitialized)
                     &&
                     screenshotImage.status !== Image.Ready
            },
            State {
                name: "splashScreen"
                when:
                     !d.hadSurface && (!root.surface || !d.surfaceInitialized)
                     &&
                     screenshotImage.status !== Image.Ready
            },
            State {
                name: "surface"
                when:
                      (root.surface && d.surfaceInitialized)
                      &&
                      (d.liveSurface ||
                       (d.applicationState !== ApplicationInstanceInterface.Running
                        && screenshotImage.status !== Image.Ready))
            },
            State {
                name: "screenshot"
                when:
                      screenshotImage.status === Image.Ready
                      &&
                      (d.applicationState !== ApplicationInstanceInterface.Running
                       || !root.surface || !d.surfaceInitialized)
            },
            State {
                // This is a dead end. From here we expect the surface to be removed from the model
                // shortly after we stop referencing to it in our SurfaceContainer.
                name: "closed"
                when:
                      // The surface died while the application is running. It must have been closed
                      // by the shell or the application decided to destroy it by itself
                      root.surface && d.surfaceInitialized && !d.liveSurface
                      && d.applicationState === ApplicationInstanceInterface.Running
            }
        ]

        transitions: [
            Transition {
                from: ""; to: "splashScreen"
                PropertyAction { target: splashLoader; property: "active"; value: true }
                PropertyAction { target: surfaceContainer
                                 property: "visible"; value: false }
            },
            Transition {
                from: "splashScreen"; to: "surface"
                SequentialAnimation {
                    PropertyAction { target: surfaceContainer
                                     property: "opacity"; value: 0.0 }
                    PropertyAction { target: surfaceContainer
                                     property: "visible"; value: true }
                    UbuntuNumberAnimation { target: surfaceContainer; property: "opacity";
                                            from: 0.0; to: 1.0
                                            duration: UbuntuAnimation.BriskDuration }
                    ScriptAction { script: {
                        splashLoader.active = false;
                        surfaceIsOldTimer.start();
                    } }
                }
            },
            Transition {
                from: "surface"; to: "splashScreen"
                SequentialAnimation {
                    ScriptAction { script: {
                        surfaceIsOldTimer.stop();
                        d.surfaceOldEnoughToBeResized = false;
                        splashLoader.active = true;
                        surfaceContainer.visible = true;
                    } }
                    UbuntuNumberAnimation { target: splashLoader; property: "opacity";
                                            from: 0.0; to: 1.0
                                            duration: UbuntuAnimation.BriskDuration }
                    PropertyAction { target: surfaceContainer
                                     property: "visible"; value: false }
                }
            },
            Transition {
                from: "surface"; to: "screenshot"
                SequentialAnimation {
                    ScriptAction { script: {
                        surfaceIsOldTimer.stop();
                        d.surfaceOldEnoughToBeResized = false;
                        screenshotImage.visible = true;
                    } }
                    UbuntuNumberAnimation { target: screenshotImage; property: "opacity";
                                            from: 0.0; to: 1.0
                                            duration: UbuntuAnimation.BriskDuration }
                    ScriptAction { script: {
                        surfaceContainer.visible = false;
                        surfaceContainer.surface = null;
                        d.hadSurface = true;
                    } }
                }
            },
            Transition {
                from: "screenshot"; to: "surface"
                SequentialAnimation {
                    PropertyAction { target: surfaceContainer
                                     property: "visible"; value: true }
                    UbuntuNumberAnimation { target: screenshotImage; property: "opacity";
                                            from: 1.0; to: 0.0
                                            duration: UbuntuAnimation.BriskDuration }
                    ScriptAction { script: {
                        screenshotImage.visible = false;
                        screenshotImage.source = "";
                        surfaceIsOldTimer.start();
                    } }
                }
            },
            Transition {
                from: "splashScreen"; to: "screenshot"
                SequentialAnimation {
                    PropertyAction { target: screenshotImage
                                     property: "visible"; value: true }
                    UbuntuNumberAnimation { target: screenshotImage; property: "opacity";
                                            from: 0.0; to: 1.0
                                            duration: UbuntuAnimation.BriskDuration }
                    PropertyAction { target: splashLoader; property: "active"; value: false }
                }
            },
            Transition {
                from: "surface"; to: "void"
                ScriptAction { script: {
                    surfaceIsOldTimer.stop();
                    d.surfaceOldEnoughToBeResized = false;
                    surfaceContainer.visible = false;
                } }
            },
            Transition {
                from: "void"; to: "surface"
                SequentialAnimation {
                    PropertyAction { target: surfaceContainer; property: "opacity"; value: 0.0 }
                    PropertyAction { target: surfaceContainer; property: "visible"; value: true }
                    UbuntuNumberAnimation { target: surfaceContainer; property: "opacity";
                                            from: 0.0; to: 1.0
                                            duration: UbuntuAnimation.BriskDuration }
                    ScriptAction { script: {
                        surfaceIsOldTimer.start();
                    } }
                }
            },
            Transition {
                to: "closed"
                SequentialAnimation {
                    ScriptAction { script: {
                        surfaceContainer.visible = false;
                        surfaceContainer.surface = null;
                        d.hadSurface = true;
                    } }
                }
            }
        ]
    }

}
