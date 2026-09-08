pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: control
    property string glyph: ""
    property bool primary: false
    property bool quiet: false
    property bool danger: false
    property string hint: ""
    implicitHeight: 38
    implicitWidth: Math.max(38, contentItem.implicitWidth + (text.length ? 28 : 16))
    hoverEnabled: true
    leftPadding: 14
    rightPadding: 14
    font.pixelSize: 12
    Accessible.name: text.length ? text : hint
    ToolTip.visible: hovered && hint.length > 0
    ToolTip.text: hint
    ToolTip.delay: 450
    background: Rectangle {
        radius: 7
        color: control.primary ? (control.down ? Theme.selected : control.hovered ? Theme.accent : Theme.blue) : control.hovered ? Theme.hover : control.quiet ? "transparent" : Theme.raised
        border.width: control.visualFocus ? 2 : 1
        border.color: control.visualFocus ? Theme.accent : control.primary ? Theme.accent : control.quiet ? "transparent" : Theme.line
        Behavior on color {
            ColorAnimation {
                duration: 110
            }
        }
    }
    contentItem: RowLayout {
        spacing: 8
        Glyph {
            visible: control.glyph.length > 0
            name: control.glyph
            implicitWidth: 16
            implicitHeight: 16
            ink: control.primary ? "white" : control.danger ? Theme.red : Theme.muted
        }
        Text {
            visible: control.text.length > 0
            text: control.text
            font: control.font
            color: control.primary ? "white" : control.danger ? Theme.red : Theme.text
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
