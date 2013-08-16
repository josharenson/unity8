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
import Utils 0.1
import "../Components"
import "../Components/ListItems"
import "../Applications"
import "Apps"

GenericScopeView {
    id: scopeView

    // FIXME: a way to aggregate these models would be ideal
    property var mainStageApplicationsModel: shell.applicationManager.mainStageApplications
    property var sideStageApplicationModel: shell.applicationManager.sideStageApplications

    SearchableResultModel {
        id: appsAvailableForDownloadModel

        model: AppsAvailableForDownloadModel {}
        filterRole: 3
        searchQuery: scopeView.scope.searchQuery
    }

    ListModel {
        id: dummyVisibilityModifier

        ListElement { name: "running-apps" }
    }

    SortFilterProxyModel {
        id: runningApplicationsModel

        property var firstModel: mainStageApplicationsModel
        property var secondModel: sideStageApplicationModel
        property bool canEnableTerminationMode: scopeView.isCurrent

        model: dummyVisibilityModifier
        filterRole: 0
        filterRegExp: invertMatch ? ((mainStageApplicationsModel.count === 0 &&
                                      sideStageApplicationModel.count === 0) ? RegExp("running-apps") : RegExp("")) : RegExp("disabled")
        invertMatch: scopeView.scope.searchQuery.length == 0
    }

    onScopeChanged: {
        scopeView.scope.categories.overrideResults("recent", runningApplicationsModel);
        scopeView.scope.categories.overrideResults("more", appsAvailableForDownloadModel);
    }
}
