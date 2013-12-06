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
 */

#include "Greeter.h"

#include <QDBusInterface>
#include <QDBusReply>
#include <QSignalSpy>
#include <QQuickItem>
#include <QQuickView>
#include <QtTestGui>

class GreeterDBusTest : public QObject
{
    Q_OBJECT

Q_SIGNALS:
    void PropertiesChangedRelay(const QString &interface, const QVariantMap &changed, const QStringList &invalidated);

private Q_SLOTS:

    void initTestCase()
    {
        // Qt doesn't like us connecting to PropertiesChanged using normal
        // SIGNAL method, because QtDBus doesn't know about PropertiesChanged.
        // So we connect the hard way for the benefit of any tests that want
        // to watch.
        QDBusConnection::sessionBus().connect(
            "com.canonical.UnityGreeter",
            "/list",
            "org.freedesktop.DBus.Properties",
            "PropertiesChanged",
            this,
            SIGNAL(PropertiesChangedRelay(const QString&, const QVariantMap&, const QStringList&)));
    }

    void init()
    {
        view = new QQuickView();
        view->setSource(QUrl::fromLocalFile(CURRENT_SOURCE_DIR "/greeter.qml"));
        greeter = dynamic_cast<Greeter*>(view->rootObject()->property("greeter").value<QObject*>());
        QVERIFY(greeter);
        QVERIFY(greeter->authenticationUser() == "");
        view->show();
        QTest::qWaitForWindowExposed(view);

        dbusList = new QDBusInterface("com.canonical.UnityGreeter",
                                      "/list",
                                      "com.canonical.UnityGreeter.List",
                                      QDBusConnection::sessionBus(), view);
        QVERIFY(dbusList->isValid());
    }

    void cleanup()
    {
        delete view;
    }

    void testGetActiveEntry()
    {
        greeter->authenticate("has-password");

        QDBusReply<QString> reply = dbusList->call("GetActiveEntry");
        QVERIFY(reply.isValid());
        QVERIFY(reply.value() == "has-password");
    }

    void testSetActiveEntry()
    {
        QSignalSpy spy(greeter, SIGNAL(requestAuthenticationUser(QString)));
        QDBusReply<void> reply = dbusList->call("SetActiveEntry", "has-password");
        QVERIFY(reply.isValid());
        spy.wait();

        QCOMPARE(spy.count(), 1);
        QList<QVariant> arguments = spy.takeFirst();
        QVERIFY(arguments.at(0).toString() == "has-password");
    }

    void testEntrySelectedSignal()
    {
        QSignalSpy spy(dbusList, SIGNAL(EntrySelected(QString)));
        greeter->authenticate("has-password");
        spy.wait();

        QCOMPARE(spy.count(), 1);
        QList<QVariant> arguments = spy.takeFirst();
        QVERIFY(arguments.at(0).toString() == "has-password");
    }

    void testActiveEntryGet()
    {
        greeter->authenticate("has-password");
        QVERIFY(dbusList->property("ActiveEntry").toString() == "has-password");
    }

    void testActiveEntrySet()
    {
        QSignalSpy spy(greeter, SIGNAL(requestAuthenticationUser(QString)));
        QVERIFY(dbusList->setProperty("ActiveEntry", "has-password"));
        spy.wait();

        QCOMPARE(spy.count(), 1);
        QList<QVariant> arguments = spy.takeFirst();
        QVERIFY(arguments.at(0).toString() == "has-password");
    }

    void testActiveEntryChanged()
    {
        QSignalSpy spy(this, SIGNAL(PropertiesChangedRelay(QString, QVariantMap, QStringList)));
        greeter->authenticate("has-password");
        spy.wait();

        QCOMPARE(spy.count(), 1);
        QList<QVariant> arguments = spy.takeFirst();
        QVERIFY(arguments.at(0).toString() == "com.canonical.UnityGreeter.List");
        QVERIFY(arguments.at(1).toMap().contains("ActiveEntry"));
        QVERIFY(arguments.at(1).toMap()["ActiveEntry"] == "has-password");
    }

    void testEntryIsLockedGet()
    {
        QVERIFY(dbusList->property("EntryIsLocked").toBool());

        greeter->authenticate("no-password");
        QVERIFY(!dbusList->property("EntryIsLocked").toBool());

        greeter->authenticate("has-password");
        QVERIFY(dbusList->property("EntryIsLocked").toBool());
    }

    void testEntryIsLockedChanged()
    {
        QSignalSpy spy(this, SIGNAL(PropertiesChangedRelay(QString, QVariantMap, QStringList)));
        greeter->authenticate("no-password");
        spy.wait();

        QCOMPARE(spy.count(), 2); // once for locked, once for user; first will be locked mode
        QList<QVariant> arguments = spy.takeFirst();
        QVERIFY(arguments.at(0).toString() == "com.canonical.UnityGreeter.List");
        QVERIFY(arguments.at(1).toMap().contains("EntryIsLocked"));
        QVERIFY(arguments.at(1).toMap()["EntryIsLocked"] == false);
    }

private:
    QQuickView *view;
    Greeter *greeter;
    QDBusInterface *dbusList;
};

QTEST_MAIN(GreeterDBusTest)

#include "dbus.moc"
