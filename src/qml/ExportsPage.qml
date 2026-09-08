pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

Item {
    id: page
    signal actionRequested(string action)

    ColumnLayout {
        anchors.fill: parent
        spacing: 24
        RowLayout {
            ColumnLayout {
                spacing: 6
                Text {
                    text: "SQL files"
                    color: Theme.text
                    font.pixelSize: 29
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.6
                }
                Text {
                    text: "Move schema and data where your work needs it."
                    color: Theme.muted
                    font.pixelSize: 12
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ActionButton {
                text: "Import SQL"
                glyph: "upload"
                onClicked: page.actionRequested("Import SQL")
            }
            ActionButton {
                text: "Export database"
                glyph: "download"
                primary: true
                onClicked: page.actionRequested("Export database")
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 142
            radius: 11
            color: Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.12)
            border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35)
            RowLayout {
                anchors.fill: parent
                anchors.margins: 26
                spacing: 22
                Rectangle {
                    implicitWidth: 60
                    implicitHeight: 60
                    radius: 15
                    color: Theme.selected
                    Glyph {
                        anchors.centerIn: parent
                        name: "code"
                        implicitWidth: 30
                        implicitHeight: 30
                        ink: Theme.accent
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        text: "Bring a database forward."
                        color: Theme.text
                        font.pixelSize: 21
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: "Import into a new database or merge into the selected one.\nThe file's embedded database name never changes your chosen target."
                        color: Theme.muted
                        font.pixelSize: 12
                        lineHeight: 1.45
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
                Tag {
                    text: ".sql"
                    tone: Theme.accent
                }
            }
        }

        RowLayout {
            Text {
                text: "Recent exports"
                color: Theme.text
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }
            Item {
                Layout.fillWidth: true
            }
            Tag {
                text: "Illustrative history"
                tone: Theme.muted
            }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 240
            radius: 9
            color: Theme.panel
            border.color: Theme.line
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 0
                Repeater {
                    model: [
                        {
                            name: "atlas_dev",
                            date: "Today, 10:42",
                            size: "18.6 MB"
                        },
                        {
                            name: "storefront",
                            date: "Yesterday, 16:08",
                            size: "12.3 MB"
                        },
                        {
                            name: "analytics_local",
                            date: "Sep 6, 09:30",
                            size: "42.1 MB"
                        }
                    ]
                    delegate: RowLayout {
                        id: exportRow
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 16
                        Glyph {
                            name: "code"
                            ink: Theme.accent
                            implicitWidth: 23
                            implicitHeight: 23
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            Text {
                                text: exportRow.modelData.name + ".sql"
                                color: Theme.text
                                font.pixelSize: 13
                            }
                            Text {
                                text: "Schema & data  ·  " + exportRow.modelData.date
                                color: Theme.subtle
                                font.pixelSize: 11
                            }
                        }
                        Text {
                            text: exportRow.modelData.size
                            color: Theme.muted
                            font.family: Theme.mono
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignRight
                            Layout.preferredWidth: 76
                        }
                        Item {
                            Layout.preferredWidth: 90
                            implicitHeight: 24
                            Tag {
                                anchors.right: parent.right
                                text: "Complete"
                                tone: Theme.green
                                dot: true
                            }
                        }
                        ActionButton {
                            glyph: "folder"
                            quiet: true
                            hint: "Show export location"
                            Layout.preferredWidth: 38
                            onClicked: page.actionRequested("Show export location")
                        }
                    }
                }
            }
        }
        Item {
            Layout.fillHeight: true
        }
        Text {
            text: "Sample export history. No SQL files have been created or imported."
            color: Theme.subtle
            font.pixelSize: 11
        }
    }
}
