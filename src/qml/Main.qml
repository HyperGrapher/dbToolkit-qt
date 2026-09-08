import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    width: 1280
    height: 800
    minimumWidth: 1000
    minimumHeight: 650
    visible: true
    title: "dbToolKit"
    color: "#111318"

    palette.window: "#111318"
    palette.windowText: "#eef0f5"
    palette.base: "#181c24"
    palette.alternateBase: "#202631"
    palette.text: "#eef0f5"
    palette.button: "#252c38"
    palette.buttonText: "#eef0f5"
    palette.highlight: "#5b91f5"
    palette.highlightedText: "#ffffff"
    font.family: "Segoe UI"

    Rectangle {
        id: sidebar
        width: 224
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        color: "#181c24"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 12

            Label {
                text: "dbToolKit"
                font.pixelSize: 23
                font.weight: Font.DemiBold
            }
            Label {
                text: "LOCAL DATABASES"
                color: "#929dad"
                font.pixelSize: 11
                font.letterSpacing: 1
            }
            Item { Layout.fillHeight: true }
            Label {
                text: "MySQL · MariaDB\nPostgreSQL"
                color: "#929dad"
                font.pixelSize: 13
                lineHeight: 1.5
            }
        }
    }

    ColumnLayout {
        anchors.left: sidebar.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 40
        spacing: 16

        Label {
            text: "Your local database workspace"
            font.pixelSize: 28
            font.weight: Font.DemiBold
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        Label {
            text: "Connect, inspect, and manage your development databases."
            color: "#929dad"
            font.pixelSize: 15
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 20
            implicitHeight: notice.implicitHeight + 48
            radius: 12
            color: "#181c24"
            border.color: "#2a313d"

            ColumnLayout {
                id: notice
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 24
                spacing: 10

                Label {
                    text: "Workspace foundation"
                    color: "#8eb6ff"
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                }
                Label {
                    text: "The application shell is ready for its first build. Vault, connections, and database tools will arrive in the next implementation stages."
                    color: "#b4bdca"
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.pixelSize: 14
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
