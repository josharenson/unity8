/*
 * Copyright 2014-2015 Canonical Ltd.
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

import QtQuick 2.0
import Ubuntu.Components 1.1
import Ubuntu.Gestures 0.1 // For TouchGate
import Utils 0.1 // for InputWatcher

FocusScope {
    id: root
    objectName: "surfaceContainer"
    property Item surface: null
    property bool hadSurface: false
    property bool interactive
    property int surfaceOrientationAngle: 0

    onSurfaceChanged: {
        if (surface) {
            // Set the surface focus *after* it is added to the scene to
            // ensure an update to the scene's active focus.
            surface.focus = false;
            surface.parent = root;
            surface.focus = true;
        } else {
            hadSurface = true;
        }
    }
    Binding { target: surface; property: "anchors.fill"; value: root }
    Binding { target: surface; property: "z"; value: 1 }
    Binding { target: surface; property: "enabled"; value: root.interactive; when: surface }
    Binding { target: surface; property: "antialiasing"; value: !root.interactive; when: surface }
    Binding { target: surface; property: "orientationAngle"; value: root.surfaceOrientationAngle; when: surface }

    InputWatcher {
        target: root.surface
        onTargetPressedChanged: {
            if (targetPressed && root.interactive) {
                root.focus = true;
                root.forceActiveFocus();
            }
        }
    }

    TouchGate {
        targetItem: surface
        anchors.fill: root
        enabled: root.surface ? root.surface.enabled : false
        z: 2
    }

    states: [
        State {
            name: "zombie"
            when: surface && !surface.live
        }
    ]
    transitions: [
        Transition {
            from: ""; to: "zombie"
            SequentialAnimation {
                UbuntuNumberAnimation { target: surface; property: "opacity"; to: 0.0
                                        duration: UbuntuAnimation.BriskDuration }
                PropertyAction { target: surface; property: "visible"; value: false }
                ScriptAction { script: { if (root.surface) { root.surface.release(); } } }
            }
        }
    ]
}
