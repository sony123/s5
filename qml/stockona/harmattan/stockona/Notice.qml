import QtQuick 1.1
import com.nokia.meego 1.0
import "js/noticeDesc.js" as T

Dialog {
    id: myDialog

    content:Column {
//        height: 350
        width: parent.width
        spacing: 10
        Text {
            width: parent.width
            font {pixelSize: 28; bold: true}
            color: "white"
            text: qsTr("Notice")
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
        Rectangle {
            height: 2
            width: parent.width
            color: "blue"
        }
        Text {
            id: text
            width: parent.width
            font.pixelSize: 22
            color: "white"
            text: T.msg()
            wrapMode: Text.WordWrap
        }
    }

    buttons: ButtonRow {
        style: ButtonStyle { }
        anchors.horizontalCenter: parent.horizontalCenter
        Button {text: qsTr("OK"); onClicked: myDialog.accept()}
    }
}
