/*
 * Copyright (C) 2013-2014 Canonical, Ltd.
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

#include "ApplicationManager.h"
#include "ApplicationInfo.h"
#include "Session.h"
#include "ApplicationTestInterface.h"

#include <paths.h>

#include <QDir>
#include <QGuiApplication>
#include <QQuickItem>
#include <QQuickView>
#include <QQmlComponent>
#include <QTimer>
#include <QDateTime>
#include <QtDBus/QtDBus>

ApplicationManager *ApplicationManager::the_application_manager = nullptr;

ApplicationManager *ApplicationManager::singleton()
{
    if (!the_application_manager) {
        the_application_manager = new ApplicationManager();
    }
    return the_application_manager;
}

ApplicationManager::ApplicationManager(QObject *parent)
    : ApplicationManagerInterface(parent)
    , m_suspended(false)
    , m_forceDashActive(false)
{
    m_roleNames.insert(RoleSession, "session");
    m_roleNames.insert(RoleFullscreen, "fullscreen");

    buildListOfAvailableApplications();

    // polling to find out when the toplevel window has been created as there's
    // no signal telling us that
    connect(&m_windowCreatedTimer, &QTimer::timeout,
            this, &ApplicationManager::onWindowCreatedTimerTimeout);
    m_windowCreatedTimer.setSingleShot(false);
    m_windowCreatedTimer.start(200);
}

ApplicationManager::~ApplicationManager()
{
}

void ApplicationManager::onWindowCreatedTimerTimeout()
{
    if (QGuiApplication::topLevelWindows().count() > 0) {
        m_windowCreatedTimer.stop();
        onWindowCreated();
    }
}

void ApplicationManager::onWindowCreated()
{
    startApplication("unity8-dash");
    focusApplication("unity8-dash");
}

int ApplicationManager::rowCount(const QModelIndex& parent) const {
    return !parent.isValid() ? m_runningApplications.size() : 0;
}

QVariant ApplicationManager::data(const QModelIndex& index, int role) const {
    if (index.row() < 0 || index.row() >= m_runningApplications.size())
        return QVariant();

    auto app = m_runningApplications.at(index.row());
    switch(role) {
    case RoleAppId:
        return app->appId();
    case RoleName:
        return app->name();
    case RoleComment:
        return app->comment();
    case RoleIcon:
        return app->icon();
    case RoleStage:
        return app->stage();
    case RoleState:
        return app->state();
    case RoleFocused:
        return app->focused();
    case RoleSession:
        return QVariant::fromValue(app->session());
    case RoleFullscreen:
        return app->fullscreen();
    default:
        return QVariant();
    }
}

ApplicationInfo *ApplicationManager::get(int row) const {
    if (row < 0 || row >= m_runningApplications.size())
        return nullptr;
    return m_runningApplications.at(row);
}

ApplicationInfo *ApplicationManager::findApplication(const QString &appId) const {
    for (ApplicationInfo *app : m_runningApplications) {
        if (app->appId() == appId) {
            return app;
        }
    }
    return nullptr;
}

QModelIndex ApplicationManager::findIndex(ApplicationInfo* application)
{
    for (int i = 0; i < m_runningApplications.size(); ++i) {
        if (m_runningApplications.at(i) == application) {
            return index(i);
        }
    }

    return QModelIndex();
}

void ApplicationManager::add(ApplicationInfo *application) {
    if (!application) {
        return;
    }

    beginInsertRows(QModelIndex(), m_runningApplications.size(), m_runningApplications.size());
    m_runningApplications.append(application);
    endInsertRows();
    Q_EMIT applicationAdded(application->appId());
    Q_EMIT countChanged();
    if (count() == 1) Q_EMIT emptyChanged(isEmpty()); // was empty but not anymore

    connect(application, &ApplicationInfo::sessionChanged, this, [application, this]() {
        QModelIndex appIndex = findIndex(application);
        if (!appIndex.isValid()) return;
        Q_EMIT dataChanged(appIndex, appIndex, QVector<int>() << ApplicationManager::RoleSession);
    });
    connect(application, &ApplicationInfo::focusedChanged, this, [application, this]() {
        QModelIndex appIndex = findIndex(application);
        if (!appIndex.isValid()) return;
        Q_EMIT dataChanged(appIndex, appIndex, QVector<int>() << ApplicationManager::RoleFocused);
    });
    connect(application, &ApplicationInfo::stateChanged, this, [application, this]() {
        QModelIndex appIndex = findIndex(application);
        if (!appIndex.isValid()) return;
        Q_EMIT dataChanged(appIndex, appIndex, QVector<int>() << ApplicationManager::RoleState);
    });
}

void ApplicationManager::remove(ApplicationInfo *application) {
    int i = m_runningApplications.indexOf(application);
    if (i != -1) {
        beginRemoveRows(QModelIndex(), i, i);
        m_runningApplications.removeAt(i);
        endRemoveRows();
        Q_EMIT applicationRemoved(application->appId());
        Q_EMIT countChanged();
        if (isEmpty()) Q_EMIT emptyChanged(isEmpty());
    }
    application->disconnect(this);
}

void ApplicationManager::move(int from, int to) {
    if (from == to) return;

    if (from >= 0 && from < m_runningApplications.size() && to >= 0 && to < m_runningApplications.size()) {
        QModelIndex parent;
        /* When moving an item down, the destination index needs to be incremented
         * by one, as explained in the documentation:
         * http://qt-project.org/doc/qt-5.0/qtcore/qabstractitemmodel.html#beginMoveRows */
        beginMoveRows(parent, from, from, parent, to + (to > from ? 1 : 0));
        m_runningApplications.move(from, to);
        endMoveRows();
    }
}

