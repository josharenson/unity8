/*
 * Copyright (C) 2011 Canonical, Ltd.
 *
 * Authors:
 *  Florian Boucault <florian.boucault@canonical.com>
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

// Self
#include "scope.h"

// local
#include "categories.h"
#include "preview.h"
#include "variantutils.h"

// Qt
#include <QUrl>
#include <QUrlQuery>
#include <QDebug>
#include <QtGui/QDesktopServices>
#include <QQmlEngine>

#include <UnityCore/Variant.h>
#include <UnityCore/GLibWrapper.h>

#include <libintl.h>
#include <glib.h>

Scope::Scope(QObject *parent) : QObject(parent)
    , m_formFactor("phone")
    , m_isActive(false)
    , m_searchInProgress(false)
{
    m_categories.reset(new Categories(this));

    connect(this, &Scope::isActiveChanged, this, &Scope::scopeIsActiveChanged);
}

QString Scope::id() const
{
    return QString::fromStdString(m_unityScope->id());
}

QString Scope::name() const
{
    return QString::fromStdString(m_unityScope->name());
}

QString Scope::iconHint() const
{
    return QString::fromStdString(m_unityScope->icon_hint());
}

QString Scope::description() const
{
    return QString::fromStdString(m_unityScope->description());
}

QString Scope::searchHint() const
{
    return QString::fromStdString(m_unityScope->search_hint());
}

bool Scope::searchInProgress() const
{
    return m_searchInProgress;
}

bool Scope::visible() const
{
    return m_unityScope->visible();
}

QString Scope::shortcut() const
{
    return QString::fromStdString(m_unityScope->shortcut());
}

bool Scope::connected() const
{
    return m_unityScope->connected();
}

Categories* Scope::categories() const
{
    return m_categories.get();
}

QString Scope::searchQuery() const
{
    return m_searchQuery;
}

QString Scope::noResultsHint() const
{
    return m_noResultsHint;
}

QString Scope::formFactor() const
{
    return m_formFactor;
}

bool Scope::isActive() const
{
    return m_isActive;
}

Filters* Scope::filters() const
{
    return m_filters.get();
}

void Scope::setSearchQuery(const QString& search_query)
{
    /* Checking for m_searchQuery.isNull() which returns true only when the string
       has never been set is necessary because when search_query is the empty
       string ("") and m_searchQuery is the null string,
       search_query != m_searchQuery is still true.
    */
    using namespace std::placeholders;

    if (m_searchQuery.isNull() || search_query != m_searchQuery) {
        m_searchQuery = search_query;
        m_cancellable.Renew();
        m_unityScope->Search(search_query.toStdString(), std::bind(&Scope::onSearchFinished, this, _1, _2, _3), m_cancellable);
        Q_EMIT searchQueryChanged();
        if (!m_searchInProgress) {
            m_searchInProgress = true;
            Q_EMIT searchInProgressChanged();
        }
    }
}

void Scope::setNoResultsHint(const QString& hint) {
    if (hint != m_noResultsHint) {
        m_noResultsHint = hint;
        Q_EMIT noResultsHintChanged();
    }
}

void Scope::setFormFactor(const QString& form_factor) {
    if (form_factor != m_formFactor) {
        m_formFactor = form_factor;
        if (m_unityScope) {
            m_unityScope->form_factor = m_formFactor.toStdString();
            synchronizeStates(); // will trigger a re-search
        }
        Q_EMIT formFactorChanged();
    }
}

void Scope::setActive(const bool active) {
    if (active != m_isActive) {
        m_isActive = active;
        Q_EMIT isActiveChanged(m_isActive);
    }
}

unity::dash::LocalResult Scope::createLocalResult(const QVariant &uri, const QVariant &icon_hint,
                                                  const QVariant &category, const QVariant &result_type,
                                                  const QVariant &mimetype, const QVariant &title,
                                                  const QVariant &comment, const QVariant &dnd_uri,
                                                  const QVariant &metadata)
{
    unity::dash::LocalResult res;
    res.uri = uri.toString().toStdString();
    res.icon_hint = icon_hint.toString().toStdString();
    res.category_index = category.toUInt();
    res.result_type = result_type.toUInt();
    res.mimetype = mimetype.toString().toStdString();
    res.name = title.toString().toStdString();
    res.comment = comment.toString().toStdString();
    res.dnd_uri = dnd_uri.toString().toStdString();
    res.hints = convertToHintsMap(metadata);

    return res;
}

