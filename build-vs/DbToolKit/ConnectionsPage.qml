pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

Item {
    id: page
    signal actionRequested(string action)
    signal openRequested(int serviceIndex)

    ColumnLayout {
        anchors.fill: parent
        spacing: 24

        RowLayout {
            ColumnLayout {
                spacing: 6
                Text {
                    text: "Connections"
                    color: Theme.text
                    font.pixelSize: 29
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.6
                }
                Text {
                    text: "Your local servers. One familiar place."
                    color: Theme.muted
                    font.pixelSize: 12
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ActionButton {
                text: "Add connection"
                glyph: "plus"
                primary: true
                onClicked: page.actionRequested("Add connection")
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 58
            radius: 8
            color: Qt.rgba(Theme.green.r, Theme.green.g, Theme.green.b, 0.08)
            border.color: Qt.rgba(Theme.green.r, Theme.green.g, Theme.green.b, 0.22)
            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12
                Glyph {
                    name: "server"
                    ink: Theme.green
                }
                Text {
                    text: "3 local services"
                    color: Theme.text
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
                Text {
                    text: "·  2 running, 1 cached offline"
                    color: Theme.muted
                    font.pixelSize: 12
                }
                Item {
                    Layout.fillWidth: true
                }
                Tag {
                    text: "Preview data"
                    tone: Theme.green
                }
            }
        }

        Text {
            text: "SAVED CONNECTIONS"
            color: Theme.subtle
            font.pixelSize: 10
            font.letterSpacing: 1.1
        }
        Repeater {
            model: PreviewData.services
            delegate: Rectangle {
                id: connectionCard
                required property int index
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 114
                radius: 10
                color: Theme.panel
                border.color: Theme.line
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 22
                    spacing: 16
                    Rectangle {
                        implicitWidth: 48
                        implicitHeight: 48
                        radius: 12
                        color: Theme.raised
                        Glyph {
                            anchors.centerIn: parent
                            name: "database"
                            implicitWidth: 26
                            implicitHeight: 26
                            ink: connectionCard.modelData.color
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 7
                        Text {
                            text: connectionCard.modelData.name + " local"
                            color: Theme.text
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: "localhost:" + connectionCard.modelData.port + "   /   " + (connectionCard.index === 0 ? "postgres" : "root")
                            color: Theme.muted
                            font.family: Theme.mono
                            font.pixelSize: 11
                        }
                        Text {
                            text: connectionCard.modelData.running ? connectionCard.modelData.databases + " live databases" : connectionCard.modelData.databases + " cached databases · refreshed 18 min ago"
                            color: Theme.subtle
                            font.pixelSize: 10
                        }
                    }
                    Tag {
                        Layout.preferredWidth: 94
                        text: connectionCard.modelData.running ? "Connected" : "Cached offline"
                        dot: true
                        tone: connectionCard.modelData.running ? Theme.green : Theme.amber
                    }
                    ActionButton {
                        glyph: "settings"
                        hint: "Edit connection"
                        quiet: true
                        Layout.preferredWidth: 38
                        onClicked: page.actionRequested("Edit connection")
                    }
                    ActionButton {
                        text: "Open"
                        glyph: "arrow"
                        Layout.preferredWidth: 86
                        onClicked: page.openRequested(connectionCard.index)
                    }
                }
            }
        }
        Item {
            Layout.fillHeight: true
        }
        RowLayout {
            spacing: 9
            Glyph {
                name: "info"
                implicitWidth: 15
                implicitHeight: 15
                ink: Theme.subtle
            }
            Text {
                text: "Passwords are requested during first connection setup. This preview never stores or sends them."
                color: Theme.subtle
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }
}
