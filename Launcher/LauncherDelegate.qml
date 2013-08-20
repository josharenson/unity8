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

Item {
    id: root

    property string iconName

    property bool highlighted: false
    property real maxAngle: 0
    property bool inverted: false

    readonly property int effectiveHeight: Math.cos(angle * Math.PI / 180) * itemHeight
    readonly property real foldedHeight: Math.cos(maxAngle * Math.PI / 180) * itemHeight

    property int itemWidth
    property int itemHeight
    // The angle used for rotating
    property real angle: 0
    // This is the offset that keeps the items inside the panel
    property real offset: 0
    property real itemOpacity: 1
    property real brightness: 0

    Item {
        id: iconItem
        width: parent.itemWidth
        height: parent.itemHeight
        anchors.centerIn: parent

        UbuntuShape {
            id: iconShape
            anchors.fill: parent
            anchors.margins: units.gu(0.5)
            radius: "medium"

            image: Image {
                id: iconImage
                sourceSize.width: iconShape.width
                sourceSize.height: iconShape.height
                source: "../graphics/applicationIcons/" + iconName + ".png"
                property string iconName: root.iconName
                onIconNameChanged: shaderEffectSource.scheduleUpdate();
            }
        }

        BorderImage {
            id: overlayHighlight
            anchors.centerIn: iconItem
            rotation: inverted ? 180 : 0
            source: isSelected ? "graphics/selected.sci" : "graphics/non-selected.sci"
            width: root.itemWidth + units.gu(0.5)
            height: root.itemHeight + units.gu(0.5)
            property bool isSelected: root.highlighted
            onIsSelectedChanged: shaderEffectSource.scheduleUpdate();
        }
    }

    ShaderEffect {
        id: transformEffect
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.offset
        width: parent.itemWidth
        height: parent.itemHeight
        property real itemOpacity: root.itemOpacity
        property real brightness: Math.max(-1, root.brightness)
        property real angle: root.angle
        rotation: root.inverted ? 180 : 0

        property variant source: ShaderEffectSource {
            id: shaderEffectSource
            sourceItem: iconItem
            hideSource: true
            live: false
        }

        transform: [
            // Rotating 3 times at top/bottom because that increases the perspective.
            // This is a hack, but as QML does not support real 3D coordinates
            // getting a higher perspective can only be done by a hack. This is the most
            // readable/understandable one I could come up with.
            Rotation {
                axis { x: 1; y: 0; z: 0 }
                origin { x: iconItem.width / 2; y: angle > 0 ? 0 : iconItem.height; z: 0 }
                angle: root.angle * 0.7
            },
            Rotation {
                axis { x: 1; y: 0; z: 0 }
                origin { x: iconItem.width / 2; y: angle > 0 ? 0 : iconItem.height; z: 0 }
                angle: root.angle * 0.7
            },
            Rotation {
                axis { x: 1; y: 0; z: 0 }
                origin { x: iconItem.width / 2; y: angle > 0 ? 0 : iconItem.height; z: 0 }
                angle: root.angle * 0.7
            },
            // Because rotating it 3 times moves it more to the front/back, i.e. it gets
            // bigger/smaller and we need a scale to compensate that again.
            Scale {
                xScale: 1 - (Math.abs(angle) / 500)
                yScale: 1 - (Math.abs(angle) / 500)
                origin { x: iconItem.width / 2; y: iconItem.height / 2}
            }
        ]

        // Using a fragment shader instead of QML's opacity and BrightnessContrast
        // to be able to do both in one step which gives quite some better performance
        fragmentShader: "
            varying highp vec2 qt_TexCoord0;
            uniform sampler2D source;
            uniform lowp float brightness;
            uniform lowp float itemOpacity;
            void main(void)
            {
                highp vec4 sourceColor = texture2D(source, qt_TexCoord0);
                sourceColor.rgb = mix(sourceColor.rgb, vec3(step(0.0, brightness)), abs(brightness));
                sourceColor *= itemOpacity;
                gl_FragColor = sourceColor;
            }"
    }
}
