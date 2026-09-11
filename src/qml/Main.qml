pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    width: 1440
    height: 900
    minimumWidth: 1000
    minimumHeight: 650
    visible: true
    title: "dbToolKit"
    color: Theme.background
    font.family: "Segoe UI"
    font.pixelSize: 12
    property int currentPage: 0
    readonly property var pageNames: ["Workspace", "Connections", "Table viewer", "Exports", "Settings"]
    property alias workspace: workspacePage
    property alias viewer: viewerPage
    property alias previewPopup: previewDialog

    palette.window: Theme.background
    palette.windowText: Theme.text
    palette.base: Theme.panel
    palette.alternateBase: Theme.raised
    palette.text: Theme.text
    palette.button: Theme.raised
    palette.buttonText: Theme.text
    palette.highlight: Theme.blue
    palette.highlightedText: "#ffffff"
    palette.mid: Theme.line
    palette.dark: Theme.background
    palette.light: Theme.raised

    function showAction(action) {
        if (["Refresh", "Copy connection", "Copy cell", "Show export location", "Rows per page", "When closing the window", "Export tools"].includes(action)) {
            toast.text = action + " is not available until a live connection is selected.";
            toast.open();
            return;
        }
        if (action === "Add connection") {
            previewDialog.prepareConnection(0, "", 5432, "");
        }
        previewDialog.kind = action;
        previewDialog.open();
    }

    function openViewerFromWorkspace(databaseName) {
        applicationController.openDatabase(databaseName);
        currentPage = 2;
    }

    Shortcut {
        sequence: "Ctrl+1"
        onActivated: window.currentPage = 0
    }
    Shortcut {
        sequence: "Ctrl+2"
        onActivated: window.currentPage = 1
    }
    Shortcut {
        sequence: "Ctrl+3"
        onActivated: window.currentPage = 2
    }

    Rectangle {
        id: sidebar
        implicitWidth: 214
        anchors.top: parent.top
        anchors.bottom: statusBar.top
        anchors.left: parent.left
        color: Theme.sidebar
        Rectangle {
            anchors.right: parent.right
            height: parent.height
            implicitWidth: 1
            color: Theme.line
        }
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 10
            RowLayout {
                Layout.topMargin: 11
                Layout.leftMargin: 9
                Layout.bottomMargin: 32
                spacing: 10
                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 36
                    radius: 9
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: Theme.accent
                        }
                        GradientStop {
                            position: 1
                            color: Theme.blue
                        }
                    }
                    Glyph {
                        anchors.centerIn: parent
                        implicitWidth: 22
                        implicitHeight: 22
                        ink: "#ffffff"
                    }
                }
                Text {
                    text: "dbToolKit"
                    color: Theme.text
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.7
                }
            }
            Text {
                text: "WORKSPACE"
                color: Theme.subtle
                font.pixelSize: 9
                font.letterSpacing: 1.1
                Layout.leftMargin: 12
                Layout.bottomMargin: 6
            }
            Repeater {
                model: [
                    {
                        title: "Overview",
                        glyph: "grid"
                    },
                    {
                        title: "Connections",
                        glyph: "server"
                    },
                    {
                        title: "Table viewer",
                        glyph: "table"
                    },
                    {
                        title: "Exports",
                        glyph: "download"
                    }
                ]
                delegate: AbstractButton {
                    id: navButton
                    required property int index
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 42
                    hoverEnabled: true
                    Accessible.name: modelData.title
                    onClicked: window.currentPage = index
                    background: Rectangle {
                        radius: 7
                        color: window.currentPage === navButton.index ? Theme.selected : navButton.hovered ? Theme.raised : "transparent"
                        border.color: navButton.visualFocus ? Theme.accent : window.currentPage === navButton.index ? Theme.accent : "transparent"
                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                    }
                    contentItem: RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 13
                        anchors.rightMargin: 12
                        spacing: 12
                        Glyph {
                            name: navButton.modelData.glyph
                            implicitWidth: 17
                            implicitHeight: 17
                            ink: window.currentPage === navButton.index ? Theme.accent : Theme.subtle
                        }
                        Text {
                            text: navButton.modelData.title
                            color: window.currentPage === navButton.index ? Theme.accent : Theme.muted
                            font.pixelSize: 12
                            font.weight: window.currentPage === navButton.index ? Font.DemiBold : Font.Normal
                            Layout.fillWidth: true
                        }
                        Text {
                            visible: navButton.index === 1
                            text: "3"
                            color: Theme.subtle
                            font.pixelSize: 10
                        }
                    }
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.bottomMargin: 16
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                implicitHeight: 1
                color: Theme.line
            }
            RowLayout {
                Layout.leftMargin: 12
                Layout.rightMargin: 7
                Layout.bottomMargin: 4
                Text {
                    text: "LOCAL SERVERS"
                    color: Theme.subtle
                    font.pixelSize: 9
                    font.letterSpacing: 1.1
                }
                Item {
                    Layout.fillWidth: true
                }
                ActionButton {
                    glyph: "plus"
                    quiet: true
                    implicitWidth: 22
                    implicitHeight: 22
                    hint: "Add connection"
                    onClicked: window.showAction("Add connection")
                }
            }
            Item {
                Layout.fillHeight: true
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 86
                visible: window.height >= 780
                radius: 8
                color: Theme.raised
                border.color: Theme.line
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 13
                    spacing: 6
                    RowLayout {
                        Glyph {
                            name: "code"
                            implicitWidth: 15
                            implicitHeight: 15
                            ink: Theme.accent
                        }
                        Text {
                            text: "Made for local."
                            color: Theme.text
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }
                    }
                    Text {
                        text: "Your projects. Your machine.\nA little more in focus."
                        color: Theme.subtle
                        font.pixelSize: 10
                        lineHeight: 1.4
                    }
                }
            }
            ActionButton {
                text: "Settings"
                glyph: "settings"
                quiet: window.currentPage !== 4
                Layout.fillWidth: true
                Layout.topMargin: 9
                onClicked: window.currentPage = 4
            }
        }
    }

    Rectangle {
        id: topBar
        anchors.left: sidebar.right
        anchors.right: parent.right
        anchors.top: parent.top
        implicitHeight: 65
        color: Theme.background
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            implicitHeight: 1
            color: Theme.line
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 30
            anchors.rightMargin: 30
            spacing: 12
            Glyph {
                name: "folder"
                implicitWidth: 15
                implicitHeight: 15
                ink: Theme.subtle
            }
            Text {
                text: "Local"
                color: Theme.subtle
                font.pixelSize: 11
            }
            Glyph {
                name: "chevron"
                implicitWidth: 12
                implicitHeight: 12
                ink: Theme.subtle
            }
            Text {
                text: window.pageNames[window.currentPage]
                color: Theme.text
                font.pixelSize: 11
            }
            Item {
                Layout.fillWidth: true
            }
            Tag {
                text: "LOCAL DATABASES"
                tone: Theme.accent
            }
            Rectangle {
                implicitWidth: 1
                implicitHeight: 17
                color: Theme.line
                Layout.leftMargin: 8
                Layout.rightMargin: 8
            }
            Rectangle {
                implicitWidth: 6
                implicitHeight: 6
                radius: 3
                color: Theme.green
            }
            Text {
                text: "Local environment"
                color: Theme.muted
                font.pixelSize: 10
            }
        }
    }

    ScrollView {
        id: pageScroll
        anchors.left: sidebar.right
        anchors.right: parent.right
        anchors.top: topBar.bottom
        anchors.bottom: statusBar.top
        anchors.margins: 30
        clip: true
        contentWidth: availableWidth
        contentHeight: Math.max(availableHeight, 700)
        StackLayout {
            width: pageScroll.availableWidth
            height: Math.max(pageScroll.availableHeight, 700)
            currentIndex: window.currentPage
            WorkspacePage {
                id: workspacePage
                onBrowseRequested: databaseName => window.openViewerFromWorkspace(databaseName)
                onActionRequested: action => window.showAction(action)
                onConnectRequested: (engine, displayName, port, serviceName) => {
                    if (applicationController.connectSavedService(serviceName)) {
                        return;
                    }
                    previewDialog.prepareConnection(engine, displayName, port, serviceName);
                    previewDialog.kind = "Add connection";
                    previewDialog.open();
                }
            }
            ConnectionsPage {
                onActionRequested: action => window.showAction(action)
                onEditRequested: connectionId => {
                    const details = applicationController.connectionDetails(connectionId);
                    if (!details.connectionId) {
                        toast.text = "The selected connection no longer exists.";
                        toast.open();
                        return;
                    }
                    previewDialog.prepareExistingConnection(details);
                    previewDialog.kind = "Edit connection";
                    previewDialog.open();
                }
                onOpenRequested: serviceIndex => {
                    workspacePage.serviceIndex = serviceIndex;
                    workspacePage.databaseIndex = 0;
                    window.currentPage = 0;
                }
            }
            ViewerPage {
                id: viewerPage
                onActionRequested: action => window.showAction(action)
            }
            ExportsPage {
                onActionRequested: action => window.showAction(action)
            }
            SettingsPage {
                onActionRequested: action => window.showAction(action)
            }
        }
    }

    Rectangle {
        id: statusBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        implicitHeight: 29
        color: Theme.sidebar
        Rectangle {
            width: parent.width
            implicitHeight: 1
            color: Theme.line
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 22
            anchors.rightMargin: 22
            spacing: 8
            Glyph {
                name: "code"
                implicitWidth: 13
                implicitHeight: 13
                ink: Theme.subtle
            }
            Text {
                text: applicationController.isBusy ? "Working…" : "Ready"
                color: Theme.muted
                font.pixelSize: 9
            }
            Text {
                text: "·  " + (applicationController.activeConnectionName.length > 0
                               ? applicationController.activeConnectionName
                               : "No active connection")
                color: Theme.subtle
                font.pixelSize: 9
            }
            Item {
                Layout.fillWidth: true
            }
            Text {
                text: applicationController.activeDatabaseName.length > 0
                      ? applicationController.activeDatabaseName
                      : "No active database"
                color: Theme.subtle
                font.pixelSize: 9
            }
            Text {
                text: "   /   v0.1.0"
                color: Theme.subtle
                font.family: Theme.mono
                font.pixelSize: 9
            }
        }
    }

    PreviewDialog {
        id: previewDialog
        databaseName: workspacePage.database ? workspacePage.database.name : ""
        cellValue: viewerPage.selectedValue
        onActionRequested: action => kind = action
        onPreviewSubmitted: action => {
            if (action === "Add connection" || action === "Edit connection") {
                return;
            }
            toast.text = "This action is ready for a selected live connection.";
            toast.open();
        }
        onConnectionSubmitted: (displayName, engine, host, port, username, password, maintenanceDatabase, serviceName, connectionId) => {
            if (typeof applicationController === "undefined") {
                toast.text = "Connection testing is available in the compiled application.";
                toast.open();
                return;
            }
            applicationController.saveAndTestConnection(displayName, engine, host, port, username, password,
                                                        maintenanceDatabase, serviceName, connectionId);
        }
        onConnectionRemovalRequested: connectionId => applicationController.removeConnection(connectionId)
    }
    Connections {
        target: typeof applicationController === "undefined" ? null : applicationController
        function onOperationCompleted(operation, succeeded, message, recoveryHint) {
            if (operation !== "saveConnection" && operation !== "removeConnection" && operation !== "testConnection" && operation !== "startService" && operation !== "refreshDatabases" && operation !== "openDatabase" && operation !== "refreshTables" && operation !== "openTable" && operation !== "refreshTable" && operation !== "copyTableCell") {
                return;
            }
            toast.text = succeeded ? message : message + (recoveryHint.length > 0 ? " " + recoveryHint : "");
            toast.open();
        }
    }
    Popup {
        id: toast
        property string text: ""
        parent: Overlay.overlay
        x: parent ? parent.width - width - 24 : 0
        y: parent ? parent.height - height - 48 : 0
        width: Math.min(460, parent ? parent.width - 48 : 460)
        padding: 16
        background: Rectangle {
            color: Theme.raised
            border.color: Theme.accent
            radius: 8
        }
        contentItem: Text {
            text: toast.text
            color: Theme.text
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
        onOpened: toastTimer.restart()
        Timer {
            id: toastTimer
            interval: 3200
            onTriggered: toast.close()
        }
    }
}