int ApplicationManager::sideStageWidth() const
{
    return 0;
}

ApplicationManager::StageHint ApplicationManager::stageHint() const
{
    return MainStage;
}

ApplicationManager::FormFactorHint ApplicationManager::formFactorHint() const
{
    return PhoneFormFactor;
}

ApplicationInfo* ApplicationManager::startApplication(const QString &appId,
                                              const QStringList &arguments)
{
    return startApplication(appId, NoFlag, arguments);
}

ApplicationInfo* ApplicationManager::startApplication(const QString &appId,
                                              ExecFlags flags,
                                              const QStringList &arguments)
{
    Q_UNUSED(arguments)
    ApplicationInfo *application = add(appId);
    if (!application)
        return 0;

    if (flags.testFlag(ApplicationManager::ForceMainStage)
            && application->stage() == ApplicationInfo::SideStage) {
        application->setStage(ApplicationInfo::MainStage);
    }
    application->setState(ApplicationInfo::Running);

    return application;
}

ApplicationInfo* ApplicationManager::add(QString appId)
{
    ApplicationInfo *application = 0;

    for (ApplicationInfo *availableApp : m_availableApplications) {
        if (availableApp->appId() == appId) {
            application = availableApp;
            break;
        }
    }

    if (application)
        add(application);

    return application;
}

bool ApplicationManager::stopApplication(const QString &appId)
{
    if (appId == "unity8-dash") {
        return false;
    }

    ApplicationInfo *application = findApplication(appId);
    if (application == nullptr)
        return false;

    if (application->appId() == focusedApplicationId()) {
        unfocusCurrentApplication();
    }
    application->setState(ApplicationInfo::Stopped);
    remove(application);
    return true;
}

QString ApplicationManager::focusedApplicationId() const {
    for (ApplicationInfo *app : m_runningApplications) {
        if (app->focused()) {
            return app->appId();
        }
    }
    return QString();
}

bool ApplicationManager::suspended() const
{
    return m_suspended;
}

void ApplicationManager::setSuspended(bool suspended)
{
    ApplicationInfo *focusedApp = findApplication(focusedApplicationId());
    if (focusedApp) {
        if (suspended) {
            focusedApp->setState(ApplicationInfo::Suspended);
        } else {
            focusedApp->setState(ApplicationInfo::Running);
        }
    }
    m_suspended = suspended;
    Q_EMIT suspendedChanged();
}

bool ApplicationManager::forceDashActive() const
{
    return m_forceDashActive;
}

void ApplicationManager::setForceDashActive(bool forceDashActive)
{
    if (m_forceDashActive == forceDashActive) {
        return;
    }

    ApplicationInfo *dash = findApplication("unity8-dash");
    if (dash) {
        if (forceDashActive) {
            dash->setState(ApplicationInfo::Running);
        } else {
            if (!dash->focused()) {
                dash->setState(ApplicationInfo::Suspended);
            }
        }
    }
    m_forceDashActive = forceDashActive;
    Q_EMIT forceDashActiveChanged();
}

