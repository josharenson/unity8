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
 */

import QtQuick 2.0
import Ubuntu.Components 0.1
import com.canonical.Oxide 1.0 
import Evernote 0.1
import "../components"

Item {
    id: root
    property string title: note.title
    property var note

    signal editNote(var note)

    onNoteChanged: {
        print("refreshing note:", root.note.guid)
        NotesStore.refreshNoteContent(root.note.guid)
    }

    ActivityIndicator {
        anchors.centerIn: parent
        running: root.note.loading
        visible: running
    }

    WebContext {
        id: webContext 

        userScripts: [
            UserScript {
                url: Qt.resolvedUrl("reminders-scripts.js");
            }
        ]
    }

    WebView {
        id: noteTextArea
        anchors { fill: parent}

        property string html: note.htmlContent
        
        onHtmlChanged: {
            loadHtml(html, "file:///")
        }

        context: webContext
        preferences.standardFontFamily: 'Ubuntu'
        preferences.minimumFontSize: 14

        Connections {
            target: note
            onResourcesChanged: {
                noteTextArea.loadHtml(noteTextArea.html, "file:///")
            }
        }

        messageHandlers: [
            ScriptMessageHandler {
                callback: function(message) {
                    var data = null;
                    try {
                        data = JSON.parse(message.data);
                    } catch (error) {
                        print("Failed to parse message:", message.data, error);
                    }

                    switch (data.type) {
                        case "checkboxChanged":
                        note.markTodo(data.todoId, data.checked);
                        NotesStore.saveNote(note.guid);
                        break;
                    }
                } 
            }
        ]
     }
}
