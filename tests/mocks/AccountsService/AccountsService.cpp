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
 *
 * Author: Michael Terry <michael.terry@canonical.com>
 */

#include "AccountsService.h"

AccountsService::AccountsService(QObject* parent)
  : QObject(parent)
{
}

QString AccountsService::getUser()
{
    return "testuser";
}

void AccountsService::setUser(const QString &user)
{
    Q_UNUSED(user)
}

bool AccountsService::getDemoEdges()
{
    return false;
}

void AccountsService::setDemoEdges(bool demoEdges)
{
    Q_UNUSED(demoEdges)
}

QString AccountsService::getBackgroundFile()
{
    return TOP_SRCDIR "/graphics/phone_background.jpg";
}
