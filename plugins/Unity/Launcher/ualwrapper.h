/*
 * Copyright (C) 2016 Canonical, Ltd.
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

#include <QObject>

class UalWrapper: public QObject
{
    Q_OBJECT
public:
    struct AppInfo {
        QString appId;
        bool valid = false;
        QString name;
        QString icon;
        QStringList keywords;
        uint popularity = 0;
    };

    UalWrapper(QObject* parent = nullptr);

    static QStringList installedApps();
    static AppInfo getApplicationInfo(const QString &appId);

Q_SIGNALS:
    void appAdded(const QString &appId);
    void appRemoved(const QString &appId);
    void appInfoChanged(const QString &appId);
};
