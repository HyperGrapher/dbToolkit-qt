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
            color: "#18232b"
            border.color: "#2a3b46"
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
                    text: "·  2 running, 1 stopped"
                    color: Theme.muted
                    font.pixelSize: 12
                }
                Item {
                    Layout.fillWidth: true
                }
                Tag {
                    text: "Sample environment"
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
                implicitHeight: 125
                radius: 10
                color: Theme.panel
                border.color: Theme.line
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 20
                    Rectangle {
                        implicitWidth: 52
                        implicitHeight: 52
                        radius: 13
                        color: "#242d3c"
                        Glyph {
                            anchors.centerIn: parent
                            implicitWidth: 28
                            implicitHeight: 28
                            ink: connectionCard.modelData.color
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        RowLayout {
                            spacing: 12
                            Text {
                                text: connectionCard.modelData.name + " local"
                                color: Theme.text
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                            }
                            Tag {
                                text: connectionCard.modelData.running ? "Connected" : "Offline"
                                dot: true
                                tone: connectionCard.modelData.running ? Theme.green : Theme.subtle
                            }
                        }
                        Text {
                            text: "localhost:" + connectionCard.modelData.port + "   /   " + (connectionCard.index === 0 ? "postgres" : "root")
                            color: Theme.muted
                            font.family: Theme.mono
                            font.pixelSize: 11
                        }
                        Text {
                            text: connectionCard.modelData.databases + " databases  ·  " + connectionCard.modelData.name + " " + connectionCard.modelData.version
                            color: Theme.subtle
                            font.pixelSize: 10
                        }
                    }
                    ActionButton {
                        glyph: "settings"
                        hint: "Edit connection"
                        quiet: true
                        onClicked: page.actionRequested("Edit connection")
                    }
                    ActionButton {
                        text: "Open"
                        glyph: "arrow"
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
                text: "Services and connections are illustrative. No local servers have been contacted."
                color: Theme.subtle
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }
}
