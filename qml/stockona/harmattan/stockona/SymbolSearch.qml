import QtQuick 1.1
import com.nokia.meego 1.0

Sheet {
    id: container
    visualParent: pageStack
    rejectButtonText: qsTr("Cancel")

    property color pressColor: (1) ? "#4A4344" : "#FDE688"
    property string mySym: ""
    property string myExg: ""
    property string myName: ""

    content: Item {
        width: 0.93*parent.width
        anchors { top: parent.top; bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }

        Text {
            id: label
            anchors { top: parent.top; left: parent.left }
            anchors { topMargin: 20; leftMargin: 10; }
            font.family: "Nokia Pure Text"

            text: qsTr("Symbol Suggestions")
            font.pixelSize: 30
            color: params.labelColor
        }

        Image {
            id: closeIcon
            anchors { verticalCenter: label.verticalCenter; right: parent.right }
            source: (useDarkTheme) ? "/usr/share/themes/blanco/meegotouch/icons/icon-m-toolbar-close-selected.png" :
                                     "/usr/share/themes/blanco/meegotouch/icons/icon-m-toolbar-close.png"
            MouseArea {
                id: closeIconMouseArea
                anchors.fill: parent
                onClicked: {
                    container.reject()
                    appWindow.showBusyIndicator = false;
                }
            }
        }

        Rectangle { id: ss; anchors { top: label.bottom; topMargin: 20} height: 1; width: parent.width; color: "#333333" }

        ListView {
            id: scView
            anchors { top: ss.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
            anchors { topMargin: 10 }
            model: searchModel
            delegate: scDelegate
            snapMode: ListView.SnapToItem
            clip: true
        }
    }

    Component {
        id: scDelegate

        Item {
            id: scDelegateItem
            width: scView.width
            height: 60

            Rectangle {
                id: background
                anchors.fill: parent
                color: (useDarkTheme) ? "black" : "#DEDFDE"
            }

            Text {
                width: parent.width
                anchors.fill: parent
                anchors { leftMargin: 10; }
                verticalAlignment: Text.AlignVCenter

                font.family: "Nokia Pure Text"
                font.bold: true
                font.pixelSize: params.scTxtTs
                elide: Text.ElideRight
                color: params.labelColor
                text: sym + " - " + name
            }

            MouseArea {
                id: scMouseArea
                anchors.fill: parent
                onClicked: {
                    mySym  = sym;
                    myExg  = exg;
                    myName = name;
                    container.accept();
                }
            }

            states: [
                State {
                    name: "Pressed"
                    when: scMouseArea.pressed
                    PropertyChanges { target: background; color: container.pressColor }
                }
            ]
        }
    }
}
