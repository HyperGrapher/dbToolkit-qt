pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    id: card
    required property var service
    property bool selected: false
    property bool startAvailable: false
    signal startRequested
    signal connectRequested
    implicitHeight: 116
    hoverEnabled: true
    Accessible.name: service.name + (service.running ? ", running" : ", stopped")
    background: Rectangle {
        radius: 10
        color: card.selected ? "#1b263a" : card.hovered ? Theme.raised : Theme.panel
        border.color: card.visualFocus ? Theme.accent : card.selected ? "#44669c" : Theme.line
        Behavior on color {
            ColorAnimation {
                duration: 140
            }
        }
        Rectangle {
            visible: card.selected
            implicitWidth: 30
            implicitHeight: 2
            radius: 1
            color: Theme.accent
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.leftMargin: 20
        }
    }
    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14
        RowLayout {
            spacing: 11
            Rectangle {
                implicitWidth: 34
                implicitHeight: 34
                radius: 9
                color: "#253044"
                Glyph {
                    anchors.centerIn: parent
                    implicitWidth: 23
                    implicitHeight: 23
                    name: "database"
                    ink: card.service.color
                }
            }
            ColumnLayout {
                spacing: 3
                Text {
                    text: card.service.name
                    color: Theme.text
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }
                Text {
                    text: "localhost : " + card.service.port
                    color: Theme.subtle
                    font.family: Theme.mono
                    font.pixelSize: 10
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ActionButton {
                visible: card.startAvailable
                text: "Start"
                glyph: "power"
                implicitHeight: 28
                hint: "Start Windows service"
                onClicked: card.startRequested()
            }
        }
        RowLayout {
            Rectangle {
                implicitWidth: 5
                implicitHeight: 5
                radius: 3
                color: card.service.running ? Theme.green : Theme.subtle
            }
            Text {
                text: card.service.running ? "Running" : "Stopped"
                color: card.service.running ? Theme.green : Theme.muted
                font.pixelSize: 11
            }
            Item {
                Layout.fillWidth: true
            }
            ActionButton {
                text: "Connect"
                glyph: "arrow"
                implicitHeight: 28
                onClicked: card.connectRequested()
            }
        }
    }
}
