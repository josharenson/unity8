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

#ifndef VARIANTUTILS_H
#define VARIANTUTILS_H

#include <glib.h>
#include <QVariant>

// libunity-core
#include <UnityCore/Variant.h>

unity::glib::HintsMap convertToHintsMap(const QHash<QString, QVariant> &val);
unity::glib::HintsMap convertToHintsMap(const QVariant &var);
QVariantHash convertToQVariantHash(const unity::glib::HintsMap &var);
/* used in tests, so we have to export it */
Q_DECL_EXPORT QVariantHash subscopeUriToMetadataHash(const QString &metadata_string);

#endif
