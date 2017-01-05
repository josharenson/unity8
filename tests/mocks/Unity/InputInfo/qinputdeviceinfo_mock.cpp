/*
 * Copyright 2015 Canonical Ltd.
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
 */

#include "qinputdeviceinfo_mock_p.h"

#include <QTimer>
#include <QDebug>

QInputDeviceManagerPrivate::QInputDeviceManagerPrivate(QObject *parent) :
    QObject(parent),
    currentFilter(QInputDevice::Unknown)
{
    QTimer::singleShot(1, this, SIGNAL(ready()));
}

QInputDeviceManagerPrivate::~QInputDeviceManagerPrivate()
{
}

QInputDevice *QInputDeviceManagerPrivate::addMockDevice(const QString &devicePath, QInputDevice::InputType type)
{
    QInputDevice *inputDevice = new QInputDevice(this);
    inputDevice->setDevicePath(devicePath);
    inputDevice->setName("Mock Device " + devicePath);
    inputDevice->setType(type);
    deviceMap.insert(devicePath, inputDevice);
    Q_EMIT deviceAdded(devicePath);
    return inputDevice;
}

void QInputDeviceManagerPrivate::removeDevice(const QString &path)
{
    auto it = deviceMap.begin();
    while (it != deviceMap.end()) {
        const QString devicePath = it.key();
        if (devicePath.contains(path)) {
            it = deviceMap.erase(it);
            Q_EMIT deviceRemoved(devicePath);
        } else {
            ++it;
        }
    }
}
