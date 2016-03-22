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

#ifndef MIRSURFACELISTMODEL_H
#define MIRSURFACELISTMODEL_H

// unity-api
#include <unity/shell/application/MirSurfaceListInterface.h>

#include <QAbstractListModel>
#include <QList>

class MirSurface;

class MirSurfaceListModel : public unity::shell::application::MirSurfaceListInterface
{
    Q_OBJECT
public:
    explicit MirSurfaceListModel(QObject *parent = nullptr);

    Q_INVOKABLE unity::shell::application::MirSurfaceInterface *get(int index) override;

    // QAbstractItemModel methods
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role) const override;
};

#endif // MIRSURFACELISTMODEL_H
