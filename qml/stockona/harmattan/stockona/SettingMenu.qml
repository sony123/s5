import QtQuick 1.1
import com.nokia.meego 1.0

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
    property bool useDarkTheme: false
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

    property alias mktSelDialog: mktOverviewSelectionDialog
    //property string homeCurrency: "USD"

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

        ToolIcon {
            platformIconId: "toolbar-back";
            onClicked: { close(); }
        }
    }

    Rectangle {
        id: header
        width: parent.width
        height: params.headerHeight
        color: params.headerColor
        z: 1

        Label {
            text: qsTr("Settings")
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: params.headerLeftMargin
            platformStyle: LabelStyle {
                textColor: "white"
                fontPixelSize: params.headerTxtTs
            }
        }
    }

    Flickable {
        anchors.fill: parent
        anchors { leftMargin: 20; rightMargin: 20; topMargin: 90; bottomMargin: 20 }
        contentHeight: 1250

        Column {
            id: column
            spacing: 20

            // Username
            Column {
                spacing: 10
                Text  { text: qsTr("Username"); font.family: params.textFamily; font.pixelSize: params.settingTxtTs; font.bold: true; color: params.labelColor }
                TextField {
                    id: usrNameInput
                    width: 400
                    inputMethodHints: Qt.ImhNoAutoUppercase
                    echoMode: TextInput.Normal
                    placeholderText: qsTr("Add username@gmail.com")
                    platformSipAttributes: SipAttributes {
                        actionKeyLabel: qsTr("Next")
                        actionKeyHighlighted: true
                    }

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
                    width: 400

                    inputMethodHints: Qt.ImhNoAutoUppercase
                    echoMode: TextInput.Password//EchoOnEdit
                    placeholderText: qsTr("Add password")

                    platformSipAttributes: SipAttributes {
                        actionKeyLabel: qsTr("Signin")
                        actionKeyHighlighted: true
                    }

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

                    text: qsTr("Signin")
                    onClicked: { settingMenu.signin(); }
                }
                Button {
                    id: signoutButton

                    text: qsTr("Signout")
                    onClicked: { settingMenu.signout(); }
                }
            }

            Rectangle { id: ss1; height: 2; width: refWidth; color: params.settingSepColor }

            Column {
                spacing: 10
                Text  { text: qsTr("Update frequecy"); font.family: params.textFamily; font.pixelSize: params.settingTxtTs; font.bold: true; color: params.labelColor }

                Button {text: updateFreq ; onClicked: { updateFreqDialog.open(); }}
            }

            Rectangle { id: ss2; height: 2; width: refWidth; color: params.settingSepColor }

            Column {
                spacing: 10
                Text  { text: qsTr("Market overview"); font.family: params.textFamily; font.pixelSize: params.settingTxtTs; font.bold: true; color: params.labelColor }
                Button { text: qsTr("Select symbols") ; onClicked: { mktOverviewSelectionDialog.open(); }}
            }

            Column {
                spacing: 10
                Text  { text: qsTr("Default view"); font.family: params.textFamily; font.pixelSize: params.settingTxtTs; font.bold: true; color: params.labelColor }
                ButtonRow {
                    id: mktViewButton
                    exclusive: true

                    Button {
                        id: idxs
                        checkable: true
                        text: qsTr("Indexes")
                        checked: appWindow.useMktViewDefault
                        onClicked: { appWindow.useMktViewDefault = true; }
                    }
                    Button {
                        id: news
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
                        checkable: true
                        text: qsTr("Quote")
                        checked: (!appWindow.usePortfolioView && !appWindow.useWidgetView)
                        onClicked: { appWindow.usePortfolioView = appWindow.useWidgetView = false; }
                    }
                    Button {
                        id: pfoRB
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
            checked: appWindow.useLocalMode
            onCheckedChanged: {
                appWindow.useLocalMode = checked;
            }
        }

        Rectangle { id: ss5; anchors { top: localModeTxt.bottom; topMargin: 20} height: 2; width: refWidth; color: params.settingSepColor }
//        Rectangle { id: ss5; anchors { top: column.bottom; topMargin: 20} height: 2; width: refWidth; color: params.settingSepColor }

        ////////////////////////////
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
            onCheckedChanged: {
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
            onCheckedChanged: {
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
            anchors { top: useSearch.bottom; topMargin: 20 }

            id: editGuide
            checked: appWindow.useEditGuide
            onCheckedChanged: {
                appWindow.useEditGuide = checked;
            }
        }

        ////////////////////////////
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
    }

    SelectionDialog {
        id: updateFreqDialog
        titleText: qsTr("Update Frequency")
        selectedIndex: appWindow.timerIdx

        model: ListModel {
            ListElement { name: "15 seconds"; value: 15   }
            ListElement { name: "30 seconds"; value: 30   }
            ListElement { name: "1 minute"  ; value: 60   }
            ListElement { name: "5 minutes" ; value: 300  }
            ListElement { name: "15 minutes"; value: 900  }
            ListElement { name: "30 minutes"; value: 1800 }
//            ListElement { name: "15 "+qsTr("seconds"); value: 15   }
//            ListElement { name: "30 "+qsTr("seconds"); value: 30   }
//            ListElement { name: "1 "+qsTr("minute");   value: 60   }
//            ListElement { name: "5 "+qsTr("minutes");  value: 300  }
//            ListElement { name: "15 "+qsTr("minutes"); value: 900  }
//            ListElement { name: "30 "+qsTr("minutes"); value: 1800 }
        }

        onAccepted: {
            appWindow.timerIdx = updateFreqDialog.selectedIndex;
            appWindow.timer    = timerValueLUT(updateFreqDialog.selectedIndex);
            //updateFreqDialog.model.get(updateFreqDialog.selectedIndex).value;
            updateFreq         = timerTextLUT(updateFreqDialog.selectedIndex);
        }
    }

    MultiSelectionDialog {
        id: mktOverviewSelectionDialog
        titleText: qsTr("Market Overview List")
        selectedIndexes: [0,1,2,3,4,5,6,7,8,9,10,11,12,13]
        model: ListModel {
            ListElement { name: "Down Jones"; symbol: "INDEXDJX:.DJI"    }
            ListElement { name: "S&P 500"; symbol: "INDEXSP:.INX"     }
            ListElement { name: "NASDAQ"; symbol: "INDEXNASDAQ:.IXIC"}
            ListElement { name: "Shanghai"; symbol: "SHA:000001"       }
            ListElement { name: "Nikkei 225"; symbol: "INDEXNIKKEI:NI225"}
            ListElement { name: "Hang Seng"; symbol: "INDEXHANGSENG:HSI"}
            ListElement { name: "TSEC"; symbol: "TPE:TAIEX"        }
            ListElement { name: "FTSE 100"; symbol: "INDEXFTSE:UKX"    }
            ListElement { name: "EU STOXX 50"; symbol: "INDEXSTOXX:SX5E"  }
            ListElement { name: "CAC 40"; symbol: "INDEXEURO:PX1"    }
            ListElement { name: "S&P TSX"; symbol: "TSE:OSPTX"        }
            ListElement { name: "S&P/ASX 200"; symbol: "INDEXASX:XJO"     }
            ListElement { name: "BSE Sensex"; symbol: "INDEXBOM:SENSEX"  }
            ListElement { name: "DAX"; symbol: "INDEXDB:DAX"  }
        }
        acceptButtonText: qsTr("Save")
        rejectButtonText: qsTr("Cancel")
    }

    // Currency
    // USD, GBP, CAD
    // HKD, TWD, CNY, JPY, INR, IDR
    // AUD
    // RUB
    /*
    MultiSelectionDialog {
        id: currencywSelectionDialog
        titleText: qsTr("Currency List")
        model: ListModel {
            ListElement { name: "USD"; }
            ListElement { name: "TWD"; }
        }
        acceptButtonText: qsTr("Save")
        rejectButtonText: qsTr("Cancel")
    }
    */
}
