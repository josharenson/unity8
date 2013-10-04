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
 * Authors:
 *  Michal Hruby <michal.hruby@canonical.com>
 */

#include <QTest>
#include <dee.h>

#include "resultstest.h"
#include "categoryresults.h"

static DeeModel* createBackendModel()
{
    auto model = dee_sequence_model_new();
    dee_model_set_schema(model, "s", "s", "u", "u", "s", "s", "s", "s", "a{sv}", NULL);

    return model;
}

void ResultsTest::testAllColumns()
{
    auto deeModel = createBackendModel();
    GVariantBuilder builder;
    g_variant_builder_init(&builder, G_VARIANT_TYPE_VARDICT);
    g_variant_builder_add(&builder, "{sv}", "metadata-field", g_variant_new_string("foo"));
    dee_model_append (deeModel,
                      "test:uri",
                      "themed-icon",
                      4,
                      0,
                      "application/octet-stream",
                      "Test",
                      "Comment",
                      "test:dnd-uri",
                      g_variant_builder_end(&builder));

    CategoryResults* results = new CategoryResults(this);
    results->setModel(deeModel);

    auto index = results->index(0, 0); // there's just one result
    QCOMPARE(index.data(CategoryResults::Roles::RoleUri).toString(), QString("test:uri"));
    QCOMPARE(index.data(CategoryResults::Roles::RoleIconHint).toString(), QString("image://theme/themed-icon"));
    QCOMPARE(index.data(CategoryResults::Roles::RoleCategory).toInt(), 4);
    QCOMPARE(index.data(CategoryResults::Roles::RoleMimetype).toString(), QString("application/octet-stream"));
    QCOMPARE(index.data(CategoryResults::Roles::RoleTitle).toString(), QString("Test"));
    QCOMPARE(index.data(CategoryResults::Roles::RoleComment).toString(), QString("Comment"));
    QCOMPARE(index.data(CategoryResults::Roles::RoleDndUri).toString(), QString("test:dnd-uri"));
    auto metadata = index.data(CategoryResults::Roles::RoleMetadata).toHash();
    QCOMPARE(metadata["metadata-field"].toString(), QString("foo"));
}

void ResultsTest::testIconColumn_data()
{
    QTest::addColumn<QString>("uri");
    QTest::addColumn<QString>("giconString");
    QTest::addColumn<QString>("result");

    QTest::newRow("unspecified") << "test:uri" << "" << "";
    QTest::newRow("absolute path") << "test:uri" << "/usr/share/icons/example.png" << "/usr/share/icons/example.png";
    QTest::newRow("file uri") << "test:uri" << "file:///usr/share/icons/example.png" << "file:///usr/share/icons/example.png";
    QTest::newRow("http uri") << "test:uri" << "http://images.ubuntu.com/example.jpg" << "http://images.ubuntu.com/example.jpg";
    QTest::newRow("image uri") << "test:uri" << "image://thumbnail/with/arguments?passed_to=ImageProvider" << "image://thumbnail/with/arguments?passed_to=ImageProvider";
    QTest::newRow("themed icon") << "test:uri" << "accessories-other" << "image://theme/accessories-other";
    QTest::newRow("fileicon") << "test:uri" << ". GFileIcon http://example.org/resource.gif" << "http://example.org/resource.gif";
    QTest::newRow("themedicon") << "test:uri" << ". GThemedIcon accessories-other accessories generic" << "image://theme/accessories-other,accessories,generic";
    QTest::newRow("annotatedicon") << "test:uri" << ". UnityProtocolAnnotatedIcon %7B'base-icon':%20%3C'.%20GThemedIcon%20accessories-other%20accessories%20generic'%3E%7D" << "image://theme/accessories-other,accessories,generic";
    QTest::newRow("thumbnailer icon") << "file:///usr/share/samples/video/foo.avi" << "" << "image://thumbnailer//usr/share/samples/video/foo.avi";
}

void ResultsTest::testIconColumn()
{
    QFETCH(QString, uri);
    QFETCH(QString, giconString);
    QFETCH(QString, result);
    auto deeModel = createBackendModel();
    dee_model_append (deeModel,
                      uri.toLocal8Bit().constData(),
                      giconString.toLocal8Bit().constData(),
                      0,
                      0,
                      "application/octet-stream",
                      "Test",
                      "",
                      "test:dnd-uri",
                      g_variant_new_array(g_variant_type_element(G_VARIANT_TYPE_VARDICT), NULL, 0));

    CategoryResults* results = new CategoryResults(this);
    results->setModel(deeModel);

    auto index = results->index(0, 0); // there's just one result
    auto transformedIcon = index.data(CategoryResults::Roles::RoleIconHint).toString();
    QCOMPARE(transformedIcon, result);
}

QTEST_MAIN(ResultsTest)
