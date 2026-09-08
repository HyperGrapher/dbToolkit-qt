import QtQuick
import QtQuick.Controls

Window {
    id: window
    width: 1000
    height: 650
    minimumWidth: 780
    minimumHeight: 520
    visible: true
    title: "Northstar Workspace"
    color: "#101827"

    property int selectedSection: 0
    property bool focusMode: false
    property int completedTasks: 3

    Rectangle {
        anchors.fill: parent
        color: "#101827"

        Rectangle {
            id: sidebar
            width: 220
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            color: "#172235"

            Column {
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 24 }
                spacing: 22

                Row {
                    spacing: 10
                    Rectangle {
                        width: 34; height: 34; radius: 10
                        color: "#7c5cff"
                        Text { anchors.centerIn: parent; text: "N"; color: "white"; font.bold: true; font.pixelSize: 18 }
                    }
                    Column {
                        spacing: 2
                        Text { text: "NORTHSTAR"; color: "#f8fafc"; font.bold: true; font.pixelSize: 15; font.letterSpacing: 1.2 }
                        Text { text: "WORKSPACE"; color: "#7e8ca3"; font.pixelSize: 9; font.letterSpacing: 1.5 }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 7
                    Repeater {
                        model: ["Overview", "Projects", "Calendar", "Messages"]
                        delegate: Rectangle {
                            required property int index
                            required property string modelData
                            width: 172; height: 42; radius: 10
                            color: selectedSection === index ? "#293957" : "transparent"
                            border.color: selectedSection === index ? "#405779" : "transparent"
                            border.width: 1
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left; anchors.leftMargin: 14
                                text: modelData
                                color: selectedSection === index ? "#ffffff" : "#9baac0"
                                font.pixelSize: 14
                                font.weight: selectedSection === index ? Font.DemiBold : Font.Normal
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: selectedSection = index }
                        }
                    }
                }
            }

            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 20 }
                height: 72; radius: 12; color: "#21304a"
                Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.top: parent.top; anchors.topMargin: 12; text: "Focus mode"; color: "#dbe5f4"; font.pixelSize: 13; font.bold: true }
                Text { anchors.left: parent.left; anchors.leftMargin: 14; anchors.bottom: parent.bottom; anchors.bottomMargin: 12; text: focusMode ? "Enabled" : "Stay on track"; color: "#94a4bd"; font.pixelSize: 11 }
                Switch {
                    anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                    checked: focusMode
                    onToggled: focusMode = checked
                }
            }
        }

        Item {
            anchors { left: sidebar.right; right: parent.right; top: parent.top; bottom: parent.bottom; margins: 34 }

            Row {
                id: topBar
                width: parent.width
                Text {
                    text: selectedSection === 0 ? "Good morning, Alex" : ["", "Your projects", "Your calendar", "Messages"][selectedSection]
                    color: "#f8fafc"; font.pixelSize: 28; font.bold: true
                }
                Item { width: 1; height: 1 }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 38; height: 38; radius: 19; color: "#2a3955"
                    Text { anchors.centerIn: parent; text: "A"; color: "#d9d2ff"; font.bold: true }
                }
            }

            Text {
                id: subtitle
                anchors.top: topBar.bottom; anchors.topMargin: 8
                text: selectedSection === 0 ? "Here is what is happening in your workspace today." : "Keep your work moving forward."
                color: "#91a0b8"; font.pixelSize: 14
            }

            Rectangle {
                id: goalCard
                anchors { top: subtitle.bottom; topMargin: 28; left: parent.left; right: parent.right }
                height: 142; radius: 18
                gradient: Gradient {
                    GradientStop { position: 0; color: "#6d4ef6" }
                    GradientStop { position: 1; color: "#9a63ef" }
                }
                Text { anchors.left: parent.left; anchors.leftMargin: 24; anchors.top: parent.top; anchors.topMargin: 22; text: "This week's goal"; color: "#e9e4ff"; font.pixelSize: 13; font.bold: true }
                Text { anchors.left: parent.left; anchors.leftMargin: 24; anchors.top: parent.top; anchors.topMargin: 46; text: "Ship the product refresh"; color: "white"; font.pixelSize: 22; font.bold: true }
                Text { anchors.left: parent.left; anchors.leftMargin: 24; anchors.bottom: parent.bottom; anchors.bottomMargin: 22; text: completedTasks + " of 5 milestones complete"; color: "#eeeaff"; font.pixelSize: 13 }
                Rectangle { anchors.right: parent.right; anchors.rightMargin: 24; anchors.bottom: parent.bottom; anchors.bottomMargin: 26; width: 132; height: 7; radius: 4; color: "#bda7ff"; Rectangle { width: parent.width * completedTasks / 5; height: parent.height; radius: parent.radius; color: "white" } }
            }

            Row {
                id: sectionHeader
                anchors { top: goalCard.bottom; topMargin: 30; left: parent.left; right: parent.right }
                Text { text: "Today's priorities"; color: "#f5f7fb"; font.pixelSize: 18; font.bold: true }
                Item { width: parent.width - 270; height: 1 }
                Button {
                    text: "+ Add task"
                    onClicked: { completedTasks = Math.min(5, completedTasks + 1) }
                    contentItem: Text { text: parent.text; color: "#dcd5ff"; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { radius: 8; color: parent.down ? "#4937a6" : "#2d255c" }
                }
            }

            Column {
                anchors { top: sectionHeader.bottom; topMargin: 14; left: parent.left; right: parent.right }
                spacing: 10
                Repeater {
                    model: [
                        { name: "Review final product screens", tag: "Design", time: "10:30 AM", done: true },
                        { name: "Prepare launch update", tag: "Marketing", time: "1:00 PM", done: false },
                        { name: "Team sync and blockers", tag: "Team", time: "3:30 PM", done: false }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width; height: 62; radius: 12; color: "#1a263b"; border.color: "#293750"; border.width: 1
                        property bool done: modelData.done
                        Rectangle { id: check; anchors.left: parent.left; anchors.leftMargin: 16; anchors.verticalCenter: parent.verticalCenter; width: 20; height: 20; radius: 6; color: parent.done ? "#7c5cff" : "transparent"; border.color: parent.done ? "#7c5cff" : "#61718b"; Text { anchors.centerIn: parent; text: "✓"; color: "white"; visible: parent.parent.done; font.bold: true; font.pixelSize: 13 } }
                        Text { anchors.left: check.right; anchors.leftMargin: 13; anchors.verticalCenter: parent.verticalCenter; text: modelData.name; color: parent.done ? "#7f8da4" : "#e5eaf2"; font.pixelSize: 14; font.strikeout: parent.done }
                        Rectangle { anchors.right: time.left; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; width: tagText.width + 18; height: 24; radius: 12; color: "#273650"; Text { id: tagText; anchors.centerIn: parent; text: modelData.tag; color: "#aebce0"; font.pixelSize: 11 } }
                        Text { id: time; anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter; text: modelData.time; color: "#8594ab"; font.pixelSize: 12 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.done = !parent.done }
                    }
                }
            }
        }
    }
}
