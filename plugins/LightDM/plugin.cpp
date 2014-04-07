/*
 * Copyright (C) 2012,2013 Canonical, Ltd.
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
 * Authors: Gerry Boland <gerry.boland@canonical.com>
 *          Michael Terry <michael.terry@canonical.com>
 */

#include "plugin.h"
#include "DBusGreeterList.h"
#include "Greeter.h"
#include "UsersModel.h"
#include <QLightDM/UsersModel>

#include <QAbstractItemModel>
#include <QDBusConnection>
#include <QtQml/qqml.h>

static const char* GREETER_LIST_DBUS_PATH = "/list";
static const char* GREETER_DBUS_SERVICE = "com.canonical.UnityGreeter";

static QObject *greeter_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    Greeter *greeter = new Greeter();
    QDBusConnection connection = QDBusConnection::sessionBus();
    DBusGreeterList *list = new DBusGreeterList(greeter, connection, GREETER_LIST_DBUS_PATH);
    connection.registerObject(GREETER_LIST_DBUS_PATH, list, QDBusConnection::ExportScriptableContents);
    connection.registerService(GREETER_DBUS_SERVICE);

    return greeter;
}

static QObject *users_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)
    return new UsersModel();
}

void LightDMPlugin::registerTypes(const char *uri)
{
    qmlRegisterType<QAbstractItemModel>();

    Q_ASSERT(uri == QLatin1String("LightDM"));
    qmlRegisterSingletonType<Greeter>(uri, 0, 1, "Greeter", greeter_provider);
    qmlRegisterSingletonType<UsersModel>(uri, 0, 1, "Users", users_provider);
    qmlRegisterUncreatableType<QLightDM::UsersModel>(uri, 0, 1, "UserRoles", "Type is not instantiable");
}
