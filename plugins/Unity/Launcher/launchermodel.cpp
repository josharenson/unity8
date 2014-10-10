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
 *      Michael Zanetti <michael.zanetti@canonical.com>
 */

#include "launchermodel.h"
#include "launcheritem.h"
#include "gsettings.h"
#include "desktopfilehandler.h"
#include "dbusinterface.h"

#include <unity/shell/application/ApplicationInfoInterface.h>

#include <QDesktopServices>
#include <QDebug>

using namespace unity::shell::application;

LauncherModel::LauncherModel(QObject *parent):
    LauncherModelInterface(parent),
    m_settings(new GSettings(this)),
    m_dbusIface(new DBusInterface(this)),
    m_appManager(0)
{
    connect(m_dbusIface, &DBusInterface::countChanged, this, &LauncherModel::countChanged);
    connect(m_dbusIface, &DBusInterface::countVisibleChanged, this, &LauncherModel::countVisibleChanged);
    connect(m_dbusIface, &DBusInterface::refreshCalled, this, &LauncherModel::refresh);

    Q_FOREACH (const QString &entry, m_settings->storedApplications()) {
        DesktopFileHandler desktopFile(entry);
        if (!desktopFile.isValid()) {
            qWarning() << "Couldn't find a .desktop file for" << entry << ". Skipping...";
            continue;
        }

        LauncherItem *item = new LauncherItem(entry,
                                              desktopFile.displayName(),
                                              desktopFile.icon(),
                                              this);
        item->setPinned(true);
        m_list.append(item);
    }
}

LauncherModel::~LauncherModel()
{
    while (!m_list.empty()) {
        m_list.takeFirst()->deleteLater();
    }
}

int LauncherModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_list.count();
}

QVariant LauncherModel::data(const QModelIndex &index, int role) const
{
    LauncherItem *item = m_list.at(index.row());
    switch(role) {
        case RoleAppId:
            return item->appId();
        case RoleName:
            return item->name();
        case RoleIcon:
            return item->icon();
        case RolePinned:
            return item->pinned();
        case RoleCount:
            return item->count();
        case RoleCountVisible:
            return item->countVisible();
        case RoleProgress:
            return item->progress();
        case RoleFocused:
            return item->focused();
    }

    return QVariant();
}

unity::shell::launcher::LauncherItemInterface *LauncherModel::get(int index) const
{
    if (index < 0 || index >= m_list.count()) {
        return 0;
    }
    return m_list.at(index);
}

void LauncherModel::move(int oldIndex, int newIndex)
{
    // Make sure its not moved outside the lists
    if (newIndex < 0) {
        newIndex = 0;
    }
    if (newIndex >= m_list.count()) {
        newIndex = m_list.count()-1;
    }

    // Nothing to do?
    if (oldIndex == newIndex) {
        return;
    }

    // QList's and QAbstractItemModel's move implementation differ when moving an item up the list :/
    // While QList needs the index in the resulting list, beginMoveRows expects it to be in the current list
    // adjust the model's index by +1 in case we're moving upwards
    int newModelIndex = newIndex > oldIndex ? newIndex+1 : newIndex;

    beginMoveRows(QModelIndex(), oldIndex, oldIndex, QModelIndex(), newModelIndex);
    m_list.move(oldIndex, newIndex);
    endMoveRows();

    if (!m_list.at(newIndex)->pinned()) {
        pin(m_list.at(newIndex)->appId());
    } else {
        storeAppList();
    }
}

void LauncherModel::pin(const QString &appId, int index)
{
    int currentIndex = findApplication(appId);

    if (currentIndex >= 0) {
        if (index == -1 || index == currentIndex) {
            m_list.at(currentIndex)->setPinned(true);
            QModelIndex modelIndex = this->index(currentIndex);
            Q_EMIT dataChanged(modelIndex, modelIndex, QVector<int>() << RolePinned);
        } else {
            move(currentIndex, index);
            // move() will store the list to the backend itself, so just exit at this point.
            return;
        }
    } else {
        if (index == -1) {
            index = m_list.count();
        }

        DesktopFileHandler desktopFile(appId);
        if (!desktopFile.isValid()) {
            qWarning() << "Can't pin this application, there is no .destkop file available.";
            return;
        }

        beginInsertRows(QModelIndex(), index, index);
        LauncherItem *item = new LauncherItem(appId,
                                              desktopFile.displayName(),
                                              desktopFile.icon(),
                                              this);
        item->setPinned(true);
        m_list.insert(index, item);
        endInsertRows();
    }

    storeAppList();
}

