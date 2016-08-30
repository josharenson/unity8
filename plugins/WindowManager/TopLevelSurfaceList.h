/*
 * Copyright (C) 2016 Canonical, Ltd.
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

#ifndef TOPLEVELSURFACELIST_H
#define TOPLEVELSURFACELIST_H

#include <QAbstractListModel>
#include <QList>
#include <QLoggingCategory>

Q_DECLARE_LOGGING_CATEGORY(UNITY_TOPSURFACELIST)

namespace unity {
    namespace shell {
        namespace application {
            class ApplicationInfoInterface;
            class ApplicationInstanceInterface;
            class MirSurfaceInterface;
        }
    }
}

/**
 * @brief A model of top-level surfaces
 *
 * It's an abstraction of top-level application windows.
 *
 * When an entry first appears, it normaly doesn't have a surface yet, meaning that the application is
 * still starting up. A shell should then display a splash screen or saved screenshot of the application
 * until its surface comes up.
 *
 * As applications can have multiple surfaces and you can also have entries without surfaces at all,
 * the only way to unambiguously refer to an entry in this model is through its id.
 */
class TopLevelSurfaceList : public QAbstractListModel
{

    Q_OBJECT

    /**
     * @brief A list model of application instances.
     *
     * It's expected to have a role called "applicationInstance" which returns an ApplicationInstanceInterface
     */
    Q_PROPERTY(QAbstractListModel* applicationInstancesModel READ applicationInstancesModel
                                                             WRITE setApplicationInstancesModel
                                                             NOTIFY applicationInstancesModelChanged)

    /**
     * @brief Number of top-level surfaces in this model
     *
     * This is the same as rowCount, added in order to keep compatibility with QML ListModels.
     */
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

    /**
      The id to be used on the next entry created
      Useful for tests
     */
    Q_PROPERTY(int nextId READ nextId NOTIFY nextIdChanged)
public:

    /**
     * @brief The Roles supported by the model
     *
     * SurfaceRole - A MirSurfaceInterface. It will be null if the application is still starting up
     * ApplicationInstanceRole - An ApplicationInstanceInterface
     * IdRole - A unique identifier for this entry. Useful to unambiguosly track elements as they move around in the list
     */
    enum Roles {
        SurfaceRole = Qt::UserRole,
        ApplicationInstanceRole = Qt::UserRole + 1,
        ApplicationRole = Qt::UserRole + 2,
        IdRole = Qt::UserRole + 3,
    };

    explicit TopLevelSurfaceList(QObject *parent = nullptr);
    virtual ~TopLevelSurfaceList();

    // QAbstractItemModel methods
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int, QByteArray> roleNames() const override {
        QHash<int, QByteArray> roleNames { {SurfaceRole, "surface"},
                                           {ApplicationInstanceRole, "applicationInstance"},
                                           {ApplicationRole, "application"},
                                           {IdRole, "id"} };
        return roleNames;
    }

    int nextId() const { return m_nextId; }

    QAbstractListModel *applicationInstancesModel() const;
    void setApplicationInstancesModel(QAbstractListModel*);

public Q_SLOTS:
    /**
     * @brief Returns the surface at the given index
     *
     * It will be a nullptr if the application is still starting up and thus hasn't yet created
     * and drawn into a surface.
     */
    unity::shell::application::MirSurfaceInterface *surfaceAt(int index) const;

    /**
     * @brief Returns the application at the given index
     */
    unity::shell::application::ApplicationInfoInterface *applicationAt(int index) const;

    /**
     * @brief Returns the unique id of the element at the given index
     */
    int idAt(int index) const;

    /**
     * @brief Returns the index where the row with the given id is located
     *
     * Returns -1 if there's no row with the given id.
     */
    int indexForId(int id) const;

    /**
     * @brief Raises the row with the given id to index 0
     */
    void raiseId(int id);

    void doRaiseId(int id);

Q_SIGNALS:
    void countChanged();

    /**
     * @brief Emitted when the list changes
     *
     * Emitted when model gains an element, loses an element or when elements exchange positions.
     */
    void listChanged();

    void nextIdChanged();

    void applicationInstancesModelChanged();

private:
    void addAppInstance(unity::shell::application::ApplicationInstanceInterface *appInstance);
    void removeAppInstance(unity::shell::application::ApplicationInstanceInterface *appInstance);

    int indexOf(unity::shell::application::MirSurfaceInterface *surface);
    void raise(unity::shell::application::MirSurfaceInterface *surface);
    void move(int from, int to);
    void appendSurfaceHelper(unity::shell::application::MirSurfaceInterface *surface,
                             unity::shell::application::ApplicationInstanceInterface *appInstance);
    void connectSurface(unity::shell::application::MirSurfaceInterface *surface);
    int generateId();
    int nextFreeId(int candidateId);
    QString toString();
    void onSurfaceDestroyed(unity::shell::application::MirSurfaceInterface *surface);
    void onSurfaceDied(unity::shell::application::MirSurfaceInterface *surface);
    void removeAt(int index);
    void findAppInstanceRole();

    unity::shell::application::ApplicationInstanceInterface *getAppInstanceFromModelAt(int index);

    /*
        Placeholder for a future surface from a starting or running application instance.
        Enables shell to give immediate feedback to the user by showing, eg,
        a splash screen.

        It's a model row containing a null surface and the given application instance.
     */
    void appendPlaceholder(unity::shell::application::ApplicationInstanceInterface *applicationInstance);

    /*
        Adds a model row with the given surface and application

        Alternatively, if a placeholder exists for the given application it's
        filled with the given surface instead.
     */
    void appendSurface(unity::shell::application::MirSurfaceInterface *surface,
            unity::shell::application::ApplicationInstanceInterface *appInstance);

    struct ModelEntry {
        ModelEntry(unity::shell::application::MirSurfaceInterface *surface,
                   unity::shell::application::ApplicationInstanceInterface *appInstance,
                   int id)
            : surface(surface), appInstance(appInstance), id(id) {}
        unity::shell::application::MirSurfaceInterface *surface;
        unity::shell::application::ApplicationInstanceInterface *appInstance;
        int id;
        bool removeOnceSurfaceDestroyed{false};
    };

    QList<ModelEntry> m_surfaceList;
    int m_nextId{1};
    static const int m_maxId{1000000};

    // applications that are being monitored
    QList<unity::shell::application::ApplicationInstanceInterface *> m_appInstances;

    QAbstractListModel* m_appInstancesModel{nullptr};
    int m_appInstanceRole{-1};

    enum ModelState {
        IdleState,
        InsertingState,
        RemovingState,
        MovingState,
        ResettingState
    };
    ModelState m_modelState{IdleState};
};

Q_DECLARE_METATYPE(TopLevelSurfaceList*)
//Q_DECLARE_METATYPE(QAbstractListModel*)

#endif // TOPLEVELSURFACELIST_H
