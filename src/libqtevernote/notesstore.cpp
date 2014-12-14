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

#include "notesstore.h"
#include "evernoteconnection.h"
#include "notebooks.h"
#include "notebook.h"
#include "note.h"
#include "tag.h"
#include "utils/enmldocument.h"
#include "utils/organizeradapter.h"
#include "userstore.h"

#include "jobs/fetchnotesjob.h"
#include "jobs/fetchnotebooksjob.h"
#include "jobs/fetchnotejob.h"
#include "jobs/createnotejob.h"
#include "jobs/savenotejob.h"
#include "jobs/savenotebookjob.h"
#include "jobs/deletenotejob.h"
#include "jobs/createnotebookjob.h"
#include "jobs/expungenotebookjob.h"
#include "jobs/fetchtagsjob.h"
#include "jobs/createtagjob.h"
#include "jobs/savetagjob.h"

#include <QImage>
#include <QDebug>
#include <QStandardPaths>
#include <QUuid>
#include <QPointer>

NotesStore* NotesStore::s_instance = 0;

NotesStore::NotesStore(QObject *parent) :
    QAbstractListModel(parent),
    m_username("@invalid "),
    m_loading(false),
    m_notebooksLoading(false),
    m_tagsLoading(false)
{
    connect(UserStore::instance(), &UserStore::usernameChanged, this, &NotesStore::userStoreConnected);

    qRegisterMetaType<evernote::edam::NotesMetadataList>("evernote::edam::NotesMetadataList");
    qRegisterMetaType<evernote::edam::Note>("evernote::edam::Note");
    qRegisterMetaType<std::vector<evernote::edam::Notebook> >("std::vector<evernote::edam::Notebook>");
    qRegisterMetaType<evernote::edam::Notebook>("evernote::edam::Notebook");
    qRegisterMetaType<std::vector<evernote::edam::Tag> >("std::vector<evernote::edam::Tag>");
    qRegisterMetaType<evernote::edam::Tag>("evernote::edam::Tag");

    m_organizerAdapter = new OrganizerAdapter(this);
}

NotesStore *NotesStore::instance()
{
    if (!s_instance) {
        s_instance = new NotesStore();
    }
    return s_instance;
}

QString NotesStore::username() const
{
    return m_username;
}

void NotesStore::setUsername(const QString &username)
{
    if (username.isEmpty()) {
        // We don't accept an empty username.
        return;
    }
    if (!UserStore::instance()->username().isEmpty() && username != UserStore::instance()->username()) {
        qWarning() << "Logged in to Evernote. Can't change account manually. User EvernoteConnection to log in to another account or log out and change this manually.";
        return;
    }

    if (m_username != username) {
        m_username = username;
        emit usernameChanged();

        m_cacheFile = QStandardPaths::standardLocations(QStandardPaths::CacheLocation).first() + "/" + m_username + "/notes.cache";
        qDebug() << "initialized cacheFile" << m_cacheFile;
        loadFromCacheFile();
    }
}

void NotesStore::userStoreConnected(const QString &username)
{
    setUsername(username);

    refreshNotebooks();
    refreshTags();
    refreshNotes();
}

bool NotesStore::loading() const
{
    return m_loading;
}

bool NotesStore::notebooksLoading() const
{
    return m_notebooksLoading;
}

bool NotesStore::tagsLoading() const
{
    return m_tagsLoading;
}

QString NotesStore::error() const
{
    return m_error;
}

QString NotesStore::notebooksError() const
{
    return m_notebooksError;
}

QString NotesStore::tagsError() const
{
    return m_tagsError;
}

int NotesStore::count() const
{
    return rowCount();
}

int NotesStore::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_notes.count();
}

QVariant NotesStore::data(const QModelIndex &index, int role) const
{
    switch (role) {
    case RoleGuid:
        return m_notes.at(index.row())->guid();
    case RoleNotebookGuid:
        return m_notes.at(index.row())->notebookGuid();
    case RoleCreated:
        return m_notes.at(index.row())->created();
    case RoleCreatedString:
        return m_notes.at(index.row())->createdString();
    case RoleUpdated:
        return m_notes.at(index.row())->updated();
    case RoleUpdatedString:
        return m_notes.at(index.row())->updatedString();
    case RoleTitle:
        return m_notes.at(index.row())->title();
    case RoleReminder:
        return m_notes.at(index.row())->reminder();
    case RoleReminderTime:
        return m_notes.at(index.row())->reminderTime();
    case RoleReminderTimeString:
        return m_notes.at(index.row())->reminderTimeString();
    case RoleReminderDone:
        return m_notes.at(index.row())->reminderDone();
    case RoleReminderDoneTime:
        return m_notes.at(index.row())->reminderDoneTime();
    case RoleEnmlContent:
        return m_notes.at(index.row())->enmlContent();
    case RoleHtmlContent:
        return m_notes.at(index.row())->htmlContent();
    case RoleRichTextContent:
        return m_notes.at(index.row())->richTextContent();
    case RolePlaintextContent:
        return m_notes.at(index.row())->plaintextContent();
    case RoleTagline:
        return m_notes.at(index.row())->tagline();
    case RoleResourceUrls:
        return m_notes.at(index.row())->resourceUrls();
    case RoleReminderSorting:
        // done reminders get +1000000000000 (this will break sorting in year 2286 :P)
        return QVariant::fromValue(m_notes.at(index.row())->reminderTime().toMSecsSinceEpoch() +
                (m_notes.at(index.row())->reminderDone() ? 10000000000000 : 0));
    case RoleTagGuids:
        return m_notes.at(index.row())->tagGuids();
    case RoleDeleted:
        return m_notes.at(index.row())->deleted();
    case RoleSynced:
        return m_notes.at(index.row())->synced();
    case RoleLoading:
        return m_notes.at(index.row())->loading();
    case RoleSyncError:
        return m_notes.at(index.row())->syncError();
    }
    return QVariant();
}

