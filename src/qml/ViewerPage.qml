pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page
    property string databaseName: "atlas_dev"
    property string tableName: "users"
    property int selectedRow: 1
    property int selectedColumn: 1
    property bool structure: false
    readonly property var columns: ["id", "name", "email", "role", "status", "created_at"]
    readonly property var columnWidths: [55, 165, 225, 95, 100, 170]
    readonly property var displayedRows: tableName === "users" ? PreviewData.rows.filter(r => String(r.name + r.email + r.role).toLowerCase().includes(rowSearch.text.toLowerCase())) : []
    readonly property var selectedRecord: displayedRows[Math.min(selectedRow, displayedRows.length - 1)]
    readonly property string selectedValue: selectedRecord ? String([selectedRecord.id, selectedRecord.name, selectedRecord.email, selectedRecord.role, selectedRecord.status, selectedRecord.created][selectedColumn]) : "No cell selected"
    signal actionRequested(string action)
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
                    text: "A closer look at " + page.databaseName + "."
                    color: Theme.muted
                    font.pixelSize: 12
                }
            }
            Item {
                Layout.fillWidth: true
            }
            Tag {
                text: "Sample data"
                tone: Theme.accent
                dot: true
            }
            ActionButton {
                text: "Export"
                glyph: "download"
                onClicked: page.actionRequested("Export database")
            }
        }
        RowLayout {
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
                        model: PreviewData.tableNames.filter(t => t.includes(tableSearch.text.toLowerCase()))
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
                        text: "12 tables · public schema"
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
                                placeholderText: "Filter sample rows…"
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
                                        text: page.tableName === "users" ? "No matching sample rows" : "No sample rows for this table. Explore users to preview the grid."
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
                                text: page.tableName === "users" ? "COLUMN DEFINITIONS" : "SCHEMA PREVIEW"
                                color: Theme.subtle
                                font.pixelSize: 10
                                font.letterSpacing: 1
                            }
                            Repeater {
                                model: page.tableName === "users" ? ["id|bigint|Primary key", "name|varchar(120)|Not null", "email|varchar(255)|Unique", "role|varchar(32)|Not null", "status|varchar(24)|Not null", "created_at|timestamp|Default: now()"] : []
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
                                visible: page.tableName !== "users"
                                text: "Select users to explore a sample schema."
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
                                text: page.displayedRows.length + " sample rows"
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
