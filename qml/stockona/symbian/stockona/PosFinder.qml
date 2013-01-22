import QtQuick 1.1
import com.nokia.symbian 1.1

Dialog {
    id: container

    property alias psIdx: psDialog.selectedIndex
    // This is the index of the selected portfolio in the full portfolio list
    property int pfoStoreIdx: 0
    property string myPfoName: ""
    property string myName: ""
    property string mySym: ""
    property string myExg: ""
    property alias symInput: symbolIn.text
    property bool noSearchMode: false

    title: Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors { left: parent.left; leftMargin: params.headerLeftMargin/2 }
        text: qsTr("Search Symbol")
        color: params.labelColor
        font.pixelSize: 24
    }

    buttons: [
        Item {
            width: parent.width
            height: 55

            Button {
                id: acceptButton
                anchors { left: parent.left; leftMargin: 10 }
                visible: mySym!=""
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
        contentHeight: 360

        //////////////////////////////
        // Position Edit
        //////////////////////////////
        Column {
            id: posGrid
            spacing: 20
            width: parent.width

            Column {
                id: searchBar
                width: parent.width
                visible: (noSearchMode) ? false : true
                spacing: 10
                Text { text: qsTr("Click search for symbol suggestions"); font.pixelSize: params.sheetTxtTs; font.bold: true; color: params.labelColor }

                TextField {
                    id: symbolIn; width: 300;
                    placeholderText: qsTr("Type keyword, press enter to search")
//                    Image {
//                        anchors { right: parent.right; rightMargin: 5; verticalCenter: parent.verticalCenter }
//                        source: "clear.svg"
//                        MouseArea {
//                            anchors.fill: parent
//                            onClicked: {
//                                if (symbolIn.text) { symbolIn.text = ""; }
//                            }
//                        }
//                    }
                    Keys.onPressed: {
                        if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
                            appWindow.__loadGoogleFinanceSearch(symbolIn.text);
                            scDialog.open();
                        }
                    }
                }
                Button {
                    id: searchButton;
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("Search");
                    width: 300;
                    onClicked: {
                        appWindow.__loadGoogleFinanceSearch(symbolIn.text);
                        scDialog.open();
                    }
                }
            }

            // Visible only when user selected a symbol
            Rectangle { id: ss1; height: (myExg != "") ? 2 : 0; width: parent.width; color: params.settingSepColor; visible: myExg != "" }

            Column {
                spacing: 10
                Text {
                    text: qsTr("You've selected");
                    font.pixelSize: params.sheetTxtTs;
                    font.bold: true;
                    color: params.labelColor
                    visible: myExg != ""
                }
                Text {
                    text: myName
                    font.pixelSize: (noSearchMode) ? 26 : params.sheetTxtTs;
                    color: params.labelColor
                    visible: myExg != ""
                }
                Text {
                    text: "(" + mySym + ":" + myExg + ")"
                    font.pixelSize: (noSearchMode) ? 26 : params.sheetTxtTs;
                    color: params.labelColor
                    visible: myExg != ""
                }
            }

            Rectangle { id: ss2; height: 2; width: parent.width; color: params.settingSepColor }

            Column {
                spacing: 10
                Text { text: (pfoStoreModel.count>0) ? qsTr("Store symbol in") : qsTr("No local portfolio"); font.pixelSize: params.sheetTxtTs; font.bold: true; color: params.labelColor }
                Button {text: myPfoName ; width: 300; visible: (pfoStoreModel.count>0); onClicked: { psDialog.open(); }}
                Button {
                    id: createButton
                    text: qsTr("Create one")
                    visible: pfoStoreModel.count==0
                    width: 300

                    onClicked: {
                        reseteditSheet();
                        editSheet.posFindMode = true;
                        editSheet.pfoMode = true;
                        editSheet.open();
                    }
                }
            }
        }
    }

    PosFinderSel {
    //SelectionDialog {
        id: psDialog
        anchors.fill: parent
        //titleText: "Choose portfolio"
        //selectedIndex: psIdx

        //model: pfoStoreModelSimple

        onAccepted: {
            pfoStoreIdx = pfoStoreModel.get(psDialog.selectedIndex).idx;
            myPfoName   = pfoStoreModel.get(psDialog.selectedIndex).name;
        }
    }
}
