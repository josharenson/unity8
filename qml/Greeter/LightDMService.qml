/*
 * Copyright (C) 2015 Canonical, Ltd.
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

/**
 * Lightweight wrapper that allows for loading integrated/real LightDM
 * plugin
 */

pragma Singleton
import QtQuick 2.4

Loader {
    id: loader

    property var greeter: d.valid ? loader.item.greeter : null
    property var infographic: d.valid ? loader.item.infographic : null
    property var prompts: d.valid ? loader.item.prompts : null
    property var sessions: d.valid ? loader.item.sessions : null
    property var sessionRoles: d.valid ? loader.item.sessionRoles : null
    property var users: d.valid ? loader.item.users : null
    property var userRoles: d.valid ? loader.item.userRoles : null

    // This trickery handles cases where applicationArguments aren't provided
    // such as during testing
    property var fullLightDM: {
        if (typeof applicationArguments === "undefined" ||
                applicationArguments.mode === "greeter") {
            return true;
        }
        return false;
    }

    source:  fullLightDM ?
        "FullLightDMImpl.qml" : "IntegratedLightDMImpl.qml"

    QtObject {
        id: d

        property bool valid: loader.item !== null
    }
}
