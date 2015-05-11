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

import QtQuick 2.2
import Ubuntu.Components 0.1
import Ubuntu.Gestures 0.1
import Unity.Application 0.1
import Unity.Session 0.1
import Utils 0.1
import "../Components"

Rectangle {
    id: root

    // Controls to be set from outside
    property int dragAreaWidth
    property real maximizedAppTopMargin
    property bool interactive
    property bool spreadEnabled: true // If false, animations and right edge will be disabled
    property real inverseProgress: 0 // This is the progress for left edge drags, in pixels.
    property int orientation: Qt.PortraitOrientation
    property QtObject applicationManager: ApplicationManager
    property bool focusFirstApp: true // If false, focused app will appear on right edge like other apps
    property bool altTabEnabled: true
    property real startScale: 1.1
    property real endScale: 0.7

    // How far left the stage has been dragged
    readonly property real dragProgress: spreadRepeater.count > 0 ? -spreadRepeater.itemAt(0).xTranslate : 0

    readonly property alias dragging: spreadDragArea.dragging

    // Only used by the tutorial right now, when it is teasing the right edge
    property real dragAreaOverlap

    signal opened()

    color: "#111111"

    function select(appId) {
        spreadView.snapTo(priv.indexOf(appId));
    }

    onWidthChanged: {
        spreadView.selectedIndex = -1;
        spreadView.phase = 0;
        spreadView.contentX = -spreadView.shift;
    }

    onInverseProgressChanged: {
        // This can't be a simple binding because that would be triggered after this handler
        // while we need it active before doing the anition left/right
        priv.animateX = (inverseProgress == 0)
        if (inverseProgress == 0 && priv.oldInverseProgress > 0) {
            // left edge drag released. Minimum distance is given by design.
            if (priv.oldInverseProgress > units.gu(22)) {
                applicationManager.requestFocusApplication("unity8-dash");
            }
        }
        priv.oldInverseProgress = inverseProgress;
    }

    Connections {
        target: applicationManager

        onFocusRequested: {
            if (spreadView.phase > 0) {
                spreadView.snapTo(priv.indexOf(appId));
            } else {
                applicationManager.focusApplication(appId);
            }
        }

        onApplicationAdded: {
            if (spreadView.phase == 2) {
                spreadView.snapTo(applicationManager.count - 1);
            } else {
                spreadView.phase = 0;
                spreadView.contentX = -spreadView.shift;
                applicationManager.focusApplication(appId);
            }
        }

        onApplicationRemoved: {
            // Unless we're closing the app ourselves in the spread,
            // lets make sure the spread doesn't mess up by the changing app list.
            if (spreadView.closingIndex == -1) {
                spreadView.phase = 0;
                spreadView.contentX = -spreadView.shift;
                focusTopMostApp();
            }
        }

        function focusTopMostApp() {
            if (applicationManager.count > 0) {
                var topmostApp = applicationManager.get(0);
                applicationManager.focusApplication(topmostApp.appId);
            }
        }
    }

    QtObject {
        id: priv

        readonly property int firstSpreadIndex: root.focusFirstApp ? 1 : 0
        property string focusedAppId: applicationManager.focusedApplicationId
        property var focusedApplication: applicationManager.findApplication(focusedAppId)
        property var focusedAppDelegate: null

        property real oldInverseProgress: 0
        property bool animateX: false

        onFocusedAppIdChanged: focusedAppDelegate = spreadRepeater.itemAt(0);

        onFocusedAppDelegateChanged: {
            if (focusedAppDelegate) {
                focusedAppDelegate.focus = true;
            }
        }

        function indexOf(appId) {
            for (var i = 0; i < applicationManager.count; i++) {
                if (applicationManager.get(i).appId == appId) {
                    return i;
                }
            }
            return -1;
        }

    }

    Flickable {
        id: spreadView
        objectName: "spreadView"
        anchors.fill: parent
        interactive: (spreadDragArea.dragging || phase > 1) && draggedDelegateCount === 0
        contentWidth: spreadRow.width - shift
        contentX: -shift

        // This indicates when the spreadView is active. That means, all the animations
        // are activated and tiles need to line up for the spread.
        readonly property bool active: shiftedContentX > 0 || spreadDragArea.dragging || !root.focusFirstApp

        // The flickable needs to fill the screen in order to get touch events all over.
        // However, we don't want to the user to be able to scroll back all the way. For
        // that, the beginning of the gesture starts with a negative value for contentX
        // so the flickable wants to pull it into the view already. "shift" tunes the
        // distance where to "lock" the content.
        readonly property real shift: width / 2
        readonly property real shiftedContentX: contentX + shift

        property int tileDistance: width / 4

        // Those markers mark the various positions in the spread (ratio to screen width from right to left):
        // 0 - 1: following finger, snap back to the beginning on release
        property real positionMarker1: 0.2
        // 1 - 2: curved snapping movement, snap to app 1 on release
        property real positionMarker2: 0.3
        // 2 - 3: movement follows finger, snaps back to app 1 on release
        property real positionMarker3: 0.35
        // passing 3, we detach movement from the finger and snap to 4
        property real positionMarker4: 0.9

        // This is where the first app snaps to when bringing it in from the right edge.
        property real snapPosition: 0.7

        // Phase of the animation:
        // 0: Starting from right edge, a new app (index 1) comes in from the right
        // 1: The app has reached the first snap position.
        // 2: The list is dragged further and snaps into the spread view when entering phase 2
        property int phase: 0

        property int selectedIndex: -1
        property int draggedDelegateCount: 0
        property int closingIndex: -1

        property bool focusChanging: false

        onShiftedContentXChanged: {
            switch (phase) {
            case 0:
                if (shiftedContentX > width * positionMarker2) {
                    phase = 1;
                }
                break;
            case 1:
                if (shiftedContentX < width * positionMarker2) {
                    phase = 0;
                } else if (shiftedContentX >= width * positionMarker4 && !spreadDragArea.dragging) {
                    phase = 2;
                }
                break;
            }
        }

        function snap() {
            if (shiftedContentX < positionMarker1 * width) {
                snapAnimation.targetContentX = -shift;
                snapAnimation.start();
            } else if (shiftedContentX < positionMarker2 * width) {
                snapTo(1);
            } else if (shiftedContentX < positionMarker3 * width) {
                snapTo(1);
            } else if (phase < 2){
                // Add 1 pixel to make sure we definitely hit positionMarker4 even with rounding errors of the animation.
                snapAnimation.targetContentX = width * positionMarker4 + 1 - shift;
                snapAnimation.start();
                root.opened();
            }
        }
        function snapTo(index) {
            if (!root.altTabEnabled) {
                // Reset to start instead
                snapAnimation.targetContentX = -shift;
                snapAnimation.start();
                return;
            }
            if (applicationManager.count <= index) {
                // In case we're trying to snap to some non existing app, lets snap back to the first one
                index = 0;
            }
            spreadView.selectedIndex = index;
            // If we're not in full spread mode yet, always unwind to start pos
            // otherwise unwind up to progress 0 of the selected index
            if (spreadView.phase < 2) {
                snapAnimation.targetContentX = -shift;
            } else {
                snapAnimation.targetContentX = -shift + index * spreadView.tileDistance;
            }
            snapAnimation.start();
        }

        // In case the applicationManager already holds an app when starting up we're missing animations
        // Make sure we end up in the same state
        Component.onCompleted: {
            spreadView.contentX = -spreadView.shift
            priv.animateX = true;
            snapAnimation.complete();
        }

        SequentialAnimation {
            id: snapAnimation
            property int targetContentX: -spreadView.shift

            UbuntuNumberAnimation {
                target: spreadView
                property: "contentX"
                to: snapAnimation.targetContentX
                duration: UbuntuAnimation.FastDuration
            }

            ScriptAction {
                script: {
                    if (spreadView.selectedIndex >= 0) {
                        applicationManager.focusApplication(applicationManager.get(spreadView.selectedIndex).appId);

                        spreadView.selectedIndex = -1;
                        spreadView.phase = 0;
                        spreadView.contentX = -spreadView.shift;
                    }
                }
            }
        }

        MouseArea {
            id: spreadRow
            // This width controls how much the spread can be flicked left/right. It's composed of:
            //  tileDistance * app count (with a minimum of 3 apps, in order to also allow moving 1 and 2 apps a bit)
            //  + some constant value (still scales with the screen width) which looks good and somewhat fills the screen
            width: Math.max(3, applicationManager.count) * spreadView.tileDistance + (spreadView.width - spreadView.tileDistance) * 1.5
            height: parent.height
            Behavior on width {
                enabled: spreadView.closingIndex >= 0
                UbuntuNumberAnimation {}
            }
            onWidthChanged: {
                if (spreadView.closingIndex >= 0) {
                    spreadView.contentX = Math.min(spreadView.contentX, width - spreadView.width - spreadView.shift);
                }
            }

            x: spreadView.contentX

            onClicked: {
                if (root.altTabEnabled) {
                    spreadView.snapTo(0);
                }
            }

            Repeater {
                id: spreadRepeater
                objectName: "spreadRepeater"
                model: applicationManager
                delegate: TransformedSpreadDelegate {
                    id: appDelegate
                    objectName: "appDelegate" + index
                    startAngle: 45
                    endAngle: 5
                    startScale: root.startScale
                    endScale: root.endScale
                    startDistance: spreadView.tileDistance
                    endDistance: units.gu(.5)
                    width: spreadView.width
                    height: spreadView.height
                    selected: spreadView.selectedIndex == index
                    otherSelected: spreadView.selectedIndex >= 0 && !selected
                    interactive: !spreadView.interactive && spreadView.phase === 0
                            && spreadView.shiftedContentX === 0 && root.interactive && isFocused
                    swipeToCloseEnabled: spreadView.interactive && root.interactive && !snapAnimation.running
                    maximizedAppTopMargin: root.maximizedAppTopMargin
                    dropShadow: spreadView.active ||
                                (priv.focusedAppDelegate && priv.focusedAppDelegate.x !== 0)
                    focusFirstApp: root.focusFirstApp

                    readonly property bool isDash: model.appId == "unity8-dash"

                    z: isDash && !spreadView.active ? -1 : behavioredIndex

                    x: {
                        // focused app is always positioned at 0 except when following left edge drag
                        if (isFocused) {
                            if (!isDash && root.inverseProgress > 0 && spreadView.phase === 0) {
                                return root.inverseProgress;
                            }
                           return 0;
                        }
                        if (isDash && !spreadView.active && !spreadDragArea.dragging) {
                           return 0;
                        }

                        // Otherwise line up for the spread
                        return spreadView.width + spreadIndex * spreadView.tileDistance;
                    }

                    application: applicationManager.get(index)
                    closeable: !isDash

                    property real behavioredIndex: index
                    Behavior on behavioredIndex {
                        enabled: spreadView.closingIndex >= 0
                        UbuntuNumberAnimation {
                            id: appXAnimation
                            onRunningChanged: {
                                if (!running) {
                                    spreadView.closingIndex = -1;
                                }
                            }
                        }
                    }

                    Behavior on x {
                        enabled: root.spreadEnabled &&
                                 !spreadView.active &&
                                 !snapAnimation.running &&
                                 priv.animateX
                        UbuntuNumberAnimation {
                            duration: UbuntuAnimation.BriskDuration
                            onRunningChanged: {
                                if (!running && root.inverseProgress == 0) {
                                    spreadView.focusChanging = false;
                                }
                            }
                        }
                    }

                    // Each tile has a different progress value running from 0 to 1.
                    // 0: means the tile is at the right edge.
                    // 1: means the tile has finished the main animation towards the left edge.
                    // >1: after the main animation has finished, tiles will continue to move very slowly to the left
                    progress: {
                        var tileProgress = (spreadView.shiftedContentX - behavioredIndex * spreadView.tileDistance) / spreadView.width;
                        // Tile 1 needs to move directly from the beginning...
                        if (root.focusFirstApp && behavioredIndex == 1 && spreadView.phase < 2) {
                            tileProgress += spreadView.tileDistance / spreadView.width;
                        }
                        // Limiting progress to ~0 and 1.7 to avoid binding calculations when tiles are not
                        // visible.
                        // < 0 :  The tile is outside the screen on the right
                        // > 1.7: The tile is *very* close to the left edge and covered by other tiles now.
                        // Using 0.0001 to differentiate when a tile should still be visible (==0)
                        // or we can hide it (< 0)
                        tileProgress = Math.max(-0.0001, Math.min(1.7, tileProgress));
                        return tileProgress;
                    }

                    // This mostly is the same as progress, just adds the snapping to phase 1 for tiles 0 and 1
                    animatedProgress: {
                        if (spreadView.phase == 0 && index <= priv.firstSpreadIndex) {
                            if (progress < spreadView.positionMarker1) {
                                return progress;
                            } else if (progress < spreadView.positionMarker1 + 0.05){
                                // p : 0.05 = x : pm2
                                return spreadView.positionMarker1 + (progress - spreadView.positionMarker1) * (spreadView.positionMarker2 - spreadView.positionMarker1) / 0.05
                            } else {
                                return spreadView.positionMarker2;
                            }
                        }
                        return progress;
                    }

                    // Hiding tiles when their progress is negative or reached the maximum
                    visible: (progress >= 0 && progress < 1.7) ||
                             (isDash && priv.focusedAppDelegate.x !== 0)

                    Binding {
                        target: appDelegate
                        property: "orientation"
                        when: appDelegate.interactive
                        value: root.orientation
                    }

                    onClicked: {
                        if (root.altTabEnabled && spreadView.phase == 2) {
                            if (applicationManager.focusedApplicationId == applicationManager.get(index).appId) {
                                spreadView.snapTo(index);
                            } else {
                                applicationManager.requestFocusApplication(applicationManager.get(index).appId);
                            }
                        }
                    }

                    onDraggedChanged: {
                        if (dragged) {
                            spreadView.draggedDelegateCount++;
                        } else {
                            spreadView.draggedDelegateCount--;
                        }
                    }

                    onClosed: {
                        spreadView.closingIndex = index;
                        applicationManager.stopApplication(applicationManager.get(index).appId);
                    }
                }
            }
        }
    }

    DirectionalDragArea {
        id: spreadDragArea
        objectName: "spreadDragArea"
        direction: Direction.Leftwards
        enabled: (spreadView.phase != 2 && root.spreadEnabled) || dragging

        anchors { top: parent.top; right: parent.right; bottom: parent.bottom; rightMargin: -root.dragAreaOverlap }
        width: root.dragAreaWidth

        property var gesturePoints: new Array()

        onTouchXChanged: {
            if (dragging) {
                // Gesture recognized. Let's move the spreadView with the finger
                var dragX = Math.min(touchX + width, width); // Prevent dragging rightwards
                dragX = -dragX + spreadDragArea.width - spreadView.shift;
                // Don't allow dragging further than the animation crossing with phase2's animation
                var maxMovement =  spreadView.width * spreadView.positionMarker4 - spreadView.shift;

                spreadView.contentX = Math.min(dragX, maxMovement);
            } else {
                // Initial touch. Let's reset the spreadView to the starting position.
                spreadView.phase = 0;
                spreadView.contentX = -spreadView.shift;
            }

            gesturePoints.push(touchX);
        }

        onDraggingChanged: {
            if (dragging) {
                // A potential edge-drag gesture has started. Start recording it
                gesturePoints = [];
            } else {
                // Ok. The user released. Find out if it was a one-way movement.
                var oneWayFlick = true;
                var smallestX = spreadDragArea.width;
                for (var i = 0; i < gesturePoints.length; i++) {
                    if (gesturePoints[i] >= smallestX) {
                        oneWayFlick = false;
                        break;
                    }
                    smallestX = gesturePoints[i];
                }
                gesturePoints = [];

                if (oneWayFlick && spreadView.shiftedContentX > units.gu(2) &&
                        spreadView.shiftedContentX < spreadView.positionMarker1 * spreadView.width) {
                    // If it was a short one-way movement, do the Alt+Tab switch
                    // no matter if we didn't cross positionMarker1 yet.
                    spreadView.snapTo(1);
                } else if (!dragging) {
                    // otherwise snap to the closest snap position we can find
                    // (might be back to start, to app 1 or to spread)
                    spreadView.snap();
                }
            }
        }
    }
}