bool ApplicationManager::focusApplication(const QString &appId)
{
    ApplicationInfo *application = findApplication(appId);
    if (application == nullptr)
        return false;

    // unfocus currently focused app
    for (ApplicationInfo *app : m_runningApplications) {
        if (app->focused()) {
            app->setFocused(false);
            app->setState(ApplicationInfo::Suspended);
        }
    }

    // focus this app
    application->setFocused(true);
    application->setState(ApplicationInfo::Running);

    // move app to top of stack
    move(m_runningApplications.indexOf(application), 0);
    Q_EMIT focusedApplicationIdChanged();
    return true;
}

bool ApplicationManager::requestFocusApplication(const QString &appId)
{
    QMetaObject::invokeMethod(this, "focusRequested", Qt::QueuedConnection, Q_ARG(QString, appId));
    return true;
}

void ApplicationManager::unfocusCurrentApplication()
{
    for (ApplicationInfo *app : m_runningApplications) {
        if (app->focused()) {
            app->setFocused(false);
        }
    }
    Q_EMIT focusedApplicationIdChanged();
}

void ApplicationManager::buildListOfAvailableApplications()
{
    ApplicationInfo *application;

    application = new ApplicationInfo(this);
    application->setAppId("unity8-dash");
    application->setName("Unity 8 Mock Dash");
    application->setScreenshotId("unity8-dash");
    application->setStage(ApplicationInfo::MainStage);
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("dialer-app");
    application->setName("Dialer");
    application->setScreenshotId("dialer");
    application->setIconId("dialer-app");
    application->setStage(ApplicationInfo::SideStage);
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("camera-app");
    application->setName("Camera");
    application->setScreenshotId("camera");
    application->setIconId("camera");
    application->setFullscreen(true);
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("gallery-app");
    application->setName("Gallery");
    application->setScreenshotId("gallery");
    application->setIconId("gallery");
    application->setFullscreen(true);
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("facebook-webapp");
    application->setName("Facebook");
    application->setScreenshotId("facebook");
    application->setIconId("facebook");
    application->setStage(ApplicationInfo::SideStage);
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("webbrowser-app");
    application->setFullscreen(true);
    application->setName("Browser");
    application->setScreenshotId("browser");
    application->setIconId("browser");
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("twitter-webapp");
    application->setName("Twitter");
    application->setScreenshotId("twitter");
    application->setIconId("twitter");
    application->setStage(ApplicationInfo::SideStage);
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("map");
    application->setName("Map");
    application->setIconId("map");
    application->setScreenshotId("map");
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("gmail-webapp");
    application->setName("GMail");
    application->setIconId("gmail");
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("ubuntu-weather-app");
    application->setName("Weather");
    application->setIconId("weather");
    application->setStage(ApplicationInfo::SideStage);
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("notes-app");
    application->setName("Notepad");
    application->setIconId("notepad");
    application->setStage(ApplicationInfo::SideStage);
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("calendar-app");
    application->setName("Calendar");
    application->setIconId("calendar");
    application->setStage(ApplicationInfo::SideStage);
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("evernote");
    application->setName("Evernote");
    application->setIconId("evernote");
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("pinterest");
    application->setName("Pinterest");
    application->setIconId("pinterest");
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("soundcloud");
    application->setName("SoundCloud");
    application->setIconId("soundcloud");
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("wikipedia");
    application->setName("Wikipedia");
    application->setIconId("wikipedia");
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("youtube");
    application->setName("YouTube");
    application->setIconId("youtube");
    m_availableApplications.append(application);

    // Vesa additions
    application = new ApplicationInfo(this);
    application->setAppId("home-feed");
    application->setName("Home Feed");
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("apps-feed");
    application->setName("Apps Feed");
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("video-feed");
    application->setName("Video Feed");
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("music-feed");
    application->setName("Music Feed");
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("news-feed");
    application->setName("News Feed");
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("amazon-feed");
    application->setName("Amazon");
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("ebay-feed");
    application->setName("Ebay");
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("store-feed");
    application->setName("Feed Store");
    m_availableApplications.append(application);

}


QStringList ApplicationManager::availableApplications()
{
    QStringList appIds;
    Q_FOREACH(ApplicationInfo *app, m_availableApplications) {
        appIds << app->appId();
    }
    return appIds;
}

bool ApplicationManager::isEmpty() const
{
    return m_runningApplications.isEmpty();
}
