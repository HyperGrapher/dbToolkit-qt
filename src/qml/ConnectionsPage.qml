pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

Item {
    id: page
    signal actionRequested(string action)
    signal openRequested(int serviceIndex)
    readonly property bool hasLiveConnections: typeof applicationController !== "undefined"

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
                    text: page.hasLiveConnections ? "Saved connections" : "No saved connections"
                    color: Theme.text
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
                Text {
                    text: page.hasLiveConnections ? "Add a connection to get started" : "Add a connection to begin"
                    color: Theme.muted
                    font.pixelSize: 12
                }
                Item {
                    Layout.fillWidth: true
                }
                Tag {
                    text: "Live session"
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
            visible: page.hasLiveConnections
            model: page.hasLiveConnections ? applicationController.connectionsModel : null
            delegate: Rectangle {
                id: liveConnectionCard
                visible: page.hasLiveConnections
                required property string displayName
                required property string connectionId
                required property int engine
                required property string host
                required property int port
                required property string administratorUser
                required property int connectionState
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
                            ink: liveConnectionCard.engine === 0 ? Theme.blue : Theme.amber
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 7
                        Text {
                            text: liveConnectionCard.displayName
                            color: Theme.text
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: liveConnectionCard.host + ":" + liveConnectionCard.port + "   /   " + liveConnectionCard.administratorUser
                            color: Theme.muted
                            font.family: Theme.mono
                            font.pixelSize: 11
                        }
                        Text {
                            text: liveConnectionCard.connectionState === 0 ? "Not tested in this session" : "Tested in this session · credentials stay in memory only"
                            color: Theme.subtle
                            font.pixelSize: 10
                        }
                    }
                    Tag {
                        Layout.preferredWidth: 94
                        text: liveConnectionCard.connectionState === 1 ? "Connected" : liveConnectionCard.connectionState === 2 ? "Offline" : "Not tested"
                        dot: true
                        tone: liveConnectionCard.connectionState === 1 ? Theme.green : liveConnectionCard.connectionState === 2 ? Theme.red : Theme.amber
                    }
                    ActionButton {
                        glyph: "settings"
                        hint: "Edit connection"
                        quiet: true
                        Layout.preferredWidth: 38
                        onClicked: page.actionRequested("Edit connection")
                    }
                    ActionButton {
                        text: "Test"
                        glyph: "arrow"
                        Layout.preferredWidth: 86
                        onClicked: {
                            applicationController.activeConnectionId = liveConnectionCard.connectionId;
                            applicationController.testActiveConnection();
                        }
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
                text: "Passwords remain in memory for the current session until encrypted vault storage is enabled."
                color: Theme.subtle
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }
}
