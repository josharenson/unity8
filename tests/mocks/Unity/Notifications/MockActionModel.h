/*
 * Copyright 2014 Canonical Ltd.
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
 *      Mirco Mueller <mirco.mueller@canonical.com>
 */

#ifndef MOCK_ACTION_MODEL_H
#define MOCK_ACTION_MODEL_H

#include <QStringListModel>

struct ActionModelPrivate;

class ActionModel : public QStringListModel {
    Q_OBJECT

public:
    ActionModel(QObject *parent=nullptr);
    virtual ~ActionModel();

    virtual int rowCount(const QModelIndex &index) const;
    virtual QVariant data(const QModelIndex &index, int role) const;
    virtual QHash<int, QByteArray> roleNames() const;

    Q_ENUMS(ActionsRoles)
    enum ActionsRoles {
        RoleActionLabel = Qt::UserRole + 1,
        RoleActionId    = Qt::UserRole + 2
    };
    Q_INVOKABLE QVariant data(int row, int role) const;

    void insertAction(const QString &id, const QString &label);

private:
    QScopedPointer<ActionModelPrivate> p;
};

#endif // MOCK_ACTION_MODEL_H
