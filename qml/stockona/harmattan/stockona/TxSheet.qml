import QtQuick 1.1
import com.nokia.meego 1.0

Sheet {
    id: container
    visualParent: pageStack

    property string myType: qsTr("Buy")
    property alias myShare: shareIn.text
    property alias myPrice: priceIn.text
    property alias myComm: commIn.text

    property bool updateMode: false

    acceptButtonText: qsTr("Save")
    rejectButtonText: qsTr("Cancel")

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
                    width: 400; id: shareIn; inputMethodHints: Qt.ImhDigitsOnly;
                    placeholderText: qsTr("Add number of shares")
                    platformSipAttributes: SipAttributes { actionKeyLabel: qsTr("Next"); actionKeyHighlighted: true }
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
                    width: 400; id: priceIn; inputMethodHints: Qt.ImhDigitsOnly;
                    placeholderText: qsTr("Add price per share")
                    platformSipAttributes: SipAttributes { actionKeyLabel: qsTr("Next"); actionKeyHighlighted: true }
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
                TextField {
                    id: commIn; width: 400; inputMethodHints: Qt.ImhDigitsOnly;
                    placeholderText: qsTr("Add commission for this transaction")
//                    platformSipAttributes: SipAttributes {
//                        actionKeyLabel: qsTr("Save")
//                        actionKeyHighlighted: true
//                    }
//                    Keys.onPressed: {
//                        if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
//                            accepted();
//                        }
//                    }
                }
            }
        }
    }
}
