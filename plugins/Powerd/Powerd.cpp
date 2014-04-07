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
 *
 * Author: Michael Terry <michael.terry@canonical.com>
 */

#include "Powerd.h"
#include <QDBusPendingCall>

void autoBrightnessChanged(GSettings *settings, const gchar *key, QDBusInterface *powerd)
{
    bool value = g_settings_get_boolean(settings, key);
    powerd->asyncCall("userAutobrightnessEnable", QVariant(value));
}

Powerd::Powerd(QObject* parent)
  : QObject(parent),
    powerd(NULL)
{
    powerd = new QDBusInterface("com.canonical.powerd",
                                "/com/canonical/powerd",
                                "com.canonical.powerd",
                                QDBusConnection::SM_BUSNAME(), this);

    powerd->connection().connect("com.canonical.powerd",
                                 "/com/canonical/powerd",
                                 "com.canonical.powerd",
                                 "DisplayPowerStateChange",
                                 this,
                                 SIGNAL(displayPowerStateChange(int, unsigned int)));

    systemSettings = g_settings_new("com.ubuntu.touch.system");
    g_signal_connect(systemSettings, "changed::auto-brightness", G_CALLBACK(autoBrightnessChanged), powerd);
    autoBrightnessChanged(systemSettings, "auto-brightness", powerd);
}

Powerd::~Powerd()
{
    g_signal_handlers_disconnect_by_data(systemSettings, powerd);
    g_object_unref(systemSettings);
}
