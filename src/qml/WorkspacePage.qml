pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page
    property int serviceIndex: 0
    property int databaseIndex: 0
    readonly property var service: PreviewData.services[serviceIndex]
    readonly property var database: PreviewData.databases[databaseIndex]
    property bool managedOnly: false
    signal browseRequested
    signal actionRequested(string action)
    ColumnLayout {
        anchors.fill: parent
        spacing: 22
        RowLayout {
            ColumnLayout {
                spacing: 6
                Text {
                    text: "Local workspace"
                    color: Theme.text
                    font.pixelSize: 29
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.6
                }
                Text {
                    text: "A clear view of your development databases."
                    color: Theme.muted
                    font.pixelSize: 12
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ActionButton {
                text: "New database"
                glyph: "plus"
                primary: true
                onClicked: page.actionRequested("New database")
            }
        }
        RowLayout {
            spacing: 14
            Repeater {
                model: PreviewData.services
                delegate: ServiceCard {
                    required property int index
                    required property var modelData
                    Layout.fillWidth: true
                    service: modelData
                    selected: page.serviceIndex === index
                    onClicked: {
                        page.serviceIndex = index;
                        page.databaseIndex = 0;
                    }
                    onPowerRequested: page.actionRequested(modelData.running ? "Stop service" : "Start service")
                }
            }
        }
        RowLayout {
            spacing: 9
            Glyph {
                name: "database"
                ink: Theme.accent
                implicitWidth: 18
                implicitHeight: 18
            }
            Text {
                text: page.service.name
                color: Theme.text
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
            Text {
                text: "/"
                color: Theme.subtle
                font.pixelSize: 15
            }
            Text {
                text: "Databases"
                color: Theme.muted
                font.pixelSize: 15
            }
            Tag {
                text: String(page.service.databases)
                tone: Theme.muted
            }
            Item {
                Layout.fillWidth: true
            }
            Text {
                text: "Updated just now"
                color: Theme.subtle
                font.pixelSize: 10
            }
            ActionButton {
                glyph: "refresh"
                quiet: true
                implicitHeight: 26
                hint: "Refresh databases"
                onClicked: page.actionRequested("Refresh")
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 18
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.panel
                border.color: Theme.line
                radius: 10
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0
                    RowLayout {
                        Layout.margins: 16
                        spacing: 10
                        SearchInput {
                            id: search
                            placeholderText: "Find a database…"
                            Layout.fillWidth: true
                            implicitWidth: 160
                        }
                        ActionButton {
                            text: page.managedOnly ? "Managed" : "All databases"
                            glyph: "filter"
                            onClicked: page.managedOnly = !page.managedOnly
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Theme.line
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 20
                        Layout.rightMargin: 20
                        Layout.preferredHeight: 38
                        Text {
                            text: "DATABASE"
                            color: Theme.subtle
                            font.pixelSize: 9
                            font.letterSpacing: 0.8
                            Layout.fillWidth: true
                        }
                        Text {
                            text: "SIZE"
                            color: Theme.subtle
                            font.pixelSize: 9
                            Layout.preferredWidth: 80
                        }
                        Text {
                            text: "TABLES"
                            color: Theme.subtle
                            font.pixelSize: 9
                            Layout.preferredWidth: 45
                        }
                        Text {
                            text: "STATUS"
                            color: Theme.subtle
                            font.pixelSize: 9
                            Layout.preferredWidth: 75
                        }
                    }
                    ListView {
                        id: databaseList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: PreviewData.databases.slice(0, page.service.databases).filter(d => (!page.managedOnly || d.managed) && d.name.toLowerCase().includes(search.text.toLowerCase()))
                        ScrollBar.vertical: ScrollBar {}
                        delegate: AbstractButton {
                            id: databaseRow
                            required property var modelData
                            width: ListView.view.width
                            implicitHeight: 66
                            hoverEnabled: true
                            readonly property bool selected: modelData.name === page.database.name
                            Accessible.name: modelData.name
                            onClicked: page.databaseIndex = PreviewData.databases.findIndex(d => d.name === modelData.name)
                            onDoubleClicked: page.browseRequested()
                            background: Rectangle {
                                color: databaseRow.selected ? "#202d43" : databaseRow.hovered ? Theme.raised : "transparent"
                                Rectangle {
                                    implicitWidth: 2
                                    height: parent.height - 20
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Theme.accent
                                    visible: databaseRow.selected || databaseRow.visualFocus
                                }
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    implicitHeight: 1
                                    color: "#232933"
                                }
                            }
                            contentItem: RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 20
                                anchors.rightMargin: 20
                                spacing: 10
                                Rectangle {
                                    implicitWidth: 31
                                    implicitHeight: 34
                                    radius: 7
                                    color: "#29313d"
                                    Glyph {
                                        anchors.centerIn: parent
                                        implicitWidth: 18
                                        implicitHeight: 18
                                        ink: databaseRow.modelData.color
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 5
                                    Text {
                                        text: databaseRow.modelData.name
                                        color: databaseRow.selected ? "#b9cfff" : Theme.text
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: databaseRow.modelData.managed ? databaseRow.modelData.owner : "Existing database"
                                        color: Theme.subtle
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                                Text {
                                    text: databaseRow.modelData.size
                                    color: Theme.muted
                                    font.family: Theme.mono
                                    font.pixelSize: 10
                                    Layout.preferredWidth: 80
                                }
                                Text {
                                    text: databaseRow.modelData.tables
                                    color: Theme.muted
                                    font.family: Theme.mono
                                    font.pixelSize: 10
                                    Layout.preferredWidth: 45
                                }
                                Item {
                                    Layout.preferredWidth: 75
                                    implicitHeight: 24
                                    Tag {
                                        text: databaseRow.modelData.managed ? "Managed" : "Existing"
                                        tone: databaseRow.modelData.managed ? Theme.accent : Theme.subtle
                                    }
                                }
                            }
                        }
                        Column {
                            anchors.centerIn: parent
                            spacing: 10
                            visible: databaseList.count === 0
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "No databases found"
                                color: Theme.text
                                font.pixelSize: 15
                            }
                            Text {
                                text: "Try another name or show all databases."
                                color: Theme.muted
                                font.pixelSize: 11
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Theme.line
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: 16
                        Text {
                            text: databaseList.count + " databases"
                            color: Theme.subtle
                            font.pixelSize: 10
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        Text {
                            text: "Double-click to explore"
                            color: Theme.subtle
                            font.pixelSize: 10
                        }
                    }
                }
            }
            DatabaseInspector {
                visible: page.width >= 1010
                Layout.preferredWidth: 280
                Layout.fillHeight: true
                database: page.database
                service: page.service
                onBrowseRequested: page.browseRequested()
                onActionRequested: action => page.actionRequested(action)
            }
        }
        RowLayout {
            visible: page.width < 1010
            Text {
                text: page.database.name
                color: Theme.accent
                font.pixelSize: 12
            }
            Item {
                Layout.fillWidth: true
            }
            ActionButton {
                text: "Details"
                onClicked: page.actionRequested("Database details")
            }
            ActionButton {
                text: "Open table viewer"
                glyph: "table"
                primary: true
                onClicked: page.browseRequested()
            }
        }
    }
}
