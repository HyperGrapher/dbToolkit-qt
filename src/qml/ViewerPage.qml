pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page
    readonly property bool hasApplicationController: typeof applicationController !== "undefined"
    readonly property bool hasSelection: hasApplicationController &&
                                         applicationController.activeConnectionId.length > 0 &&
                                         applicationController.activeDatabaseName.length > 0
    readonly property var databasesModel: hasApplicationController ? applicationController.databasesModel : null
    readonly property var tablesModel: hasApplicationController ? applicationController.tablesModel : null
    readonly property string databaseName: hasSelection ? applicationController.activeDatabaseName : ""
    readonly property string serviceName: hasSelection ? applicationController.activeConnectionName : ""
    property string schemaName: ""
    property string tableName: ""
    property int selectedRow: -1
    property int selectedColumn: -1
    property bool structure: false
    property string selectedColumnName: ""
    property string selectedValue: "No cell selected"
    signal actionRequested(string action)

    function selectDatabase(databaseName) {
        if (!hasApplicationController || databaseName.length === 0)
            return;
        applicationController.openDatabase(databaseName);
        schemaName = "";
        tableName = "";
        selectedRow = -1;
        selectedColumn = -1;
        structure = false;
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: 20
        RowLayout {
            ColumnLayout {
                spacing: 6
                Text {
                    text: "Table viewer"
                    color: Theme.text
                    font.pixelSize: 29
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.6
                }
                Text {
                    text: page.hasSelection ? "A closer look at " + page.databaseName + "." : "Choose a database before opening its tables."
                    color: Theme.muted
                    font.pixelSize: 12
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ComboBox {
                id: databaseSelector
                model: page.databasesModel
                textRole: "name"
                currentIndex: -1
                displayText: page.hasSelection ? page.databaseName : "Choose a database…"
                implicitWidth: 190
                implicitHeight: 36
                onActivated: page.selectDatabase(currentText)
            }
            Tag {
                text: page.hasSelection ? "Live data" : "Selection required"
                tone: page.hasSelection ? Theme.accent : Theme.amber
                dot: true
            }
            ActionButton {
                text: "Export"
                glyph: "download"
                onClicked: page.actionRequested("Export database")
            }
        }
        Rectangle {
            visible: !page.hasSelection
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: Theme.panel
            border.color: Theme.line
            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(360, parent.width - 48)
                spacing: 12
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 52
                    implicitHeight: 52
                    radius: 14
                    color: Theme.selected
                    Glyph {
                        anchors.centerIn: parent
                        name: "database"
                        ink: Theme.accent
                        implicitWidth: 28
                        implicitHeight: 28
                    }
                }
                Text {
                    text: "Choose a database to explore"
                    color: Theme.text
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: "Tables and rows appear only after you choose an explicit target."
                    color: Theme.muted
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }
                ActionButton {
                    text: "Choose a database"
                    glyph: "database"
                    primary: true
                    Layout.alignment: Qt.AlignHCenter
                    enabled: databaseSelector.count > 0
                    onClicked: databaseSelector.popup.open()
                }
            }
        }
        RowLayout {
            visible: page.hasSelection
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16
            Rectangle {
                Layout.preferredWidth: 175
                Layout.fillHeight: true
                color: Theme.panel
                radius: 9
                border.color: Theme.line
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12
                    RowLayout {
                        Layout.topMargin: 5
                        Glyph {
                            name: "folder"
                            implicitWidth: 15
                            implicitHeight: 15
                            ink: Theme.accent
                        }
                        Text {
                            text: "SCHEMAS & TABLES"
                            color: Theme.text
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        Text {
                            text: page.hasApplicationController ? applicationController.tableCount : 0
                            color: Theme.subtle
                            font.pixelSize: 10
                        }
                    }
                    SearchInput {
                        id: tableSearch
                        Layout.fillWidth: true
                        implicitWidth: 120
                        placeholderText: "Find table…"
                    }
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 3
                        model: page.tablesModel
                        ScrollBar.vertical: ScrollBar {}
                        delegate: AbstractButton {
                            id: tableButton
                            required property string schemaName
                            required property string tableName
                            required property string qualifiedName
                            width: ListView.view.width
                            implicitHeight: visible ? 46 : 0
                            visible: tableSearch.text.length === 0 ||
                                     qualifiedName.toLowerCase().includes(tableSearch.text.toLowerCase())
                            hoverEnabled: true
                            onClicked: {
                                page.schemaName = tableButton.schemaName;
                                page.tableName = tableButton.tableName;
                                page.selectedRow = -1;
                                page.selectedColumn = -1;
                                page.selectedColumnName = "";
                                page.selectedValue = "No cell selected";
                                applicationController.openTable(tableButton.schemaName, tableButton.tableName);
                            }
                            Accessible.name: qualifiedName
                            background: Rectangle {
                                radius: 5
                                color: page.tableName === tableButton.tableName && page.schemaName === tableButton.schemaName ? "#263650" : tableButton.hovered ? Theme.raised : "transparent"
                                border.color: tableButton.visualFocus ? Theme.accent : "transparent"
                            }
                            contentItem: RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8
                                Glyph {
                                    name: "table"
                                    implicitWidth: 14
                                    implicitHeight: 14
                                    ink: page.tableName === tableButton.tableName && page.schemaName === tableButton.schemaName ? Theme.accent : Theme.subtle
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: tableButton.tableName
                                        color: page.tableName === tableButton.tableName && page.schemaName === tableButton.schemaName ? Theme.accent : Theme.muted
                                        font.pixelSize: 11
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: tableButton.schemaName
                                        color: Theme.subtle
                                        font.pixelSize: 9
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: parent.count === 0
                            text: applicationController.isBusy ? "Loading tables…" : "No tables found"
                            color: Theme.muted
                            font.pixelSize: 11
                        }
                    }
                    Text {
                        text: (page.hasApplicationController ? applicationController.tableCount : 0) + " tables"
                        color: Theme.subtle
                        font.pixelSize: 9
                    }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 14
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Theme.panel
                    border.color: Theme.line
                    radius: 9
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.margins: 14
                            spacing: 10
                            Glyph {
                                name: "table"
                                ink: Theme.accent
                                implicitWidth: 17
                                implicitHeight: 17
                            }
                            Text {
                                text: page.tableName.length > 0 ? page.schemaName + "." + page.tableName : "Choose a table"
                                color: Theme.text
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            ActionButton {
                                text: "Data"
                                quiet: page.structure
                                primary: !page.structure
                                implicitHeight: 29
                                onClicked: page.structure = false
                            }
                            ActionButton {
                                text: "Structure"
                                quiet: !page.structure
                                primary: page.structure
                                implicitHeight: 29
                                onClicked: page.structure = true
                            }
                            ActionButton {
                                glyph: "more"
                                quiet: true
                                hint: "Table actions"
                                onClicked: page.actionRequested("Table actions")
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 1
                            color: Theme.line
                        }
                        RowLayout {
                            visible: !page.structure
                            Layout.margins: 12
                            SearchInput {
                                id: rowSearch
                                placeholderText: "Filter rows…"
                                Layout.fillWidth: true
                                implicitWidth: 130
                            }
                            ActionButton {
                                glyph: "filter"
                                text: "Filter"
                                onClicked: page.actionRequested("Filter rows")
                            }
                            ActionButton {
                                glyph: "refresh"
                                quiet: true
                                hint: "Refresh rows"
                                onClicked: page.actionRequested("Refresh")
                            }
                        }
                        Item {
                            visible: !page.structure
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            HorizontalHeaderView {
                                id: tableHeader
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                syncView: tableData
                                delegate: Rectangle {
                                    required property var display
                                    implicitHeight: 36
                                    color: "#202630"
                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: display
                                        color: Theme.muted
                                        font.family: Theme.mono
                                        font.pixelSize: 10
                                    }
                                }
                            }
                            TableView {
                                id: tableData
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: tableHeader.bottom
                                anchors.bottom: parent.bottom
                                clip: true
                                model: applicationController.tableDataModel
                                columnSpacing: 1
                                rowSpacing: 1
                                columnWidthProvider: column => 180
                                delegate: Rectangle {
                                    required property int row
                                    required property int column
                                    required property string displayText
                                    required property string fullText
                                    required property int valueKind
                                    implicitHeight: 43
                                    color: page.selectedRow === row ? "#23324a" : row % 2 ? "#1b2028" : Theme.panel
                                    border.color: page.selectedRow === row && page.selectedColumn === column ? Theme.accent : "transparent"
                                    Text {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: displayText
                                        color: valueKind === 1 ? Theme.amber : valueKind === 2 ? Theme.subtle : Theme.muted
                                        font.pixelSize: 11
                                        font.family: Theme.mono
                                        elide: Text.ElideRight
                                    }
                                    TapHandler {
                                        onTapped: {
                                            page.selectedRow = row;
                                            page.selectedColumn = column;
                                            page.selectedColumnName = applicationController.tableDataModel.headerData(column, Qt.Horizontal);
                                            page.selectedValue = fullText;
                                        }
                                        onDoubleTapped: page.actionRequested("Edit cell")
                                    }
                                }
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: applicationController.loadedRowCount === 0
                                text: applicationController.isBusy ? "Loading table data…" : page.tableName.length > 0 ? "This table has no rows" : "Choose a table"
                                color: Theme.muted
                                font.pixelSize: 12
                            }
                        }
                        ColumnLayout {
                            visible: page.structure
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.margins: 20
                            spacing: 16
                            Text {
                                        text: "COLUMN DEFINITIONS"
                                color: Theme.subtle
                                font.pixelSize: 10
                                font.letterSpacing: 1
                            }
                            Repeater {
                                model: applicationController.columnsModel
                                delegate: RowLayout {
                                    id: columnDefinition
                                    required property string name
                                    required property string typeName
                                    required property bool nullable
                                    required property bool generated
                                    Layout.fillWidth: true
                                    Text {
                                        text: columnDefinition.name
                                        color: Theme.text
                                        font.family: Theme.mono
                                        font.pixelSize: 12
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: columnDefinition.typeName
                                        color: Theme.accent
                                        font.family: Theme.mono
                                        font.pixelSize: 11
                                        Layout.preferredWidth: 145
                                    }
                                    Text {
                                        text: columnDefinition.generated ? "Generated" : columnDefinition.nullable ? "Nullable" : "Required"
                                        color: Theme.muted
                                        font.pixelSize: 11
                                        Layout.preferredWidth: 110
                                    }
                                }
                            }
                            Text {
                                text: applicationController.isBusy ? "Loading column definitions…" : "Select a table to view its columns."
                                color: Theme.muted
                                font.pixelSize: 12
                            }
                            Item {
                                Layout.fillHeight: true
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 1
                            color: Theme.line
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.margins: 12
                            Text {
                                text: applicationController.loadedRowCount + " rows"
                                color: Theme.subtle
                                font.pixelSize: 10
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            ActionButton {
                                text: "Previous"
                                quiet: true
                                implicitHeight: 27
                                enabled: applicationController.tablePageNumber > 0 && !applicationController.isBusy
                                onClicked: applicationController.previousTablePage()
                            }
                            ActionButton {
                                text: "Next"
                                quiet: true
                                implicitHeight: 27
                                enabled: applicationController.hasMoreRows && applicationController.hasStableRowOrder && !applicationController.isBusy
                                hint: applicationController.hasStableRowOrder ? "Load the next 100 rows" : "A primary key or non-null unique key is required for reliable paging"
                                onClicked: applicationController.nextTablePage()
                            }
                            Text {
                                text: applicationController.hasMoreRows
                                      ? "Page " + (applicationController.tablePageNumber + 1) + " · 100 rows"
                                      : applicationController.hasStableRowOrder
                                        ? "Page " + (applicationController.tablePageNumber + 1) + " · stable key order"
                                        : "No stable key"
                                color: Theme.subtle
                                font.pixelSize: 10
                            }
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 110
                    radius: 9
                    color: Theme.panel
                    border.color: Theme.line
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 9
                        RowLayout {
                            Text {
                                text: "CELL INSPECTOR"
                                color: Theme.subtle
                                font.pixelSize: 9
                                font.letterSpacing: 1
                            }
                            Tag {
                                text: page.selectedColumnName
                                tone: Theme.accent
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            ActionButton {
                                glyph: "copy"
                                quiet: true
                                implicitHeight: 25
                                hint: "Copy cell"
                                enabled: page.selectedRow >= 0 && page.selectedColumn >= 0
                                onClicked: applicationController.copyTableCell(page.selectedRow, page.selectedColumn)
                            }
                            ActionButton {
                                text: "Edit value"
                                implicitHeight: 28
                                onClicked: page.actionRequested("Edit cell")
                            }
                        }
                        Text {
                            text: page.selectedValue
                            color: Theme.text
                            font.family: Theme.mono
                            font.pixelSize: 13
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
    Connections {
        target: page.hasApplicationController ? applicationController : null
        function onActiveDatabaseChanged() {
            page.schemaName = "";
            page.tableName = "";
            page.selectedRow = 0;
            page.selectedColumn = 0;
        }
        function onTableDataChanged() {
            page.selectedRow = -1;
            page.selectedColumn = -1;
            page.selectedColumnName = "";
            page.selectedValue = "No cell selected";
        }
    }
}