QHash<int, QByteArray> NotesStore::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles.insert(RoleGuid, "guid");
    roles.insert(RoleNotebookGuid, "notebookGuid");
    roles.insert(RoleCreated, "created");
    roles.insert(RoleCreatedString, "createdString");
    roles.insert(RoleUpdated, "updated");
    roles.insert(RoleUpdatedString, "updatedString");
    roles.insert(RoleTitle, "title");
    roles.insert(RoleReminder, "reminder");
    roles.insert(RoleReminderTime, "reminderTime");
    roles.insert(RoleReminderTimeString, "reminderTimeString");
    roles.insert(RoleReminderDone, "reminderDone");
    roles.insert(RoleReminderDoneTime, "reminderDoneTime");
    roles.insert(RoleEnmlContent, "enmlContent");
    roles.insert(RoleRichTextContent, "richTextContent");
    roles.insert(RoleHtmlContent, "htmlContent");
    roles.insert(RolePlaintextContent, "plaintextContent");
    roles.insert(RoleTagline, "tagline");
    roles.insert(RoleResourceUrls, "resourceUrls");
    roles.insert(RoleTagGuids, "tagGuids");
    roles.insert(RoleDeleted, "deleted");
    roles.insert(RoleLoading, "loading");
    roles.insert(RoleSynced, "synced");
    roles.insert(RoleSyncError, "syncError");
    return roles;
}

NotesStore::~NotesStore()
{
}

QList<Note*> NotesStore::notes() const
{
    return m_notes;
}

Note *NotesStore::note(const QString &guid)
{
    return m_notesHash.value(guid);
}

QList<Notebook *> NotesStore::notebooks() const
{
    return m_notebooks;
}

Notebook *NotesStore::notebook(const QString &guid)
{
    return m_notebooksHash.value(guid);
}

void NotesStore::createNotebook(const QString &name)
{
    Notebook *notebook = new Notebook(QUuid::createUuid().toString().remove(QRegExp("[\{\}]*")), 1, this);
    notebook->setName(name);

    m_notebooks.append(notebook);
    m_notebooksHash.insert(notebook->guid(), notebook);
    emit notebookAdded(notebook->guid());

    syncToCacheFile(notebook);

    if (EvernoteConnection::instance()->isConnected()) {
        notebook->setLoading(true);
        CreateNotebookJob *job = new CreateNotebookJob(notebook);
        connect(job, &CreateNotebookJob::jobDone, this, &NotesStore::createNotebookJobDone);
        EvernoteConnection::instance()->enqueue(job);
    }
}

void NotesStore::createNotebookJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &tmpGuid, const evernote::edam::Notebook &result)
{
    Notebook *notebook = m_notebooksHash.value(tmpGuid);
    if (!notebook) {
        qWarning() << "Cannot find temporary notebook after create finished";
        return;
    }

    notebook->setLoading(false);

    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Error creating notebook:" << errorMessage;
        notebook->setSyncError(true);
        return;
    }
    QString guid = QString::fromStdString(result.guid);
    qDebug() << "create notebooks job done2";

    m_notebooksHash.insert(guid, notebook);
    notebook->setGuid(QString::fromStdString(result.guid));
    emit notebookGuidChanged(tmpGuid, notebook->guid());
    m_notebooksHash.remove(tmpGuid);

    notebook->setUpdateSequenceNumber(result.updateSequenceNum);
    notebook->setLastSyncedSequenceNumber(result.updateSequenceNum);
    notebook->setName(QString::fromStdString(result.name));
    emit notebookChanged(notebook->guid());

    QSettings cacheFile(m_cacheFile, QSettings::IniFormat);
    cacheFile.beginGroup("notebooks");
    cacheFile.remove(tmpGuid);
    cacheFile.endGroup();

    syncToCacheFile(notebook);

    foreach (const QString &noteGuid, notebook->m_notesList) {
        saveNote(noteGuid);
    }
}

void NotesStore::saveNotebook(const QString &guid)
{
    Notebook *notebook = m_notebooksHash.value(guid);
    if (!notebook) {
        qWarning() << "Can't save notebook. Guid not found:" << guid;
        return;
    }

    notebook->setUpdateSequenceNumber(notebook->updateSequenceNumber()+1);
    syncToCacheFile(notebook);

    if (EvernoteConnection::instance()->isConnected()) {
        SaveNotebookJob *job = new SaveNotebookJob(notebook, this);
        connect(job, &SaveNotebookJob::jobDone, this, &NotesStore::saveNotebookJobDone);
        EvernoteConnection::instance()->enqueue(job);
        notebook->setLoading(true);
    }
    emit notebookChanged(notebook->guid());
}

void NotesStore::saveTag(const QString &guid)
{
    Tag *tag = m_tagsHash.value(guid);
    if (!tag) {
        qWarning() << "Can't save tag. Guid not found:" << guid;
        return;
    }

    tag->setUpdateSequenceNumber(tag->updateSequenceNumber()+1);
    syncToCacheFile(tag);

    if (EvernoteConnection::instance()->isConnected()) {
        tag->setLoading(true);
        emit tagChanged(tag->guid());
        SaveTagJob *job = new SaveTagJob(tag);
        connect(job, &SaveTagJob::jobDone, this, &NotesStore::saveTagJobDone);
        EvernoteConnection::instance()->enqueue(job);
    }
}

void NotesStore::expungeNotebook(const QString &guid)
{
    ExpungeNotebookJob *job = new ExpungeNotebookJob(guid);
    connect(job, &ExpungeNotebookJob::jobDone, this, &NotesStore::expungeNotebookJobDone);
    EvernoteConnection::instance()->enqueue(job);
}

QList<Tag *> NotesStore::tags() const
{
    return m_tags;
}

Tag *NotesStore::tag(const QString &guid)
{
    return m_tagsHash.value(guid);
}

Tag* NotesStore::createTag(const QString &name)
{
    Tag *tag = new Tag(QUuid::createUuid().toString().remove(QRegExp("[\{\}]*")), 1);
    tag->setName(name);
    m_tags.append(tag);
    m_tagsHash.insert(tag->guid(), tag);
    emit tagAdded(tag->guid());

    syncToCacheFile(tag);

    if (EvernoteConnection::instance()->isConnected()) {
        CreateTagJob *job = new CreateTagJob(tag);
        connect(job, &CreateTagJob::jobDone, this, &NotesStore::createTagJobDone);
        EvernoteConnection::instance()->enqueue(job);
    }
    return tag;
}

