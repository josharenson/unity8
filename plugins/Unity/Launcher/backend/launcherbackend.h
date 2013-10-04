/* Copyright (C) 2013 Canonical, Ltd.
 *
 * Authors:
 *  Michael Zanetti <michael.zanetti@canonical.com>
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

#ifndef LAUNCHERBACKEND_H
#define LAUNCHERBACKEND_H

#include "common/quicklistentry.h"

#include <QObject>
#include <QSettings>
#include <QStringList>

class AccountsServiceDBusAdaptor;

/**
  * @brief An interface that provides all the data needed by the launcher.
  */

class LauncherBackendItem;

class LauncherBackend : public QObject
{
    Q_OBJECT


public:
    LauncherBackend(QObject *parent = 0);
    virtual ~LauncherBackend();

    /**
      * @brief Returns a list of stored applications.
      * @returns A list of application IDs.
      */
    QStringList storedApplications() const;

    /**
      * @brief Set the list of stored applications.
      *
      * Any previously stored information for apps not contained
      * in the list any more, e.g. the pinned state, will be
      * discarded.
      *
      * @param appIds The new list of stored applications.
      */
    void setStoredApplications(const QStringList &appIds);

    /**
      * @brief Get the full path to the .desktop file.
      *
      * The application does not need to be in the list of stored applications.
      *
      * @returns The full path to the .dekstop file.
      */
    QString desktopFile(const QString &appId) const;

    /**
      * @brief Get the user friendly name of an application.
      *
      * The application does not need to be in the list of stored applications.
      *
      * @param appId The ID of the application.
      * @returns The user friendly name of the application.
      */
    QString displayName(const QString &appId) const;

    /**
      * @brief Get the icon of an application.
      *
      * The application does not need to be in the list of stored applications.
      *
      * @param appId The ID of the application.
      * @returns The full path to the icon for the application.
      */
    QString icon(const QString &appId) const;

    /**
      * @brief Is the app manually pinned?
      * @returns true if pinned, otherwise false.
      */
    bool isPinned(const QString &appId) const;

    /**
      * @brief Change the pinned state of an application.
      * @param appId The application where the pinned flag should be set.
      * @param pinned true if pinned, otherwise false.
      */
    void setPinned(const QString &appId, bool pinned);

    //TODO: Fill in getters for all the other things needed from the .desktop file.

    /**
      * @brief Get the QuickList for an application.
      * @param appId The ID of the application.
      * @returns A QuickListModelInterface containing the QuickList.
      */
    QList<QuickListEntry> quickList(const QString &appId) const;

    /**
      * @brief Execute an action from the quickList
      * @param appId The app ID for which the action was triggered
      * @param the quicklist ID of the action that was triggered
      */
    void triggerQuickListAction(const QString &appId, const QString &entryId);

    /**
      * @brief Get the progress for the progress overlay of an application.
      * @param appId The ID of the application.
      * @returns The percentage of the overlay progress bar. -1 if no progress bar available.
      */
    int progress(const QString &appId) const;

    /**
      * @brief Get the count of the count overlay of an application.
      * @param appId The ID of the application.
      * @returns The number to be displayed in the overlay. -1 if no count overlay is available.
      */
    int count(const QString &appId) const;

    /**
      * @brief Sets the username for which to look up launcher items.
      * @param username The username to use.
      */
    void setUser(const QString &username);

Q_SIGNALS:
    void quickListChanged(const QString &appId, const QList<QuickListEntry> &quickList);
    void progressChanged(const QString &appId, int progress);
    void countChanged(const QString &appId, int count);

private:
    QString findDesktopFile(const QString &appId) const;
    LauncherBackendItem* parseDesktopFile(const QString &desktopFile) const;

    QVariantMap itemToVariant(const QString &appId) const;
    void loadFromVariant(const QVariantMap &details);

    bool isDefaultsItem(const QList<QVariantMap> &apps) const;
    void syncFromAccounts();
    void syncToAccounts();

    QList<QString> m_storedApps;
    mutable QHash<QString, LauncherBackendItem*> m_itemCache;

    AccountsServiceDBusAdaptor *m_accounts;
    QString m_user;
};

#endif // LAUNCHERBACKEND_H
