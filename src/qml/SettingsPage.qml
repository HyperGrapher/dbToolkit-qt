pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page
    signal actionRequested(string action)

    ColumnLayout {
        anchors.fill: parent
        spacing: 22

        ColumnLayout {
            spacing: 6
            Text {
                text: "Settings"
                color: Theme.text
                font.pixelSize: 29
                font.weight: Font.DemiBold
                font.letterSpacing: -0.6
            }
            Text {
                text: "A workspace that feels like yours."
                color: Theme.muted
                font.pixelSize: 12
            }
        }

        Text {
            text: "APPEARANCE"
            color: Theme.subtle
            font.pixelSize: 10
            font.letterSpacing: 1.1
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            Repeater {
                model: Theme.palettes
                delegate: AbstractButton {
                    id: themeCard
                    required property int index
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 198
                    hoverEnabled: true
                    Accessible.name: modelData.name + " theme"
                    onClicked: Theme.select(index)
                    background: Rectangle {
                        radius: 10
                        color: themeCard.hovered ? Theme.raised : Theme.panel
                        border.width: Theme.selectedIndex === themeCard.index ? 2 : 1
                        border.color: Theme.selectedIndex === themeCard.index ? Theme.accent : Theme.line
                    }
                    contentItem: ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 72
                            radius: 6
                            color: themeCard.modelData.background
                            border.color: themeCard.modelData.line
                            Rectangle {
                                implicitWidth: 22
                                height: parent.height - 2
                                x: 1
                                y: 1
                                radius: 5
                                color: themeCard.modelData.sidebar
                            }
                            Rectangle {
                                x: 32
                                y: 14
                                implicitWidth: 58
                                implicitHeight: 5
                                radius: 2
                                color: themeCard.modelData.accent
                            }
                            Repeater {
                                model: 3
                                Rectangle {
                                    required property int index
                                    x: 32
                                    y: 29 + index * 13
                                    implicitWidth: 105
                                    implicitHeight: 7
                                    radius: 2
                                    color: index === 0 ? themeCard.modelData.selected : themeCard.modelData.panel
                                }
                            }
                            Rectangle {
                                visible: Theme.selectedIndex === themeCard.index
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 5
                                implicitWidth: 20
                                implicitHeight: 20
                                radius: 10
                                color: themeCard.modelData.blue
                                Glyph {
                                    anchors.centerIn: parent
                                    name: "check"
                                    implicitWidth: 12
                                    implicitHeight: 12
                                    ink: "white"
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: themeCard.modelData.name
                                color: Theme.text
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Tag {
                                visible: Theme.selectedIndex === themeCard.index
                                text: "Active"
                                tone: Theme.accent
                            }
                        }
                        Text {
                            text: themeCard.modelData.description
                            color: Theme.muted
                            font.pixelSize: 10
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        Text {
            text: "PREFERENCES"
            color: Theme.subtle
            font.pixelSize: 10
            font.letterSpacing: 1.1
            Layout.topMargin: 4
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 226
            radius: 10
            color: Theme.panel
            border.color: Theme.line
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 20
                Repeater {
                    model: [
                        {
                            title: "Rows per page",
                            detail: "Keep large tables comfortable to browse.",
                            value: "100 rows"
                        },
                        {
                            title: "When closing the window",
                            detail: "Keep your workspace within reach.",
                            value: "Minimize to tray"
                        },
                        {
                            title: "Export tools",
                            detail: "Use utilities from your local database installations.",
                            value: "Configure"
                        }
                    ]
                    delegate: RowLayout {
                        id: preferenceRow
                        required property var modelData
                        Layout.fillWidth: true
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            Text {
                                text: preferenceRow.modelData.title
                                color: Theme.text
                                font.pixelSize: 13
                            }
                            Text {
                                text: preferenceRow.modelData.detail
                                color: Theme.subtle
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                        ActionButton {
                            text: preferenceRow.modelData.value
                            glyph: "down"
                            onClicked: page.actionRequested(preferenceRow.modelData.title)
                        }
                    }
                }
            }
        }
        Item {
            Layout.fillHeight: true
        }
        Text {
            text: "Theme changes are preview-only until preferences are stored with the application data."
            color: Theme.subtle
            font.pixelSize: 11
        }
    }
}
