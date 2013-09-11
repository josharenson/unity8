/*
 * Copyright (C) 2013 Canonical, Ltd.
 *
 * Authors:
 *  Pawel Stolowski <pawel.stolowski@canonical.com>
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

// local
#include "applicationpreview.h"
#include "iconutils.h"

#include <QDebug>

ApplicationPreview::ApplicationPreview(QObject *parent):
    Preview(parent),
    m_unityAppPreview(nullptr)
{
}

QString ApplicationPreview::lastUpdate() const
{
    if (m_unityAppPreview) {
        return QString::fromStdString(m_unityAppPreview->last_update());
    } else {
        qWarning() << "Preview not set";
    }
    return QString();
}

QString ApplicationPreview::copyright() const
{
    if (m_unityAppPreview) {
        return QString::fromStdString(m_unityAppPreview->copyright());
    } else {
        qWarning() << "Preview not set";
    }
    return QString();
}

QString ApplicationPreview::license() const
{
    if (m_unityAppPreview) {
        return QString::fromStdString(m_unityAppPreview->license());
    } else {
        qWarning() << "Preview not set";
    }
    return QString();
}

QString ApplicationPreview::appIcon() const
{
    if (m_unityAppPreview) {
        auto giconString = g_icon_to_string(m_unityAppPreview->app_icon());
        QString result(gIconToDeclarativeImageProviderString(QString::fromUtf8(giconString)));
        g_free(giconString);
        return result;
    } else {
        qWarning() << "Preview not set";
    }
    return QString();
}

float ApplicationPreview::rating() const
{
    if (m_unityAppPreview) {
        return m_unityAppPreview->rating();
    } else {
        qWarning() << "Preview not set";
    }
    return 0.0f;
}

unsigned int ApplicationPreview::numRatings() const
{
    if (m_unityAppPreview) {
        return m_unityAppPreview->num_ratings();
    } else {
        qWarning() << "Preview not set";
    }
    return 0;
}

void ApplicationPreview::setUnityPreview(unity::dash::Preview::Ptr unityPreview)
{
    m_unityAppPreview = std::dynamic_pointer_cast<unity::dash::ApplicationPreview>(unityPreview);

    Q_EMIT previewChanged();
}