void NotesStore::createTagJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &tmpGuid, const evernote::edam::Tag &result)
{
    qDebug() << "CreateTagJob done";
    Tag *tag = m_tagsHash.value(tmpGuid);
    if (!tag) {
        qWarning() << "Create Tag job done but tag can't be found any more";
        return;
    }

    tag->setLoading(false);
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Error creating tag:" << errorMessage;
        tag->setSyncError(true);
        emit tagChanged(tag->guid());
        return;
    }

    QString guid = QString::fromStdString(result.guid);
    m_tagsHash.insert(guid, tag);
    tag->setGuid(QString::fromStdString(result.guid));
    emit tagGuidChanged(tmpGuid, guid);
    m_tagsHash.remove(tmpGuid);

    tag->setUpdateSequenceNumber(result.updateSequenceNum);
    tag->setLastSyncedSequenceNumber(result.updateSequenceNum);
    emit tagChanged(tag->guid());

    QSettings cacheFile(m_cacheFile, QSettings::IniFormat);
    cacheFile.beginGroup("tags");
    cacheFile.remove(tmpGuid);
    cacheFile.endGroup();

    syncToCacheFile(tag);

    foreach (const QString &noteGuid, tag->m_notesList) {
        saveNote(noteGuid);
    }
}

void NotesStore::saveTagJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Tag &result)
{
    Tag *tag = m_tagsHash.value(QString::fromStdString(result.guid));
    if (!tag) {
        qWarning() << "Save tag job finished, but tag can't be found any more";
        return;
    }
    tag->setLoading(false);
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "error updating tag" << errorMessage;
        tag->setSyncError(true);
        emit tagChanged(tag->guid());
        return;
    }

    tag->setName(QString::fromStdString(result.name));
    tag->setUpdateSequenceNumber(result.updateSequenceNum);
    tag->setLastSyncedSequenceNumber(result.updateSequenceNum);
    emit tagChanged(tag->guid());
    syncToCacheFile(tag);
}

void NotesStore::tagNote(const QString &noteGuid, const QString &tagGuid)
{
    Note *note = m_notesHash.value(noteGuid);
    if (!note) {
        qWarning() << "No such note" << noteGuid;
        return;
    }

    Tag *tag = m_tagsHash.value(tagGuid);
    if (!tag) {
        qWarning() << "No such tag" << tagGuid;
        return;
    }

    if (note->tagGuids().contains(tagGuid)) {
        qWarning() << "Note" << noteGuid << "already tagged with tag" << tagGuid;
        return;
    }

    note->setTagGuids(note->tagGuids() << tagGuid);
    saveNote(noteGuid);
}

void NotesStore::untagNote(const QString &noteGuid, const QString &tagGuid)
{
    Note *note = m_notesHash.value(noteGuid);
    if (!note) {
        qWarning() << "No such note" << noteGuid;
        return;
    }

    Tag *tag = m_tagsHash.value(tagGuid);
    if (!tag) {
        qWarning() << "No such tag" << tagGuid;
        return;
    }

    if (!note->tagGuids().contains(tagGuid)) {
        qWarning() << "Note" << noteGuid << "is not tagged with tag" << tagGuid;
        return;
    }

    QStringList newTagGuids = note->tagGuids();
    newTagGuids.removeAll(tagGuid);
    note->setTagGuids(newTagGuids);
    saveNote(noteGuid);
}

void NotesStore::refreshNotes(const QString &filterNotebookGuid, int startIndex)
{
    if (m_loading && startIndex == 0) {
        qWarning() << "Still busy with refreshing...";
        return;
    }

    m_unhandledNotes = m_notesHash.keys();

    if (EvernoteConnection::instance()->isConnected()) {
        m_loading = true;
        emit loadingChanged();
        FetchNotesJob *job = new FetchNotesJob(filterNotebookGuid, QString(), startIndex);
        connect(job, &FetchNotesJob::jobDone, this, &NotesStore::fetchNotesJobDone);
        EvernoteConnection::instance()->enqueue(job);
    }
}

