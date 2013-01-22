import QtQuick 1.1

Item {
    id: splashScreen
    anchors.fill: parent
    property bool isE6: height==480

//    property bool isLandscape: (width>height)

    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    // E6 height = 480
    Image {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 30 //(isLandscape) ? 20 : 0
        source: "gfx/stockona-splash-s.jpg"
    }
}
