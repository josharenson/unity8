/*
 * Copyright (C) 2012 Canonical, Ltd.
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

#ifndef QSORTFILTERPROXYMODELQML_H
#define QSORTFILTERPROXYMODELQML_H

#include <QSortFilterProxyModel>

class QSortFilterProxyModelQML : public QSortFilterProxyModel
{
    Q_OBJECT

    Q_PROPERTY(QAbstractItemModel* model READ sourceModel WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(int totalCount READ totalCount NOTIFY totalCountChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(bool invertMatch READ invertMatch WRITE setInvertMatch NOTIFY invertMatchChanged)

public:
    explicit QSortFilterProxyModelQML(QObject *parent = 0);

    Q_INVOKABLE QVariant data(int row, int role);
    Q_INVOKABLE int count();
    Q_INVOKABLE int findFirst(int role, const QVariant& value) const;
    virtual bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const;

    /* getters */
    int totalCount() const;
    bool invertMatch() const;
    QHash<int, QByteArray> roleNames() const;

    /* setters */
    void setModel(QAbstractItemModel *model);
    void setInvertMatch(bool invertMatch);

Q_SIGNALS:
    void totalCountChanged();
    void countChanged();
    void invertMatchChanged(bool);
    void modelChanged();

private:
    bool m_invertMatch;
};

#endif // QSORTFILTERPROXYMODELQML_H
