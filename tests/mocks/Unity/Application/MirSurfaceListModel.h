/*
 * Copyright (C) 2016-2017 Canonical, Ltd.
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

#ifndef MIRSURFACELISTMODEL_H
#define MIRSURFACELISTMODEL_H

// unity-api
#include <unity/shell/application/MirSurfaceListInterface.h>

#include <QAbstractListModel>
#include <QList>

class MirSurfaceListModel : public unity::shell::application::MirSurfaceListInterface
{
    Q_OBJECT
public:
    explicit MirSurfaceListModel(QObject *parent = 0);

    Q_INVOKABLE unity::shell::application::MirSurfaceInterface *get(int index) override;
    const unity::shell::application::MirSurfaceInterface *get(int index) const;

    // QAbstractItemModel methods
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role) const override;

    void addSurface(unity::shell::application::MirSurfaceInterface *surface);
    void removeSurface(unity::shell::application::MirSurfaceInterface *surface);

    bool contains(unity::shell::application::MirSurfaceInterface *surface) const { return m_surfaceList.contains(surface); }

private:
    void raise(unity::shell::application::MirSurfaceInterface *surface);
    void moveSurface(int from, int to);
    void connectSurface(unity::shell::application::MirSurfaceInterface *surface);

    QList<unity::shell::application::MirSurfaceInterface*> m_surfaceList;
};

Q_DECLARE_METATYPE(MirSurfaceListModel*)

#endif // MIRSURFACELISTMODEL_H
