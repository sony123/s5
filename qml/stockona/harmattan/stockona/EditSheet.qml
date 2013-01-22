import QtQuick 1.1
import com.nokia.meego 1.0

Sheet {
    id: container
    visualParent: pageStack

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

    acceptButtonText: qsTr("Save")
    rejectButtonText: qsTr("Cancel")

    content: Flickable {
        id: editItem
        anchors.fill: parent
        anchors { leftMargin: 20; rightMargin: 20; topMargin: 20; bottomMargin: 20 }
        contentHeight: 700

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
                    id: pfoNameIn; width: 400; placeholderText: qsTr("Add portfolio name")
                    platformSipAttributes: SipAttributes {
                        actionKeyLabel: qsTr("Next")
                        actionKeyHighlighted: true
                    }
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
                TextField { id: pfoDescIn; width: 400; placeholderText: qsTr("Add description") }
            }

            /*
            Text { visible: !posFindMode; text: "Yahoo quote (Limited feature)"; font.pixelSize: params.sheetTxtTs; font.bold: true; color: params.labelColor }
            CheckBox {
                visible: !posFindMode
                checked: myIsYahoo
                onClicked: {
                    console.log("myIsYahoo=" + myIsYahoo);
                    myIsYahoo = !myIsYahoo;
                }
            }
            */
        }

        // This is not stable for dynamic model
//        SelectionDialog {
//            id: scDialog
//            titleText: qsTr("Symbol Suggestions")

//            model: searchModel

//            onAccepted: {
//                container.scId = scDialog.selectedIndex;
//                // load symbol & exchange
//                myName = searchModel.get(container.scId).sym;
//                myExg  = searchModel.get(container.scId).exg;
//            }
//        }

        //////////////////////////////
        // Position Edit
        //////////////////////////////
        Column {
            id: posGrid
            spacing: 20
            width: parent.width
            visible: !pfoMode

            Column {
                spacing: 10
                Text { text: (myIsYahoo) ? qsTr("Yahoo Symbol") : qsTr("Google Symbol"); font.pixelSize: params.sheetTxtTs; font.bold: true; color: params.labelColor }
                TextField {
                    id: symbolIn; width: 400;
                    inputMethodHints: Qt.ImhUppercaseOnly;
                    placeholderText: qsTr("Add symbol name, e.g. GOOG")
                    Image {
                        anchors { right: parent.right; rightMargin: 5; verticalCenter: parent.verticalCenter }
                        source: "/usr/share/themes/blanco/meegotouch/icons/" + ((symbolIn.text) ? "icon-m-input-clear.png" : "icon-m-common-search.png")
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (symbolIn.text) { symbolIn.text = ""; }
                            }
                        }
                    }
                    platformSipAttributes: SipAttributes {
                        actionKeyLabel: qsTr("Next")
                        actionKeyHighlighted: true
                    }
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
                    width: 400; id: exchangeIn; inputMethodHints: Qt.ImhUppercaseOnly;
                    placeholderText: qsTr("Add exchange name, e.g. NASDAQ")
                    platformSipAttributes: SipAttributes {
                        actionKeyLabel: qsTr("Next")
                        actionKeyHighlighted: true
                    }
                    Keys.onPressed: {
                        if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
                            shareIn.focus = true
                        }
                    }
                }
            }

//            Column {
//                spacing: 10
//                visible: !googleMode
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
                visible: !googleMode
                Text { text: qsTr("Share"); font.pixelSize: params.sheetTxtTs; font.bold: true; color: params.labelColor }
                TextField {
                    id: shareIn
                    width: 400
                    inputMethodHints: Qt.ImhDigitsOnly
                    placeholderText: qsTr("Add number of share")
                    platformSipAttributes: SipAttributes {
                        actionKeyLabel: qsTr("Next")
                        actionKeyHighlighted: true
                    }
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
                    id: costIn; width: 400; inputMethodHints: Qt.ImhDigitsOnly|Qt.ImhNoAutoUppercase;
                    placeholderText: qsTr("Add price per share")
                    platformSipAttributes: SipAttributes {
                        actionKeyLabel: qsTr("Next")
                        actionKeyHighlighted: true
                    }
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
                    id: stopIn; width: 400; inputMethodHints: Qt.ImhDigitsOnly|Qt.ImhNoAutoUppercase;
                    placeholderText: qsTr("Add comission")
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
