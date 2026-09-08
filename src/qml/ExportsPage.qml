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
                    text: "Exports"
                    color: Theme.text
                    font.pixelSize: 29
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.6
                }
                Text {
                    text: "A clean snapshot. Ready for whatever comes next."
                    color: Theme.muted
                    font.pixelSize: 12
                }
            }
            Item {
                Layout.fillWidth: true
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
            implicitHeight: 158
            radius: 11
            color: "#1b2638"
            border.color: "#334966"
            RowLayout {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 24
                Rectangle {
                    implicitWidth: 66
                    implicitHeight: 66
                    radius: 16
                    color: "#293c59"
                    Glyph {
                        anchors.centerIn: parent
                        name: "download"
                        implicitWidth: 32
                        implicitHeight: 32
                        ink: Theme.accent
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        text: "Take your work with you."
                        color: Theme.text
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: "Export your schema and data to a portable SQL file.\nYour next environment is one snapshot away."
                        color: Theme.muted
                        font.pixelSize: 12
                        lineHeight: 1.5
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
                        }
                        Tag {
                            text: "Complete"
                            tone: Theme.green
                            dot: true
                        }
                        ActionButton {
                            glyph: "folder"
                            quiet: true
                            hint: "Show export location"
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
            text: "Sample export history. No SQL files have been created."
            color: Theme.subtle
            font.pixelSize: 11
        }
    }
}
