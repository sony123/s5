import QtQuick 1.1
import com.nokia.meego 1.0

Page {
    id: container
    width: 640
    height: 480

    property bool editMode: false
    property bool pfoIsLocal: false
    property bool pfoIsYahoo: false

    property int selectedIdx: 0
    property int pfoLocalIdx: 0

    signal close
    signal inTxView

    ///////////////////////////////
    // ToolBar
    ///////////////////////////////
    tools: ToolBarLayout {
        ToolIcon {
            id: backButton
            platformIconId: "toolbar-back";
            anchors.left: parent.left
            onClicked: {
                container.close();
            }
        }
        ToolIcon {
            platformIconId: "toolbar-add";
            visible: editMode
            anchors.verticalCenter: backButton.verticalCenter
            onClicked: {
                reseteditSheet();
                editSheet.pfoMode = false;
                editSheet.googleMode = !pfoIsLocal;

                if (pfoIsLocal)   container.state = "entry";
                else            container.state = "googleEntry";
            }
        }
        // Save portfolio
        ToolIcon {
            platformIconId: "toolbar-done";
            visible: editMode&&!pfoIsLocal
            anchors.verticalCenter: backButton.verticalCenter
            onClicked: {
                appWindow.__createGooglePos(pfoLocalIdx);

                container.close();
            }
        }
        ToolIcon {
            platformIconId: "toolbar-view-menu";
            visible: !pfoIsLocal
            onClicked: {
                if (posEditMenu.status == DialogStatus.Closed) { posEditMenu.open(); }
                else { posEditMenu.close(); }
            }
        }
    }

    Menu {
        id: posEditMenu
        visualParent: pageStack
        MenuLayout {
            MenuItem {
                text: qsTr("Save to local");
                visible: !pfoIsLocal;
                onClicked: {
                    // Save current Google portfolio into a local portfolio
                    storeGPtoLocal();
                }
            }
        }
    }

    ///////////////////////////////
    // function
    ///////////////////////////////
    function storeGPtoLocal() {
        // Create a Portfolio, copy name, cost
        storeEditPfo();

        // Load fileHandler position array
        storeEditPos(pfoModel.count - appWindow.gPfoLength);
    }

    function reloadEditSheetPos(name, exchange, share, cost, comm, isYahoo) {
        editSheet.mySym    = name;
        editSheet.myExg    = exchange;
        editSheet.myShare  = share;
        editSheet.myCost   = cost;
        editSheet.myStop   = comm;
        editSheet.myIsYahoo = isYahoo;
        editSheet.myType    = qsTr("Buy");
    }

    // Save the current Google portfolio into the last portfolio
    function storeEditPfo() {
        var i = appWindow.pfoSelectedIdx;

        fileHandler.addPfo(pfoModel.get(i).name, pfoModel.get(i).excerpt, false);

        // Call errorDialog to display saved message
        errorState.reason = qsTr("Save to local") + ":\n\"" + appWindow.pfoName + "\"" + qsTr("created.");
        errorState.state = "success";
    }

    ///////////////////////////////
    // Main
    ///////////////////////////////
    Rectangle {
        id: header
        width: parent.width
        height: (2*headerMainText.height+21)
        color: (editMode) ? "#F87217" : params.headerColor
        z: 1

        Label {
            id: headerMainText
            text: (editMode) ?  qsTr("Edit Positon") : qsTr("Position")
            anchors { top: parent.top; topMargin: (editMode) ? 5 : 15 }
            anchors { left: parent.left; leftMargin: params.headerLeftMargin }
            platformStyle: LabelStyle {
                textColor: "white"
                fontPixelSize: params.headerTxtTs
            }
        }

        Rectangle {
            id: headerSep
            anchors { top: headerMainText.bottom; topMargin: 3}
            anchors { left: parent.left; leftMargin: params.headerLeftMargin }
            width: headerMainText.width
            height: 1
            color: "white"
        }

        Label {
            id: headerSubText
            text: pfoName
            anchors { top: headerSep.bottom; topMargin: 3 }
            anchors { left: parent.left; leftMargin: params.headerLeftMargin }
            platformStyle: LabelStyle {
                textColor: "white"
                fontPixelSize: params.headerTxtTs
            }
        }
    }

    ListView {
        id: posEditListView
        anchors.top: header.bottom
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }

        model: posModel
        delegate: posEditDelegate
        snapMode: ListView.SnapToItem
    }

    Component {
        id: posEditDelegate

        Item {
            id: posEditDelegateItem
            width: parent.width
            height: (nameBox.height+excerptBox.height+5)

            Rectangle {
                id: background
                anchors.fill: parent
                color: params.bkgColor
                radius: 5
            }

            SimpleRect {
                id: countBubbleBox
                anchors { left: parent.left; leftMargin: 10; }
                anchors.verticalCenter: background.verticalCenter
                color: "#FFE9CA"

                visible: (pfoIsLocal&editMode)

                text: shareGain
                textColor: "grey"
                textSize: params.posEditTxtTs
           }

            Text {
                id: nameBox
                anchors { top: background.top; left: countBubbleBox.right; leftMargin: 20; topMargin: 5}

                font.bold: true
                font.pixelSize: params.posEditTxtTs
                //verticalAlignment: Text.AlignVCenter
                color: params.labelColor
                text: name
            }

            Text {
                id: excerptBox
                anchors { top: nameBox.bottom; left: countBubbleBox.right; leftMargin: 20; }

                color: (useDarkTheme) ? params.labelColor : "#808080"
                font.pixelSize: params.posEditTxtTs - 10
                text: ((exchange=="") ? "" : (exchange+" | ")) +
                      qsTr("Share: ") + share + ", " +
                      qsTr("Cost: ") + shareCost
            }

            MouseArea {
                id: mouseArea
                anchors.fill: background
                onClicked: {
                    appWindow.posName = posModel.get(index).name;
                    appWindow.posExg  = posModel.get(index).exchange;
                    selectedIdx = index;
                    posEditDelegateItem.ListView.view.currentIndex = index;
                    console.log("pos.(name, exg)=" + appWindow.posName + "," + appWindow.posExg);

                    if (pfoIsLocal&editMode) {
                            appWindow.loadLocalTx(appWindow.activePos, name, exchange);
                            txView.editMode = true;
                            container.inTxView();
                    }
                    else {
                        editSheet.pfoMode    = false;
                        editSheet.googleMode = !pfoIsLocal;

                        reloadEditSheetPos(name, exchange, share, shareCost, shareComm, pfoIsYahoo);
                        container.state = "googleUpdate";
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
                        appWindow.posName = posModel.get(index).name;
                        appWindow.posExg  = posModel.get(index).exchange;
                        selectedIdx = index;
                        posEditDelegateItem.ListView.view.currentIndex = index;

                        deleteDialog.open();
                    }
                }
           }

            states: [
                State {
                    name: "Pressed"
                    when: mouseArea.pressed
                    PropertyChanges { target: background; color: params.pressColor }
                },
                State {
                    name: "highlightCurrentItem"
                    when: selectedIdx == index
                    PropertyChanges { target: background; color: params.currentItemColor }
                }
            ]
        }
    }

    QueryDialog {
        id: deleteDialog
        titleText: qsTr("Delete Position")
        message: qsTr("Are you sure you want to delete ") + posName + "?"

        acceptButtonText: qsTr("Ok")
        rejectButtonText: qsTr("Cancel")

        onAccepted: {
            // Immediately removed
            posModel.remove(selectedIdx);
            fileHandler.removeHashCmodel(appWindow.posName, appWindow.posExg);
            storePos(appWindow.activePos);
//            storeEditPos(appWindow.activePos);
//            fileHandler.removePos(appWindow.activePos, posModel.get(selectedIdx).name, posModel.get(selectedIdx).exchange);

            // Jump to previous item
            selectedIdx = (selectedIdx>0) ? selectedIdx-1 : 0;
        }
    }

    states: [
        State {
            name: ""
            StateChangeScript { script: { console.log("posEdit.default"); }}
        },

        State {
            name: "entry"
            StateChangeScript { script: { console.log("posEdit.entry"); editSheet.open(); }}
        },

        State {
            name: "entryUpdate"
            StateChangeScript { script: { console.log("posEdit.entryUpdate"); editSheet.open(); }}
        },

        State {
            name: "google"
            PropertyChanges { target: container; pfoIsLocal: false; pfoIsYahoo: false }
            StateChangeScript { script: { console.log("posEdit.google"); }}
        },

        State {
            name: "googleEntry"
            PropertyChanges { target: container; pfoIsLocal: false; pfoIsYahoo: false }
            StateChangeScript { script: { console.log("posEdit.googleEntry"); editSheet.open(); }}
        },

        State {
            name: "googleUpdate"
            PropertyChanges { target: container; pfoIsLocal: false; pfoIsYahoo: false }
            StateChangeScript { script: { console.log("posEdit.entryUpdate"); editSheet.open(); }}
        }

    ]
}
