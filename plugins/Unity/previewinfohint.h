/*
 * Copyright (C) 2013 Canonical, Ltd.
 *
 * Authors:
 *  Pawel Stolowski <pawel.stolowski@canonical.com>
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

#ifndef PREVIEWINFOHINT_H
#define PREVIEWINFOHINT_H

// Qt
#include <QObject>
#include <QString>
#include <QVariant>

// libunity-core
#include <UnityCore/Preview.h>

class PreviewInfoHint : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString id READ id NOTIFY previewInfoHintChanged)
    Q_PROPERTY(QString displayName READ displayName NOTIFY previewInfoHintChanged)
    Q_PROPERTY(QString iconHint READ iconHint NOTIFY previewInfoHintChanged)
    Q_PROPERTY(QVariant value READ value NOTIFY previewInfoHintChanged)

public:
    explicit PreviewInfoHint(QObject *parent = 0);
    void setUnityInfoHint(unity::dash::Preview::InfoHintPtr unityInfoHint);

    QString id() const;
    QString displayName() const;
    QString iconHint() const;
    QVariant value() const;

Q_SIGNALS:
    void previewInfoHintChanged();

private:
    unity::dash::Preview::InfoHintPtr m_unityInfoHint;
};

Q_DECLARE_METATYPE(PreviewInfoHint *)

#endif
