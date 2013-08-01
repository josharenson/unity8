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

#ifndef APPLICATION_H
#define APPLICATION_H

#include <QObject>
#include <QQmlComponent>

class QQuickItem;

// A pretty dumb file. Just a container for properties.
// Implemented in C++ instead of QML just because of the enumerations
// See QTBUG-14861
class ApplicationInfo : public QObject {
    Q_OBJECT
    Q_ENUMS(Stage)
    Q_ENUMS(State)
    Q_PROPERTY(QString desktopFile READ desktopFile WRITE setDesktopFile NOTIFY desktopFileChanged)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QString comment READ comment WRITE setComment NOTIFY commentChanged)
    Q_PROPERTY(QString icon READ icon WRITE setIcon NOTIFY iconChanged)
    Q_PROPERTY(QString exec READ exec WRITE setExec NOTIFY execChanged)
    Q_PROPERTY(qint64 handle READ handle WRITE setHandle NOTIFY handleChanged)
    Q_PROPERTY(Stage stage READ stage WRITE setStage NOTIFY stageChanged)
    Q_PROPERTY(State state READ state WRITE setState NOTIFY stateChanged)
    Q_PROPERTY(bool fullscreen READ fullscreen WRITE setFullscreen NOTIFY fullscreenChanged)

    // Only exists in this fake implementation

    // QML component used to represent its image/screenhot
    Q_PROPERTY(QString imageQml READ imageQml WRITE setImageQml NOTIFY imageQmlChanged)

    // QML component used to represent the application window
    Q_PROPERTY(QString windowQml READ windowQml WRITE setWindowQml NOTIFY windowQmlChanged)

 public:
    enum Stage { MainStage, SideStage };
    enum State { Starting, Running };

    ApplicationInfo(QObject *parent = NULL);

    #define IMPLEMENT_PROPERTY(name, Name, type) \
    public: \
    type name() const { return m_##name; } \
    void set##Name(const type& value) \
    { \
        if (m_##name != value) { \
            m_##name = value; \
            Q_EMIT name##Changed(); \
        } \
    } \
    Q_SIGNALS: \
    void name##Changed(); \
    private: \
    type m_##name;

    IMPLEMENT_PROPERTY(desktopFile, DesktopFile, QString)
    IMPLEMENT_PROPERTY(name, Name, QString)
    IMPLEMENT_PROPERTY(comment, Comment, QString)
    IMPLEMENT_PROPERTY(icon, Icon, QString)
    IMPLEMENT_PROPERTY(exec, Exec, QString)
    IMPLEMENT_PROPERTY(handle, Handle, qint64)
    IMPLEMENT_PROPERTY(stage, Stage, Stage)
    IMPLEMENT_PROPERTY(state, State, State)
    IMPLEMENT_PROPERTY(fullscreen, Fullscreen, bool)
    IMPLEMENT_PROPERTY(imageQml, ImageQml, QString)
    IMPLEMENT_PROPERTY(windowQml, WindowQml, QString)

    #undef IMPLEMENT_PROPERTY

 public:
    void showWindow(QQuickItem *parent);
    void hideWindow();

 private Q_SLOTS:
    void onWindowComponentStatusChanged(QQmlComponent::Status status);

 private:
    void createWindowItem();
    void doCreateWindowItem();
    void createWindowComponent();
    QQuickItem *m_windowItem;
    QQmlComponent *m_windowComponent;
    QQuickItem *m_parentItem;
};

Q_DECLARE_METATYPE(ApplicationInfo*)

#endif  // APPLICATION_H
