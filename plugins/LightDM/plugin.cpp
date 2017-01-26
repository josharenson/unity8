/*
 * Copyright (C) 2012,2013,2015 Canonical, Ltd.
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

#include "plugin.h"
#include "DBusGreeter.h"
#include "DBusGreeterList.h"
#include "Greeter.h"
#include "PromptsModel.h"
#include "SessionsModel.h"
#include "UsersModel.h"
#include <libusermetricsoutput/ColorTheme.h>
#include <libusermetricsoutput/UserMetrics.h>
#include <QLightDM/SessionsModel>
#include <QLightDM/UsersModel>

#include <QAbstractItemModel>
#include <QDBusConnection>
#include <QtQml/qqml.h>

static QObject *greeter_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(scriptEngine)

    Greeter *greeter = Greeter::instance();
    new DBusGreeter(greeter, QStringLiteral("/"));
    new DBusGreeterList(greeter, QStringLiteral("/list"));

    engine->setObjectOwnership(greeter, QQmlEngine::CppOwnership);

    return greeter;
}

static QObject *prompts_provider(QQmlEngine *engine, QJSEngine *)
{
    auto model = Greeter::instance()->promptsModel();
    engine->setObjectOwnership(model, QQmlEngine::CppOwnership);
    return model;
}

static QObject *sessions_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)
    return new SessionsModel();
}

static QObject *users_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)
    return new UsersModel();
}

static QObject *infographic_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)
    return UserMetricsOutput::UserMetrics::getInstance();
}

void PLUGIN_CLASSNAME::registerTypes(const char *uri)
{
    qmlRegisterType<QAbstractItemModel>();
    qmlRegisterType<UserMetricsOutput::ColorTheme>();

#if defined INTEGRATED_LIGHTDM
    Q_ASSERT(uri == QLatin1String("LightDM.IntegratedLightDM"));
    qmlRegisterSingletonType<Greeter>(uri, 0, 1, "Greeter", greeter_provider);
#elif defined FULL_LIGHTDM
    Q_ASSERT(uri == QLatin1String("LightDM.FullLightDM"));
    qmlRegisterSingletonType<QLightDM::Greeter>(uri, 0, 1, "Greeter", greeter_provider);
#else
    #error No library defined in LightDM plugin
#endif

    qmlRegisterSingletonType<PromptsModel>(uri, 0, 1, "Prompts", prompts_provider);

    qmlRegisterSingletonType<SessionsModel>(uri, 0, 1, "Sessions", sessions_provider);
    qmlRegisterUncreatableType<QLightDM::SessionsModel>(uri, 0, 1, "SessionRoles", QStringLiteral("Type is not instantiable"));

    qmlRegisterSingletonType<UsersModel>(uri, 0, 1, "Users", users_provider);
    qmlRegisterUncreatableType<QLightDM::UsersModel>(uri, 0, 1, "UserRoles", QStringLiteral("Type is not instantiable"));

    qmlRegisterSingletonType<UserMetricsOutput::UserMetrics>(uri, 0, 1, "Infographic", infographic_provider);
}
