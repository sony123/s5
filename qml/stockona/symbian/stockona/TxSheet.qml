import QtQuick 1.1
import com.nokia.symbian 1.1

Dialog {
    id: container

    property string myType: "Buy"
    property alias myShare: shareIn.text
    property alias myPrice: priceIn.text
    property alias myComm: commIn.text

    property bool updateMode: false

    title: Text {
        id: label
        anchors.verticalCenter:  parent.verticalCenter
        anchors { left: parent.left; leftMargin: params.headerLeftMargin/2; }

        text: qsTr("Edit transaction")
        font.pixelSize: 24
        color: params.labelColor
    }

    buttons: [
        Item {
            width: parent.width
            height: 55
            Button {
                id: acceptButton
                anchors { left: parent.left; leftMargin: 10 }
                text: qsTr("Save")
                width: 150; height: 45
                onClicked: { container.accept(); }
            }
            Button {
                id: rejectButton
                anchors { right: parent.right; rightMargin: 10 }
                text: qsTr("Cancel")
                width: 150; height: 45
                onClicked: { container.reject(); }
            }
        }
    ]

    content: Flickable {
        id: editItem
        anchors.fill: parent
        anchors { leftMargin: 20; rightMargin: 20; topMargin: 20; bottomMargin: 20 }
        contentHeight: 700

        //////////////////////////////
        // Transaction
        //////////////////////////////
        Column {
            id: txGrid
            spacing: 20
            width: parent.width

//            Column {
//                spacing: 10
//                visible: !updateMode

//                Text { text: "Type"; font.pixelSize: params.sheetTxtTs; font.bold: true; color: params.labelColor }
//                ButtonRow {
//                    id: typeButton
//                    exclusive: true

//                    Button {
//                        id: buyButton
//                        checkable: true
//                        text: "Buy"
//                        checked: myType == "Buy"
//                        onClicked: { myType = "Buy"; console.log(myType); }
//                    }
//                    Button {
//                        id: sellButton
//                        checkable: true
//                        text: "Sell"
//                        checked: myType == "Sell"
//                        onClicked: { myType = "Sell"; console.log(myType);  }
//                    }
//                }
//            }

            Column {
                spacing: 10
                Text { text: qsTr("Share"); font.pixelSize: params.sheetTxtTs; font.bold: true; color: params.labelColor }
                TextField {
                    width: 300; id: shareIn; inputMethodHints: Qt.ImhFormattedNumbersOnly;
					placeholderText: qsTr("Add number of shares")
                    Keys.onPressed: {
                        if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
                            priceIn.focus = true
                        }
                    }
				}
            }

            Column {
                spacing: 10
                Text { text: qsTr("Price"); font.pixelSize: params.sheetTxtTs; font.bold: true; color: params.labelColor }
                TextField {
                    width: 300; id: priceIn; inputMethodHints: Qt.ImhFormattedNumbersOnly;
					placeholderText: qsTr("Add price per share")
                    Keys.onPressed: {
                        if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
                            commIn.focus = true
                        }
                    }
				}
            }

            Column {
                spacing: 10
                Text { text: qsTr("Commission"); font.pixelSize: params.sheetTxtTs; font.bold: true; color: params.labelColor }
                TextField { id: commIn; width: 300; inputMethodHints: Qt.ImhFormattedNumbersOnly; placeholderText: qsTr("Add commission for this transaction") }
            }
        }
    }
}
