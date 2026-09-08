pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: tag
    property string text: ""
    property color tone: Theme.muted
    property bool dot: false
    implicitWidth: tagRow.implicitWidth + 16
    implicitHeight: 24
    radius: 5
    color: Qt.rgba(tone.r, tone.g, tone.b, 0.09)
    RowLayout {
        id: tagRow
        anchors.centerIn: parent
        spacing: 6
        Rectangle {
            visible: tag.dot
            implicitWidth: 5
            implicitHeight: 5
            radius: 3
            color: tag.tone
        }
        Text {
            text: tag.text
            color: tag.tone
            font.pixelSize: 10
            font.weight: Font.Medium
        }
    }
}
