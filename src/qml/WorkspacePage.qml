pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page
    property int serviceIndex: 0
    property int databaseIndex: 0
    readonly property bool hasApplicationController: typeof applicationController !== "undefined"
    readonly property var servicesModel: hasApplicationController ? applicationController.servicesModel : null
    readonly property var databases: []
    property string selectedServiceName: ""
    property string selectedServiceDisplayName: ""
    property int selectedServiceEngine: 0
    property int selectedServicePort: 0
    property int selectedServiceState: 0
    readonly property bool hasServiceSelection: selectedServiceName.length > 0
    readonly property var service: hasServiceSelection ? ({
        serviceName: selectedServiceName,
        name: selectedServiceDisplayName,
        engine: selectedServiceEngine,
        port: selectedServicePort,
        running: selectedServiceState === 1,
        databases: 0,
        version: ""
    }) : null
    readonly property var database: databases[databaseIndex] || null
    readonly property bool hasSelection: service !== null && database !== null
    readonly property bool offline: service === null || !service.running
    property bool managedOnly: false
    signal browseRequested
    signal actionRequested(string action)
    signal connectRequested(int engine, string displayName, int port, string serviceName)
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
                    text: page.hasApplicationController && applicationController.isScanningServices
                          ? "Discovering installed database services…"
                          : page.hasServiceSelection
                            ? (page.offline ? "This service is installed but currently stopped." : "Service is running. Connect to load its databases.")
                            : "Choose an installed database service to get started."
                    color: Theme.muted
                    font.pixelSize: 12
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ActionButton {
                text: "Refresh services"
                glyph: "refresh"
                enabled: page.hasApplicationController && !applicationController.isScanningServices
                onClicked: applicationController.refreshServices()
            }
            ActionButton {
                text: "New database"
                glyph: "plus"
                primary: true
                enabled: !page.offline
                hint: page.offline ? "Start the service before creating a database" : ""
                onClicked: page.actionRequested("New database")
            }
        }
        RowLayout {
            spacing: 14
            Rectangle {
                visible: page.hasApplicationController && applicationController.discoveredServiceCount === 0
                Layout.fillWidth: true
                implicitHeight: 116
                radius: 10
                color: Theme.panel
                border.color: Theme.line
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 7
                    Text {
                        text: applicationController.isScanningServices ? "Looking for local database services…" : "No PostgreSQL, MySQL, or MariaDB services found"
                        color: Theme.text
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: "Install or register a Windows database service, then refresh."
                        color: Theme.muted
                        font.pixelSize: 11
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
            Repeater {
                model: page.servicesModel
                delegate: ServiceCard {
                    required property int index
                    required property string serviceName
                    required property string displayName
                    required property int engine
                    required property int port
                    required property int serviceState
                    required property bool isRunning
                    required property bool canStart
                    Layout.fillWidth: true
                    service: ({
                        serviceName: serviceName,
                        name: displayName,
                        engine: engine,
                        port: port,
                        running: isRunning,
                        version: "",
                        color: engine === 0 ? Theme.blue : engine === 1 ? Theme.amber : Theme.accent
                    })
                    startAvailable: canStart
                    selected: page.serviceIndex === index
                    onClicked: {
                        page.serviceIndex = index;
                        page.databaseIndex = 0;
                        page.selectedServiceName = serviceName;
                        page.selectedServiceDisplayName = displayName;
                        page.selectedServiceEngine = engine;
                        page.selectedServicePort = port;
                        page.selectedServiceState = serviceState;
                    }
                    onServiceStateChanged: {
                        if (page.selectedServiceName === serviceName) {
                            page.selectedServiceState = serviceState;
                        }
                    }
                    onStartRequested: {
                        page.selectedServiceName = serviceName;
                        applicationController.startService(serviceName);
                    }
                    onConnectRequested: {
                        page.serviceIndex = index;
                        page.selectedServiceName = serviceName;
                        page.selectedServiceDisplayName = displayName;
                        page.selectedServiceEngine = engine;
                        page.selectedServicePort = port;
                        page.selectedServiceState = serviceState;
                        page.connectRequested(engine, displayName, port, serviceName);
                    }
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
                text: page.service ? page.service.name : "No connection selected"
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
                text: page.service ? String(page.service.databases) : "0"
                tone: Theme.muted
            }
            Tag {
                visible: page.offline
                text: "Offline"
                tone: Theme.amber
                dot: true
            }
            Item {
                Layout.fillWidth: true
            }
            Text {
                text: page.offline ? "No live service selected" : "Updated"
                color: page.offline ? Theme.amber : Theme.subtle
                font.pixelSize: 10
            }
            ActionButton {
                glyph: "refresh"
                quiet: true
                implicitHeight: 26
                hint: "Refresh databases"
                enabled: !page.offline
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
                        model: page.service ? page.databases.slice(0, page.service.databases).filter(d => (!page.managedOnly || d.managed) && d.name.toLowerCase().includes(search.text.toLowerCase())) : []
                        ScrollBar.vertical: ScrollBar {}
                        delegate: AbstractButton {
                            id: databaseRow
                            required property var modelData
                            width: ListView.view.width
                            implicitHeight: 66
                            hoverEnabled: true
                            readonly property bool selected: modelData.name === page.database.name
                            Accessible.name: modelData.name
                            onClicked: page.databaseIndex = page.databases.findIndex(d => d.name === modelData.name)
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
            Loader {
                visible: page.width >= 1010 && page.hasSelection
                active: page.hasSelection
                Layout.preferredWidth: 280
                Layout.fillHeight: true
                sourceComponent: DatabaseInspector {
                    database: page.database
                    service: page.service
                    onBrowseRequested: page.browseRequested()
                    onActionRequested: action => page.actionRequested(action)
                }
            }
        }
        RowLayout {
            visible: page.width < 1010
            Text {
                text: page.database ? page.database.name : "No database selected"
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
                text: page.offline ? "Viewer unavailable offline" : "Open table viewer"
                glyph: "table"
                primary: true
                enabled: !page.offline
                hint: page.offline ? "Cached summaries are available; tables require the service." : ""
                onClicked: page.browseRequested()
            }
        }
    }
}
