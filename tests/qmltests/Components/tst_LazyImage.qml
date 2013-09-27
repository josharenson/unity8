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
import "../../../Components"
import Ubuntu.Components 0.1
import Unity.Test 0.1 as UT
import "tst_LazyImage"

Rectangle {
    width: units.gu(120)
    height: units.gu(70)

    Rectangle {
        id: baseRect
        anchors {
            fill: parent
            rightMargin: 2 * parent.width / 3
        }

        color: "grey"

        Column {
            anchors { fill: parent; margins: units.gu(5) }

            Label {
                height: units.gu(4)
                text: "Unbound"
                color: "white"
                verticalAlignment: Text.AlignBottom
            }

            LazyImage {
                id: lazy1
            }

            Label {
                height: units.gu(4)
                text: "Width-bound"
                color: "white"
                verticalAlignment: Text.AlignBottom
            }

            LazyImage {
                id: lazy2
                width: units.gu(30)
                scaleTo: "width"
            }

            Label {
                height: units.gu(4)
                text: "Height-bound"
                color: "white"
                verticalAlignment: Text.AlignBottom
            }

            LazyImage {
                id: lazy3
                height: units.gu(10)
                scaleTo: "height"
            }
        }
    }

    Rectangle {
        id: controlsRect
        anchors {
            fill: parent
            leftMargin: parent.width / 3
        }

        color: "lightgrey"

        Column {
            id: controls
            spacing: units.gu(1)

            anchors { fill: parent; margins: units.gu(3) }

            ImageControls { id: controls1; image: lazy1 }
            ImageControls { id: controls2; image: lazy2 }
            ImageControls { id: controls3; image: lazy3 }
        }
    }

    UT.UnityTestCase {
        name: "Stage"
        when: windowShown

        function cleanup() {
            controls1.blank();
            tryCompare(lazy1, "width", units.gu(10));
            controls2.blank();
            tryCompare(lazy2, "height", units.gu(10));
            controls3.blank();
            tryCompare(lazy3, "width", units.gu(10));
        }

        function test_lazyimage_data() {
            return [
                {tag: "Unbound Blank", image: lazy1, func: controls1.blank, width: units.gu(10), height: units.gu(10), placeholder: true},
                {tag: "Unbound Wide", image: lazy1, func: controls1.wide, transition: "readyTransition", width: 160, height: 80},
                {tag: "Unbound Square", image: lazy1, func: controls1.square, transition: "readyTransition", width: 160, height: 160},
                {tag: "Unbound Portrait", image: lazy1, func: controls1.portrait, transition: "readyTransition", width: 80, height: 160},
                {tag: "Unbound Bad path", image: lazy1, func: controls1.badpath, transition: "genericTransition", width: units.gu(10), height: units.gu(10), placeholder: true, error: true},
                {tag: "Width-bound Blank", image: lazy2, func: controls2.blank, width: units.gu(30), height: units.gu(10), placeholder: true},
                {tag: "Width-bound Wide", image: lazy2, func: controls2.wide, transition: "readyTransition", width: units.gu(30), height: units.gu(15)},
                {tag: "Width-bound Square", image: lazy2, func: controls2.square, transition: "readyTransition", width: units.gu(30), height: units.gu(30)},
                {tag: "Width-bound Portrait", image: lazy2, func: controls2.portrait, transition: "readyTransition", width: units.gu(30), height: units.gu(60)},
                {tag: "Width-bound Bad path", image: lazy2, func: controls2.badpath, transition: "genericTransition", width: units.gu(30), height: units.gu(10), placeholder: true, error: true},
                {tag: "Height-bound Blank", image: lazy3, func: controls3.blank, width: units.gu(10), height: units.gu(10), placeholder: true},
                {tag: "Height-bound Wide", image: lazy3, func: controls3.wide, transition: "readyTransition", width: units.gu(20), height: units.gu(10)},
                {tag: "Height-bound Square", image: lazy3, func: controls3.square, transition: "readyTransition", width: units.gu(10), height: units.gu(10)},
                {tag: "Height-bound Portrait", image: lazy3, func: controls3.portrait, transition: "readyTransition", width: units.gu(5), height: units.gu(10)},
                {tag: "Height-bound Bad path", image: lazy3, func: controls3.badpath, transition: "genericTransition", width: units.gu(10), height: units.gu(10), placeholder: true, error: true},
            ]
        }

        function test_lazyimage(data) {
            data.func();

            if (data.transition) {
                // wait for the transition to complete
                var transition = findInvisibleChild(data.image, data.transition);
                tryCompare(transition, "running", true);
                tryCompare(transition, "running", false);
            }

            // check the dimensions
            compare(data.image.width, data.width);
            compare(data.image.height, data.height);

            // check the placeholder
            var placeholder = findChild(data.image, "placeholder");
            compare(placeholder.visible, data.placeholder ? true : false);

            // check the error image
            var error = findChild(data.image, "errorImage");
            compare(error.visible, data.error ? true : false);
        }
    }
}