void NotesStore::fetchNotesJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::NotesMetadataList &results, const QString &filterNotebookGuid)
{
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Failed to fetch notes list:" << errorMessage;
        m_error = tr("Error refreshing notes: %1").arg(errorMessage);
        emit errorChanged();
        return;
    }
    if (!m_error.isEmpty()) {
        m_error.clear();
        emit errorChanged();
    }

    for (unsigned int i = 0; i < results.notes.size(); ++i) {
        evernote::edam::NoteMetadata result = results.notes.at(i);
        Note *note = m_notesHash.value(QString::fromStdString(result.guid));
        m_unhandledNotes.removeAll(QString::fromStdString(result.guid));
        QVector<int> changedRoles;
        bool newNote = note == 0;
        if (newNote) {
            note = new Note(QString::fromStdString(result.guid), 0, this);
            connect(note, &Note::reminderChanged, this, &NotesStore::emitDataChanged);
            connect(note, &Note::reminderDoneChanged, this, &NotesStore::emitDataChanged);

            updateFromEDAM(result, note);
            qDebug() << "updated from EDAM:" << note->updateSequenceNumber() << note->lastSyncedSequenceNumber() << result.__isset.updateSequenceNum;

            beginInsertRows(QModelIndex(), m_notes.count(), m_notes.count());
            m_notesHash.insert(note->guid(), note);
            m_notes.append(note);
            endInsertRows();
            emit noteAdded(note->guid(), note->notebookGuid());
            emit countChanged();
            syncToCacheFile(note);

        } else if (note->synced()) {
            // Local note did not change. Check if we need to refresh from server.
            if (note->updateSequenceNumber() < result.updateSequenceNum) {
                qDebug() << "refreshing note from network. suequence number changed: " << note->updateSequenceNumber() << "->" << result.updateSequenceNum;
                changedRoles = updateFromEDAM(result, note);
                refreshNoteContent(note->guid(), FetchNoteJob::LoadContent, EvernoteConnection::JobPriorityLow);
                syncToCacheFile(note);
            }
        } else {
            // Local note changed. See if we can push our changes.
            if (note->lastSyncedSequenceNumber() == result.updateSequenceNum) {
                qDebug() << "Local note has changed while server note did not. Pushing changes.";
                note->setLoading(true);
                changedRoles << RoleLoading;
                SaveNoteJob *job = new SaveNoteJob(note, this);
                connect(job, &SaveNoteJob::jobDone, this, &NotesStore::saveNoteJobDone);
                EvernoteConnection::instance()->enqueue(job);
            } else {
                qWarning() << "CONFLICT: Note has been changed on server and locally!";
                qWarning() << "local note sequence:" << note->updateSequenceNumber();
                qWarning() << "last synced sequence:" << note->lastSyncedSequenceNumber();
                qWarning() << "remote sequence:" << result.updateSequenceNum;
                note->setSyncError(true);
                changedRoles << RoleSyncError;
            }
        }

        if (!results.searchedWords.empty()) {
            note->setIsSearchResult(true);
            changedRoles << RoleIsSearchResult;
        }

        if (changedRoles.count() > 0) {
            QModelIndex noteIndex = index(m_notes.indexOf(note));
            emit dataChanged(noteIndex, noteIndex, changedRoles);
            emit noteChanged(note->guid(), note->notebookGuid());
        }
    }

    if (results.startIndex + (int32_t)results.notes.size() < results.totalNotes) {
        refreshNotes(filterNotebookGuid, results.startIndex + results.notes.size());
    } else {
        m_organizerAdapter->startSync();
        m_loading = false;
        emit loadingChanged();


        foreach (const QString &unhandledGuid, m_unhandledNotes) {
            Note *note = m_notesHash.value(unhandledGuid);
            if (!note) {
                continue; // Note might be deleted locally by now
            }
            qDebug() << "Have a local note that's not available on server!" << note->guid();
            if (note->lastSyncedSequenceNumber() == 0) {
                // This note hasn't been created on the server yet. Do that now.
                bool hasUnsyncedTag = false;
                foreach (const QString &tagGuid, note->tagGuids()) {
                    Tag *tag = m_tagsHash.value(tagGuid);
                    Q_ASSERT_X(tag, "FetchNotesJob done", "note->tagGuids() contains a non existing tag.");
                    if (tag && tag->lastSyncedSequenceNumber() == 0) {
                        hasUnsyncedTag = true;
                        break;
                    }
                }
                if (hasUnsyncedTag) {
                    qDebug() << "Not syncing note to server yet. Have a tag that needs sync first";
                    continue;
                }
                Notebook *notebook = m_notebooksHash.value(note->notebookGuid());
                if (notebook && notebook->lastSyncedSequenceNumber() == 0) {
                    qDebug() << "Not syncing note to server yet. The notebook needs to be synced first";
                    continue;
                }
                qDebug() << "Creating note on server:" << note->notebookGuid() << m_notebooksHash.keys();

                QModelIndex idx = index(m_notes.indexOf(note));
                note->setLoading(true);
                emit dataChanged(idx, idx, QVector<int>() << RoleLoading);
                CreateNoteJob *job = new CreateNoteJob(note, this);
                connect(job, &CreateNoteJob::jobDone, this, &NotesStore::createNoteJobDone);
                EvernoteConnection::instance()->enqueue(job);
            } else {
                // This note has been deleted from the server... drop it
                int idx = m_notes.indexOf(note);
                if (idx > -1) {
                    beginRemoveRows(QModelIndex(), idx, idx);
                    m_notes.removeAt(idx);
                    m_notesHash.remove(note->guid());
                    endRemoveRows();
                    emit noteRemoved(note->guid(), note->notebookGuid());
                    emit countChanged();

                    QSettings settings(m_cacheFile, QSettings::IniFormat);
                    settings.beginGroup("notes");
                    settings.remove(note->guid());
                    settings.endGroup();

                    note->deleteLater();
                }
            }
        }
    }
}

void NotesStore::refreshNoteContent(const QString &guid, FetchNoteJob::LoadWhat what, EvernoteConnection::JobPriority priority)
{
    qDebug() << "fetching note content from network for note" << guid << (what == FetchNoteJob::LoadContent ? "content" : "image");
    Note *note = m_notesHash.value(guid);
    if (note) {
        note->setLoading(true);
        int idx = m_notes.indexOf(note);
        emit dataChanged(index(idx), index(idx), QVector<int>() << RoleLoading);
    }

    FetchNoteJob *job = new FetchNoteJob(guid, what, this);
    connect(job, &FetchNoteJob::resultReady, this, &NotesStore::fetchNoteJobDone);
    EvernoteConnection::instance()->enqueue(job, priority);
}

void NotesStore::fetchNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result, FetchNoteJob::LoadWhat what)
{
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Error fetching note:" << errorMessage;
        return;
    }

    Note *note = m_notesHash.value(QString::fromStdString(result.guid));
    if (!note) {
        qWarning() << "can't find note for this update... ignoring...";
        return;
    }
    note->setLoading(false);
    note->setNotebookGuid(QString::fromStdString(result.notebookGuid));
    note->setTitle(QString::fromStdString(result.title));
    note->setUpdated(QDateTime::fromMSecsSinceEpoch(result.updated));

    // Notes are fetched without resources by default. if we discover one or more resources where we don't have
    // data in the cache, let's refresh the note again with resource data.
    bool refreshWithResourceData = false;

    qDebug() << "got note content" << note->guid() << (what == FetchNoteJob::LoadContent ? "content" : "image") << result.resources.size();
    // Resources need to be set before the content because otherwise the image provider won't find them when the content is updated in the ui
    for (unsigned int i = 0; i < result.resources.size(); ++i) {

        evernote::edam::Resource resource = result.resources.at(i);

        QString hash = QByteArray::fromRawData(resource.data.bodyHash.c_str(), resource.data.bodyHash.length()).toHex();
        QString fileName = QString::fromStdString(resource.attributes.fileName);
        QString mime = QString::fromStdString(resource.mime);

        if (what == FetchNoteJob::LoadResources) {
            QByteArray resourceData = QByteArray(resource.data.body.data(), resource.data.size);
            note->addResource(resourceData, hash, fileName, mime);
        } else if (Resource::isCached(hash)) {
            qDebug() << "have resource cached";
            note->addResource(QByteArray(), hash, fileName, mime);
        } else {
            qDebug() << "refetching for image";
            refreshWithResourceData = true;
        }
    }

    if (what == FetchNoteJob::LoadContent) {
        note->setEnmlContent(QString::fromStdString(result.content));
        note->setUpdateSequenceNumber(result.updateSequenceNum);
    }
    note->setReminderOrder(result.attributes.reminderOrder);
    QDateTime reminderTime;
    if (result.attributes.reminderTime > 0) {
        reminderTime = QDateTime::fromMSecsSinceEpoch(result.attributes.reminderTime);
    }
    note->setReminderTime(reminderTime);
    QDateTime reminderDoneTime;
    if (result.attributes.reminderDoneTime > 0) {
        reminderDoneTime = QDateTime::fromMSecsSinceEpoch(result.attributes.reminderDoneTime);
    }
    note->setReminderDoneTime(reminderDoneTime);
    emit noteChanged(note->guid(), note->notebookGuid());

    QModelIndex noteIndex = index(m_notes.indexOf(note));
    emit dataChanged(noteIndex, noteIndex);

    if (refreshWithResourceData) {
        qDebug() << "refreshWithResourceData";
        refreshNoteContent(note->guid(), FetchNoteJob::LoadResources);
    }

    syncToCacheFile(note); // Syncs into the list cache
    note->syncToCacheFile(); // Syncs note's content into notes cache
}

