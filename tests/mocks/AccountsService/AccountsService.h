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
 * Authors: Gerry Boland <gerry.boland@canonical.com>
 *          Michael Terry <michael.terry@canonical.com>
 */

#ifndef UNITY_MOCK_ACCOUNTSSERVICE_H
#define UNITY_MOCK_ACCOUNTSSERVICE_H

#include <QObject>
#include <QString>
#include <QVariant>

class AccountsService: public QObject
{
    Q_OBJECT
    Q_ENUMS(PasswordDisplayHint)
    Q_PROPERTY (QString user
                READ user
                WRITE setUser
                NOTIFY userChanged)
    Q_PROPERTY (bool demoEdges
                READ demoEdges
                WRITE setDemoEdges
                NOTIFY demoEdgesChanged)
    Q_PROPERTY (QString backgroundFile
                READ backgroundFile
                WRITE setBackgroundFile // only available in mock
                NOTIFY backgroundFileChanged)
    Q_PROPERTY (bool statsWelcomeScreen
                READ statsWelcomeScreen
                WRITE setStatsWelcomeScreen // only available in mock
                NOTIFY statsWelcomeScreenChanged)
    Q_PROPERTY (PasswordDisplayHint passwordDisplayHint
                READ passwordDisplayHint
                NOTIFY passwordDisplayHintChanged)

public:
    enum PasswordDisplayHint {
        Keyboard,
        Numeric,
    };

    explicit AccountsService(QObject *parent = 0);

    QString user() const;
    void setUser(const QString &user);
    bool demoEdges() const;
    void setDemoEdges(bool demoEdges);
    QString backgroundFile() const;
    void setBackgroundFile(const QString &backgroundFile);
    bool statsWelcomeScreen() const;
    void setStatsWelcomeScreen(bool statsWelcomeScreen);
    PasswordDisplayHint passwordDisplayHint() const;

Q_SIGNALS:
    void userChanged();
    void demoEdgesChanged();
    void backgroundFileChanged();
    void statsWelcomeScreenChanged();
    void passwordDisplayHintChanged();

private:
    QString m_backgroundFile;
    QString m_user;
    bool m_statsWelcomeScreen;
};

#endif
