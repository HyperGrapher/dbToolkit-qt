pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: dialog
    property string kind: "New database"
    property string databaseName: ""
    property string cellValue: "Jamie Chen"
    property int selectedEngine: 0
    property bool showPassword: false
    property bool importToNew: false
    property string suggestedConnectionName: ""
    property int suggestedPort: 5432
    property string selectedServiceName: ""
    property string editingConnectionId: ""
    signal actionRequested(string action)
    signal previewSubmitted(string action)
    signal connectionSubmitted(string displayName, int engine, string host, int port, string username, string password, string maintenanceDatabase, string serviceName, string connectionId)
    signal connectionRemovalRequested(string connectionId)
    readonly property bool destructive: ["Delete database", "Recreate database", "Empty database", "Delete row", "Empty table", "Stop service"].includes(kind)
    readonly property bool menuMode: kind === "Database actions" || kind === "Table actions"
    readonly property var fields: kind === "New database" ? [
        {
            label: "DATABASE NAME",
            value: "",
            placeholder: "e.g. my_next_project"
        },
        {
            label: "PROJECT USER",
            value: "",
            placeholder: "e.g. my_project_app"
        },
        {
            label: "PROJECT NOTE",
            value: "",
            placeholder: "A little context for future you…"
        }
    ] : kind === "Export database" ? [
        {
            label: "DATABASE",
            value: databaseName,
            placeholder: "Database"
        },
        {
            label: "FILE NAME",
            value: databaseName + ".sql",
            placeholder: "File name"
        }
    ] : kind === "Import SQL" ? [
        {
            label: "SQL FILE",
            value: "",
            placeholder: "Choose a .sql file…"
        },
        {
            label: importToNew ? "NEW DATABASE NAME" : "TARGET DATABASE",
            value: importToNew ? "" : databaseName,
            placeholder: importToNew ? "e.g. restored_project" : databaseName
        }
    ] : kind === "Edit cell" ? [
        {
            label: "VALUE",
            value: cellValue,
            placeholder: "Enter a value"
        }
    ] : kind === "Filter rows" ? [
        {
            label: "COLUMN",
            value: "name",
            placeholder: "Column"
        },
        {
            label: "CONTAINS",
            value: "",
            placeholder: "Filter value…"
        }
    ] : kind === "Adopt database" ? [
        {
            label: "DATABASE",
            value: databaseName,
            placeholder: "Database"
        },
        {
            label: "PROJECT USER",
            value: "",
            placeholder: "Existing database user"
        }
    ] : destructive ? [
        {
            label: "TYPE THE TARGET NAME TO CONFIRM",
            value: "",
            placeholder: databaseName
        }
    ] : []
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(500, parent ? parent.width - 48 : 500)
    height: Math.min(implicitHeight, parent ? parent.height - 40 : implicitHeight)
    padding: 28
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    onOpened: {
        showPassword = false;
        importToNew = false;
    }
    function prepareConnection(engine, displayName, port, serviceName) {
        editingConnectionId = "";
        selectedEngine = engine;
        suggestedConnectionName = displayName;
        suggestedPort = port;
        selectedServiceName = serviceName;
        connectionNameInput.text = displayName;
        hostInput.text = "localhost";
        portInput.text = String(port);
        usernameInput.text = engine === 0 ? "postgres" : "root";
        passwordInput.text = "";
        maintenanceDatabaseInput.text = "postgres";
    }
    function prepareExistingConnection(details) {
        editingConnectionId = details.connectionId;
        selectedEngine = details.engine;
        suggestedConnectionName = details.displayName;
        suggestedPort = details.port;
        selectedServiceName = details.serviceName;
        connectionNameInput.text = details.displayName;
        hostInput.text = details.host;
        portInput.text = String(details.port);
        usernameInput.text = details.administratorUser;
        passwordInput.text = "";
        maintenanceDatabaseInput.text = details.maintenanceDatabase;
    }
    background: Rectangle {
        color: "#1a1f28"
        radius: 14
        border.color: "#3c4656"
    }
    Overlay.modal: Rectangle {
        color: "#a0080b10"
    }
    enter: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            duration: 140
        }
    }
    contentItem: ScrollView {
        id: dialogScroll
        implicitHeight: form.implicitHeight
        contentWidth: availableWidth
        clip: true
        ColumnLayout {
            id: form
            width: dialogScroll.availableWidth
            spacing: 18
            RowLayout {
                Rectangle {
                    implicitWidth: 40
                    implicitHeight: 40
                    radius: 11
                    color: dialog.destructive ? "#3e2831" : "#263853"
                    Glyph {
                        anchors.centerIn: parent
                        name: dialog.destructive ? "info" : dialog.kind === "Export database" ? "download" : dialog.kind === "Import SQL" ? "upload" : "database"
                        ink: dialog.destructive ? Theme.red : Theme.accent
                        implicitWidth: 22
                        implicitHeight: 22
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
                ActionButton {
                    glyph: "close"
                    quiet: true
                    hint: "Close dialog"
                    onClicked: dialog.close()
                }
            }
            Text {
                text: dialog.kind
                color: Theme.text
                font.pixelSize: 23
                font.weight: Font.DemiBold
            }
            Text {
                text: dialog.destructive ? "This action would affect “" + dialog.databaseName + "”. " + (dialog.kind === "Recreate database" ? "All tables and data would be removed and a fresh database created." : dialog.kind === "Empty database" || dialog.kind === "Empty table" ? "All rows would be removed; table definitions would remain." : dialog.kind === "Stop service" ? "Connections to this service would be interrupted." : "Review the target carefully before continuing.") : dialog.kind === "New database" ? "A fresh space for your next project." : dialog.kind === "Export database" ? "Keep a portable copy of your schema and data." : dialog.kind === "Import SQL" ? "The selected target stays in control. Names inside the SQL file will not redirect the import." : dialog.menuMode ? "Manage “" + dialog.databaseName + "”." : dialog.kind === "Edit cell" ? "Review your change before saving it." : dialog.kind === "Database details" ? "Connection and project information for “" + dialog.databaseName + "”." : "Set up the details for your local workspace."
                color: Theme.muted
                font.pixelSize: 12
                lineHeight: 1.4
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            RowLayout {
                visible: ["New database", "Add connection", "Edit connection"].includes(dialog.kind)
                spacing: 8
                Repeater {
                    model: ["PostgreSQL", "MySQL", "MariaDB"]
                    ActionButton {
                        required property int index
                        required property string modelData
                        text: modelData
                        primary: dialog.selectedEngine === index
                        Layout.fillWidth: true
                        onClicked: {
                            dialog.selectedEngine = index;
                            dialog.suggestedPort = index === 0 ? 5432 : 3306;
                        }
                    }
                }
            }
            ColumnLayout {
                visible: dialog.kind === "Add connection" || dialog.kind === "Edit connection"
                Layout.fillWidth: true
                spacing: 10
                Text {
                    text: "CONNECTION NAME"
                    color: Theme.subtle
                    font.pixelSize: 9
                    font.letterSpacing: 0.7
                }
                TextField {
                    id: connectionNameInput
                    Layout.fillWidth: true
                    text: dialog.suggestedConnectionName
                    placeholderText: "e.g. PostgreSQL local"
                    color: Theme.text
                    placeholderTextColor: Theme.subtle
                    background: Rectangle { color: Theme.background; radius: 6; border.color: connectionNameInput.activeFocus ? Theme.accent : Theme.line }
                }
                Text { text: "HOST  /  PORT"; color: Theme.subtle; font.pixelSize: 9; font.letterSpacing: 0.7 }
                RowLayout {
                    Layout.fillWidth: true
                    TextField {
                        id: hostInput
                        Layout.fillWidth: true
                        text: "localhost"
                        placeholderText: "localhost"
                        color: Theme.text
                        placeholderTextColor: Theme.subtle
                        background: Rectangle { color: Theme.background; radius: 6; border.color: hostInput.activeFocus ? Theme.accent : Theme.line }
                    }
                    TextField {
                        id: portInput
                        Layout.preferredWidth: 96
                        text: String(dialog.suggestedPort > 0 ? dialog.suggestedPort : dialog.selectedEngine === 0 ? 5432 : 3306)
                        validator: IntValidator { bottom: 1; top: 65535 }
                        color: Theme.text
                        horizontalAlignment: TextInput.AlignHCenter
                        background: Rectangle { color: Theme.background; radius: 6; border.color: portInput.activeFocus ? Theme.accent : Theme.line }
                    }
                }
                Text { text: "ADMINISTRATOR USER"; color: Theme.subtle; font.pixelSize: 9; font.letterSpacing: 0.7 }
                TextField {
                    id: usernameInput
                    Layout.fillWidth: true
                    text: dialog.selectedEngine === 0 ? "postgres" : "root"
                    color: Theme.text
                    background: Rectangle { color: Theme.background; radius: 6; border.color: usernameInput.activeFocus ? Theme.accent : Theme.line }
                }
                Text { text: "ADMINISTRATOR PASSWORD"; color: Theme.subtle; font.pixelSize: 9; font.letterSpacing: 0.7 }
                RowLayout {
                    Layout.fillWidth: true
                    TextField {
                        id: passwordInput
                        Layout.fillWidth: true
                        placeholderText: "Enter administrator password"
                        echoMode: dialog.showPassword ? TextInput.Normal : TextInput.Password
                        color: Theme.text
                        placeholderTextColor: Theme.subtle
                        background: Rectangle { color: Theme.background; radius: 6; border.color: passwordInput.activeFocus ? Theme.accent : Theme.line }
                    }
                    ActionButton { text: dialog.showPassword ? "Hide" : "Show"; glyph: "eye"; quiet: true; onClicked: dialog.showPassword = !dialog.showPassword }
                }
                Text {
                    visible: dialog.kind === "Edit connection"
                    text: "Leave blank to keep the current session password."
                    color: Theme.subtle
                    font.pixelSize: 10
                }
                Text {
                    visible: dialog.selectedEngine === 0
                    text: "POSTGRES MAINTENANCE DATABASE"
                    color: Theme.subtle
                    font.pixelSize: 9
                    font.letterSpacing: 0.7
                }
                TextField {
                    id: maintenanceDatabaseInput
                    visible: dialog.selectedEngine === 0
                    Layout.fillWidth: true
                    text: "postgres"
                    color: Theme.text
                    background: Rectangle { color: Theme.background; radius: 6; border.color: maintenanceDatabaseInput.activeFocus ? Theme.accent : Theme.line }
                }
            }
            RowLayout {
                visible: dialog.kind === "Import SQL"
                spacing: 8
                ActionButton {
                    text: "Merge into existing"
                    primary: !dialog.importToNew
                    Layout.fillWidth: true
                    onClicked: dialog.importToNew = false
                }
                ActionButton {
                    text: "Create new database"
                    primary: dialog.importToNew
                    Layout.fillWidth: true
                    onClicked: dialog.importToNew = true
                }
            }
            Repeater {
                model: dialog.fields
                delegate: ColumnLayout {
                    id: fieldRow
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 7
                    Text {
                        text: fieldRow.modelData.label
                        color: Theme.subtle
                        font.pixelSize: 9
                        font.letterSpacing: 0.7
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        TextField {
                            id: input
                            Layout.fillWidth: true
                            implicitHeight: 40
                            text: fieldRow.modelData.value
                            placeholderText: fieldRow.modelData.placeholder
                            echoMode: fieldRow.modelData.password && !dialog.showPassword ? TextInput.Password : TextInput.Normal
                            color: Theme.text
                            placeholderTextColor: Theme.subtle
                            font.pixelSize: 12
                            leftPadding: 12
                            selectionColor: Theme.blue
                            background: Rectangle {
                                color: Theme.background
                                radius: 6
                                border.color: input.activeFocus ? Theme.accent : Theme.line
                            }
                        }
                        ActionButton {
                            visible: fieldRow.modelData.password === true
                            text: dialog.showPassword ? "Hide" : "Show"
                            glyph: "eye"
                            quiet: true
                            implicitHeight: 40
                            onClicked: dialog.showPassword = !dialog.showPassword
                        }
                    }
                }
            }
            RowLayout {
                visible: dialog.kind === "New database"
                Text {
                    text: dialog.selectedEngine === 0 ? "UTF8  /  Server default collation" : "utf8mb4  /  Server default collation"
                    color: Theme.muted
                    font.family: Theme.mono
                    font.pixelSize: 10
                }
            }
            Tag {
                visible: dialog.kind === "Export database" || dialog.kind === "Import SQL"
                text: dialog.kind === "Import SQL" ? "Plain SQL · Target selected in dbToolKit" : "SQL · Schema and data"
                tone: Theme.accent
            }
            Repeater {
                model: dialog.kind === "Database actions" ? ["Adopt database", "Export database", "Empty database", "Recreate database", "Delete database"] : dialog.kind === "Table actions" ? ["Edit cell", "Delete row", "Empty table"] : []
                ActionButton {
                    required property string modelData
                    text: modelData
                    danger: modelData.startsWith("Delete") || modelData.startsWith("Empty") || modelData.startsWith("Recreate")
                    Layout.fillWidth: true
                    onClicked: dialog.actionRequested(modelData)
                }
            }
            Text {
                visible: dialog.kind === "Database details"
                text: dialog.databaseName + "\nlocalhost:5432\nDevelopment · UTF8"
                color: Theme.accent
                font.family: Theme.mono
                font.pixelSize: 12
                lineHeight: 1.7
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.line
            }
            RowLayout {
                Glyph {
                    name: "info"
                    implicitWidth: 14
                    implicitHeight: 14
                    ink: Theme.subtle
                }
                Text {
                    text: "Review the selected action before continuing"
                    color: Theme.subtle
                    font.pixelSize: 10
                    Layout.fillWidth: true
                }
            }
            RowLayout {
                visible: !dialog.menuMode
                ActionButton {
                    visible: dialog.kind === "Edit connection"
                    text: "Remove"
                    glyph: "trash"
                    danger: true
                    onClicked: {
                        dialog.connectionRemovalRequested(dialog.editingConnectionId);
                        passwordInput.text = "";
                        dialog.close();
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
                ActionButton {
                    text: "Cancel"
                    quiet: true
                    onClicked: dialog.close()
                }
                ActionButton {
                    text: dialog.destructive ? "Confirm preview" : dialog.kind === "Add connection" || dialog.kind === "Edit connection" ? "Save and test" : dialog.kind === "New database" ? "Create database" : dialog.kind === "Export database" ? "Export SQL" : dialog.kind === "Import SQL" ? (dialog.importToNew ? "Create and import" : "Merge SQL") : "Done"
                    primary: !dialog.destructive
                    danger: dialog.destructive
                    onClicked: {
                        if (dialog.kind === "Add connection" || dialog.kind === "Edit connection") {
                            dialog.connectionSubmitted(connectionNameInput.text, dialog.selectedEngine,
                                                       hostInput.text, Number(portInput.text), usernameInput.text,
                                                       passwordInput.text, maintenanceDatabaseInput.text,
                                                       dialog.selectedServiceName, dialog.editingConnectionId);
                            passwordInput.text = "";
                        }
                        dialog.previewSubmitted(dialog.kind);
                        dialog.close();
                    }
                }
            }
        }
    }
}
