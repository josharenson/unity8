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

#include <QObject>
#include <QVariantMap>
#include <QRect>

// unity-api
#include <unity/shell/application/Mir.h>

class WindowStateStorage: public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap geometry READ geometry WRITE setGeometry NOTIFY geometryChanged)
public:
    enum WindowState {
        WindowStateNormal = 1 << 0,
        WindowStateMaximized = 1 << 1,
        WindowStateMinimized = 1 << 2,
        WindowStateFullscreen = 1 << 3,
        WindowStateMaximizedLeft = 1 << 4,
        WindowStateMaximizedRight = 1 << 5,
        WindowStateMaximizedHorizontally = 1 << 6,
        WindowStateMaximizedVertically = 1 << 7,
        WindowStateMaximizedTopLeft = 1 << 8,
        WindowStateMaximizedTopRight = 1 << 9,
        WindowStateMaximizedBottomLeft = 1 << 10,
        WindowStateMaximizedBottomRight = 1 << 11,
        WindowStateRestored = 1 << 12
    };
    Q_ENUM(WindowState)
    Q_DECLARE_FLAGS(WindowStates, WindowState)
    Q_FLAG(WindowStates)

    WindowStateStorage(QObject *parent = 0);

    Q_INVOKABLE void saveState(const QString &windowId, WindowState state);
    Q_INVOKABLE WindowState getState(const QString &windowId, WindowState defaultValue) const;

    Q_INVOKABLE void saveGeometry(const QString &windowId, const QRect &rect);
    Q_INVOKABLE QRect getGeometry(const QString &windowId, const QRect &defaultValue) const;

    Q_INVOKABLE void saveStage(const QString &appId, int stage);
    Q_INVOKABLE int getStage(const QString &appId, int defaultValue) const;

    // Only in the mock, to easily restore a fresh state
    Q_INVOKABLE void clear();

    Q_INVOKABLE Mir::State toMirState(WindowState state) const;

Q_SIGNALS:
    void geometryChanged(const QVariantMap& geometry);

    // For testing.
    void stageSaved(const QString& appId, int stage);

private:
    void setGeometry(const QVariantMap& geometry);
    QVariantMap geometry() const;

    QHash<QString, WindowState> m_state;
    QHash<QString, int> m_stage;
    QVariantMap m_geometry;
};
