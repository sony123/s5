import QtQuick 1.1
import com.nokia.meego 1.0

Sheet {
    id: container
    visualParent: pageStack

    property alias psIdx: psDialog.selectedIndex
    // This is the index of the selected portfolio in the full portfolio list
    property int pfoStoreIdx: 0
    property string myPfoName: ""
    property string myName: ""
    property string mySym: ""
    property string myExg: ""

    property alias symInput: symbolIn.text
    property bool noSearchMode: false

    acceptButtonText: (myExg != "" && pfoStoreModel.count>0) ? qsTr("Save") : ""
    rejectButtonText: qsTr("Cancel")

    content: Flickable {
        id: editItem
        anchors.fill: parent
        anchors { leftMargin: 20; rightMargin: 20; topMargin: 20; bottomMargin: 20 }
        contentHeight: 700

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
                    id: symbolIn; width: 440;
                    placeholderText: qsTr("Type keyword, press enter to search")
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
                        actionKeyLabel: qsTr("Search")
                        actionKeyHighlighted: true
                    }
                    Keys.onPressed: {
                        if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
                            appWindow.__loadGoogleFinanceSearch(symbolIn.text);
                            scDialog.open();
                            symbolIn.platformCloseSoftwareInputPanel();
                        }
                    }
                }
                Button {
                    id: searchButton;
                    text: qsTr("Search");
                    onClicked: {
                        appWindow.__loadGoogleFinanceSearch(symbolIn.text);
                        scDialog.open();
                        symbolIn.platformCloseSoftwareInputPanel();
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
                Button {text: myPfoName ; visible: (pfoStoreModel.count>0); onClicked: { psDialog.open(); }}
                Button {
                    id: createButton
                    text: qsTr("Create one")
                    visible: pfoStoreModel.count==0

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

    SelectionDialog {
        id: psDialog
        titleText: qsTr("Choose portfolio")

        model: pfoStoreModel

        onAccepted: {
            pfoStoreIdx = pfoStoreModel.get(psDialog.selectedIndex).idx;
            myPfoName   = pfoStoreModel.get(psDialog.selectedIndex).name;
        }
    }
}
