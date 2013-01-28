import QtQuick 1.1
import com.nokia.symbian 1.1

Page {
    id: container
    width: 600
    height: 480

    property bool editMode: false
    property bool syncMode: false
    property bool edited: false
    property int  syncErrorCode: 0
    property string currency: ""

    signal close
    signal update

    ///////////////////////////////
    // ToolBar
    ///////////////////////////////
    tools: ToolBarLayout {
        ToolButton {
            id: backButton
            iconSource: "toolbar-back";
            anchors.left: parent.left
            onClicked: {
                if (csvModel.count>0) {
                    csvModel.clear();
                }
                fileHandler.clearCsvCmodel();

                if (container.state=="") {
                    if (container.edited)
                        container.update();
                    else
                        container.close();

                    container.edited = false;

                    garbageCollectCModel();
                }
                else
                    container.state = "";
            }
        }
        ToolButton {
            id: refreshButton
            iconSource: "toolbar-refresh";
            visible: !editMode && !syncMode
            opacity: (waitState.state!="hidden") ? 0.3 : 1
            anchors { left: parent.left; leftMargin: parent.width/5 }
            onClicked: {
                if (waitState.state=="hidden")
                    appWindow.__loadPortfolio();
            }
        }
        ToolButton {
            id: searchButton
            iconSource: "toolbar-search";
            visible: !editMode && !syncMode
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                activatePosFinder();
            }
        }
        // Edit portfolio
        ToolButton {
            id: editButton
            iconSource: "gfx/edit.png";
            visible: !editMode && !syncMode
            anchors { right: parent.right; rightMargin: parent.width/5 }
            onClicked: {
                container.edited = true;
                container.state = "pfoEdit";
                if (appWindow.useEditGuide){ egDialog.open(); }
            }
        }
        ToolButton {
            iconSource: "toolbar-view-menu";
            visible: !editMode&&!syncMode
            anchors.right: parent.right
            onClicked: {
                if (pfoMenu.status == DialogStatus.Closed) { pfoMenu.open(); }
                else { pfoMenu.close(); }
            }
        }
        ToolButton {
            iconSource: "toolbar-add";
            visible: editMode
            anchors.right: parent.right
            onClicked: {
                reseteditSheet();
                editSheet.pfoMode = true;
                editSheet.googleMode = false;
                container.state = "entry";
            }
        }
    }

    Menu {
        id: pfoMenu
        visualParent: pageStack
        MenuLayout {
            MenuItem {
                text: qsTr("Export Portfolio");
                visible: !editMode&&!syncMode;
                onClicked: {
                    syncDialog.open();
                    appWindow.__loadPortfolio();
                    container.state="syncGoogle";
                }
            }
            MenuItem {
                text: qsTr("Import Portfolio");
                visible: !editMode&&!syncMode;
                onClicked: {
                    showCSV();
                    csvDialog.open();
                }
            }
        }
    }

    // UI for "Import Portfolio"
    ListModel {
        id: csvModel
    }

    SelectionDialog {
        id: csvDialog
        titleText: qsTr("Choose csv file")

        model: csvModel

        onAccepted: {
            //console.log( csvModel.get(csvDialog.selectedIndex).name );
            var name = csvModel.get(csvDialog.selectedIndex).name;

            if (name != "") {
                loadCSV(name);
            }
        }
    }

    ///////////////////////////////
    // Function
    ///////////////////////////////
    function showCSV() {
        fileHandler.listCSV();
        csvModel.clear();
        for (var i=0; i< fileHandler.localCsvList.length; i++) {
            //console.log("listCSV: " + fileHandler.localCsvList[i]);
            csvModel.append({"name": fileHandler.localCsvList[i]});
        }
    }

    function loadCSV(csvName) {
        fileHandler.loadCSV(csvName);
        appWindow.__loadPortfolio();
    }

    function calcLocalIdx (idx, gIdx) {
        var tmp = idx - gIdx;
        tmp = (tmp < 0) ? 0 : tmp;
        return tmp ;
    }

    function editDialogTxt() {
        var str;

        str =  qsTr("Click + to add portfolio, then click the newly-created portfolio to add position. ");
        str += qsTr("Long press a portfolio to edit its name and description. ");
        str += qsTr("Enter the symbol's name and exchange as they appeared on Google Finance. ");
        str += qsTr("If you don't know the exact symbol name, use search button to provide a list of suggestions. ");
        str += qsTr("For more info, please see the 'Help' page or visit project website.");
        return str;
    }

    function reloadEditSheet(name, excerpt, isYahoo) {
        editSheet.myPfoName   = name;
        editSheet.myPfoDesc  = excerpt;
        editSheet.myIsYahoo  = isYahoo;
    }

    function loadGooglePosEditModel(feedlink) {
        appWindow.__loadPositionSymbol(feedlink);
    }

    // Update the position file indexes after deletion.
    function updatePos(idx) {        
		var localIdx    = calcLocalIdx(idx, gPfoLength);
        var localLength = calcLocalIdx(pfoModel.count, gPfoLength);
        //console.log("(localIdx, localLength)=(" + localIdx + "," + localLength + ")");

        // Delete the position table
        fileHandler.deletePos(localIdx);

        // Rename filenames that have higher indexes than var idx.
        for (var i=localIdx+1; i<localLength; i++) {
            console.log("updatePos: rename " + i + ".pos by decrement the file index.");
            fileHandler.renamePos(i, i-1);
        }
    }

    function syncDesc() {
        var str;
        //str  = "Click a local portfolio to export portfolio in cvs format by email. \n";
        str  = qsTr("Click a local portfolio to sync to Google Finance. \n");
        str += qsTr("The Portfolio name created is appended with \"_meego.\" \n");
        str += qsTr("Make sure all symbols have explicit exchange info, otherwise syncing will be incomplete. ");
        str += qsTr("Due to technical issue, transaction data are not sync'ed.");
        return str;
    }

    ///////////////////////////////
    // Main
    ///////////////////////////////
    Rectangle {
        id: header
        width: parent.width
        height: params.headerHeight
        color: (editMode || syncMode) ? "#F87217" : params.headerColor
        z: 1

        Text {
            id: label
            text: (editMode) ? qsTr("Edit Portfolio") :
                  (syncMode) ? qsTr("Sync to Google") :
                               qsTr("Portfolio")
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: params.headerLeftMargin
            color: "white"
            font.pixelSize: params.headerTxtTs
        }
    }

    ListView {
        id: pfoView
        anchors.top: header.bottom
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        model: pfoModel
        delegate: pfoDelegate
        snapMode: ListView.SnapToItem
    }

    Component {
        id: pfoDelegate

        Item {
            id: pfoDelegateItem
            width: pfoView.width
            height: (nameBox.height + excerptBox.height + 7)
            opacity: ( (!syncMode) || (local && syncMode) ) ? 1 : 0.3

            Rectangle {
                id: background
                anchors.fill: parent
                anchors.bottomMargin: 1
                color: params.bkgColor
            }

            Text {
                id: nameBox
                anchors { top: background.top; left: background.left; leftMargin: 20; topMargin: 5}
                width: parent.width - countBox.width - 55

                font.bold: true
                font.pixelSize: params.pfoTxtTs
                color: params.labelColor
                text: name
            }

            Text {
                id: excerptBox
                anchors { top: nameBox.bottom; left: background.left; leftMargin: 25; topMargin: 0 }
                visible: (gain=="")
                color: params.excerptColor
                font.pixelSize: params.pfoTxtTs - 10
                text: excerpt
            }

            Text {
                id: valueBox
                anchors { top: nameBox.bottom; left: background.left; leftMargin: 25; topMargin: 0 }
                visible: (gain!="")
                color: params.excerptColor//(useDarkTheme) ? params.labelColor : "#808080"
                font.pixelSize: params.pfoTxtTs - 8
                text: (value=="") ? "" : value
            }

            Text {
                id: gainBox
                anchors { top: nameBox.bottom; left: valueBox.right; leftMargin: 10; topMargin: 0 }
                visible: (gain!="")
                color: colorModifier(gain)
                font.pixelSize: params.pfoTxtTs - 8
                text: (gain=="") ? "" : "(" + signModifier(gain) + ")"
            }

            SimpleRect {
                id: countBox
                anchors { right: background.right; rightMargin: 10; }
                anchors.verticalCenter: background.verticalCenter
                visible: !(local&&editMode)
                color: (local) ? "#FFE9CA" : "#E0ECF7"
                height: 40
                text:  num
                textColor: "grey"
                textSize: params.pfoTxtTs - 6
           }

            MouseArea {
                id: mouseArea
                anchors.fill: background
                onClicked: {
                    gPfoLength = calcGPfoLength();

                    // pfoSelectedIdx: index in PfoList.
                    // activePos: index for local portfolio, start from zero.
                    pfoDelegateItem.ListView.view.currentIndex = index;
                    pfoSelectedIdx = index;
                    appWindow.pfoName   = pfoModel.get(index).name;

                    // Save pfoModel index to C in order to update portfolio performance in script.js.
                    fileHandler.localPos = index;

                    console.log("idx=" + index + " gPfoLength=" + gPfoLength + " activePos=" +activePos + " local=" + local + " yh=" + isYahoo);

                    // Don't load for locally-created portfolio
                    if (!local) {
                        if (!editMode&&!syncMode) {
                            pfoIsLocal  = pfoIsYahoo = false;
                            activePos   = feedLink;
                            console.log("Non-local portfolio (" + index + "): " + activePos);

                            container.update();
                        }
                        // Edit Mode
                        else if (editMode) {
                            // Setup elements
                            activePos   = feedLink;
                            posEditView.pfoLocalIdx = index;
                            posEditView.state = "google";

                            loadGooglePosEditModel(feedLink);
                            pageStack.push(posEditView);
                        }
                        else {
                            // do nothing for now
                        }
                    }
                    else {
                        pfoIsLocal = true;
                        activePos = calcLocalIdx(index, gPfoLength);

                        // Go to posEditView or launch pfo
                        posEditView.pfoLocalIdx = activePos;
                        posEditView.pfoIsYahoo  = pfoIsYahoo = isYahoo;
                        posEditView.state = "";

                        if (editMode) {
                                loadLocalPfoToPosEditModel(activePos);
                                pageStack.push(posEditView);
                        }
                        else if (syncMode) {
                            currencyDialog.open();

                            // export to email
//                            var dir = fileHandler.toCSV(activePos, appWindow.pfoName);
//                            if (dir!=-1) {
//                                Qt.openUrlExternally("mailto:" +
//                                                     "?subject=Stockona's portfolio file" +
//                                                     "&attach=" + dir +
//                                                     "stockona_" + appWindow.pfoName + ".csv" +
//                                                     "&body=Attached is the csv file for Stockona's portfolio, \"" + pfoName + "\"");
//                            }
                        }
                        else {
                            console.log("Local pfo: " + posEditView.pfoLocalIdx);
                            container.update();
                            container.state = "";
                        }
                    }
                }

                // Edit current local portfolio
                // Long preess and hold doesn't fetch
                onPressAndHold: {                    
                    gPfoLength = calcGPfoLength();

                    pfoSelectedIdx = index;
                    pfoDelegateItem.ListView.view.currentIndex = index
                    activePos = calcLocalIdx(index, gPfoLength);

                    if (local&&editMode) {
                        editSheet.pfoMode = true;
                        editSheet.googleMode = false;

                        reloadEditSheet(name, excerpt, isYahoo);
                        container.state = "entryUpdate";
                    }
                }
            }

            Image {
                source: "gfx/delete-s.png"
                anchors { right: background.right; rightMargin: 10; }
                anchors.verticalCenter: background.verticalCenter
                visible: (local&&editMode)

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        gPfoLength = calcGPfoLength();

                        // pfoSelectedIdx: index in PfoList.
                        // activePos: index for local portfolio, start from zero.
                        pfoDelegateItem.ListView.view.currentIndex = index;
                        pfoSelectedIdx = index;
                        appWindow.pfoName   = pfoModel.get(index).name;

                        // Save pfoModel index to C in order to update portfolio performance.
                        fileHandler.localPos = index;

                        container.state = "pfoDelete";
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
                    when: pfoSelectedIdx == index
                    PropertyChanges { target: background; color: params.currentItemColor }
                }
            ]
        }
    }

    QueryDialog {
        id: deleteDialog
        titleText: qsTr("Delete Portfolio")
        message: qsTr("Are you sure you want to delete ") + appWindow.pfoName + "?\n"

        acceptButtonText: qsTr("Ok")
        rejectButtonText: qsTr("Cancel")

        onAccepted: {
            if (container.state=="pfoDelete") {
                updatePos(pfoSelectedIdx);
                pfoModel.remove(pfoSelectedIdx);
                fileHandler.removePfoCmodel(activePos);
                storePfo();
                //fileHandler.removePfo(pfoSelectedIdx);

                // Jump to last portfolio
                activePos      = (activePos>0) ? activePos-1 : 0;
                pfoSelectedIdx = (pfoSelectedIdx>0) ? pfoSelectedIdx-1 : 0;

                container.state = "pfoEdit";
            }
        }
    }

    // Separate message dialog because symbian draws these objects statically....
    QueryDialog {
        id: egDialog
        titleText: qsTr("Create local portfolio")
        message: editDialogTxt()

        acceptButtonText: qsTr("Ok")
        rejectButtonText: "";
    }

    QueryDialog {
        id: syncDialog
        titleText: qsTr("Sync to Google")
        message: syncDesc()

        acceptButtonText: qsTr("Ok")
        rejectButtonText: "";
    }

    SelectionDialog {
        id: currencyDialog
        titleText: qsTr("Select Currency")
        selectedIndex: 0

        model: ListModel {
            ListElement { name: "USD" }
            ListElement { name: "EUR" }
            ListElement { name: "AUD" }
            ListElement { name: "CAD" }
            ListElement { name: "GBP" }
            ListElement { name: "HKD" }
            ListElement { name: "JPY" }
            ListElement { name: "INR" }
            ListElement { name: "TWD" }
            ListElement { name: "MXN" }
            ListElement { name: "RUB" }
            ListElement { name: "SGD" }
            ListElement { name: "CNY" }
        }

        onAccepted: {
            currency = model.get(selectedIndex).name;
            console.log("##DBG:" + currency);

            syncErrorCode = appWindow.__createGooglePfo(appWindow.pfoName, currency, activePos);
            container.state = "syncWarning";

            // Sanity check failed trigger in script.js
            // errorDialog used to display error messages.
            if (syncErrorCode == 0) {
                // Update portfolio after editing
                appWindow.__loadPortfolio();
                container.state = "";
            }
        }
    }

    states: [
        State {
            name: ""
            // Workaround for visible set to false in "inLoadPortfolio" state.
            PropertyChanges { target: pfoView; visible: true }
        },
        // Somehow appWindow.showToolBar is not working correctly.
        // Workaround is to disable toolbar when editSheet.visible = true
        State {
            name: "entry"
            PropertyChanges { target: container; editMode: true; }
            StateChangeScript { script: { dbgStr = "pfoView.entry"; editSheet.open(); }}
        },
        State {
            name: "entryUpdate"
            PropertyChanges { target: container; editMode: true  }
            StateChangeScript { script: { dbgStr = "pfoView.entryUpdate"; editSheet.open(); }}
        },
        State {
            name: "pfoDelete"
            PropertyChanges { target: container; editMode: true  }
            StateChangeScript { script: { dbgStr = "pfoView.delete"; } }
        },
        State {
            name: "pfoEdit"
            PropertyChanges { target: container; editMode: true  }
            StateChangeScript { script: { dbgStr = "pfoView.edit"; } }
        },
        State {
            name: "syncGoogle"
            PropertyChanges { target: container; syncMode: true  }
            StateChangeScript { script: { dbgStr = "pfoView.sync"; } }
        },
        State {
            name: "syncWarning"
            // Error messages are directly set in script.js

            PropertyChanges { target: container; syncMode: true  }
            StateChangeScript { script: { dbgStr = "pfoView.syncWarning"; } }
        },
        // Hide listview because inLoadPortfolio clear then re-load pfoView.
        State {
            name: "hidePfoListView"
            PropertyChanges { target: pfoView; visible: false }
        }
    ]
}
