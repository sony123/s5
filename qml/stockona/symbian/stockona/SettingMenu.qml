import QtQuick 1.1
import com.nokia.symbian 1.1

Page {
    id: settingMenu
    anchors.fill: parent

    // Public properties, aliased in appWindow
    property string username: ""
    property string password: ""
    property alias  shadow_username: usrNameInput.text
    property alias  shadow_password: usrPwdInput.text

    property int timer: 30
    property int timerIdx: 1
    property int overviewNewsIdx: 0
    property string overviewNewsRegion: "us"

    property int pfoSelectedIdx: 0
    property bool pfoIsLocal: false
    property bool pfoIsYahoo: false
    property int gPfoLength: 0

    property bool useWidgetView: false
    property bool usePortfolioView: false
    //property bool useWebview: false
    property bool useAsianGainColor: false
    property bool useDarkTheme: true
    property bool useLocalMode: false
    property bool useEditGuide: true
    property bool useMktViewDefault: true
    property bool useSearchShortcut: false

    property bool showBusyIndicator: false
    property int  startIndicator: 0
    property bool localModeTrue2False: false
    property bool localModeFalse2True: false

    property bool plus: fileHandler.plus
    property bool qmlDbg: false

    property string dbgStr: "stockona"
    property string signature: (fileHandler.plus) ? "stockona+" : "stockona"
    property string activePos: ""
    property string pfoName: ""
    property string posName: ""
    property string posExg: ""

    property alias mktSelDialog: mktSelDialog
    //property string homeCurrency: "USD"
    property bool mktOverviewListView: false

    // Private properties
    property int refWidth: parent.width - 40
    property string updateFreq: timerTextLUT(updateFreqDialog.selectedIndex)///appWindow.timerIdx)

    // signal interface
    signal close
    signal signout
    signal signin

    //////////////////////////
    //  ToolBar
    //////////////////////////
    tools: ToolBarLayout {
        id: settingMenuTools

        ToolButton {
            iconSource: "toolbar-back";
            onClicked: {
                if (settingMenu.state == "")
                    close();
                else {
                    updateMktSelIndex();
                    settingMenu.state = "";
                }
            }
        }
    }

    Rectangle {
        id: header
        width: parent.width
        height: params.headerHeight
        color: params.headerColor
        z: 1

        Text {
            text: (mktOverviewListView) ? qsTr("Market Overview List") : qsTr("Settings")
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: params.headerLeftMargin
            color: "white"
            font.pixelSize: params.headerTxtTs
        }
    }

    ListView {
        id: mktSelDialog
        anchors.top: header.bottom
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        visible: false
        model: mktSelModel
        delegate: mktSelDelegate
        property variant selectedIndexes: [0,1,2,3,4,5,6,7,8,9,10,11,12,13]
    }

    Flickable {
        id: settingFlick
        anchors.fill: parent
        anchors { leftMargin: 20; rightMargin: 20; topMargin: 90; bottomMargin: 20 }
        contentHeight: 1200

        Column {
            id: column
            spacing: 20

            // Username
            Column {
                spacing: 10
                Text  { text: qsTr("Username"); font.family: params.textFamily; font.pixelSize: params.settingTxtTs; font.bold: true; color: params.labelColor }
                TextField {
                    id: usrNameInput
                    width: params.buttonSize + 140
                    inputMethodHints: Qt.ImhNoAutoUppercase
                    echoMode: TextInput.Normal
                    placeholderText: qsTr("Add username@gmail.com")

                    Keys.onPressed: {
                        if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
                            usrPwdInput.focus = true
                        }
                    }
                }
            }
            // Password
            Column {
                spacing: 10
                Text  { text: qsTr("Password"); font.family: params.textFamily; font.pixelSize: params.settingTxtTs; font.bold: true; color: params.labelColor }
                TextField {
                    id: usrPwdInput
                    width: params.buttonSize + 140
                    inputMethodHints: Qt.ImhNoAutoUppercase
                    echoMode: TextInput.Password//EchoOnEdit
                    placeholderText: qsTr("Add password")

                    Keys.onPressed: {
                        if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
                            // Re-assign focus to signinButton so vkb doesn't pop up when returning to setting.
                            usrPwdInput.focus  = false;
                            signinButton.focus = true;
                            //platformCloseSoftwareInputPanel();
                            settingMenu.signin();
                        }
                    }
                }
            }
            Text  {
                text: qsTr("Privacy Notice") + ":\n" + qsTr("Credential is stored securely on device.")+"\n"+qsTr("It is only used to authenticate Google finance.")+"\n"+qsTr("Signing out clears the credential.")
                width: parent.width
                font.family: params.textFamily;
                font.pixelSize: params.settingTxtTs;
                color: params.labelColor
                wrapMode: Text.Wrap
            }
            ButtonRow {
                exclusive: false
                Button {
                    id: signinButton
                    width: params.buttonSize - 30

                    text: qsTr("Signin")
                    onClicked: { settingMenu.signin(); }
                }
                Button {
                    id: signoutButton
                    width: params.buttonSize - 30

                    text: qsTr("Signout")
                    onClicked: { settingMenu.signout(); }
                }
            }

            Rectangle { id: ss1; height: 2; width: refWidth; color: params.settingSepColor }

            Column {
                spacing: 10
                Text  { text: qsTr("Update frequecy"); font.family: params.textFamily; font.pixelSize: params.settingTxtTs; font.bold: true; color: params.labelColor }
                Button {text: updateFreq; width: params.buttonSize; onClicked: { updateFreqDialog.open(); }}
            }

            Rectangle { id: ss2; height: 2; width: refWidth; color: params.settingSepColor }

            Column {
                spacing: 10
                Text  { text: qsTr("Market overview"); font.family: params.textFamily; font.pixelSize: params.settingTxtTs; font.bold: true; color: params.labelColor }
                Button { text: qsTr("Select symbols"); width: params.buttonSize; onClicked: { updateMktModel(); settingMenu.state = "mktSel"; } }
            }

            Column {
                spacing: 10
                Text  { text: qsTr("Default view"); font.family: params.textFamily; font.pixelSize: params.settingTxtTs; font.bold: true; color: params.labelColor }
                ButtonRow {
                    id: mktViewButton
                    exclusive: true

                    Button {
                        id: idxs
                        width: params.buttonSize - 35
                        checkable: true
                        text: qsTr("Indexes")
                        checked: appWindow.useMktViewDefault
                        onClicked: { appWindow.useMktViewDefault = true; }
                    }
                    Button {
                        id: news
                        width: params.buttonSize - 35
                        checkable: true
                        text: qsTr("News")
                        checked: !appWindow.useMktViewDefault
                        onClicked: { appWindow.useMktViewDefault = false; }
                    }
                }
            }


            Rectangle { id: ss3; height: 2; width: refWidth; color: params.settingSepColor }

            Column {
                spacing: 10
                Text  { text: qsTr("Default position view"); font.family: params.textFamily; font.pixelSize: params.settingTxtTs; font.bold: true; color: params.labelColor }
                ButtonRow {
                    id: viewButton
                    exclusive: true

                    Button {
                        id: quoteRB
                        width: params.buttonSize - 90
                        checkable: true
                        text: qsTr("Quote")
                        checked: (!appWindow.usePortfolioView && !appWindow.useWidgetView)
                        onClicked: { appWindow.usePortfolioView = appWindow.useWidgetView = false; }
                    }
                    Button {
                        id: pfoRB
                        width: params.buttonSize - 90
                        checkable: true
                        text: qsTr("Portfolio")
                        checked: appWindow.usePortfolioView
                        onClicked: {
                            appWindow.usePortfolioView = true;
                            appWindow.useWidgetView = false;
                        }
                    }
                    Button {
                        id: widgetRB
                        width: params.buttonSize - 90
                        checkable: true
                        text: qsTr("Widget")
                        checked: appWindow.useWidgetView
                        onClicked: {
                            appWindow.useWidgetView = true;
                            appWindow.usePortfolioView = false;
                        }
                    }
                }
            }

            Rectangle { id: ss4; height: 2; width: refWidth; color: params.settingSepColor }
        }

        Text  {
            id: localModeTxt
            anchors.left: parent.left;
            anchors { verticalCenter: localMode.verticalCenter }

            text: qsTr("Bypass Google login"); font.family: params.textFamily; font.pixelSize: params.settingTxtTs; font.bold: true; color: params.labelColor
        }

        Switch {
            anchors.right: parent.right;
            anchors { top: column.bottom; topMargin: 20 }

            id: localMode
            // Read-only in symbian
            checked: appWindow.useLocalMode
            onClicked: {
                appWindow.useLocalMode = checked;
            }
        }

        Rectangle { id: ss5; anchors { top: localMode.bottom; topMargin: 20} height: 2; width: refWidth; color: params.settingSepColor }

        Text  {
            id: asianGainColorTxt
            anchors.left: parent.left;
            anchors { verticalCenter: asianGainColor.verticalCenter }

            text: qsTr("Show gain (+) in red color"); font.family: params.textFamily; font.pixelSize: params.settingTxtTs; font.bold: true; color: params.labelColor
        }

        Switch {
            anchors.right: parent.right;
            anchors { top: ss5.bottom; topMargin: 20 }

            id: asianGainColor
            checked: appWindow.useAsianGainColor
            onClicked: {
                appWindow.useAsianGainColor = checked;
            }
        }

        ////////////////////////////
        Text  {
            id: useSearchTxt
            anchors.left: parent.left;
            anchors { verticalCenter: useSearch.verticalCenter }

            text: qsTr("Search button in home view"); font.family: params.textFamily; font.pixelSize: params.settingTxtTs; font.bold: true; color: params.labelColor
        }

        Switch {
            anchors.right: parent.right;
            anchors { top: asianGainColor.bottom; topMargin: 20 }

            id: useSearch
            checked: useSearchShortcut
            onClicked: {
                useSearchShortcut = checked;
            }
        }

        ////////////////////////////
        Text  {
            id: editGuideTxt
            anchors.left: parent.left;
            anchors { verticalCenter: editGuide.verticalCenter }

            text: qsTr("Portfolio editing guide"); font.family: params.textFamily; font.pixelSize: params.settingTxtTs; font.bold: true; color: params.labelColor
        }

        Switch {
            anchors.right: parent.right;
            anchors { top: useSearchTxt.bottom; topMargin: 20 }

            id: editGuide
            checked: appWindow.useEditGuide
            onClicked: {
                appWindow.useEditGuide = checked;
            }
        }

        /*
        Text  {
            id: darkThemeTxt
            visible: plus
            anchors.left: parent.left;
            anchors { verticalCenter: darkTheme.verticalCenter }

            text: qsTr("Dark Theme"); font.family: params.textFamily; font.pixelSize: params.settingTxtTs; font.bold: true; color: params.labelColor
        }

        Switch {
            anchors.right: parent.right;
            anchors { top: editGuide.bottom; topMargin: 20 }

            id: darkTheme
            visible: plus
            checked: appWindow.useDarkTheme
            onCheckedChanged: {
                appWindow.useDarkTheme = checked;
                theme.inverted = (appWindow.useDarkTheme) ? true : false;
            }
        }
        */
    }

    SelectionDialog {
        id: updateFreqDialog
        titleText: qsTr("Update Frequency")
        selectedIndex: appWindow.timerIdx

        model: ListModel {
            ListElement { name: "15 seconds";}
            ListElement { name: "30 seconds";}
            ListElement { name: "1 minute";  }
            ListElement { name: "5 minutes"; }
            ListElement { name: "15 minutes";}
            ListElement { name: "30 minutes";}
//            ListElement { name: "15 "+qsTr("15 seconds");}
//            ListElement { name: "30 "+qsTr("30 seconds");}
//            ListElement { name: "1 "+qsTr("1 minute");  }
//            ListElement { name: "5 "+qsTr("5 minutes"); }
//            ListElement { name: "15 "+qsTr("15 minutes");}
//            ListElement { name: "30 "+qsTr("30 minutes");}
        }

        onAccepted: {
            appWindow.timerIdx = updateFreqDialog.selectedIndex;
            appWindow.timer    = timerValueLUT(updateFreqDialog.selectedIndex);
            updateFreq         = timerTextLUT(updateFreqDialog.selectedIndex);
        }
    }

    ListModel {
        id: mktSelModel
        ListElement { selected: true; name: "Down Jones"; symbol: "INDEXDJX:.DJI"    }
        ListElement { selected: true; name: "S&P 500"; symbol: "INDEXSP:.INX"        }
        ListElement { selected: true; name: "NASDAQ"; symbol: "INDEXNASDAQ:.IXIC"    }
        ListElement { selected: true; name: "Shanghai"; symbol: "SHA:000001"         }
        ListElement { selected: true; name: "Nikkei 225"; symbol: "INDEXNIKKEI:NI225"}
        ListElement { selected: true; name: "Hang Seng"; symbol: "INDEXHANGSENG:HSI" }
        ListElement { selected: true; name: "TSEC"; symbol: "TPE:TAIEX"              }
        ListElement { selected: true; name: "FTSE 100"; symbol: "INDEXFTSE:UKX"      }
        ListElement { selected: true; name: "EU STOXX 50"; symbol: "INDEXSTOXX:SX5E" }
        ListElement { selected: true; name: "CAC 40"; symbol: "INDEXEURO:PX1"        }
        ListElement { selected: true; name: "S&P TSX"; symbol: "TSE:OSPTX"           }
        ListElement { selected: true; name: "S&P/ASX 200"; symbol: "INDEXASX:XJO"    }
        ListElement { selected: true; name: "BSE Sensex"; symbol: "INDEXBOM:SENSEX"  }
        ListElement { selected: true; name: "DAX"; symbol: "INDEXDB:DAX"  }

    }

    Component {
        id: mktSelDelegate

        ListItem {
            id: listItem

            // The texts to display
            Column {
                anchors {
                    left:  listItem.paddingItem.left
                    top: listItem.paddingItem.top
                    bottom: listItem.paddingItem.bottom
                    right: checkbox.left
                }

                ListItemText {
                    mode: listItem.mode
                    role: "Title"
                    text: name // Title text is from the 'name' property in the model item (ListElement)
                    width: parent.width
                }
            }

            // The checkbox to display
            CheckBox {
                id: checkbox
                checked: selected  // Checked state is from the 'selected' property in the model item
                anchors { right: listItem.paddingItem.right; verticalCenter: listItem.verticalCenter }
                onClicked: mktSelModel.set(index, { "selected": checkbox.checked })
            }
        }
    }

    function updateMktModel() {
        for (var i=0; i<mktSelModel.count; i++) {
            mktSelModel.get(i).selected = false;
        }

        for (var i=0; i<mktSelDialog.selectedIndexes.length; i++) {
            var idx = mktSelDialog.selectedIndexes[i];
            mktSelModel.get(idx).selected = true;
        }
    }

    function updateMktSelIndex() {
        var tmp = new Array;
        for (var i=0; i<mktSelModel.count; i++) {
            if (mktSelModel.get(i).selected) {
                tmp.push(i);
            }
        }
        //console.log(tmp);
        mktSelDialog.selectedIndexes = tmp;
    }

    states: [
        State {
            name: "";
            PropertyChanges{ target: mktSelDialog; visible: false }
            PropertyChanges{ target: settingFlick; visible: true; }
            PropertyChanges{ target: settingMenu; mktOverviewListView: false; }
        },
        State {
            name: "mktSel";
            PropertyChanges{ target: mktSelDialog; visible: true }
            PropertyChanges{ target: settingFlick; visible: false; }
            PropertyChanges{ target: settingMenu; mktOverviewListView: true; }
        }
    ]
}
