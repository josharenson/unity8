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
import Unity.Test 0.1 as UT
import QMenuModel 0.1
import Unity.Indicators.Messaging 0.1 as Indicators

Item {
    id: testView
    width: units.gu(40)
    height: units.gu(70)

    Indicators.MessageMenuItemFactory {
        id: factory
        menuModel: UnityMenuModel {}
        menuIndex: 0
    }

    UT.UnityTestCase {
        name: "MessageMenuItemFactory"

        property QtObject menuData: QtObject {
            property string label: "root"
            property bool sensitive: true
            property bool isSeparator: false
            property string icon: ""
            property string type: ""
            property var ext: undefined
            property string action: ""
            property var actionState: undefined
            property bool isCheck: false
            property bool isRadio: false
            property bool isToggled: false
        }

        function init() {
            menuData.label = "";
            menuData.sensitive = true;
            menuData.isSeparator = false;
            menuData.icon = "";
            menuData.type = "";
            menuData.ext = undefined;
            menuData.action = "";
            menuData.actionState = undefined;
            menuData.isCheck = false;
            menuData.isRadio = false;
            menuData.isToggled = false;

            factory.menuData = null;
        }

        function test_create_simpleTextmessage_data() {
            return [
                { title: "Title1", time: new Date(2013, 10, 10).getTime()*1000, message: "This is a text message 1", avatar: "file:///avatar1", appIcon: "file:///appIcon1", enabled: true},
                { title: "Title2", time: new Date(2014, 12, 10).getTime()*1000, message: "This is a text message 2", avatar: "file:///avatar2", appIcon: "file:///appIcon2", enabled: false},
            ];
        }

        function test_create_simpleTextmessage(data) {
            menuData.type = "com.canonical.indicator.messages.messageitem";
            menuData.label = data.title;
            menuData.sensitive = data.enabled;
            menuData.ext = {
                'xCanonicalTime': data.time,
                'xCanonicalText': data.message,
                'icon': data.avatar,
                'xCanonicalAppIcon': data.appIcon,
            };
            factory.menuData = menuData;

            var loader = findChild(factory, "loader");
            verify(loader !== undefined);

            tryCompare(loader.item, "objectName", "simpleTextMessage");
            compare(loader.item.title, data.title, "Title does not match data");
            compare(loader.item.time, data.time, "Time does not match data");
            compare(loader.item.message, data.message, "Message does not match data");
            compare(loader.item.avatar, data.avatar, "Avatar does not match data");
            compare(loader.item.appIcon, data.appIcon, "App icon does not match data");
            compare(loader.item.enabled, data.enabled, "Enabled does not match data");
        }

        function test_create_textmessage_data() {
            return [
                { title: "Title1", time: new Date(2013, 10, 10).getTime()*1000, message: "This is a text message 1", avatar: "file:///avatar1", appIcon: "file:///appIcon1", enabled: true},
                { title: "Title2", time: new Date(2014, 12, 10).getTime()*1000, message: "This is a text message 2", avatar: "file:///avatar2", appIcon: "file:///appIcon2", enabled: false},
            ];
        }

        function test_create_textmessage(data) {
            menuData.type = "com.canonical.indicator.messages.messageitem";
            menuData.label = data.title;
            menuData.sensitive = data.enabled;
            menuData.ext = {
                'xCanonicalTime': data.time,
                'xCanonicalText': data.message,
                'icon': data.avatar,
                'xCanonicalAppIcon': data.appIcon,
                'xCanonicalMessageActions': [{
                        'parameter-type': "s",
                        'name': "action::reply",
                        'label': "Reply1"
                    }
                ]
            };
            factory.menuData = menuData;

            var loader = findChild(factory, "loader");
            verify(loader !== undefined);

            tryCompare(loader.item, "objectName", "textMessage");
            compare(loader.item.title, data.title, "Title does not match data");
            compare(loader.item.time, data.time, "Time does not match data");
            compare(loader.item.message, data.message, "Message does not match data");
            compare(loader.item.avatar, data.avatar, "Avatar does not match data");
            compare(loader.item.appIcon, data.appIcon, "App icon does not match data");
            compare(loader.item.enabled, data.enabled, "Enabled does not match data");
        }


        function test_create_snapDecision_data() {
            return [
                { title: "Title1", time: new Date(2013, 10, 10).getTime()*1000, message: "This is a text message 1", avatar: "file:///avatar1", appIcon: "file:///appIcon1", enabled: true},
                { title: "Title2", time: new Date(2014, 12, 10).getTime()*1000, message: "This is a text message 2", avatar: "file:///avatar2", appIcon: "file:///appIcon2", enabled: false},
            ];
        }

        function test_create_snapDecision(data) {
            menuData.type = "com.canonical.indicator.messages.messageitem";
            menuData.label = data.title;
            menuData.sensitive = data.enabled;
            menuData.ext = {
                'xCanonicalTime': data.time,
                'xCanonicalText': data.message,
                'icon': data.avatar,
                'xCanonicalAppIcon': data.appIcon,
                'xCanonicalMessageActions': [{
                        'name': "action::callback",
                        'label': "Callback1"
                    },{
                        'parameter-type': "s",
                        'name': "action::reply",
                        'label': "Reply1"
                    }
                ]
            };
            factory.menuData = menuData;

            var loader = findChild(factory, "loader");
            verify(loader !== undefined);

            tryCompare(loader.item, "objectName", "snapDecision");
            compare(loader.item.title, data.title, "Title does not match data");
            compare(loader.item.time, data.time, "Time does not match data");
            compare(loader.item.message, data.message, "Message does not match data");
            compare(loader.item.avatar, data.avatar, "Avatar does not match data");
            compare(loader.item.appIcon, data.appIcon, "App icon does not match data");
            compare(loader.item.enabled, data.enabled, "Enabled does not match data");
        }

    }
}