// FIXME: Change to use row index.
void Scope::activate(const QVariant &uri, const QVariant &icon_hint, const QVariant &category,
                     const QVariant &result_type, const QVariant &mimetype, const QVariant &title,
                     const QVariant &comment, const QVariant &dnd_uri, const QVariant &metadata)
{
    auto res = createLocalResult(uri, icon_hint, category, result_type, mimetype, title, comment, dnd_uri, metadata);
    m_unityScope->Activate(res);
}

// FIXME: Change to use row index.
void Scope::preview(const QVariant &uri, const QVariant &icon_hint, const QVariant &category,
             const QVariant &result_type, const QVariant &mimetype, const QVariant &title,
             const QVariant &comment, const QVariant &dnd_uri, const QVariant &metadata)
{
    QVariant real_metadata(metadata);
    // handle overridden results, since QML doesn't support defining maps
    if (metadata.type() == QVariant::String) {
        real_metadata = QVariant::fromValue(subscopeUriToMetadataHash(metadata.toString()));
    }

    auto res = createLocalResult(uri, icon_hint, category, result_type, mimetype, title, comment, dnd_uri, real_metadata);
    m_previewCancellable.Renew();

    // canned queries don't have previews, must be activated
    if (uri.toString().startsWith("x-unity-no-preview-scopes-query://")) {
        m_unityScope->Activate(res);
    } else {
        m_unityScope->Preview(res, nullptr, m_previewCancellable);
    }
}

void Scope::cancelActivation()
{
    m_previewCancellable.Cancel();
}

void Scope::onActivated(unity::dash::LocalResult const& result, unity::dash::ScopeHandledType type, unity::glib::HintsMap const& hints)
{
    Q_EMIT activated();
    // note: we will not get called on SHOW_PREVIEW, instead UnityCore will signal preview_ready.
    switch (type)
    {
        case unity::dash::NOT_HANDLED:
            fallbackActivate(QString::fromStdString(result.uri));
            break;
        case unity::dash::SHOW_DASH:
            Q_EMIT showDash();
            break;
        case unity::dash::HIDE_DASH:
            Q_EMIT hideDash();
            break;
        case unity::dash::GOTO_DASH_URI:
            if (hints.find("goto-uri") != hints.end()) {
                Q_EMIT gotoUri(QString::fromStdString(g_variant_get_string(hints.at("goto-uri"), nullptr)));
            } else {
                qWarning() << "Missing goto-uri hint for GOTO_DASH_URI activation reply";
            }
            break;
        case unity::dash::PERFORM_SEARCH:
            if (hints.find("query") != hints.end()) {
                // note: this will emit searchQueryChanged, and shell will call setSearchQuery back with a new query,
                // but it will get ignored.
                setSearchQuery(QString::fromStdString(g_variant_get_string(hints.at("query"), nullptr)));
            }
            break;
        default:
            qWarning() << "Unhandled activation response:" << type;
    }
}

void Scope::onPreviewReady(unity::dash::LocalResult const& /* result */, unity::dash::Preview::Ptr const& preview)
{
    Q_EMIT activated();
    auto prv = Preview::newFromUnityPreview(preview);
    // is this the best solution? QML may need to keep more than one preview instance around, so we can't own it.
    // passing it by value is not possible.
    QQmlEngine::setObjectOwnership(prv, QQmlEngine::JavaScriptOwnership);
    Q_EMIT previewReady(prv);
}

void Scope::fallbackActivate(const QString& uri)
{
    /* Tries various methods to trigger a sensible action for the given 'uri'.
       If it has no understanding of the given scheme it falls back on asking
       Qt to open the uri.
    */
    QUrl url(uri);
    if (url.scheme() == "file") {
        /* Override the files place's default URI handler: we want the file
           manager to handle opening folders, not the dash.

           Ref: https://bugs.launchpad.net/upicek/+bug/689667
        */
        QDesktopServices::openUrl(url);
        return;
    }
    if (url.scheme() == "application") {
        // get the full path to the desktop file
        QString path(url.path().isEmpty() ? url.authority() : url.path());
        if (path.startsWith("/")) {
            Q_EMIT activateApplication(path);
        } else {
            // TODO: use the new desktop file finder/parser when it's ready
            gchar* full_path = nullptr;
            GKeyFile* key_file = g_key_file_new();
            QString apps_path = "applications/" + path;
            if (g_key_file_load_from_data_dirs(key_file, apps_path.toLocal8Bit().constData(), &full_path,
                                               G_KEY_FILE_NONE, nullptr)) {
                path = full_path;
                Q_EMIT activateApplication(path);
            } else {
                qWarning() << "Unable to activate " << path;
            }
            g_key_file_free(key_file);
            g_free(full_path);
        }
        return;
    }

    qDebug() << "Trying to open" << uri;

    /* Try our luck */
    QDesktopServices::openUrl(uri); //url?
}

