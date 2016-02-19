/*
 * This file was generated by qdbusxml2cpp version 0.8
 * Command line was: qdbusxml2cpp -a inputprovideradaptor -c InputProviderAdaptor org.aethercast.xml org.aethercast.InputProvider
 *
 * qdbusxml2cpp is Copyright (C) 2015 The Qt Company Ltd.
 *
 * This is an auto-generated file.
 * Do not edit! All changes made to it will be lost.
 */

#include "inputprovideradaptor.h"
#include <QtCore/QMetaObject>
#include <QtCore/QByteArray>
#include <QtCore/QList>
#include <QtCore/QMap>
#include <QtCore/QString>
#include <QtCore/QStringList>
#include <QtCore/QVariant>

/*
 * Implementation of adaptor class InputProviderAdaptor
 */

InputProviderAdaptor::InputProviderAdaptor(QObject *parent)
    : QDBusAbstractAdaptor(parent)
{
    // constructor
    setAutoRelaySignals(true);
}

InputProviderAdaptor::~InputProviderAdaptor()
{
    // destructor
}

QString InputProviderAdaptor::cursor() const
{
    // get the value of property cursor
    return qvariant_cast< QString >(parent()->property("cursor"));
}

void InputProviderAdaptor::NewConnection(const QDBusUnixFileDescriptor &fd, const QVariantMap &options)
{
    // handle method call org.aethercast.InputProvider.NewConnection
    QMetaObject::invokeMethod(parent(), "NewConnection", Q_ARG(QDBusUnixFileDescriptor, fd), Q_ARG(QVariantMap, options));
}

void InputProviderAdaptor::RequestDisconnection()
{
    // handle method call org.aethercast.InputProvider.RequestDisconnection
    QMetaObject::invokeMethod(parent(), "RequestDisconnection");
}
