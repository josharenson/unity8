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

#include "SurfaceManager.h"

#include "VirtualKeyboard.h"

#include <paths.h>

SurfaceManager *SurfaceManager::the_surface_manager = nullptr;

SurfaceManager *SurfaceManager::singleton()
{
    if (!the_surface_manager) {
        the_surface_manager = new SurfaceManager();
    }
    return the_surface_manager;
}

SurfaceManager::SurfaceManager(QObject *parent) :
    QObject(parent)
    , m_virtualKeyboard(nullptr)
{
}

MirSurfaceItem *SurfaceManager::createSurface(const QString& name,
                                              MirSurfaceItem::Type type,
                                              MirSurfaceItem::State state,
                                              const QUrl& screenshot)
{
    MirSurfaceItem* surface = new MirSurfaceItem(name, type, state, screenshot);
    Q_EMIT surfaceCreated(surface);
    return surface;
}

void SurfaceManager::registerSurface(MirSurfaceItem *surface)
{
    connect(surface, &MirSurfaceItem::deregister, this, [this] {
        MirSurfaceItem* surface = qobject_cast<MirSurfaceItem*>(sender());
        disconnect(surface, 0, this, 0);

        surface->setLive(false);
        Q_EMIT surfaceDestroyed(surface);
    });
}

MirSurfaceItem *SurfaceManager::inputMethodSurface()
{
    if (!m_virtualKeyboard) {
        m_virtualKeyboard = new VirtualKeyboard;
        Q_EMIT surfaceCreated(m_virtualKeyboard);
    }
    return m_virtualKeyboard;
}
