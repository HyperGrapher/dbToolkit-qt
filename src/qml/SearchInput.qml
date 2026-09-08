pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls

TextField {
    id: field
    implicitHeight: 37
    implicitWidth: 240
    leftPadding: 36
    rightPadding: 12
    font.pixelSize: 12
    color: Theme.text
    placeholderTextColor: Theme.subtle
    selectionColor: Theme.blue
    background: Rectangle {
        radius: 7
        color: Theme.background
        border.color: field.activeFocus ? Theme.accent : Theme.line
    }
    Glyph {
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 15
        implicitHeight: 15
        name: "search"
        ink: Theme.subtle
    }
}
