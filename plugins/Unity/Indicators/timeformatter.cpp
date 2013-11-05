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
 *
 * Author: Lars Uebernickel <lars.uebernickel@canonical.com>
 */

#include "timeformatter.h"

#include <gio/gio.h>
#include <QDateTime>

struct TimeFormatterPrivate
{
    TimeFormatter *formatter;

    QString format;
    QString timeString;
    qint64 time;

    GDBusConnection *system_bus;
    guint subscription_id;
    GCancellable *cancellable;
};

static void
timedate1_properties_changed (GDBusConnection *connection,
                              const gchar *sender_name,
                              const gchar *object_path,
                              const gchar *interface_name,
                              const gchar *signal_name,
                              GVariant *parameters,
                              gpointer user_data)
{
    Q_UNUSED(connection);
    Q_UNUSED(sender_name);
    Q_UNUSED(object_path);
    Q_UNUSED(interface_name);
    Q_UNUSED(signal_name);

    TimeFormatterPrivate *priv = (TimeFormatterPrivate *)user_data;
    GVariant *changed;
    GVariantIter *iter;
    const gchar *name;

    if (!g_variant_is_of_type (parameters, G_VARIANT_TYPE ("(sa{sv}as)")))
        return;

    g_variant_get (parameters, "(s@a{sv}as)", NULL, &changed, &iter);

    if (g_variant_lookup (changed, "Timezone", "s", NULL)) {
        priv->formatter->update();
    }
    else {
        while (g_variant_iter_next (iter, "&s", &name)) {
            if (g_str_equal (name, "Timezone")) {
                priv->formatter->update();
                break;
            }
        }
    }

    g_variant_unref (changed);
    g_variant_iter_free (iter);
}

static void
got_bus(GObject *object, GAsyncResult *result, gpointer user_data)
{
    Q_UNUSED(object);

    TimeFormatterPrivate *priv = (TimeFormatterPrivate *)user_data;
    GError *error = NULL;

    priv->system_bus = g_bus_get_finish (result, &error);
    if (priv->system_bus == NULL) {
        if (!g_error_matches (error, G_IO_ERROR, G_IO_ERROR_CANCELLED))
            qWarning("TimeFormatter: cannot connect to the system bus: %s", error->message);
        g_error_free (error);
        return;
    }

    /* Listen to the PropertiesChanged on the org.freedesktop.timedate1
     * interface from any sender. In practice, this signal will only be sent
     * from timedated (we can trust other processes on the system bus to behave
     * nicely). That way, we don't have to watch timedated's well-known name
     * and keep the process alive.
     */
    priv->subscription_id = g_dbus_connection_signal_subscribe (priv->system_bus,
                                                                NULL,   /* sender */
                                                                "org.freedesktop.DBus.Properties",
                                                                "PropertiesChanged",
                                                                NULL,
                                                                "org.freedesktop.timedate1",
                                                                G_DBUS_SIGNAL_FLAGS_NONE,
                                                                timedate1_properties_changed,
                                                                priv, NULL);
}

TimeFormatter::TimeFormatter(QObject *parent): QObject(parent)
{
    priv = new TimeFormatterPrivate;
    priv->formatter = this;
    priv->time = 0;
    priv->format = "yyyy-MM-dd hh:mm";
    priv->system_bus = NULL;
    priv->subscription_id = 0;
    priv->cancellable = g_cancellable_new ();

    g_bus_get (G_BUS_TYPE_SYSTEM, priv->cancellable, got_bus, priv);
}

TimeFormatter::~TimeFormatter()
{
    if (priv->system_bus) {
        g_dbus_connection_signal_unsubscribe (priv->system_bus, priv->subscription_id);
        g_object_unref (priv->system_bus);
    }

    g_cancellable_cancel (priv->cancellable);
    g_object_unref (priv->cancellable);
}

QString TimeFormatter::format() const
{
    return priv->format;
}

QString TimeFormatter::timeString() const
{
    return priv->timeString;
}

qint64 TimeFormatter::time() const
{
    return priv->time;
}

void TimeFormatter::setFormat(const QString &format)
{
    if (priv->format != format) {
        priv->format = format;
        Q_EMIT formatChanged(priv->format);
        update();
    }
}

void TimeFormatter::setTime(qint64 time)
{
    if (priv->time != time) {
        priv->time = time;
        Q_EMIT timeChanged(priv->time);
        update();
    }
}

void TimeFormatter::update()
{
    priv->timeString = QDateTime::fromMSecsSinceEpoch(priv->time / 1000).toString(priv->format);
    Q_EMIT timeStringChanged(priv->timeString);
}