void LauncherModel::requestRemove(const QString &appId)
{
    int index = findApplication(appId);
    if (index < 0) {
        return;
    }

    if (m_appManager->findApplication(appId)) {
        m_list.at(index)->setPinned(false);
        QModelIndex modelIndex = this->index(index);
        Q_EMIT dataChanged(modelIndex, modelIndex, QVector<int>() << RolePinned);
        return;
    }

    beginRemoveRows(QModelIndex(), index, index);
    m_list.takeAt(index)->deleteLater();
    endRemoveRows();

    storeAppList();
}

void LauncherModel::quickListActionInvoked(const QString &appId, int actionIndex)
{
    int index = findApplication(appId);
    if (index < 0) {
        return;
    }

    LauncherItem *item = m_list.at(index);
    QuickListModel *model = qobject_cast<QuickListModel*>(item->quickList());
    if (model) {
        QString actionId = model->get(actionIndex).actionId();

        // Check if this is one of the launcher actions we handle ourselves
        if (actionId == "pin_item") {
            if (item->pinned()) {
                requestRemove(appId);
            } else {
                pin(appId);
            }
        } else if (actionId == "launch_item") {
            QDesktopServices::openUrl(getUrlForAppId(appId));

        // Nope, we don't know this action, let the backend forward it to the application
        } else {
            // TODO: forward quicklist action to app, possibly via m_dbusIface
        }
    }
}

void LauncherModel::setUser(const QString &username)
{
    Q_UNUSED(username)
    qWarning() << "This backend doesn't support multiple users";
}

QString LauncherModel::getUrlForAppId(const QString &appId) const
{
    // appId is either an appId or a legacy app name.  Let's find out which
    if (appId.isEmpty()) {
        return QString();
    }

    if (!appId.contains("_")) {
        return "application:///" + appId + ".desktop";
    }

    QStringList parts = appId.split('_');
    QString package = parts.value(0);
    QString app = parts.value(1, "first-listed-app");
    return "appid://" + package + "/" + app + "/current-user-version";
}

ApplicationManagerInterface *LauncherModel::applicationManager() const
{
    return m_appManager;
}

void LauncherModel::setApplicationManager(unity::shell::application::ApplicationManagerInterface *appManager)
{
    // Is there already another appmanager set?
    if (m_appManager) {
        // Disconnect any signals
        disconnect(this, SLOT(applicationAdded(QModelIndex,int)));
        disconnect(this, SLOT(applicationRemoved(QModelIndex,int)));
        disconnect(this, SLOT(focusedAppIdChanged()));

        // remove any recent/running apps from the launcher
        QList<int> recentAppIndices;
        for (int i = 0; i < m_list.count(); ++i) {
            if (m_list.at(i)->recent()) {
                recentAppIndices << i;
            }
        }
        int run = 0;
        while (recentAppIndices.count() > 0) {
            beginRemoveRows(QModelIndex(), recentAppIndices.first() - run, recentAppIndices.first() - run);
            m_list.takeAt(recentAppIndices.first() - run)->deleteLater();
            endRemoveRows();
            recentAppIndices.takeFirst();
            ++run;
        }
    }

    m_appManager = appManager;
    connect(m_appManager, SIGNAL(rowsInserted(QModelIndex, int, int)), SLOT(applicationAdded(QModelIndex,int)));
    connect(m_appManager, SIGNAL(rowsAboutToBeRemoved(QModelIndex,int,int)), SLOT(applicationRemoved(QModelIndex,int)));
    connect(m_appManager, SIGNAL(focusedApplicationIdChanged()), SLOT(focusedAppIdChanged()));

    Q_EMIT applicationManagerChanged();

    for (int i = 0; i < appManager->count(); ++i) {
        applicationAdded(QModelIndex(), i);
    }
}


void LauncherModel::storeAppList()
{
    QStringList appIds;
    Q_FOREACH(LauncherItem *item, m_list) {
        if (item->pinned()) {
            appIds << item->appId();
        }
    }
    m_settings->setStoredApplications(appIds);
}

int LauncherModel::findApplication(const QString &appId)
{
    for (int i = 0; i < m_list.count(); ++i) {
        LauncherItem *item = m_list.at(i);
        if (item->appId() == appId) {
            return i;
        }
    }
    return -1;
}

