import QtQuick 1.1
import com.nokia.meego 1.0
import com.nokia.extras 1.1

Page {
    id: container
    width: 600
    height: 480

    property int selectedIdx: 0
    property string txLink: ""
    property bool pfoIsLocal: false
    property bool editMode: false

    signal close
    signal home

    ///////////////////////////////
    // Function
    ///////////////////////////////
    function goBack() {
        fileHandler.clearTxCmodel();
        if (editMode && pfoIsLocal)
            loadLocalPfoToPosEditModel(appWindow.activePos);
        // Save memory
        if (!editMode && pfoIsLocal)
            garbageCollectCModel();
    }

    function reloadTxSheet(type, share, price, comm) {
        txSheet.myType = type; txSheet.myShare = share;
        txSheet.myPrice = price; txSheet.myComm = comm;
    }

    function resetTxSheet() {
        txSheet.myType = "Buy";
        txSheet.myShare = "";
        txSheet.myPrice = "";
        txSheet.myComm  = "";
    }

    // Update data after transaction deletion.
    function storeTx(posIdx) {
        var txIdx = fileHandler.localTxId[posIdx];
        //console.log("storeTx: txId=" + txIdx);

        fileHandler.removePosCmodel(txIdx);
        fileHandler.removePosAll(appWindow.activePos);
        fileHandler.storePosAll(appWindow.activePos);
    }

    ///////////////////////////////
    // ToolBar
    ///////////////////////////////
    tools: ToolBarLayout {
        ToolIcon {
            id: backButton
            platformIconId: "toolbar-back";
            anchors.left: parent.left
            onClicked: {
                if (container.state == "edit") {
                    container.state = "";
                }
                else {
                    container.close();
                }
            }
        }
        ToolIcon {
            id: homeButton
            platformIconId: "toolbar-home";
            visible: !editMode
            anchors.centerIn: parent
            onClicked: {
                container.state = "";
                container.home();
            }
        }
        ToolIcon {
            id: addButton
            platformIconId: "toolbar-add";
            visible: editMode
            onClicked: {
                resetTxSheet();
                txSheet.open();
            }
        }
    }

    PageIndicator {
        id: pageIndicator
        anchors { bottom:  parent.bottom; bottomMargin: params.pgiMargin }
        anchors.horizontalCenter: parent.horizontalCenter
        z: 2
        objectName: "pageIndicatorObject"
        currentPage: 3
        totalPages: 3
    }

    Rectangle {
        id: header
        width: parent.width
        height: (editMode) ? (2*label.height+21) : params.headerHeight
        color: (editMode) ? "#F87217" : params.headerColor
        z: 1

        Label {
            id: label
            text: ((editMode) ? qsTr("Edit") : appWindow.posName) + qsTr(" Transactions")
            anchors { top: parent.top; topMargin: (editMode) ? 5 : 10 }
            anchors { left: parent.left; leftMargin: params.headerLeftMargin }
            platformStyle: LabelStyle {
                textColor: "white"
                fontPixelSize: params.headerTxtTs
            }
        }

        Rectangle {
            id: headerSep
            anchors { top: label.bottom; topMargin: 3}
            anchors { left: parent.left; leftMargin: params.headerLeftMargin }
            width: label.width
            height: 1
            visible: editMode
            color: "white"
        }

        Label {
            id: headerSubText
            text: appWindow.posName
            anchors { top: headerSep.bottom; topMargin: 3 }
            anchors { left: parent.left; leftMargin: params.headerLeftMargin }
            visible: editMode
            platformStyle: LabelStyle {
                textColor: "white"
                fontPixelSize: params.headerTxtTs
            }
        }
    }

    ListView {
        id: txView
        anchors.top: header.bottom
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom ;}

        model: txModel
        delegate: txDelegate
        snapMode: ListView.SnapToItem
     }

    Component {
        id: txDelegate

        Item {
            id: txDelegateItem
            width: txView.width
            height: 126

            Rectangle {
                id: background
                anchors.fill: parent
                anchors { topMargin: 1; bottomMargin: 1 }
                color: params.bkgColor
                radius: 5
            }

            Text {
                id: typeBox
                anchors { top: background.top; left: background.left; }
                anchors { topMargin: 10; leftMargin: 10; }

                text: ((type=="") ? qsTr("Buy") : type) + " @ " + price
                font.pixelSize: params.txViewTxtTs
                font.bold: true
                color: params.labelColor
            }
            Text {
                id: shareBox
                anchors { top: typeBox.bottom; left: background.left; }
                anchors { topMargin: 10; leftMargin: 10; }

                text: qsTr("Share: ") + share
                font.pixelSize: params.txViewTxtTs - 4
                color: params.labelColor
            }
            Text {
                id: commBox
                anchors { top: shareBox.bottom; bottom: background.bottom; left: background.left; }
                anchors { topMargin: 5; leftMargin: 10; bottomMargin: 10}

                text: qsTr("Comm: ") + comm
                font.pixelSize: params.txViewTxtTs - 4
                color: params.labelColor
            }
            Text {
                id: priceBox
                anchors { top: background.top; bottom: background.bottom; right: background.right; }
                anchors { topMargin: 10; rightMargin: 10; bottomMargin: 10}

                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter

                font.bold: true
                font.pixelSize: params.txViewTxtTs
                text: fileHandler.calcTxCost(share, comm, price)
                color: params.labelColor
                visible: !editMode
            }

            MouseArea {
                id: txMouseArea
                anchors.fill: background
                onClicked: {
                    txDelegateItem.ListView.view.currentIndex = index;
                    selectedIdx = index;
                    //console.log("txView select="+selectedIdx);

                    if (pfoIsLocal&editMode) {
                        if (container.state == "") {
                            container.state = "entryUpdate";
                            reloadTxSheet(type, share, price, comm);
                            txSheet.open();
                        }
                    }
                }
            }

            Image {
                source: "gfx/delete.png"
                anchors { right: background.right; rightMargin: 10; }
                anchors.verticalCenter: background.verticalCenter
                visible: (pfoIsLocal&editMode)
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        txDelegateItem.ListView.view.currentIndex = index;
                        selectedIdx = index;
                        deleteDialog.open();
                    }
                }
            }

            states: [
                State {
                    name: "Pressed"
                    when: txMouseArea.pressed
                    PropertyChanges { target: background; color: params.pressColor }
                }
//                State {
//                    name: "highlightCurrentItem"
//                    when: selectedIdx == index;
//                    PropertyChanges { target: background; color: params.currentItemColor }
//                }
            ]
         }
    }

    QueryDialog {
        id: deleteDialog
        titleText: qsTr("Delete Transaction")
        message: qsTr("Are you sure you want to delete transaction?")

        acceptButtonText: "Ok"
        rejectButtonText: "Cancel"

        onAccepted: {
            // Immediately remove a transaction
            txModel.remove(container.selectedIdx);
            storeTx(container.selectedIdx);

            // loadLocalTx
            appWindow.loadLocalTx(appWindow.activePos, appWindow.posName, appWindow.posExg);
        }
    }

    states: [
//        State {
//            name: "entry"
//            StateChangeScript { script: dbgStr = "State.txView.entry"; }
//        },
        State {
            name: "entryUpdate"
            StateChangeScript { script: dbgStr = "State.txView.entryUpdate"; }
        }
    ]
}