void NotesStore::refreshNotebooks()
{
    if (!EvernoteConnection::instance()->isConnected()) {
        qWarning() << "Not connected. Cannot fetch notebooks from server.";
        return;
    }

    m_notebooksLoading = true;
    emit notebooksLoadingChanged();
    FetchNotebooksJob *job = new FetchNotebooksJob();
    connect(job, &FetchNotebooksJob::jobDone, this, &NotesStore::fetchNotebooksJobDone);
    EvernoteConnection::instance()->enqueue(job);
}

void NotesStore::fetchNotebooksJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const std::vector<evernote::edam::Notebook> &results)
{
    m_notebooksLoading = false;
    emit notebooksLoadingChanged();

    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Error fetching notebooks:" << errorMessage;
        m_notebooksError = tr("Error refreshing notebooks: %1").arg(errorMessage);
        emit notebooksErrorChanged();
        return;
    }
    if (!m_notebooksError.isEmpty()) {
        m_notebooksError.clear();
        emit notebooksErrorChanged();
    }

    QList<Notebook*> unhandledNotebooks = m_notebooks;

    for (unsigned int i = 0; i < results.size(); ++i) {
        evernote::edam::Notebook result = results.at(i);
        Notebook *notebook = m_notebooksHash.value(QString::fromStdString(result.guid));
        unhandledNotebooks.removeAll(notebook);
        bool newNotebook = notebook == 0;
        if (newNotebook) {
            notebook = new Notebook(QString::fromStdString(result.guid), 0, this);
            updateFromEDAM(result, notebook);
            m_notebooksHash.insert(notebook->guid(), notebook);
            m_notebooks.append(notebook);
            emit notebookAdded(notebook->guid());
            syncToCacheFile(notebook);
        } else if (notebook->synced()) {
            if (notebook->updateSequenceNumber() < result.updateSequenceNum) {
                updateFromEDAM(result, notebook);
                emit notebookChanged(notebook->guid());
                syncToCacheFile(notebook);
            }
        } else {
            // Local notebook changed. See if we can push our changes
            if (result.updateSequenceNum == notebook->lastSyncedSequenceNumber()) {
                SaveNotebookJob *job = new SaveNotebookJob(notebook);
                connect(job, &SaveNotebookJob::jobDone, this, &NotesStore::saveNotebookJobDone);
                EvernoteConnection::instance()->enqueue(job);
                notebook->setLoading(true);
                emit notebookChanged(notebook->guid());
            } else {
                qWarning() << "CONFLICT in notebook:" << notebook->name();
                notebook->setSyncError(true);
                emit notebookChanged(notebook->guid());
            }
        }
    }

    foreach (Notebook *notebook, unhandledNotebooks) {
        if (notebook->lastSyncedSequenceNumber() == 0) {
            notebook->setLoading(true);
            CreateNotebookJob *job = new CreateNotebookJob(notebook);
            connect(job, &CreateNotebookJob::jobDone, this, &NotesStore::createNotebookJobDone);
            EvernoteConnection::instance()->enqueue(job);
            emit notebookChanged(notebook->guid());
        } else {
            m_notebooks.removeAll(notebook);
            m_notebooksHash.remove(notebook->guid());
            emit notebookRemoved(notebook->guid());

            QSettings settings(m_cacheFile, QSettings::IniFormat);
            settings.beginGroup("notenooks");
            settings.remove(notebook->guid());
            settings.endGroup();

            notebook->deleteInfoFile();
            notebook->deleteLater();
        }
    }
}

void NotesStore::refreshTags()
{
    if (!EvernoteConnection::instance()->isConnected()) {
        qWarning() << "Not connected. Cannot fetch tags from server.";
        return;
    }
    m_tagsLoading = true;
    emit tagsLoadingChanged();
    FetchTagsJob *job = new FetchTagsJob();
    connect(job, &FetchTagsJob::jobDone, this, &NotesStore::fetchTagsJobDone);
    EvernoteConnection::instance()->enqueue(job);
}

void NotesStore::fetchTagsJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const std::vector<evernote::edam::Tag> &results)
{
    m_tagsLoading = false;
    emit tagsLoadingChanged();

    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Error fetching tags:" << errorMessage;
        m_tagsError = tr("Error refreshing tags: %1").arg(errorMessage);
        emit tagsErrorChanged();
        return;
    }
    if (!m_tagsError.isEmpty()) {
        m_tagsError.clear();
        emit tagsErrorChanged();
    }

    QHash<QString, Tag*> unhandledTags = m_tagsHash;
    for (unsigned int i = 0; i < results.size(); ++i) {
        evernote::edam::Tag result = results.at(i);
        unhandledTags.remove(QString::fromStdString(result.guid));
        Tag *tag = m_tagsHash.value(QString::fromStdString(result.guid));
        bool newTag = tag == 0;
        if (newTag) {
            tag = new Tag(QString::fromStdString(result.guid), result.updateSequenceNum, this);
            tag->setLastSyncedSequenceNumber(result.updateSequenceNum);
            qDebug() << "got new tag with seq:" << result.updateSequenceNum << tag->synced() << tag->updateSequenceNumber() << tag->lastSyncedSequenceNumber();
            tag->setName(QString::fromStdString(result.name));
            m_tagsHash.insert(tag->guid(), tag);
            m_tags.append(tag);
            emit tagAdded(tag->guid());
            syncToCacheFile(tag);
        } else if (tag->synced()) {
            if (tag->updateSequenceNumber() < result.updateSequenceNum) {
                tag->setName(QString::fromStdString(result.name));
                tag->setUpdateSequenceNumber(result.updateSequenceNum);
                tag->setLastSyncedSequenceNumber(result.updateSequenceNum);
                emit tagChanged(tag->guid());
                syncToCacheFile(tag);
            }
        } else {
            // local tag changed. See if we can sync it to the server
            if (result.updateSequenceNum == tag->lastSyncedSequenceNumber()) {
                SaveTagJob *job = new SaveTagJob(tag);
                connect(job, &SaveTagJob::jobDone, this, &NotesStore::saveTagJobDone);
                EvernoteConnection::instance()->enqueue(job);
                tag->setLoading(true);
                emit tagChanged(tag->guid());
            } else {
                qWarning() << "CONFLICT in tag" << tag->name();
                tag->setSyncError(true);
                emit tagChanged(tag->guid());
            }
        }


    }

    foreach (Tag *tag, unhandledTags) {
        if (tag->lastSyncedSequenceNumber() == 0) {
            tag->setLoading(true);
            CreateTagJob *job = new CreateTagJob(tag);
            connect(job, &CreateTagJob::jobDone, this, &NotesStore::createTagJobDone);
            EvernoteConnection::instance()->enqueue(job);
            emit tagChanged(tag->guid());
        } else {
            m_tags.removeAll(tag);
            m_tagsHash.remove(tag->guid());
            emit tagRemoved(tag->guid());

            tag->deleteInfoFile();
            tag->deleteLater();
        }
    }
}

