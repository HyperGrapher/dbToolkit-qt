pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page
    property int selectedDatabaseIndex: -1
    readonly property bool hasSelection: selectedDatabaseIndex >= 0 && selectedDatabaseIndex < databases.length
    readonly property var databases: []
    readonly property var tableNames: []
    readonly property var rows: []
    readonly property string databaseName: hasSelection ? databases[selectedDatabaseIndex].name : ""
    readonly property string serviceName: ""
    property string tableName: ""
    property int selectedRow: 1
    property int selectedColumn: 1
    property bool structure: false
    readonly property var columns: []
    readonly property var columnWidths: []
    readonly property var displayedRows: []
    readonly property var selectedRecord: displayedRows[Math.min(selectedRow, displayedRows.length - 1)]
    readonly property string selectedValue: selectedRecord ? String([selectedRecord.id, selectedRecord.name, selectedRecord.email, selectedRecord.role, selectedRecord.status, selectedRecord.created][selectedColumn]) : "No cell selected"
    signal actionRequested(string action)

    function selectDatabase(index) {
        selectedDatabaseIndex = index;
        tableName = "";
        selectedRow = 0;
        selectedColumn = 0;
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
                model: ["Choose a database…"].concat(page.databases.slice(0, 4).map(database => database.name))
                currentIndex: page.selectedDatabaseIndex + 1
                implicitWidth: 190
                implicitHeight: 36
                onActivated: page.selectDatabase(currentIndex - 1)
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
                    onClicked: page.selectDatabase(0)
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
                            text: "public"
                            color: Theme.text
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        Text {
                            text: "12"
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
                        model: page.tableNames.filter(t => t.includes(tableSearch.text.toLowerCase()))
                        ScrollBar.vertical: ScrollBar {}
                        delegate: AbstractButton {
                            id: tableButton
                            required property string modelData
                            width: ListView.view.width
                            implicitHeight: 35
                            hoverEnabled: true
                            onClicked: {
                                page.tableName = modelData;
                                page.selectedRow = 0;
                            }
                            Accessible.name: modelData
                            background: Rectangle {
                                radius: 5
                                color: page.tableName === tableButton.modelData ? "#263650" : tableButton.hovered ? Theme.raised : "transparent"
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
                                    ink: page.tableName === tableButton.modelData ? Theme.accent : Theme.subtle
                                }
                                Text {
                                    text: tableButton.modelData
                                    color: page.tableName === tableButton.modelData ? Theme.accent : Theme.muted
                                    font.pixelSize: 11
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                    Text {
                        text: page.tableNames.length + " tables"
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
                                text: page.tableName
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
                        ScrollView {
                            visible: !page.structure
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: 810
                            contentHeight: rowColumn.height
                            Column {
                                id: rowColumn
                                width: 810
                                Row {
                                    height: 36
                                    Repeater {
                                        model: page.columns
                                        delegate: Rectangle {
                                            id: columnHeader
                                            required property int index
                                            required property string modelData
                                            width: page.columnWidths[index]
                                            implicitHeight: 36
                                            color: "#202630"
                                            Text {
                                                anchors.left: parent.left
                                                anchors.leftMargin: 12
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: columnHeader.modelData + (columnHeader.index === 0 ? " ↑" : "")
                                                color: Theme.muted
                                                font.family: Theme.mono
                                                font.pixelSize: 10
                                            }
                                        }
                                    }
                                }
                                Repeater {
                                    model: page.displayedRows
                                    delegate: Row {
                                        id: recordRow
                                        required property int index
                                        required property var modelData
                                        Repeater {
                                            model: [recordRow.modelData.id, recordRow.modelData.name, recordRow.modelData.email, recordRow.modelData.role, recordRow.modelData.status, recordRow.modelData.created]
                                            delegate: Rectangle {
                                                id: gridCell
                                                required property int index
                                                required property string modelData
                                                width: page.columnWidths[index]
                                                implicitHeight: 43
                                                color: page.selectedRow === recordRow.index ? "#23324a" : recordRow.index % 2 ? "#1b2028" : Theme.panel
                                                border.color: page.selectedRow === recordRow.index && page.selectedColumn === index ? "#6c94dc" : "transparent"
                                                Text {
                                                    anchors.left: parent.left
                                                    anchors.leftMargin: 12
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: gridCell.modelData
                                                    color: gridCell.index === 4 ? (gridCell.modelData === "active" ? Theme.green : gridCell.modelData === "invited" ? Theme.amber : Theme.subtle) : gridCell.index === 0 ? Theme.subtle : Theme.muted
                                                    font.pixelSize: 11
                                                    font.family: gridCell.index === 1 ? "Segoe UI" : Theme.mono
                                                }
                                                TapHandler {
                                                    onTapped: {
                                                        page.selectedRow = recordRow.index;
                                                        page.selectedColumn = gridCell.index;
                                                    }
                                                    onDoubleTapped: page.actionRequested("Edit cell")
                                                }
                                            }
                                        }
                                    }
                                }
                                Item {
                                    visible: page.displayedRows.length === 0
                                    implicitWidth: 600
                                    implicitHeight: 160
                                    Text {
                                        anchors.centerIn: parent
                                        text: "No rows loaded"
                                        color: Theme.muted
                                        font.pixelSize: 12
                                    }
                                }
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
                                model: []
                                delegate: RowLayout {
                                    id: columnDefinition
                                    required property string modelData
                                    Layout.fillWidth: true
                                    Text {
                                        text: columnDefinition.modelData.split("|")[0]
                                        color: Theme.text
                                        font.family: Theme.mono
                                        font.pixelSize: 12
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: columnDefinition.modelData.split("|")[1]
                                        color: Theme.accent
                                        font.family: Theme.mono
                                        font.pixelSize: 11
                                        Layout.preferredWidth: 145
                                    }
                                    Text {
                                        text: columnDefinition.modelData.split("|")[2]
                                        color: Theme.muted
                                        font.pixelSize: 11
                                        Layout.preferredWidth: 110
                                    }
                                }
                            }
                            Text {
                                text: "Select a table to view its columns."
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
                                text: page.displayedRows.length + " rows"
                                color: Theme.subtle
                                font.pixelSize: 10
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            Text {
                                text: "100 per page   ·   Page 1 of 1"
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
                                text: page.columns[page.selectedColumn]
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
                                onClicked: page.actionRequested("Copy cell")
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
}
