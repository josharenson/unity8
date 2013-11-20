import QtQuick 2.0
import Ubuntu.Components 0.1
import "components"
import "ui"

/*!
    \brief MainView with a Label and Button elements.
*/

MainView {
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "mainView"

    // Note! applicationName needs to match the "name" field of the click manifest
    applicationName: "com.ubuntu.reminders-app"

    /*
     This property enables the application to change orientation
     when the device is rotated. The default is false.
    */
    //automaticOrientation: true

    width: units.gu(50)
    height: units.gu(75)

    // Temporary background color. This can be changed to other suitable backgrounds when we get official mockup designs
    backgroundColor: UbuntuColors.coolGrey

    PageStack {
        id: pagestack

        Tabs {
            id: rootTabs

            anchors.fill: parent

            Tab {
                title: i18n.tr("Notes")
                page: Notes {
                    id: notesPage
                }
            }

            Tab {
                title: i18n.tr("Notebook")
                page: Notebooks {
                    id: notebooksPage
                }
            }

            Tab {
                title: i18n.tr("Reminders")
                page: Reminders {
                    id: remindersPage
                }
            }
        }
    }
}