void Scope::setUnityScope(const unity::dash::Scope::Ptr& scope)
{
    m_unityScope = scope;

    m_categories->setUnityScope(m_unityScope);
    m_filters.reset(new Filters(m_unityScope->filters, this));

    m_unityScope->form_factor = m_formFactor.toStdString();
    /* Property change signals */
    m_unityScope->id.changed.connect(sigc::mem_fun(this, &Scope::idChanged));
    m_unityScope->name.changed.connect(sigc::mem_fun(this, &Scope::nameChanged));
    m_unityScope->icon_hint.changed.connect(sigc::mem_fun(this, &Scope::iconHintChanged));
    m_unityScope->description.changed.connect(sigc::mem_fun(this, &Scope::descriptionChanged));
    m_unityScope->search_hint.changed.connect(sigc::mem_fun(this, &Scope::searchHintChanged));
    m_unityScope->visible.changed.connect(sigc::mem_fun(this, &Scope::visibleChanged));
    m_unityScope->shortcut.changed.connect(sigc::mem_fun(this, &Scope::shortcutChanged));
    m_unityScope->connected.changed.connect(sigc::mem_fun(this, &Scope::connectedChanged));
    m_unityScope->results_dirty.changed.connect(sigc::mem_fun(this, &Scope::resultsDirtyToggled));

    /* FIXME: signal should be forwarded instead of calling the handler directly */
    m_unityScope->activated.connect(sigc::mem_fun(this, &Scope::onActivated));

    m_unityScope->preview_ready.connect(sigc::mem_fun(this, &Scope::onPreviewReady));

    /* Synchronize local states with m_unityScope right now and whenever
       m_unityScope becomes connected */
    /* FIXME: should emit change notification signals for all properties */
    connect(this, SIGNAL(connectedChanged(bool)), SLOT(synchronizeStates()));
    synchronizeStates();
}

unity::dash::Scope::Ptr Scope::unityScope() const
{
    return m_unityScope;
}

void Scope::synchronizeStates()
{
    using namespace std::placeholders;

    if (connected()) {
        /* Forward local states to m_unityScope */
        if (!m_searchQuery.isNull()) {
            m_cancellable.Renew();
            m_unityScope->Search(m_searchQuery.toStdString(), std::bind(&Scope::onSearchFinished, this, _1, _2, _3), m_cancellable);
            if (!m_searchInProgress) {
                m_searchInProgress = true;
                Q_EMIT searchInProgressChanged();
            }
        }
    }
}

void Scope::scopeIsActiveChanged()
{
    if (!isActive() || !m_unityScope || !m_unityScope->results_dirty()) return;

    // force new search
    synchronizeStates();
}

void Scope::resultsDirtyToggled(bool results_dirty)
{
    if (!results_dirty || !isActive()) return;

    // force new search
    synchronizeStates();
}

void Scope::onSearchFinished(std::string const& /* query */, unity::glib::HintsMap const& hints, unity::glib::Error const& err)
{
    QString hint;

    GError* error = const_cast<unity::glib::Error&>(err);

    if (!err || !g_error_matches(error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
        if (m_searchInProgress) {
            m_searchInProgress = false;
            Q_EMIT searchInProgressChanged();
        }
    } else {
        // no need to check the results hint, we're still searching
        return;
    }

    if (!m_unityScope->results()->count()) {
        unity::glib::HintsMap::const_iterator it = hints.find("no-results-hint");
        if (it != hints.end()) {
            hint = QString::fromStdString(it->second.GetString());
        } else {
            hint = QString::fromUtf8(dgettext("unity", "Sorry, there is nothing that matches your search."));
        }
    }

    setNoResultsHint(hint);
}