Note* NotesStore::createNote(const QString &title, const QString &notebookGuid, const QString &richTextContent)
{
    EnmlDocument enmlDoc;
    enmlDoc.setRichText(richTextContent);
    return createNote(title, notebookGuid, enmlDoc);
}

Note* NotesStore::createNote(const QString &title, const QString &notebookGuid, const EnmlDocument &content)
{
    Note *note = new Note(QUuid::createUuid().toString().remove(QRegExp("[\{\}]*")), 1, this);
    connect(note, &Note::reminderChanged, this, &NotesStore::emitDataChanged);
    connect(note, &Note::reminderDoneChanged, this, &NotesStore::emitDataChanged);

    note->setTitle(title);
    if (notebookGuid.isEmpty() && m_notebooks.count() > 0) {
        note->setNotebookGuid(m_notebooks.first()->guid());
    } else {
        note->setNotebookGuid(notebookGuid);
    }
    note->setEnmlContent(content.enml());
    note->setCreated(QDateTime::currentDateTime());
    note->setUpdated(note->created());

    beginInsertRows(QModelIndex(), m_notes.count(), m_notes.count());
    m_notesHash.insert(note->guid(), note);
    m_notes.append(note);
    endInsertRows();

    emit countChanged();
    emit noteAdded(note->guid(), note->notebookGuid());
    emit noteCreated(note->guid(), note->notebookGuid());

    syncToCacheFile(note);

    if (EvernoteConnection::instance()->isConnected()) {
        CreateNoteJob *job = new CreateNoteJob(note);
        connect(job, &CreateNoteJob::jobDone, this, &NotesStore::createNoteJobDone);
        EvernoteConnection::instance()->enqueue(job);
    }
    return note;
}

void NotesStore::createNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &tmpGuid, const evernote::edam::Note &result)
{
    Note *note = m_notesHash.value(tmpGuid);
    if (!note) {
        qWarning() << "Cannot find temporary note after create operation!";
        return;
    }
    int idx = m_notes.indexOf(note);
    QVector<int> roles;

    note->setLoading(false);
    roles << RoleLoading;

    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Error creating note:" << errorMessage;
        note->setSyncError(true);
        roles << RoleSyncError;
        emit dataChanged(index(idx), index(idx), roles);
        return;
    }

    if (note->syncError()) {
        note->setSyncError(false);
        roles << RoleSyncError;
    }

    note->setLoading(false);
    roles << RoleLoading;

    QString guid = QString::fromStdString(result.guid);
    m_notesHash.insert(guid, note);
    note->setGuid(guid);
    m_notesHash.remove(tmpGuid);
    emit noteGuidChanged(tmpGuid, guid);
    roles << RoleGuid;

    if (note->updateSequenceNumber() != result.updateSequenceNum) {
        note->setUpdateSequenceNumber(result.updateSequenceNum);
        note->setLastSyncedSequenceNumber(result.updateSequenceNum);
        roles << RoleSynced;
    }
    if (result.__isset.created) {
        note->setCreated(QDateTime::fromMSecsSinceEpoch(result.created));
        roles << RoleCreated;
    }
    if (result.__isset.updated) {
        note->setUpdated(QDateTime::fromMSecsSinceEpoch(result.updated));
        roles << RoleUpdated;
    }
    if (result.__isset.notebookGuid) {
        note->setNotebookGuid(QString::fromStdString(result.notebookGuid));
        roles << RoleNotebookGuid;
    }
    if (result.__isset.title) {
        note->setTitle(QString::fromStdString(result.title));
        roles << RoleTitle;
    }
    if (result.__isset.content) {
        note->setEnmlContent(QString::fromStdString(result.content));
        roles << RoleEnmlContent << RoleRichTextContent << RoleTagline << RolePlaintextContent;
    }
    emit dataChanged(index(idx), index(idx), roles);

    QSettings cacheFile(m_cacheFile, QSettings::IniFormat);
    cacheFile.beginGroup("notes");
    cacheFile.remove(tmpGuid);
    cacheFile.endGroup();

    syncToCacheFile(note);
}

void NotesStore::saveNote(const QString &guid)
{
    Note *note = m_notesHash.value(guid);
    if (!note) {
        qWarning() << "Can't save note. Guid not found:" << guid;
        return;
    }
    note->setUpdateSequenceNumber(note->updateSequenceNumber()+1);
    syncToCacheFile(note);
    note->syncToCacheFile();

    if (EvernoteConnection::instance()->isConnected()) {
        note->setLoading(true);
        if (note->lastSyncedSequenceNumber() == 0) {
            // This note hasn't been created on the server yet... try that first
            CreateNoteJob *job = new CreateNoteJob(note, this);
            connect(job, &CreateNoteJob::jobDone, this, &NotesStore::createNoteJobDone);
            EvernoteConnection::instance()->enqueue(job);
        } else {
            SaveNoteJob *job = new SaveNoteJob(note, this);
            connect(job, &SaveNoteJob::jobDone, this, &NotesStore::saveNoteJobDone);
            EvernoteConnection::instance()->enqueue(job);
        }
    }

    int idx = m_notes.indexOf(note);
    emit dataChanged(index(idx), index(idx));
    emit noteChanged(guid, note->notebookGuid());

    m_organizerAdapter->startSync();
}

