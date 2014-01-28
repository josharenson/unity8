/*
 * Copyright (C) 2013 Canonical, Ltd.
 *
 * Authors:
 *  Michal Hruby <michal.hruby@canonical.com>
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

// Qt
#include <QtGlobal>
#include <QDir>

// local
#include "registry-tracker.h"


RegistryTracker::RegistryTracker(QString const& scope_dir):
    m_scopeDir(scope_dir),
    m_registry(nullptr),
    m_endpoints_dir(QDir::temp().filePath("scope-dev-endpoints.XXXXXX"))
{
    runRegistry();
}

RegistryTracker::~RegistryTracker()
{
    if (m_registry.state() != QProcess::NotRunning) {
        m_registry.terminate();
        m_registry.waitForFinished(5000);
        m_registry.kill();
    }
}

#define RUNTIME_CONFIG \
"[Runtime]\n" \
"Registry.Identity = Registry\n" \
"Registry.ConfigFile = %1\n" \
"Default.Middleware = Zmq\n" \
"Zmq.ConfigFile = %2\n"

#define REGISTRY_CONFIG \
"[Registry]\n" \
"Middleware = Zmq\n" \
"Zmq.Endpoint = ipc://%1/Registry\n" \
"Zmq.EndpointDir = %2\n" \
"Zmq.ConfigFile = %3\n" \
"Scope.InstallDir = %4\n" \
"Scoperunner.Path = %5\n"

#define MW_CONFIG \
"[Zmq]\n" \
"EndpointDir.Public = %1\n" \
"EndpointDir.Private = %2\n"

void RegistryTracker::runRegistry()
{
    QDir tmp(QDir::temp());
    m_runtime_config.setFileTemplate(tmp.filePath("Runtime.ini.XXXXXX"));
    m_registry_config.setFileTemplate(tmp.filePath("Registry.ini.XXXXXX"));
    m_mw_config.setFileTemplate(tmp.filePath("Zmq.ini.XXXXXX"));

    if (!m_runtime_config.open() || !m_registry_config.open() || !m_mw_config.open() || !m_endpoints_dir.isValid()) {
        qWarning("Unable to open temporary files!");
        return;
    }

    QString scopesLibdir;
    {
        QProcess pkg_config;
        QStringList arguments;
        arguments << "--variable=libdir";
        arguments << "libunity-scopes";
        pkg_config.start("pkg-config", arguments);
        pkg_config.waitForFinished();
        QByteArray libdir = pkg_config.readAllStandardOutput();
        scopesLibdir = QDir(QString::fromLocal8Bit(libdir)).path().trimmed();
    }

    if (scopesLibdir.size() == 0) {
        qWarning("Unable to find libunity-scopes package config file");
        return;
    }

    QString scopeRunnerPath = QDir(scopesLibdir).filePath("scoperunner/scoperunner");

    QString runtime_ini = QString(RUNTIME_CONFIG).arg(m_registry_config.fileName()).arg(m_mw_config.fileName());
    QString registry_ini = QString(REGISTRY_CONFIG).arg(m_endpoints_dir.path()).arg(m_endpoints_dir.path()).arg(m_mw_config.fileName()).arg(m_scopeDir).arg(scopeRunnerPath);
    QString mw_ini = QString(MW_CONFIG).arg(m_endpoints_dir.path()).arg(m_endpoints_dir.path());

    m_runtime_config.write(runtime_ini.toUtf8());
    m_registry_config.write(registry_ini.toUtf8());
    m_mw_config.write(mw_ini.toUtf8());

    m_runtime_config.flush();
    m_registry_config.flush();
    m_mw_config.flush();

    qputenv("UNITY_SCOPES_RUNTIME_PATH", m_runtime_config.fileName().toLocal8Bit());

    QString registryBin(QDir(scopesLibdir).filePath("scoperegistry/scoperegistry"));
    QStringList arguments;
    arguments << m_runtime_config.fileName();

    m_registry.start(registryBin, arguments);
}
