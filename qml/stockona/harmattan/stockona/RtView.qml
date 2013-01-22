import QtQuick 1.1
import com.nokia.meego 1.0
import com.nokia.extras 1.1

Page {
    id: container
    width: 600
    height: 480

    property string mySym: ""
    property string myExg: ""
    property string myName: ""
    //property int rtId: -1

    signal close
    signal home

    ///////////////////////////////
    // Function
    ///////////////////////////////
    function activatePosFinder() {
        // Reset specified portfolio every time for now
        posFinderSheet.psIdx = 0;

        posFinderSheet.noSearchMode = true;
        posFinderSheet.myName = myName;
        posFinderSheet.mySym  = mySym;
        posFinderSheet.myExg  = myExg;

        posFinderSheet.symInput    = "";
        posFinderSheet.pfoStoreIdx = 0;
        posFinderSheet.myPfoName   = "";

        appWindow.loadPfoStoreModel();

        if (pfoStoreModel.count>0) {
            posFinderSheet.pfoStoreIdx = pfoStoreModel.get(0).idx;
            posFinderSheet.myPfoName   = pfoStoreModel.get(0).name;
        }

        posFinderSheet.open();
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
                container.close();
            }
        }
        ToolIcon {
            id: homeButton
            platformIconId: "toolbar-home";
            visible: plus
            anchors.centerIn: parent
            onClicked: {
                container.home();
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
        height: 67
        color: params.headerColor
        z: 1

        Label {
            id: label
            text: appWindow.posName + qsTr(" Related")
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: params.headerLeftMargin
            platformStyle: LabelStyle {
                textColor: "white"
                fontPixelSize: params.headerTxtTs
            }
        }

//        Text {
//            text: posName + " News"
//            anchors.verticalCenter: parent.verticalCenter
//            anchors.left: parent.left
//            anchors.leftMargin: params.headerLeftMargin
//            color: "white"
//            font.pixelSize: 35
//            font.family: params.textFamily
//        }
    }

    ListView {
        id: rtView
        anchors.top: header.bottom
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom ; topMargin: 2 }

        model: rtModel
        delegate: rtDelegate
        snapMode: ListView.SnapToItem
     }

    Component {
        id: rtDelegate

        Item {
            id: rtDelegateItem
            width: rtView.width
            height: (nameBox.height + fullNameBox.height + 7) // 67

            property bool self: (id==0)

            // Anchor is more efficient
            Rectangle {
                id: background
                anchors.fill: parent
                anchors.bottomMargin: (self) ? 2 : 1
                color: params.bkgColor
            }

            /*
            "name":          jObj.company.related.row[i].values[0],
            "fullname":      jObj.company.related.row[i].values[1],
            "quotePrice":    jObj.company.related.row[i].values[2],
            "quoteChg":      tmp.sign + jObj.company.related.row[i].values[4],
            "quoteChgColor": tmp.color,
            "quoteChgPtg":   tmp.sign + jObj.company.related.row[i].values[5],
            "quoteMktCap":   jObj.company.related.row[i].values[7],
            "exchange":      jObj.company.related.row[i].values[8]
            */

            Text {
                id: nameBox
                anchors { top: background.top; left: background.left; }
                anchors { topMargin: 5; leftMargin: 5; }
//                verticalAlignment: Text.AlignVCenter

                text: name
                font.bold: true
                font.pixelSize: params.rtViewTxtTs
                color: params.labelColor
            }
            Text {
                id: priceBox
                anchors { top: background.top; right: gainBox.left; }
                anchors { topMargin: 5; rightMargin: 15; }

                horizontalAlignment: Text.AlignRight
//                verticalAlignment: Text.AlignVCenter

                font.pixelSize: params.rtViewTxtTs
                text: quotePrice
                color: params.labelColor
            }
            Text {
                id: gainBox
                anchors { top: background.top; right: parent.right; }
                anchors { topMargin: 5; rightMargin: 5; }

                horizontalAlignment: Text.AlignRight
//                verticalAlignment: Text.AlignVCenter

                font.pixelSize: params.rtViewTxtTs
                text: quoteChg + " (" + quoteChgPtg + "%)"
                color: quoteChgColor
            }
            Text {
                id: fullNameBox
                anchors { top: nameBox.bottom; left: background.left; }
                anchors { topMargin: 2; leftMargin: 5; }
                opacity: 0.8

//                horizontalAlignment: Text.AlignRight
//                verticalAlignment: Text.AlignVCenter

                font.pixelSize: params.rtViewTxtTs - 4
                text: fullname //+ "  " + quoteMktCap
                color: params.labelColor
            }

            MouseArea {
                id: rtMouseArea
                anchors.fill: background
                onClicked: {
                    //rtDelegateItem.ListView.view.currentIndex = index;
                    //rtId = index;
                    if (index>0) {
                        myName = fullname;
                        mySym  = name;
                        myExg  = exchange;

                        activatePosFinder();
                    }
                }
            }

            states: [
                State {
                    name: "Pressed"
                    when: rtMouseArea.pressed && (index > 0)
                    PropertyChanges { target: background; color: params.pressColor }
                }
//                ,
//                State {
//                    name: "highlightCurrentItem"
//                    when: rtId == index
//                    PropertyChanges { target: background; color: params.currentItemColor }
//                }
            ]
         }
    }
}

