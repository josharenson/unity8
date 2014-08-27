/*
 * Copyright 2013 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 *      Nick Dedekind <nick.dedekind@canonical.com>
 */

#ifndef UNITYMENUMODELCACHE_H
#define UNITYMENUMODELCACHE_H

#include "unityindicatorsglobal.h"

#include <QObject>
#include <QHash>

class UnityMenuModel;

class UNITYINDICATORS_EXPORT UnityMenuModelCache : public QObject
{
    Q_OBJECT
public:
    UnityMenuModelCache(QObject*parent=nullptr);
    ~UnityMenuModelCache();

    Q_INVOKABLE UnityMenuModel* model(const QByteArray& bus,
                                      const QByteArray& path,
                                      const QVariantMap& actions);
    Q_INVOKABLE bool contains(const QByteArray& path);

private:
    QHash<QByteArray, UnityMenuModel*> m_registry;
};

#endif // UNITYMENUMODELCACHE_H