void NotesStore::saveNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result)
{
    qDebug() << "saveNoteJobDone. guid:" << QString::fromStdString(result.guid);
    Note *note = m_notesHash.value(QString::fromStdString(result.guid));
    if (!note) {
        qWarning() << "Got a save note job result, but note has disappeared locally.";
        return;
    }

    int idx = m_notes.indexOf(note);
    note->setLoading(false);

    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Error saving note:" << errorMessage;
        note->setSyncError(true);
        emit dataChanged(index(idx), index(idx), QVector<int>() << RoleLoading << RoleSyncError);
        return;
    }

    note->setUpdateSequenceNumber(result.updateSequenceNum);
    note->setLastSyncedSequenceNumber(result.updateSequenceNum);
    note->setTitle(QString::fromStdString(result.title));
    note->setNotebookGuid(QString::fromStdString(result.notebookGuid));
    note->setUpdated(QDateTime::fromMSecsSinceEpoch(result.updated));

    syncToCacheFile(note);

    QModelIndex noteIndex = index(m_notes.indexOf(note));
    emit dataChanged(noteIndex, noteIndex);
    emit noteChanged(note->guid(), note->notebookGuid());
}

void NotesStore::saveNotebookJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Notebook &result)
{
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "error saving notebook" << errorMessage;
        return;
    }

    Notebook *notebook = m_notebooksHash.value(QString::fromStdString(result.guid));
    if (!notebook) {
        qWarning() << "Save notebook job done but notebook can't be found any more!";
        return;
    }
    qDebug() << "save notebook done for:" << notebook->name() << notebook->lastSyncedSequenceNumber() << notebook->updateSequenceNumber() << result.updateSequenceNum;
    updateFromEDAM(result, notebook);
    notebook->setLoading(false);
    emit notebookChanged(notebook->guid());
    syncToCacheFile(notebook);
}

void NotesStore::deleteNote(const QString &guid)
{
    Note *note = m_notesHash.value(guid);
    if (!note) {
        qWarning() << "Note not found. Can't delete";
        return;
    }

    int idx = m_notes.indexOf(note);

    if (note->lastSyncedSequenceNumber() == 0) {
        emit noteRemoved(note->guid(), note->notebookGuid());
        beginRemoveRows(QModelIndex(), idx, idx);
        m_notes.takeAt(idx);
        m_notesHash.take(guid);
        endRemoveRows();
        emit countChanged();
        deleteFromCacheFile(note);
        note->deleteLater();
    } else {

        qDebug() << "setting note" << note << "to deleted" << idx;
        note->setDeleted(true);
        note->setUpdateSequenceNumber(note->updateSequenceNumber()+1);
        emit dataChanged(index(idx), index(idx), QVector<int>() << RoleDeleted);

        syncToCacheFile(note);
        if (EvernoteConnection::instance()->isConnected()) {
            DeleteNoteJob *job = new DeleteNoteJob(guid, this);
            connect(job, &DeleteNoteJob::jobDone, this, &NotesStore::deleteNoteJobDone);
            EvernoteConnection::instance()->enqueue(job);
        }
    }

    if (note->reminder() && !note->reminderDone()) {
        m_organizerAdapter->startSync();
    }
}

void NotesStore::findNotes(const QString &searchWords)
{
    foreach (Note *note, m_notes) {
        note->setIsSearchResult(false);
    }
    emit dataChanged(index(0), index(m_notes.count()), QVector<int>() << RoleIsSearchResult);

    FetchNotesJob *job = new FetchNotesJob(QString(), searchWords);
    connect(job, &FetchNotesJob::jobDone, this, &NotesStore::fetchNotesJobDone);
    EvernoteConnection::instance()->enqueue(job);
}

void NotesStore::clearSearchResults()
{
    foreach (Note *note, m_notes) {
        note->setIsSearchResult(false);
    }
    emit dataChanged(index(0), index(m_notes.count()-1), QVector<int>() << RoleIsSearchResult);
}

void NotesStore::deleteNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &guid)
{
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Cannot delete note:" << errorMessage;
        return;
    }
    Note *note = m_notesHash.value(guid);
    int noteIndex = m_notes.indexOf(note);

    emit noteRemoved(guid, note->notebookGuid());

    beginRemoveRows(QModelIndex(), noteIndex, noteIndex);
    m_notes.takeAt(noteIndex);
    m_notesHash.take(guid);
    endRemoveRows();
    emit countChanged();
    deleteFromCacheFile(note);
    note->deleteLater();
}

void NotesStore::expungeNotebookJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &guid)
{
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Error expunging notebook:" << errorMessage;
        return;
    }
    emit notebookRemoved(guid);
    Notebook *notebook = m_notebooksHash.take(guid);
    m_notebooks.removeAll(notebook);
    notebook->deleteLater();
}

void NotesStore::emitDataChanged()
{
    Note *note = qobject_cast<Note*>(sender());
    if (!note) {
        return;
    }
    int idx = m_notes.indexOf(note);
    emit dataChanged(index(idx), index(idx));
}

void NotesStore::clear()
{
    beginResetModel();
    foreach (Note *note, m_notes) {
        emit noteRemoved(note->guid(), note->notebookGuid());
        note->deleteLater();
    }
    m_notes.clear();
    m_notesHash.clear();
    endResetModel();

    while (!m_notebooks.isEmpty()) {
        Notebook *notebook = m_notebooks.takeFirst();
        m_notebooksHash.remove(notebook->guid());
        emit notebookRemoved(notebook->guid());
    }

    while (!m_tags.isEmpty()) {
        Tag *tag = m_tags.takeFirst();
        m_tagsHash.remove(tag->guid());
        emit tagRemoved(tag->guid());
    }
}

void NotesStore::syncToCacheFile(Note *note)
{
    qDebug() << "syncToCacheFile for note" << note->guid();
    QSettings cacheFile(m_cacheFile, QSettings::IniFormat);
    cacheFile.beginGroup("notes");
    cacheFile.setValue(note->guid(), note->updateSequenceNumber());
    cacheFile.endGroup();
    note->syncToInfoFile();
}

void NotesStore::deleteFromCacheFile(Note *note)
{
    QSettings cacheFile(m_cacheFile, QSettings::IniFormat);
    cacheFile.beginGroup("notes");
    cacheFile.remove(note->guid());
    cacheFile.endGroup();
    note->deleteFromCache();
}

