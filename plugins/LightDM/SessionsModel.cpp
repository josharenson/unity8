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

#include "SessionsModel.h"
#include <QtCore/QFile>
#include <QtCore/QSortFilterProxyModel>

QHash<int, QByteArray> SessionsModel::roleNames() const
{
    return m_roleNames;
}

int SessionsModel::rowCount(const QModelIndex& parent) const
{
    return m_model->rowCount(parent);
}

QList<QUrl> SessionsModel::iconSearchDirectories() const
{
    return m_iconSearchDirectories;
}

void SessionsModel::setIconSearchDirectories(const QList<QUrl> searchDirectories)
{
    // QML gives us a url with file:// prepended which breaks QFile::exists()
    // so convert the url to a local file
    QList<QUrl> localList = {};
    Q_FOREACH(const QUrl& searchDirectory, searchDirectories)
    {
        localList.append(searchDirectory.toLocalFile());
    }
    m_iconSearchDirectories = localList;
    Q_EMIT iconSearchDirectoriesChanged();
}

QUrl SessionsModel::iconUrl(const QString sessionName) const
{
    Q_FOREACH(const QUrl& searchDirectory, m_iconSearchDirectories)
    {
        // This is an established icon naming convention
        QString customIconUrl = searchDirectory.toString(QUrl::StripTrailingSlash) +
            "/custom_" + sessionName  + "_badge.png";
        QString iconUrl = searchDirectory.toString(QUrl::StripTrailingSlash) +
            "/" + sessionName  + "_badge.png";

        QFile customIconFile(customIconUrl);
        QFile iconFile(iconUrl);
        if (customIconFile.exists()) {
            return QUrl(customIconUrl);
        } else if (iconFile.exists()) {
            return QUrl(iconUrl);
        } else{
            // Search the legacy way
            QString path = searchDirectory.toString(QUrl::StripTrailingSlash) + "/";
            if (sessionName == "ubuntu" || sessionName == "ubuntu-2d") {
                path += "ubuntu_badge.png";
            } else if(
                        sessionName == "gnome-classic" ||
                        sessionName == "gnome-flashback-compiz" ||
                        sessionName == "gnome-flashback-metacity" ||
                        sessionName == "gnome-shell" ||
                        sessionName == "gnome-wayland" ||
                        sessionName == "gnome"
                    ){
                path += "gnome_badge.png";
            } else if (sessionName == "plasma") {
                path += "kde_badge.png";
            } else if (sessionName == "xterm") {
                path += "recovery_console_badge.png";
            } else if (sessionName == "remote-login") {
                path += "remote_login_help.png";
            }

            if (QFile(path).exists()) {
                return path;
            }
        }
    }

    // FIXME make this smarter
    return QUrl("./graphics/session_icons/unknown_badge.png");
}

QVariant SessionsModel::data(const QModelIndex& index, int role) const
{
    switch (role) {
        case SessionsModel::IconRole:
            return iconUrl(m_model->data(index, Qt::DisplayRole).toString());
        default:
            return m_model->data(index, role);
    }
}

QObject *SessionsModel::mock()
{
    return m_model->property("mock").value<QObject*>();
}

SessionsModel::SessionsModel(QObject* parent)
  : UnitySortFilterProxyModelQML(parent)
{
    // Add a custom IconRole that isn't in either of the lightdm implementations
    m_model = new QLightDM::SessionsModel(this);
    m_roleNames = m_model->roleNames();
    m_roleNames[IconRole] = "icon_url";

    setModel(m_model);
    setSortCaseSensitivity(Qt::CaseInsensitive);
    setSortLocaleAware(true);
    setSortRole(Qt::DisplayRole);
    sort(0);
}
