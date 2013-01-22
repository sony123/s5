import QtQuick 1.0

Rectangle {
    id: container
    height: 50

    color: (params.useDarkTheme) ? "#5F5A59" : "#E4F5FF"
    radius: 5
    smooth: true

    property int textSize: 12
    property alias text: label.text
    property bool textBold: false
    property bool textElide: false

    property color textColor: (useDarkTheme) ? "white" : "#396AB3"
    property color pressedColor: (useDarkTheme) ? "#4A4344" : "#68C8FF"
//    property bool useDarkTheme: true

    signal clicked

    Text {
        id: label;
        width: parent.width
        height: parent.height
        color: textColor
        font.bold: textBold
        font.pixelSize: textSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: (textElide) ? Text.ElideRight : Text.ElideNone
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: {
            container.clicked();
        }
    }

    states: State {
        name: "pressed"
        when: mouseArea.pressed
        PropertyChanges { target: container; color: container.pressedColor }
    }
}
