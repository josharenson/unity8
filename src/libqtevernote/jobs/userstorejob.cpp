/*
 * Copyright: 2013 Canonical, Ltd
 *
 * This file is part of reminders
 *
 * reminders is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Michael Zanetti <michael.zanetti@canonical.com>
 */

#include "userstorejob.h"

#include "evernoteconnection.h"

UserStoreJob::UserStoreJob(QObject *parent) :
    EvernoteJob(parent)
{
}

void UserStoreJob::resetConnection()
{
    EvernoteConnection::instance()->setupUserStore();
    EvernoteConnection::instance()->connectUserStore();
}

evernote::edam::UserStoreClient *UserStoreJob::client() const
{
    return EvernoteConnection::instance()->m_userstoreClient;
}
