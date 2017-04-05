/*
 * Copyright 2015-2016 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include "windowstatestorage.h"

#include <QtConcurrent>
#include <QDebug>
#include <QFutureSynchronizer>
#include <QSqlQuery>
#include <QSqlError>
#include <QSqlResult>
#include <QRect>
#include <unity/shell/application/ApplicationInfoInterface.h>

QMutex WindowStateStorage::s_mutex;

inline QString sanitiseString(QString string) {
    return string.remove(QLatin1Char('\"'))
                 .remove(QLatin1Char('\''))
                 .remove(QLatin1Char('\\'));
}

WindowStateStorage::WindowStateStorage(QObject *parent):
    QObject(parent)
{
    const QString dbPath = QStandardPaths::writableLocation(QStandardPaths::GenericCacheLocation) + QStringLiteral("/unity8/");
    m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"));
    QDir dir;
    dir.mkpath(dbPath);
    m_db.setDatabaseName(dbPath + "windowstatestorage.sqlite");
    initdb();
}

WindowStateStorage::~WindowStateStorage()
{
    QFutureSynchronizer<void> futureSync;
    for (int i = 0; i < m_asyncQueries.count(); ++i) {
        futureSync.addFuture(m_asyncQueries[i]);
    }
    futureSync.waitForFinished();
    m_db.close();
}

void WindowStateStorage::saveState(const QString &windowId, WindowStateStorage::WindowState state)
{
    const QString queryString = QStringLiteral("INSERT OR REPLACE INTO state (windowId, state) values ('%1', '%2');")
            .arg(sanitiseString(windowId))
            .arg((int)state);

    saveValue(queryString);
}

WindowStateStorage::WindowState WindowStateStorage::getState(const QString &windowId, WindowStateStorage::WindowState defaultValue) const
{
    const QString queryString = QStringLiteral("SELECT state FROM state WHERE windowId = '%1';")
            .arg(sanitiseString(windowId));

    QSqlQuery query = getValue(queryString);

    if (!query.first()) {
        return defaultValue;
    }
    return (WindowState)query.value(QStringLiteral("state")).toInt();
}

void WindowStateStorage::saveGeometry(const QString &windowId, const QRect &rect)
{
    const QString queryString = QStringLiteral("INSERT OR REPLACE INTO geometry (windowId, x, y, width, height) values ('%1', '%2', '%3', '%4', '%5');")
            .arg(sanitiseString(windowId))
            .arg(rect.x())
            .arg(rect.y())
            .arg(rect.width())
            .arg(rect.height());

    saveValue(queryString);
}

void WindowStateStorage::saveStage(const QString &appId, int stage)
{
    const QString queryString = QStringLiteral("INSERT OR REPLACE INTO stage (appId, stage) values ('%1', '%2');")
            .arg(sanitiseString(appId))
            .arg(stage);

    saveValue(queryString);
}

int WindowStateStorage::getStage(const QString &appId, int defaultValue) const
{
    const QString queryString = QStringLiteral("SELECT stage FROM stage WHERE appId = '%1';")
            .arg(sanitiseString(appId));

    QSqlQuery query = getValue(queryString);

    if (!query.first()) {
        return defaultValue;
    }
    return query.value("stage").toInt();
}

void WindowStateStorage::executeAsyncQuery(const QString &queryString)
{
    QMutexLocker l(&s_mutex);
    QSqlQuery query;

    bool ok = query.exec(queryString);
    if (!ok) {
        qWarning() << "Error executing query" << queryString
                   << "Driver error:" << query.lastError().driverText()
                   << "Database error:" << query.lastError().databaseText();
    }
}

QRect WindowStateStorage::getGeometry(const QString &windowId, const QRect &defaultValue) const
{
    QString queryString = QStringLiteral("SELECT * FROM geometry WHERE windowId = '%1';")
            .arg(sanitiseString(windowId));

    QSqlQuery query = getValue(queryString);

    if (!query.first()) {
        return defaultValue;
    }

    const QRect result(query.value(QStringLiteral("x")).toInt(), query.value(QStringLiteral("y")).toInt(),
                       query.value(QStringLiteral("width")).toInt(), query.value(QStringLiteral("height")).toInt());

    if (result.isValid()) {
        return result;
    }

    return defaultValue;
}

void WindowStateStorage::initdb()
{
    m_db.open();
    if (!m_db.open()) {
        qWarning() << "Error opening state database:" << m_db.lastError().driverText() << m_db.lastError().databaseText();
        return;
    }

    if (!m_db.tables().contains(QStringLiteral("geometry"))) {
        QSqlQuery query;
        query.exec(QStringLiteral("CREATE TABLE geometry(windowId TEXT UNIQUE, x INTEGER, y INTEGER, width INTEGER, height INTEGER);"));
    }

    if (!m_db.tables().contains(QStringLiteral("state"))) {
        QSqlQuery query;
        query.exec(QStringLiteral("CREATE TABLE state(windowId TEXT UNIQUE, state INTEGER);"));
    }

    if (!m_db.tables().contains(QStringLiteral("stage"))) {
        QSqlQuery query;
        query.exec(QStringLiteral("CREATE TABLE stage(appId TEXT UNIQUE, stage INTEGER);"));
    }
}

void WindowStateStorage::saveValue(const QString &queryString)
{
    QMutexLocker mutexLocker(&s_mutex);

    QFuture<void> future = QtConcurrent::run(&m_threadPool, executeAsyncQuery, queryString);
    m_asyncQueries.append(future);

    QFutureWatcher<void> *futureWatcher = new QFutureWatcher<void>();
    futureWatcher->setFuture(future);
    connect(futureWatcher, &QFutureWatcher<void>::finished,
            this,
            [=](){ m_asyncQueries.removeAll(futureWatcher->future());
        futureWatcher->deleteLater(); });
}

QSqlQuery WindowStateStorage::getValue(const QString &queryString) const
{
    QMutexLocker l(&s_mutex);
    QSqlQuery query;

    bool ok = query.exec(queryString);
    if (!ok) {
        qWarning() << "Error retrieving database query:" << queryString
                   << "Driver error:" << query.lastError().driverText()
                   << "Database error:" << query.lastError().databaseText();
    }
    return query;
}

Mir::State WindowStateStorage::toMirState(WindowState state) const
{
    // assumes a single state (not an OR of several)
    switch (state) {
        case WindowStateMaximized:             return Mir::MaximizedState;
        case WindowStateMinimized:             return Mir::MinimizedState;
        case WindowStateFullscreen:            return Mir::FullscreenState;
        case WindowStateMaximizedLeft:         return Mir::MaximizedLeftState;
        case WindowStateMaximizedRight:        return Mir::MaximizedRightState;
        case WindowStateMaximizedHorizontally: return Mir::HorizMaximizedState;
        case WindowStateMaximizedVertically:   return Mir::VertMaximizedState;
        case WindowStateMaximizedTopLeft:      return Mir::MaximizedTopLeftState;
        case WindowStateMaximizedTopRight:     return Mir::MaximizedTopRightState;
        case WindowStateMaximizedBottomLeft:   return Mir::MaximizedBottomLeftState;
        case WindowStateMaximizedBottomRight:  return Mir::MaximizedBottomRightState;

        case WindowStateNormal:
        case WindowStateRestored:
        default:
            return Mir::RestoredState;
    }
}