void NotesStore::syncToCacheFile(Notebook *notebook)
{
    QSettings cacheFile(m_cacheFile, QSettings::IniFormat);
    cacheFile.beginGroup("notebooks");
    cacheFile.setValue(notebook->guid(), notebook->updateSequenceNumber());
    cacheFile.endGroup();
    notebook->syncToInfoFile();
}

void NotesStore::syncToCacheFile(Tag *tag)
{
    QSettings cacheFile(m_cacheFile, QSettings::IniFormat);
    cacheFile.beginGroup("tags");
    cacheFile.setValue(tag->guid(), tag->updateSequenceNumber());
    cacheFile.endGroup();
    tag->syncToInfoFile();
}

void NotesStore::loadFromCacheFile()
{
    clear();
    QSettings cacheFile(m_cacheFile, QSettings::IniFormat);

    cacheFile.beginGroup("notebooks");
    if (cacheFile.allKeys().count() > 0) {
        foreach (const QString &key, cacheFile.allKeys()) {
            Notebook *notebook = new Notebook(key, cacheFile.value(key).toUInt(), this);
            m_notebooksHash.insert(key, notebook);
            m_notebooks.append(notebook);
            emit notebookAdded(key);
        }
    }
    cacheFile.endGroup();

    cacheFile.beginGroup("tags");
    if (cacheFile.allKeys().count() > 0) {
        foreach (const QString &key, cacheFile.allKeys()) {
            Tag *tag = new Tag(key, cacheFile.value(key).toUInt(), this);
            m_tagsHash.insert(key, tag);
            m_tags.append(tag);
            emit tagAdded(key);
        }
    }
    cacheFile.endGroup();

    cacheFile.beginGroup("notes");
    if (cacheFile.allKeys().count() > 0) {
        beginInsertRows(QModelIndex(), 0, cacheFile.allKeys().count()-1);
        foreach (const QString &key, cacheFile.allKeys()) {
            if (m_notesHash.contains(key)) {
                qWarning() << "already have note. Not reloading from cache.";
                continue;
            }
            Note *note = new Note(key, cacheFile.value(key).toUInt(), this);
            m_notesHash.insert(key, note);
            m_notes.append(note);
            emit noteAdded(note->guid(), note->notebookGuid());
        }
        endInsertRows();
    }
    cacheFile.endGroup();
}

QVector<int> NotesStore::updateFromEDAM(const evernote::edam::NoteMetadata &evNote, Note *note)
{
    QVector<int> roles;
    if (note->guid() != QString::fromStdString(evNote.guid)) {
        note->setGuid(QString::fromStdString(evNote.guid));
        roles << RoleGuid;
    }

    if (evNote.__isset.title && note->title() != QString::fromStdString(evNote.title)) {
        note->setTitle(QString::fromStdString(evNote.title));
        roles << RoleTitle;
    }
    if (evNote.__isset.created && note->created() != QDateTime::fromMSecsSinceEpoch(evNote.created)) {
        note->setCreated(QDateTime::fromMSecsSinceEpoch(evNote.created));
        roles << RoleCreated;
    }
    if (evNote.__isset.updated && note->updated() != QDateTime::fromMSecsSinceEpoch(evNote.updated)) {
        note->setUpdated(QDateTime::fromMSecsSinceEpoch(evNote.updated));
        roles << RoleUpdated;
    }
    if (evNote.__isset.updateSequenceNum && note->updateSequenceNumber() != evNote.updateSequenceNum) {
        note->setUpdateSequenceNumber(evNote.updateSequenceNum);
    }
    if (evNote.__isset.notebookGuid && note->notebookGuid() != QString::fromStdString(evNote.notebookGuid)) {
        note->setNotebookGuid(QString::fromStdString(evNote.notebookGuid));
        roles << RoleNotebookGuid;
    }
    if (evNote.__isset.tagGuids) {
        QStringList tagGuids;
        for (quint32 i = 0; i < evNote.tagGuids.size(); i++) {
            tagGuids << QString::fromStdString(evNote.tagGuids.at(i));
        }
        if (note->tagGuids() != tagGuids) {
            note->setTagGuids(tagGuids);
            roles << RoleTagGuids;
        }
    }
    if (evNote.__isset.attributes && evNote.attributes.__isset.reminderTime) {
        QDateTime reminderTime;
        if (evNote.attributes.reminderTime > 0) {
            reminderTime = QDateTime::fromMSecsSinceEpoch(evNote.attributes.reminderTime);
        }
        if (note->reminderTime() != reminderTime) {
            note->setReminderTime(reminderTime);
            roles << RoleReminderTime;
        }
    }
    if (evNote.__isset.attributes && evNote.attributes.__isset.reminderDoneTime) {
        QDateTime reminderDoneTime;
        if (evNote.attributes.reminderDoneTime > 0) {
            reminderDoneTime = QDateTime::fromMSecsSinceEpoch(evNote.attributes.reminderDoneTime);
        }
        if (note->reminderDoneTime() != reminderDoneTime) {
            note->setReminderDoneTime(reminderDoneTime);
            roles << RoleReminderDoneTime;
        }
    }
    note->setLastSyncedSequenceNumber(evNote.updateSequenceNum);
    return roles;
}

void NotesStore::updateFromEDAM(const evernote::edam::Notebook &evNotebook, Notebook *notebook)
{
    if (evNotebook.__isset.guid && QString::fromStdString(evNotebook.guid) != notebook->guid()) {
        notebook->setGuid(QString::fromStdString(evNotebook.guid));
    }
    if (evNotebook.__isset.name && QString::fromStdString(evNotebook.name) != notebook->name()) {
        notebook->setName(QString::fromStdString(evNotebook.name));
    }
    if (evNotebook.__isset.updateSequenceNum && evNotebook.updateSequenceNum != notebook->updateSequenceNumber()) {
        notebook->setUpdateSequenceNumber(evNotebook.updateSequenceNum);
    }
    if (evNotebook.__isset.serviceUpdated && QDateTime::fromMSecsSinceEpoch(evNotebook.serviceUpdated) != notebook->lastUpdated()) {
        notebook->setLastUpdated(QDateTime::fromMSecsSinceEpoch(evNotebook.serviceUpdated));
    }
    if (evNotebook.__isset.published && evNotebook.published != notebook->published()) {
        notebook->setPublished(evNotebook.published);
    }
    notebook->setLastSyncedSequenceNumber(evNotebook.updateSequenceNum);
}
