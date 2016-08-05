/*
 * Copyright (C) 2015-2016 Canonical, Ltd.
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
 *
 */


// LightDM currently is Qt4 compatible, and so doesn't define setRoleNames.
// To use the same method of setting role name that it does, we
// set our compatibility to Qt4 here too.
#define QT_DISABLE_DEPRECATED_BEFORE QT_VERSION_CHECK(4, 0, 0)

#include "MockController.h"
#include "MockSessionsModel.h"

namespace QLightDM
{

class SessionItem
{
public:
    QString key;
    QString type; // unused
    QString name;
    QString comment; // unused
};

class SessionsModelPrivate
{
public:
    QHash<int, QByteArray> roleNames;
    QList<SessionItem> sessionItems;
};

SessionsModel::SessionsModel(QObject* parent)
    : QAbstractListModel(parent)
    , d_ptr(new SessionsModelPrivate)
{
    Q_D(SessionsModel);

    d->roleNames = QAbstractListModel::roleNames();
    d->roleNames[KeyRole] = "key";
    d->roleNames[TypeRole] = "type";

    connect(MockController::instance(), SIGNAL(sessionModeChanged()),
            this, SLOT(resetEntries()));
    resetEntries();
}

SessionsModel::~SessionsModel()
{
    delete d_ptr;
}

QVariant SessionsModel::data(const QModelIndex& index, int role) const
{
    Q_D(const SessionsModel);

    if(!index.isValid()) {
        return QVariant();
    }

    int row = index.row();

    switch (role) {
        case QLightDM::SessionsModel::KeyRole:
            return d->sessionItems[row].key;
        case Qt::DisplayRole:
            return d->sessionItems[row].name;
        default:
            return QVariant();
    }
}

QHash<int, QByteArray> SessionsModel::roleNames() const
{
    Q_D(const SessionsModel);

    return d->roleNames;
}

int SessionsModel::rowCount(const QModelIndex& parent) const
{
    Q_D(const SessionsModel);

    if (parent.isValid()) {
        return 0;
    } else { // parent is root
        return d->sessionItems.size();
    }
}

void SessionsModel::resetEntries()
{
    Q_D(SessionsModel);

    beginResetModel();

    QString sessionMode = MockController::instance()->sessionMode();

    if (sessionMode == "full") {
        d->sessionItems =
        {
            {"ubuntu", "", "Ubuntu", ""},
            {"ubuntu-2d", "", "Ubuntu 2D", ""},
            {"gnome", "", "GNOME", ""},
            {"gnome-classic", "", "GNOME Classic", ""},
            {"gnome-flashback-compiz", "", "GNOME Flashback (Compiz)", ""},
            {"gnome-flashback-metacity", "", "GNOME Flashback (Metacity)", ""},
            {"gnome-wayland", "", "GNOME on Wayland", ""},
            {"plasma", "", "Plasma", ""},
            {"kde", "", "KDE" , ""},
            {"xterm", "", "Recovery Console", ""},
            {"", "", "Unknown?", ""}
        };
    } else if (sessionMode == "single") {
        d->sessionItems = {{"ubuntu", "", "Ubuntu", ""}};
    } else {
        d->sessionItems = {};
    }

    endResetModel();
}

QObject *SessionsModel::mock()
{
    return MockController::instance();
}

} // namespace QLightDM
