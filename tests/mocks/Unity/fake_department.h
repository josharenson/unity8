/*
 * Copyright (C) 2014 Canonical, Ltd.
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

#ifndef FAKE_DEPARTMENT_H
#define FAKE_DEPARTMENT_H

#include <unity/shell/scopes/DepartmentInterface.h>

class Scope;

class Department : public unity::shell::scopes::DepartmentInterface
{
    Q_OBJECT

public:
    Department(const QString& departmentId, const QString& label, const QString& allLabel, const QString& parentId, const QString& parentLabel, Scope* scope);

    QString departmentId() const override;
    QString label() const override;
    QString allLabel() const override;
    QString parentDepartmentId() const override;
    QString parentLabel() const override;
    bool loaded() const override;
    int count() const override;
    bool isRoot() const override;

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QHash<int, QByteArray> roleNames() const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

public Q_SLOTS:
    void slotCurrentDepartmentChanged();

private Q_SLOTS:
    void slotLoaded();

private:
    QString m_departmentId;
    QString m_label;
    QString m_allLabel;
    QString m_parentId;
    QString m_parentLabel;
    bool m_loaded;
    QString m_currentDepartment;
    Scope *m_scope;
};

#endif // FAKE_DEPARTMENT_H
