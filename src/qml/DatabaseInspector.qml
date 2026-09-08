pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: inspector
    required property var database
    required property var service
    signal browseRequested
    signal actionRequested(string action)
    color: Theme.panel
    radius: 10
    border.color: Theme.line
    ScrollView {
        anchors.fill: parent
        anchors.margins: 20
        anchors.bottomMargin: 122
        contentWidth: availableWidth
        clip: true
        ColumnLayout {
            width: parent.width
            spacing: 12
            RowLayout {
                Text {
                    text: "DATABASE DETAILS"
                    color: Theme.subtle
                    font.pixelSize: 10
                    font.letterSpacing: 1.1
                }
                Item {
                    Layout.fillWidth: true
                }
                Glyph {
                    name: "database"
                    implicitWidth: 15
                    implicitHeight: 15
                    ink: Theme.subtle
                }
            }
            RowLayout {
                spacing: 12
                Rectangle {
                    implicitWidth: 42
                    implicitHeight: 42
                    radius: 10
                    color: "#253450"
                    Text {
                        anchors.centerIn: parent
                        text: inspector.database.letter
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                        color: inspector.database.color
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    Text {
                        text: inspector.database.name
                        color: Theme.text
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: inspector.service.name + " · " + inspector.service.version
                        color: Theme.muted
                        font.pixelSize: 11
                    }
                }
            }
            Tag {
                text: inspector.database.managed ? "Managed by dbToolKit" : "Existing database"
                tone: inspector.database.managed ? Theme.accent : Theme.muted
                dot: true
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.line
            }
            Repeater {
                model: [
                    {
                        label: "Size",
                        value: inspector.database.size
                    },
                    {
                        label: "Tables",
                        value: String(inspector.database.tables)
                    },
                    {
                        label: inspector.service.name === "PostgreSQL" ? "Owner" : "Project user",
                        value: inspector.database.owner
                    },
                    {
                        label: "Encoding",
                        value: inspector.service.name === "PostgreSQL" ? "UTF8" : "utf8mb4"
                    },
                    {
                        label: "Environment",
                        value: "Development"
                    }
                ]
                delegate: RowLayout {
                    id: detailRow
                    required property var modelData
                    Layout.fillWidth: true
                    Text {
                        text: detailRow.modelData.label
                        color: Theme.muted
                        font.pixelSize: 11
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Text {
                        text: detailRow.modelData.value
                        color: Theme.text
                        font.pixelSize: 11
                        font.family: Theme.mono
                        elide: Text.ElideRight
                        Layout.maximumWidth: 160
                    }
                }
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.line
            }
            RowLayout {
                Text {
                    text: "CONNECTION"
                    color: Theme.subtle
                    font.pixelSize: 10
                    font.letterSpacing: 1.1
                }
                Item {
                    Layout.fillWidth: true
                }
                ActionButton {
                    glyph: "copy"
                    quiet: true
                    implicitWidth: 24
                    implicitHeight: 24
                    hint: "Copy connection string"
                    onClicked: inspector.actionRequested("Copy connection")
                }
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 66
                radius: 6
                color: Theme.background
                border.color: Theme.line
                Text {
                    anchors.fill: parent
                    anchors.margins: 12
                    text: (inspector.service.name === "PostgreSQL" ? "postgresql" : "mysql") + "://localhost:" + inspector.service.port + "/\n" + inspector.database.name
                    color: Theme.muted
                    font.family: Theme.mono
                    font.pixelSize: 10
                    wrapMode: Text.WrapAnywhere
                    lineHeight: 1.5
                }
            }
            Text {
                text: "PROJECT NOTE"
                color: Theme.subtle
                font.pixelSize: 10
                font.letterSpacing: 1.1
            }
            Text {
                text: inspector.database.note
                color: Theme.muted
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                lineHeight: 1.45
            }
        }
    }
    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        spacing: 10
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.line
        }
        ActionButton {
            text: "Open table viewer"
            glyph: "table"
            primary: true
            Layout.fillWidth: true
            onClicked: inspector.browseRequested()
        }
        RowLayout {
            Layout.fillWidth: true
            ActionButton {
                text: "Export"
                glyph: "download"
                Layout.fillWidth: true
                onClicked: inspector.actionRequested("Export database")
            }
            ActionButton {
                glyph: "more"
                hint: "Database actions"
                onClicked: inspector.actionRequested("Database actions")
            }
        }
    }
}