void LauncherModel::progressChanged(const QString &appId, int progress)
{
    int idx = findApplication(appId);
    if (idx >= 0) {
        LauncherItem *item = m_list.at(idx);
        item->setProgress(progress);
        Q_EMIT dataChanged(index(idx), index(idx), QVector<int>() << RoleProgress);
    }
}


void LauncherModel::countChanged(const QString &appId, int count)
{
    int idx = findApplication(appId);
    if (idx >= 0) {
        LauncherItem *item = m_list.at(idx);
        item->setCount(count);
        Q_EMIT dataChanged(index(idx), index(idx), QVector<int>() << RoleCount);
    }
}

void LauncherModel::countVisibleChanged(const QString &appId, int countVisible)
{
    int idx = findApplication(appId);
    if (idx >= 0) {
        LauncherItem *item = m_list.at(idx);
        item->setCountVisible(countVisible);
        Q_EMIT dataChanged(index(idx), index(idx), QVector<int>() << RoleCountVisible);

        // If countVisible goes to false, and the item is neither pinned nor recent we can drop it
        if (!countVisible && !item->pinned() && !item->recent()) {
            beginRemoveRows(QModelIndex(), idx, idx);
            m_list.takeAt(idx)->deleteLater();
            endRemoveRows();
        }
    } else {
        // Need to create a new LauncherItem and show the highlight
        DesktopFileHandler desktopFile(appId);
        if (countVisible && desktopFile.isValid()) {
            LauncherItem *item = new LauncherItem(appId,
                                                  desktopFile.displayName(),
                                                  desktopFile.icon());
            item->setCountVisible(true);
            beginInsertRows(QModelIndex(), m_list.count(), m_list.count());
            m_list.append(item);
            endInsertRows();
        }
    }
}

void LauncherModel::refresh()
{
    QList<LauncherItem*> toBeRemoved;
    Q_FOREACH (LauncherItem* item, m_list) {
        DesktopFileHandler desktopFile(item->appId());
        if (!desktopFile.isValid()) {
            toBeRemoved << item;
        } else {
            int idx = m_list.indexOf(item);
            item->setName(desktopFile.displayName());
            item->setIcon(desktopFile.icon());
            Q_EMIT dataChanged(index(idx), index(idx), QVector<int>() << RoleName << RoleIcon);
        }
    }

    Q_FOREACH (LauncherItem* item, toBeRemoved) {
        requestRemove(item->appId());
    }
}

void LauncherModel::applicationAdded(const QModelIndex &parent, int row)
{
    Q_UNUSED(parent);

    ApplicationInfoInterface *app = m_appManager->get(row);
    if (!app) {
        qWarning() << "LauncherModel received an applicationAdded signal, but there's no such application!";
        return;
    }

    if (app->appId() == "unity8-dash") {
        // Not adding the dash app
        return;
    }

    bool found = false;
    Q_FOREACH(LauncherItem *item, m_list) {
        if (app->appId() == item->appId()) {
            found = true;
            break;
        }
    }
    if (found) {
        // Shall we paint some running/recent app highlight? If yes, do it here.
    } else {
        LauncherItem *item = new LauncherItem(app->appId(), app->name(), app->icon().toString(), this);
        item->setRecent(true);
        item->setFocused(app->focused());

        beginInsertRows(QModelIndex(), m_list.count(), m_list.count());
        m_list.append(item);
        endInsertRows();
    }
}

void LauncherModel::applicationRemoved(const QModelIndex &parent, int row)
{
    Q_UNUSED(parent)

    int appIndex = -1;
    for (int i = 0; i < m_list.count(); ++i) {
        if (m_list.at(i)->appId() == m_appManager->get(row)->appId()) {
            appIndex = i;
            break;
        }
    }

    if (appIndex > -1 && !m_list.at(appIndex)->pinned()) {
        beginRemoveRows(QModelIndex(), appIndex, appIndex);
        m_list.takeAt(appIndex)->deleteLater();
        endRemoveRows();
    }
}

void LauncherModel::focusedAppIdChanged()
{
    QString appId = m_appManager->focusedApplicationId();
    for (int i = 0; i < m_list.count(); ++i) {
        LauncherItem *item = m_list.at(i);
        if (!item->focused() && item->appId() == appId) {
            item->setFocused(true);
            Q_EMIT dataChanged(index(i), index(i), QVector<int>() << RoleFocused);
        } else if (item->focused() && item->appId() != appId) {
            item->setFocused(false);
            Q_EMIT dataChanged(index(i), index(i), QVector<int>() << RoleFocused);
        }
    }
}
