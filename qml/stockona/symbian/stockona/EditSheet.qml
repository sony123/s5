import QtQuick 1.1
import com.nokia.symbian 1.1

Dialog {
    id: container

    property bool  pfoMode: false
    property bool  posFindMode: false
    property bool  googleMode: false

    property bool  myIsYahoo: false
    property alias myPfoName: pfoNameIn.text
    property alias myPfoDesc: pfoDescIn.text

    property alias mySym: symbolIn.text
    property alias myExg: exchangeIn.text
    property alias myShare: shareIn.text
    property alias myCost: costIn.text
    property alias myStop: stopIn.text
    property string myType: qsTr("Buy")

    //property int scId: 0

    title: Text {
        id: label
        anchors.verticalCenter:  parent.verticalCenter
        anchors { left: parent.left; leftMargin: params.headerLeftMargin/2; }

        text: (pfoMode) ? qsTr("Edit portfolio") : qsTr("Edit Position")
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
                opacity: (googleMode) ? 0 : 1
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
        anchors { leftMargin: 20; rightMargin: 20; topMargin: 10; bottomMargin: 20 }
        contentHeight: 460

        //////////////////////////////
        // Portfolio Edit
        //////////////////////////////
        Column {
            id: pfoGrid
            spacing: 20
            width: parent.width
            visible: pfoMode

            Column {
                spacing: 10
                Text { text: qsTr("Portfolio name"); font.pixelSize: params.sheetTxtTs; font.bold: true; color: params.labelColor  }
                TextField {
                    id: pfoNameIn; width: 300; placeholderText: qsTr("Add portfolio name")
                    Keys.onPressed: {
                        if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
                            pfoDescIn.focus = true
                        }
                    }
                }
            }

            Column {
                spacing: 10
                Text { text: qsTr("Description"); font.pixelSize: params.sheetTxtTs; font.bold: true; color: params.labelColor }
                TextField { id: pfoDescIn; width: 300; placeholderText: qsTr("Add description") }
            }

//            Text { visible: !posFindMode; text: "Yahoo quote (Limited feature)"; font.pixelSize: params.sheetTxtTs; font.bold: true; color: params.labelColor }
//            CheckBox {
//                visible: !posFindMode
//                checked: myIsYahoo
//                onClicked: {
//                    console.log("myIsYahoo=" + myIsYahoo);
//                    myIsYahoo = !myIsYahoo;
//                }
//            }
        }

        //////////////////////////////
        // Position Edit
        //////////////////////////////
        Column {
            id: posGrid
            spacing: 10
            width: parent.width
            visible: !pfoMode

            Column {
                spacing: 10
                Text { text: (myIsYahoo) ? qsTr("Yahoo Symbol") : qsTr("Google Symbol"); font.pixelSize: params.sheetTxtTs; font.bold: true; color: params.labelColor }
                TextField {
                    id: symbolIn; width: 300;
                    inputMethodHints: Qt.ImhUppercaseOnly;
                    placeholderText: qsTr("Add symbol name, e.g. GOOG")
                    Keys.onPressed: {
                        if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
                            exchangeIn.focus = true
                        }
                    }
                }
                Button {
                    id: searchButton;
                    visible: !myIsYahoo
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("Search");
                    width: 300;
                    onClicked: {
                        appWindow.__loadGoogleFinanceSearch(symbolIn.text);
                        scDialog.open();
                    }
                }
            }

            Column {
                spacing: 10
                Text { text: qsTr("Exchange"); font.pixelSize: params.sheetTxtTs; font.bold: true; color: params.labelColor }
                TextField {
                    width: 300; id: exchangeIn; inputMethodHints: Qt.ImhUppercaseOnly;
                    placeholderText: qsTr("Add exchange name, e.g. NASDAQ")
                    Keys.onPressed: {
                        if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
                            shareIn.focus = true
                        }
                    }
                }
            }

            Column {
                spacing: 10
                visible: !googleMode
                Text { text: qsTr("Share"); font.pixelSize: params.sheetTxtTs; font.bold: true; color: params.labelColor }
                TextField {
                    id: shareIn
                    width: 300
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    placeholderText: qsTr("Add number of share")

                    Keys.onPressed: {
                        if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
                            costIn.focus = true
                        }
                    }

                }
            }

            Column {
                spacing: 10
                visible: !googleMode
                Text { text: qsTr("Price per share"); font.pixelSize: params.sheetTxtTs; font.bold: true; color: params.labelColor }
                TextField {
                    id: costIn; width: 300; inputMethodHints: Qt.ImhFormattedNumbersOnly;
                    placeholderText: qsTr("Add price per share")

                    Keys.onPressed: {
                        if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
                            stopIn.focus = true
                        }
                    }
                }
            }

            Column {
                spacing: 10
                visible: !googleMode
                Text { text: qsTr("Commision"); font.pixelSize: params.sheetTxtTs; font.bold: true; color: params.labelColor  }
                TextField {
                    id: stopIn; width: 300; inputMethodHints: Qt.ImhFormattedNumbersOnly;
                    placeholderText: qsTr("Add comission")
                }
            }
        }
    }
}
