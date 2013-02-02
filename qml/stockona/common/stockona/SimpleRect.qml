import QtQuick 1.0

Rectangle {
    id: container
    width: label.paintedWidth + 20
    height: 50

    property bool useDarkTheme: true
    color: (useDarkTheme) ? "#5F5A59" : "#E4F5FF"
    radius: 12

    property int textSize: 12
    property alias text: label.text
    property bool textBold: false
    property bool textElide: false

    property color textColor: (useDarkTheme) ? "white" : "#396AB3"

    signal clicked

    Text {
        id: label;
        anchors.centerIn: parent

        color: textColor
        font.bold: textBold
        font.pixelSize: textSize
    }
}
