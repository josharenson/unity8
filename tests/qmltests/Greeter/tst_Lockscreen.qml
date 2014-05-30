/*
 * Copyright 2013 Canonical Ltd.
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
import QtTest 1.0
import ".."
import "../../../qml/Components"
import Ubuntu.Components 0.1
import LightDM 0.1 as LightDM
import Unity.Test 0.1 as UT

Rectangle {
    id: root
    width: units.gu(80)
    height: units.gu(80)
    color: "orange"

    Lockscreen {
        id: lockscreen
        anchors.fill: parent
        anchors.rightMargin: units.gu(30)
        placeholderText: "Please enter your PIN"
        wrongPlaceholderText: "Incorrect PIN"
        retryText: retryCountTextField.text
        alphaNumeric: pinPadCheckBox.checked
        minPinLength: minPinLengthTextField.text
        maxPinLength: maxPinLengthTextField.text
        username: "Lola"
        infoText: infoTextTextField.text
    }

    Connections {
        target: lockscreen

        onEmergencyCall: emergencyCheckBox.checked = true
        onEntered: {
            enteredLabel.text = passphrase
            lockscreen.clear(true)
        }
    }

    Connections {
        target: LightDM.Greeter

        onShowPrompt: {
            if (text.indexOf("PIN") >= 0) {
                pinPadCheckBox.checked = false
            } else {
                pinPadCheckBox.checked = true
            }
            lockscreen.placeholderText = text;
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: lockscreen.width
        color: "lightgray"

        Column {
            anchors.fill: parent
            anchors.margins: units.gu(1)
            spacing: units.gu(1)

            Row {
                CheckBox {
                    id: pinPadCheckBox
                }
                Label {
                    text: "Alphanumeric"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Row {
                CheckBox {
                    id: emergencyCheckBox
                }
                Label {
                    text: "Emergency Call"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Row {
                TextField {
                    id: minPinLengthTextField
                    width: units.gu(7)
                    text: "4"
                }
                Label {
                    text: "Min PIN length"
                }
            }
            Row {
                TextField {
                    id: maxPinLengthTextField
                    width: units.gu(7)
                    text: "4"
                }
                Label {
                    text: "Max PIN length"
                }
            }
            Row {
                TextField {
                    id: retryCountTextField
                    width: units.gu(7)
                    text: "3 retries left"
                }
                Label {
                    text: "Retries left"
                }
            }
            Label {
                id: pinLabel
                anchors.verticalCenter: parent.verticalCenter
            }
            Row {
                Label {
                    text: "Entered:"
                }
                Label {
                    id: enteredLabel
                }
            }
            Button {
                text: "start auth (1234)"
                width: parent.width
                onClicked: LightDM.Greeter.authenticate("has-pin")
            }
            Button {
                text: "start auth (password)"
                width: parent.width
                onClicked: LightDM.Greeter.authenticate("has-password")
            }

            TextField {
                id: infoTextTextField
                width: parent.width
                placeholderText: "Infotext"
                text: "+49 179 3253553"
            }

            TextField {
                id: infoPopupTitleTextField
                width: parent.width
                placeholderText: "Popup title"
                text: "This will be the last attempt"
            }

            TextArea {
                id: infoPopupTextArea
                width: parent.width
                text: "If the SIM PIN is entered incorrectly, your SIM will be blocked and would require the PUK code to unlock."
            }

            Button {
                text: "open info popup"
                width: parent.width
                onClicked: lockscreen.showInfoPopup(infoPopupTitleTextField.text, infoPopupTextArea.text)
            }
        }
    }

    UT.UnityTestCase {
        name: "Lockscreen"
        when: windowShown

        function cleanup() {
            lockscreen.clear(false);
        }

        function waitForLockscreenReady() {
            var pinPadLoader = findChild(lockscreen, "pinPadLoader");
            tryCompare(pinPadLoader, "status", Loader.Ready)
            waitForRendering(lockscreen)
        }

        function test_loading_data() {
            return [
                {tag: "numeric", alphanumeric: false, pinPadAvailable: true },
                {tag: "alphanumeric", alphanumeric: true, pinPadAvailable: false }
            ]
        }

        function test_loading(data) {
            pinPadCheckBox.checked = data.alphanumeric
            waitForLockscreenReady();
            if (data.pinPadAvailable) {
                compare(findChild(lockscreen, "pinPadButton8").text, "8", "Could not find number 8 on PinPad")
            } else {
                compare(findChild(lockscreen, "pinPadButton8"), null, "Could find number 8 on PinPad even though it should be only OSK")
            }
        }

        function test_emergency_call_data() {
            return [
                {tag: "numeric", alphanumeric: false },
                {tag: "alphanumeric", alphanumeric: true }
            ]
        }

        function test_emergency_call(data) {
            emergencyCheckBox.checked = false
            pinPadCheckBox.checked = data.alphanumeric
            waitForLockscreenReady();
            var emergencyButton = findChild(lockscreen, "emergencyCallIcon")
            mouseClick(emergencyButton, units.gu(1), units.gu(1))
            tryCompare(emergencyCheckBox, "checked", true)

        }

        function test_labels_data() {
            return [
                {tag: "numeric", alphanumeric: false, placeholderText: "Please enter your PIN", username: "foobar" },
                {tag: "alphanumeric", alphanumeric: true, placeholderText: "Please enter your password", username: "Lola" }
            ]
        }

        function test_labels(data) {
            pinPadCheckBox.checked = data.alphanumeric
            lockscreen.placeholderText = data.placeholderText
            waitForLockscreenReady();
            compare(findChild(lockscreen, "pinentryField").placeholderText, data.placeholderText, "Placeholdertext is not what it should be")
            if (data.alphanumeric) {
                compare(findChild(lockscreen, "greeterLabel").text, "Hello " + data.username, "Greeter is not set correctly")
            }
        }


        function test_unlock_data() {
            return [
                {tag: "numeric", alphanumeric: false, username: "has-pin", password: "1234", minPinLength: 4, maxPinLength: 4},
                {tag: "alphanumeric",  alphanumeric: true, username: "has-password", password: "password", minPinLength: -1, maxPinLength: -1},
                {tag: "numeric (wrong)",  alphanumeric: false, username: "has-pin", password: "4321", minPinLength: 4, maxPinLength: 4},
                {tag: "alphanumeric (wrong)",  alphanumeric: true, username: "has-password", password: "drowssap", minPinLength: -1, maxPinLength: -1},
                {tag: "flexible length",  alphanumeric: false, username: "has-pin", password: "1234", minPinLength: -1, maxPinLength: -1},
            ]
        }

        function test_unlock(data) {
            enteredLabel.text = ""
            minPinLengthTextField.text = data.minPinLength
            maxPinLengthTextField.text = data.maxPinLength
            LightDM.Greeter.authenticate(data.username)
            waitForLockscreenReady();

            var inputField = findChild(lockscreen, "pinentryField")
            if (data.alphanumeric) {
                mouseClick(inputField, units.gu(1), units.gu(1))
                tryCompare(inputField, "focus", true);
                typeString(data.password)
                keyClick(Qt.Key_Enter)
            } else {
                for (var i = 0; i < data.password.length; ++i) {
                    var character = data.password.charAt(i)
                    var button = findChild(lockscreen, "pinPadButton" + character)
                    mouseClick(button, units.gu(1), units.gu(1))
                }
                if (data.minPinLength !== data.maxPinLength || data.minPinLength == -1) {
                    var pinPadButtonErase = findChild(lockscreen, "pinPadButtonErase");
                    mouseClick(pinPadButtonErase, units.gu(1), units.gu(1));
                }
            }
            tryCompare(enteredLabel, "text", data.password)
        }

        function test_clear_data() {
            return [
                {tag: "animated PIN", animation: true, alphanumeric: false},
                {tag: "not animated PIN", animation: false, alphanumeric: false},
                {tag: "animated passphrase", animation: true, alphanumeric: true},
                {tag: "not animated passphrase", animation: false, alphanumeric: true}
            ];
        }

        function test_clear(data) {
            pinPadCheckBox.checked = data.alphanumeric
            waitForLockscreenReady();

            var inputField = findChild(lockscreen, "pinentryField")
            if (data.alphanumeric) {
                mouseClick(inputField, units.gu(1), units.gu(1))
                tryCompare(inputField, "activeFocus", true);
                typeString("1")
            } else {
                var button = findChild(lockscreen, "pinPadButton1")
                mouseClick(button, units.gu(1), units.gu(1))
            }

            var animation = findInvisibleChild(lockscreen, "wrongPasswordAnimation")

            tryCompare(inputField, "text", "1")

            lockscreen.clear(data.animation)
            tryCompare(inputField, "text", "")

            wait(0) // Trigger event loop to make sure the animation would start running
            compare(animation.running, data.animation)
            if (data.animation) {
                if (data.alphanumeric) {
                    tryCompare(inputField, "placeholderText", lockscreen.wrongPlaceholderText)
                    tryCompare(inputField, "placeholderText", lockscreen.placeholderText)
                } else {
                    var label = findChild(lockscreen, "pinentryFieldPlaceHolder");
                    tryCompare(label, "text", lockscreen.wrongPlaceholderText)
                    tryCompare(label, "text", lockscreen.placeholderText)
                }
            }

            // wait for animation to finish to not disturb other tests
            tryCompare(animation, "running", false)
        }

        function test_backspace_data() {
            return [
                {tag: "fixed length", minPinLength: 4, maxPinLength: 4},
                {tag: "variable undefined length", minPinLength: -1, maxPinLength: -1},
                {tag: "variable restricted length", minPinLength: 4, maxPinLength: 8}
            ];
        }

        function test_backspace(data) {
            pinPadCheckBox.checked = false
            minPinLengthTextField.text = data.minPinLength
            maxPinLengthTextField.text = data.maxPinLength
            waitForLockscreenReady();

            var pinPadButtonErase = findChild(lockscreen, "pinPadButtonErase");
            var backspaceIcon = findChild(lockscreen, "backspaceIcon");
            var pinEntryField = findChild(lockscreen, "pinentryField");

            var autoConfirmEnabled = data.minPinLength === data.maxPinLength && data.minPinLength !== -1;
            compare(pinPadButtonErase.iconName, autoConfirmEnabled ? "erase" : "");
            compare(backspaceIcon.visible, !autoConfirmEnabled);

            var pinPadButton5 = findChild(lockscreen, "pinPadButton5");
            mouseClick(pinPadButton5, units.gu(1), units.gu(1));
            compare(pinEntryField.text, "5");

            if (data.minPinLength !== data.maxPinLength) {
                mouseClick(backspaceIcon, units.gu(1), units.gu(1));
            } else {
                mouseClick(pinPadButtonErase, units.gu(1), units.gu(1));
            }
            compare(pinEntryField.text, "");
        }

        function test_minMaxLength_data() {
            return [
                {tag: "undefined", minPinLength: -1, maxPinLength: -1},
                {tag: "fixed", minPinLength: 4, maxPinLength: 4},
                {tag: "variable, limited", minPinLength: 4, maxPinLength: 8},
            ];
        }

        function test_minMaxLength(data) {
            pinPadCheckBox.checked = false
            minPinLengthTextField.text = data.minPinLength
            maxPinLengthTextField.text = data.maxPinLength
            waitForLockscreenReady();

            var pinPadButton5 = findChild(lockscreen, "pinPadButton5");
            var pinPadButtonErase = findChild(lockscreen, "pinPadButtonErase");
            var inputField = findChild(lockscreen, "pinentryField")

            for (var i = 0; i < 10; i++) {
                mouseClick(pinPadButton5, units.gu(1), units.gu(1));

                if (data.minPinLength == data.maxPinLength && data.minPinLength != -1) {
                    // auto confirm mode...
                    compare(inputField.text.length, (i+1) % data.minPinLength);
                } else {
                    // manual confirm mode
                    tryCompare(pinPadButtonErase, "enabled", (i+1) >= data.minPinLength)
                    if (data.maxPinLength == -1) {
                        compare(inputField.text.length, i+1);
                    } else {
                        compare(inputField.text.length, Math.min(data.maxPinLength, i+1));
                    }

                }
            }
        }

        function test_retryDisplay_data() {
            return [
                {tag: "empty", retryText: "", shown: false},
                {tag: "3 retries left", retryText: "3 retries left", shown: true},
            ]
        }

        function test_retryDisplay(data) {
            pinPadCheckBox.checked = false
            waitForLockscreenReady();

            retryCountTextField.text = data.retryText;
            var label = findChild(lockscreen, "retryCountLabel")
            compare(label.visible, data.shown);
        }

        function test_infoPopup() {
            verify(findChild(root, "infoPopup") === null);
            lockscreen.showInfoPopup("foo", "bar");
            tryCompareFunction(function() { return findChild(root, "infoPopup") !== null}, true);

            var infoPopup = findChild(root, "infoPopup");
            compare(infoPopup.title, "foo");
            compare(infoPopup.text, "bar");

            signalSpy.signalName = "infoPopupConfirmed"
            signalSpy.clear();

            var okButton = findChild(root, "infoPopupOkButton");
            mouseClick(okButton, okButton.width / 2, okButton.height / 2);

            tryCompareFunction(function() { return findChild(root, "infoPopup") === null}, true);

            tryCompare(signalSpy, "count", 1);
        }

        function test_infoTextDisplay_data() {
            return [
                {tag: "empty string", text: "", shown: false},
                {tag: "hello world", text: "hello world", shown: true},
            ]
        }

        function test_infoTextDisplay(data) {
            pinPadCheckBox.checked = false
            waitForLockscreenReady();

            infoTextTextField.text = data.text;
            var label = findChild(lockscreen, "infoTextLabel")
            compare(label.visible, data.shown);
        }
    }

    SignalSpy {
        id: signalSpy
        target: lockscreen
    }
}
