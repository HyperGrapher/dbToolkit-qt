pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

Item {
    id: page
    signal actionRequested(string action)
    ColumnLayout {
        anchors.fill: parent
        spacing: 24
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
            text: "WORKSPACE"
            color: Theme.subtle
            font.pixelSize: 10
            font.letterSpacing: 1.1
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 150
            radius: 10
            color: Theme.panel
            border.color: Theme.line
            RowLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 28
                Rectangle {
                    implicitWidth: 150
                    implicitHeight: 96
                    radius: 7
                    color: Theme.background
                    border.color: "#536d98"
                    Rectangle {
                        implicitWidth: 32
                        height: parent.height - 2
                        x: 1
                        y: 1
                        radius: 6
                        color: "#232b38"
                    }
                    Rectangle {
                        x: 45
                        y: 15
                        implicitWidth: 55
                        implicitHeight: 5
                        radius: 2
                        color: "#7f9bc8"
                    }
                    Repeater {
                        model: 3
                        Rectangle {
                            required property int index
                            x: 45
                            y: 33 + index * 17
                            implicitWidth: 91
                            implicitHeight: 10
                            radius: 3
                            color: index === 0 ? "#2a3e5d" : "#222936"
                        }
                    }
                    Rectangle {
                        x: 132
                        y: 78
                        implicitWidth: 22
                        implicitHeight: 22
                        radius: 11
                        color: Theme.blue
                        Glyph {
                            anchors.centerIn: parent
                            name: "check"
                            ink: "white"
                            implicitWidth: 13
                            implicitHeight: 13
                        }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        text: "Midnight"
                        color: Theme.text
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: "Less glare. More focus.\nA considered dark palette, everywhere."
                        color: Theme.muted
                        font.pixelSize: 12
                        lineHeight: 1.5
                    }
                }
                Tag {
                    text: "Always dark"
                    tone: Theme.accent
                }
            }
        }
        Text {
            text: "PREFERENCES"
            color: Theme.subtle
            font.pixelSize: 10
            font.letterSpacing: 1.1
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 230
            radius: 10
            color: Theme.panel
            border.color: Theme.line
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 24
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
            text: "dbToolKit 0.1.0  ·  Designed for local development"
            color: Theme.subtle
            font.pixelSize: 11
        }
    }
}
