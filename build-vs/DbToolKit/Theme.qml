pragma ComponentBehavior: Bound
pragma Singleton
import QtQuick

QtObject {
    property int selectedIndex: 0
    readonly property var palettes: [
        {
            name: "Midnight",
            description: "Calm graphite with clear blue focus.",
            background: "#101216",
            sidebar: "#14171c",
            panel: "#191d24",
            raised: "#20252e",
            hover: "#242b36",
            line: "#2a303a",
            text: "#edf0f7",
            muted: "#9ba5b5",
            subtle: "#727e91",
            accent: "#82aaff",
            blue: "#497ef1",
            green: "#70d6ab",
            amber: "#e4bb78",
            red: "#f38b96",
            selected: "#243957"
        },
        {
            name: "Sublime Text Default Dark",
            description: "The familiar charcoal, cyan, and amber of Sublime Text.",
            background: "#272822",
            sidebar: "#1e1f1c",
            panel: "#30312b",
            raised: "#3a3b34",
            hover: "#45463e",
            line: "#4d4e46",
            text: "#f8f8f2",
            muted: "#c3c4b7",
            subtle: "#909184",
            accent: "#66d9ef",
            blue: "#4ba3d3",
            green: "#a6e22e",
            amber: "#fd971f",
            red: "#f92672",
            selected: "#3d4c4b"
        },
        {
            name: "Nord",
            description: "Cool blue-gray surfaces with frost-blue accents.",
            background: "#2e3440",
            sidebar: "#252b36",
            panel: "#3b4252",
            raised: "#434c5e",
            hover: "#4c566a",
            line: "#566175",
            text: "#eceff4",
            muted: "#d8dee9",
            subtle: "#aeb9cb",
            accent: "#88c0d0",
            blue: "#5e81ac",
            green: "#a3be8c",
            amber: "#ebcb8b",
            red: "#bf616a",
            selected: "#465875"
        }
    ]
    readonly property var palette: palettes[selectedIndex]
    readonly property string name: palette.name
    readonly property string description: palette.description
    readonly property color background: palette.background
    readonly property color sidebar: palette.sidebar
    readonly property color panel: palette.panel
    readonly property color raised: palette.raised
    readonly property color hover: palette.hover
    readonly property color line: palette.line
    readonly property color text: palette.text
    readonly property color muted: palette.muted
    readonly property color subtle: palette.subtle
    readonly property color accent: palette.accent
    readonly property color blue: palette.blue
    readonly property color green: palette.green
    readonly property color amber: palette.amber
    readonly property color red: palette.red
    readonly property color selected: palette.selected
    readonly property string mono: "Cascadia Mono"

    function select(index) {
        selectedIndex = Math.max(0, Math.min(index, palettes.length - 1));
    }
}
