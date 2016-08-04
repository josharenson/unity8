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
 *
 */

#include "MockGreeter.h"
#include <GreeterPrivate.h>

QString MockGreeter::mockMode() const
{
    Q_D(const Greeter);
    return d->m_greeter->mockMode();
}

void MockGreeter::setMockMode(QString mockMode)
{
    Q_D(Greeter);

    if (d->m_greeter->mockMode() != mockMode) {
        d->m_greeter->setMockMode(mockMode);
        Q_EMIT mockModeChanged(mockMode);
    }
}

QString MockGreeter::selectUserHint() const
{
    Q_D(const Greeter);
    return d->m_greeter->selectUserHint();
}

void MockGreeter::setSelectUserHint(const QString &selectUserHint)
{
    Q_D(Greeter);

    if (d->m_greeter->selectUserHint() != selectUserHint) {
        d->m_greeter->setSelectUserHint(selectUserHint);
        Q_EMIT selectUserHintChanged();
    }
}

bool MockGreeter::hasGuestAccount() const
{
    Q_D(const Greeter);
    return d->m_greeter->hasGuestAccountHint();
}

void MockGreeter::setHasGuestAccount(bool hasGuestAccount)
{
    Q_D(Greeter);

    if (d->m_greeter->hasGuestAccountHint() != hasGuestAccount) {
        d->m_greeter->setHasGuestAccountHint(hasGuestAccount);
        Q_EMIT hasGuestAccountChanged();
    }
}
