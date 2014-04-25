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
import Ubuntu.Components.ListItems 0.1
import "../Components"

Column {
    id: root
    anchors.centerIn: parent
    spacing: units.gu(3.5)

    property alias placeholderText: pinentryField.placeholderText
    property int padWidth: units.gu(34)
    property int padHeight: units.gu(28)
    property int pinLength: -1
    property var pinMinMax : [4, 8]

    signal entered(string passphrase)
    signal cancel()

    property bool entryEnabled: true

    function clear(playAnimation) {
        pinentryField.text = "";
        if (playAnimation) {
            wrongPasswordAnimation.start();
        }
    }


    UbuntuShape {
        id: pinentryField
        objectName: "pinentryField"
        anchors.horizontalCenter: parent.horizontalCenter
        color: "#55000000"
        width:root.padWidth
        height: units.gu(6)
        radius: "medium"
        property string text: ""
        property string placeholderText: ""
        onTextChanged: {
            /// todo: get rid of the pinLength and replace with MinMax
            if (root.pinMinMax != null) {
                if (text.length > root.pinMinMax[1]) {
                    text = text.substring(0, text.length-1);
                    return;
                }
            }

            pinentryFieldLabel.text = "";
            for (var i = 0; i < text.length; ++i) {
                pinentryFieldLabel.text += "•";
            }
            if (text.length === root.pinLength) {
                root.entered(text);
            }            
        }

        Label {
            id: pinentryFieldLabel
            anchors.centerIn: parent
            width: parent.width - (backspaceIcon.width + backspaceIcon.anchors.rightMargin) * 2
            elide: Text.ElideMiddle
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: units.dp(44)
            color: "#f3f3e7"
            opacity: 0.6
            textFormat: Text.RichText
        }
        Label {
            id: pinentryFieldPlaceHolder
            anchors.centerIn: parent
            color: "grey"
            text: parent.placeholderText
            visible: pinentryFieldLabel.text.length == 0
        }

        Icon {
            id: backspaceIcon
            objectName: "backspaceIcon"
            anchors {
                top: parent.top
                topMargin: units.gu(1)
                right: parent.right
                rightMargin: units.gu(2)
                bottom: parent.bottom
                bottomMargin: units.gu(1)
            }
            visible: root.pinLength == -1
            width: height
            name: "erase"
            MouseArea {
                anchors.fill: parent
                onClicked: pinentryField.text = pinentryField.text.substring(0, pinentryField.text.length-1);
            }
        }
    }

    UbuntuShape {
        anchors {
            left: parent.left
            right: parent.right
            margins: (parent.width - root.padWidth) / 2
        }
        height: root.padHeight
        color: "#55000000"
        radius: "medium"

        ThinDivider {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                topMargin: root.padHeight / 4
            }
        }
        ThinDivider {
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
        }
        ThinDivider {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                bottomMargin: root.padHeight / 4
            }
        }

        ThinDivider {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -root.padWidth / 6
            width: root.padHeight
            rotation: -90
        }
        ThinDivider {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.padWidth / 6
            width: root.padHeight
            rotation: -90
        }

        Grid {
            anchors {
                left: parent.left
                right: parent.right
                margins: (parent.width - root.padWidth) / 2
            }

            columns: 3

            Repeater {
                model: 9

                PinPadButton {
                    objectName: "pinPadButton" + (index + 1)
                    width: root.padWidth / 3
                    height: root.padHeight / 4
                    text: index + 1
                    enabled: entryEnabled

                    onClicked: {
                        pinentryField.text = pinentryField.text + text;
                    }
                }
            }

            PinPadButton {
                objectName: "pinPadButtonBack"
                width: root.padWidth / 3
                height: root.padHeight / 4
                subText: "CANCEL"
                onClicked: root.cancel();
            }

            PinPadButton {
                objectName: "pinPadButton0"
                width: root.padWidth / 3
                height: root.padHeight / 4
                text: "0"
                onClicked: pinentryField.text = pinentryField.text + text
                enabled: entryEnabled
            }

            PinPadButton {
                objectName: "pinPadButtonErase"
                width: root.padWidth / 3
                height: root.padHeight / 4
                iconName: root.pinLength == -1 ? "" : "erase"
                subText: root.pinLength == -1 ? "DONE" : ""
                onClicked: {
                    if (root.pinLength !== -1) {
                        pinentryField.text = pinentryField.text.substring(0, pinentryField.text.length-1);
                    } else {
                        root.entered(pinentryField.text);
                    }
                }
                enabled: {
                    if (root.pinMinMax == null) {
                        return true;
                    } else {
                        if (root.pinMinMax[0] <= pinentryField.text.length) {
                            return true;
                        } else {
                            return false;
                        }
                    }
                }
            }
        }
    }

    WrongPasswordAnimation {
        id: wrongPasswordAnimation
        objectName: "wrongPasswordAnimation"
        target: pinentryField
    }
}
