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
 */

#include "ApplicationManager.h"
#include "ApplicationInfo.h"
#include "paths.h"

#include <QDir>
#include <QGuiApplication>
#include <QQuickItem>
#include <QQuickView>
#include <QQmlComponent>

ApplicationManager::ApplicationManager(QObject *parent)
    : ApplicationManagerInterface(parent)
    , m_mainStageComponent(0)
    , m_mainStage(0)
    , m_sideStageComponent(0)
    , m_sideStage(0)
{
    buildListOfAvailableApplications();
}

ApplicationManager::~ApplicationManager()
{
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

void ApplicationManager::add(ApplicationInfo *application) {
    if (!application)
        return;

    beginInsertRows(QModelIndex(), m_runningApplications.size(), m_runningApplications.size());
    m_runningApplications.append(application);
    endInsertRows();
    Q_EMIT countChanged();
}

void ApplicationManager::remove(ApplicationInfo *application) {
    int i = m_runningApplications.indexOf(application);
    if (i != -1) {
        beginRemoveRows(QModelIndex(), i, i);
        m_runningApplications.removeAt(i);
        endRemoveRows();
        Q_EMIT countChanged();
    }
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

int ApplicationManager::keyboardHeight() const
{
    return 0;
}

bool ApplicationManager::keyboardVisible() const
{
    return false;
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
    ApplicationInfo *application = 0;

    for (ApplicationInfo *availableApp : m_availableApplications) {
        if (availableApp->appId() == appId) {
            application = availableApp;
            break;
        }
    }

    if (!application)
        return 0;

    if (flags.testFlag(ApplicationManager::ForceMainStage)
            && application->stage() == ApplicationInfo::SideStage) {
        application->setStage(ApplicationInfo::MainStage);
    }
    add(application);

    return application;
}

bool ApplicationManager::stopApplication(const QString &appId)
{
    ApplicationInfo *application = findApplication(appId);
    if (application == nullptr)
        return false;

    remove(application);
    Q_EMIT focusedApplicationIdChanged();
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

bool ApplicationManager::focusApplication(const QString &appId)
{
    ApplicationInfo *application = findApplication(appId);
    if (application == nullptr)
        return false;

    if (application->stage() == ApplicationInfo::MainStage) {
        // unfocus currently focused mainstage app
        for (ApplicationInfo *app : m_runningApplications) {
            if (app->focused() && app->stage() == ApplicationInfo::MainStage) {
                app->setFocused(false);
                app->hideWindow();
            }
        }

        // focus this app
        application->setFocused(true);
        if (!m_mainStage)
            createMainStage();
        application->showWindow(m_mainStage);
        m_mainStage->setZ(-1000);
        if (m_sideStage)
            m_sideStage->setZ(-2000);
    } else if (application->stage() == ApplicationInfo::SideStage) {
        // unfocus currently focused sidestage app
        for (ApplicationInfo *app : m_runningApplications) {
            if (app->focused() && app->stage() == ApplicationInfo::SideStage) {
                app->setFocused(false);
                app->hideWindow();
            }
        }

        // focus this app
        application->setFocused(true);
        if (!m_sideStage)
            createSideStage();
        application->showWindow(m_sideStage);
        m_sideStage->setZ(-1000);
        if (m_mainStage)
            m_mainStage->setZ(-2000);
    }

    // move app to top of stack
    move(m_runningApplications.indexOf(application), 0);
    Q_EMIT focusedApplicationIdChanged();
    return true;
}

void ApplicationManager::unfocusCurrentApplication()
{
    for (ApplicationInfo *app : m_runningApplications) {
        if (app->focused()) {
            app->hideWindow();
            app->setFocused(false);
        }
    }
    Q_EMIT focusedApplicationIdChanged();
}

void ApplicationManager::generateQmlStrings(ApplicationInfo *application)
{
    // TODO: Is there a better way of solving this fullscreen vs. regular
    //       application height?
    QString topMargin;
    if (application->fullscreen()) {
        topMargin.append("0");
    } else {
        // Taken from Panel.panelHeight
        topMargin.append("units.gu(3) + units.dp(2)");
    }

    QString windowQml = QString(
        "import QtQuick 2.0\n"
        "Image {\n"
        "   anchors.fill: parent\n"
        "   anchors.topMargin: %1\n"
        "   source: \"file://%2/Dash/graphics/phone/screenshots/%3.png\"\n"
        "   smooth: true\n"
        "   fillMode: Image.PreserveAspectCrop\n"
        "}").arg(topMargin)
            .arg(shellAppDirectory())
            .arg(application->icon().toString());
    application->setWindowQml(windowQml);

    QString imageQml = QString(
        "import QtQuick 2.0\n"
        "Image {\n"
        "   anchors.fill: parent\n"
        "   source: \"file://%1/Dash/graphics/phone/screenshots/%2.png\"\n"
        "   smooth: true\n"
        "   fillMode: Image.PreserveAspectCrop\n"
        "}").arg(shellAppDirectory())
            .arg(application->icon().toString());
    application->setImageQml(imageQml);
}

void ApplicationManager::buildListOfAvailableApplications()
{
    ApplicationInfo *application;

    application = new ApplicationInfo(this);
    application->setAppId("phone-app");
    application->setName("Phone");
    application->setIcon(QUrl("phone"));
    application->setStage(ApplicationInfo::SideStage);
    generateQmlStrings(application);
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("camera-app");
    application->setName("Camera");
    application->setIcon(QUrl("camera"));
    application->setFullscreen(true);
    generateQmlStrings(application);
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("gallery-app");
    application->setName("Gallery");
    application->setIcon(QUrl("gallery"));
    generateQmlStrings(application);
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("facebook-webapp");
    application->setName("Facebook");
    application->setIcon(QUrl("facebook"));
    application->setStage(ApplicationInfo::SideStage);
    generateQmlStrings(application);
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("webbrowser-app");
    application->setName("Browser");
    application->setIcon(QUrl("browser"));
    generateQmlStrings(application);
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("twitter-webapp");
    application->setName("Twitter");
    application->setIcon(QUrl("twitter"));
    application->setStage(ApplicationInfo::SideStage);
    generateQmlStrings(application);
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("gmail-webapp");
    application->setName("GMail");
    application->setIcon(QUrl("gmail"));
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("ubuntu-weather-app");
    application->setName("Weather");
    application->setIcon(QUrl("weather"));
    application->setStage(ApplicationInfo::SideStage);
    generateQmlStrings(application);
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("notes-app");
    application->setName("Notepad");
    application->setIcon(QUrl("notepad"));
    application->setStage(ApplicationInfo::SideStage);
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("calendar-app");
    application->setName("Calendar");
    application->setIcon(QUrl("calendar"));
    application->setStage(ApplicationInfo::SideStage);
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("mediaplayer-app");
    application->setName("Media Player");
    application->setIcon(QUrl("mediaplayer-app"));
    application->setFullscreen(true);
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("evernote");
    application->setName("Evernote");
    application->setIcon(QUrl("evernote"));
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("map");
    application->setName("Map");
    application->setIcon(QUrl("map"));
    generateQmlStrings(application);
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("pinterest");
    application->setName("Pinterest");
    application->setIcon(QUrl("pinterest"));
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("soundcloud");
    application->setName("SoundCloud");
    application->setIcon(QUrl("soundcloud"));
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("wikipedia");
    application->setName("Wikipedia");
    application->setIcon(QUrl("wikipedia"));
    m_availableApplications.append(application);

    application = new ApplicationInfo(this);
    application->setAppId("youtube");
    application->setName("YouTube");
    application->setIcon(QUrl("youtube"));
    m_availableApplications.append(application);
}

void ApplicationManager::createMainStageComponent()
{
    // The assumptions I make here really should hold.
    QQuickView *quickView =
        qobject_cast<QQuickView*>(QGuiApplication::topLevelWindows()[0]);

    QQmlEngine *engine = quickView->engine();

    m_mainStageComponent = new QQmlComponent(engine, this);
    QString mainStageQml =
        "import QtQuick 2.0\n"
        "Rectangle {\n"
        "   anchors.fill: parent\n"
        "   color: 'black'\n"
        "   z: -2000\n"
        "}\n";
    m_mainStageComponent->setData(mainStageQml.toLatin1(), QUrl());
}

void ApplicationManager::createMainStage()
{
    if (!m_mainStageComponent)
        createMainStageComponent();

    // The assumptions I make here really should hold.
    QQuickView *quickView =
        qobject_cast<QQuickView*>(QGuiApplication::topLevelWindows()[0]);

    QQuickItem *shell = quickView->rootObject();

    m_mainStage = qobject_cast<QQuickItem *>(m_mainStageComponent->create());
    m_mainStage->setParentItem(shell);
}

void ApplicationManager::createSideStageComponent()
{
    // The assumptions I make here really should hold.
    QQuickView *quickView =
        qobject_cast<QQuickView*>(QGuiApplication::topLevelWindows()[0]);

    QQmlEngine *engine = quickView->engine();

    m_sideStageComponent = new QQmlComponent(engine, this);
    QString sideStageQml =
        "import QtQuick 2.0\n"
        "import Ubuntu.Components 0.1\n"
        "Item {\n"
        "   width: units.gu(40)\n" // from SideStage in Shell.qml
        "   anchors.top: parent.top\n"
        "   anchors.bottom: parent.bottom\n"
        "   anchors.right: parent.right\n"
        "   z: -1000\n"
        "}\n";
    m_sideStageComponent->setData(sideStageQml.toLatin1(), QUrl());
}

void ApplicationManager::createSideStage()
{
    if (!m_sideStageComponent)
        createSideStageComponent();

    // The assumptions I make here really should hold.
    QQuickView *quickView =
        qobject_cast<QQuickView*>(QGuiApplication::topLevelWindows()[0]);

    QQuickItem *shell = quickView->rootObject();

    m_sideStage = qobject_cast<QQuickItem *>(m_sideStageComponent->create());
    m_sideStage->setParentItem(shell);
    m_sideStage->setFlag(QQuickItem::ItemHasContents, false);
}
