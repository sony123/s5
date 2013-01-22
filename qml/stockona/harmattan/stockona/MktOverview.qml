import QtQuick 1.1
import com.nokia.meego 1.0
import com.nokia.extras 1.1

Page {
    id: container
    width: 300
    height: 500

    // Google mobile related news: http://www.google.com/m/finance?hl=en&tab=we#news
    property string chartUrl: "http://www.google.com/finance/chart?cht=c&tlf=12h&q=INDEXDJX:.DJI,INDEXSP:.INX,INDEXNASDAQ:.IXIC"
    property string myDescription: ""
    property string myNewsLink: ""

    signal close
    signal home

    ///////////////////////////////
    // Function
    ///////////////////////////////

    ///////////////////////////////
    // ToolBar
    ///////////////////////////////
    tools: ToolBarLayout {
        ToolIcon {
            id: backButton
            platformIconId: "toolbar-back";
            anchors.left: parent.left
            onClicked: {
                if (appWindow.useMktViewDefault && container.state == "newsList") {
                    container.state = "";
                }
                else if (appWindow.useMktViewDefault && container.state == "") {
                    rssModel.source = "";
                    container.close();
                }
                else if (!appWindow.useMktViewDefault && container.state == "newsList") {
                    rssModel.source = "";
                    container.close();
                }
                else if (!appWindow.useMktViewDefault && container.state == "") {
                    container.state = "newsList";
                }
                else {
                    myNewsLink = "";
                    container.state = "newsList";
                }

                /*
                if (container.state == "newsDetail") {
                    myNewsLink = "";
                    container.state = "newsList";
                }
                else if (container.state == "newsList") {
                    container.state = "";
                }
                else {
                    rssModel.source = "";
                    container.close();
                }
                */
            }
        }
        ToolIcon {
            id: refreshButton
            platformIconId: "toolbar-refresh1";
            anchors.centerIn: parent
            visible: (container.state=="")
            opacity: (waitState.state!="hidden") ? 0.3 : 1
            onClicked: {
                if (waitState.state=="hidden")
                    appWindow.updateOverview();
            }
        }
        ToolIcon {
            id: homeButton
            platformIconId: "toolbar-home";
            anchors.centerIn: parent
            visible: plus && (container.state!="")
            onClicked: {
                myNewsLink = "";
                container.state = "";
                rssModel.source = "";
                container.home();
            }
        }
        ToolIcon {
            id: viewButton
            platformIconId: "toolbar-pages-all";
            visible: container.state!="newsDetail"
            onClicked: {
                if (container.state == "") { container.state = "newsList"; }
                else                       { container.state = ""; }
            }
        }
    }

    PageIndicator {
        id: pageIndicator
        anchors { bottom:  parent.bottom; bottomMargin: params.pgiMargin }
        anchors.horizontalCenter: parent.horizontalCenter
        z: 2
        objectName: "pageIndicatorObject"
        currentPage: 2
        totalPages: 3
    }

    Rectangle {
        id: header
        width: parent.width
        height: params.headerHeight
        color: params.headerColor
        z: 1

        Label {
            id: label
            text: (container.state=="") ? qsTr("Market Indexes") : (qsTr("Market News - ") + overviewNewsDialog.model.get(overviewNewsDialog.selectedIndex).name)
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: params.headerLeftMargin/2
            platformStyle: LabelStyle {
                textColor: "white"
                fontPixelSize: params.headerTxtTs
            }
        }

        Image {
            anchors { right: parent.right; rightMargin: 10 }
            anchors.verticalCenter: parent.verticalCenter
            source: "/usr/share/themes/blanco/meegotouch/icons/icon-m-textinput-combobox-arrow.png"
            visible: container.state=="newsList"
        }

        MouseArea {
            id: headerMouseArea
            anchors.fill: parent
            visible: container.state=="newsList"
            onClicked: {
                overviewNewsDialog.open();
            }
        }

        states: [
            State {
                name: "Pressed"
                when: container.state=="newsList" && headerMouseArea.pressed
                PropertyChanges { target: header; color: "grey" }
            }
        ]
    }

    SelectionDialog {
        id: overviewNewsDialog
        titleText: qsTr("Select news region")
        selectedIndex: appWindow.overviewNewsIdx

        model: ListModel {
                ListElement { name: "US";        } // 0
                ListElement { name: "Canada";    } // 1
                ListElement { name: "Mexico";    } // 2
                ListElement { name: "Brazil";    } // 3
                ListElement { name: "UK";        } // 4
                ListElement { name: "France";    } // 5
                ListElement { name: "Germany";   } // 6
                ListElement { name: "Spain";     } // 7
                ListElement { name: "Russian";   } // 8
                ListElement { name: "South Africa"; } // 9
                ListElement { name: "Singapore"; } // 10
                ListElement { name: "Malaysia";  } // 11
                ListElement { name: "Taiwan";    } // 12
                ListElement { name: "HK";        } // 13
                ListElement { name: "China";     } // 14
                ListElement { name: "India";     } // 15
        }

        onAccepted: {
            appWindow.overviewNewsIdx    = overviewNewsDialog.selectedIndex;
            appWindow.overviewNewsRegion = appWindow.mktOverviewValueLUT(overviewNewsDialog.selectedIndex);
        }
    }

    /*
    Market News - Powered by Google News RSS
    http://news.google.com/news?cf=all&ned=us&hl=en&topic=b&output=rss

    au Australia
    uk UK
    fr France
    BR_br Brasil
    ca Canada
    es_ar Argentina
    es_mx Mexico
    de Deutschland
    cn China
    tw Taiwan
    jp Japan
    hk Hong Kong
    en_my Malaysia
    en_sg Singapore
    in India
    */

    // Snapshot
    ListView {
        id: overView
        anchors.top: header.bottom
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom ; topMargin: 2 }

        model: overviewModel
        delegate: overviewDelegate
        snapMode: ListView.SnapToItem
    }

    Component {
        id: overviewDelegate

        Item {
            id: overviewDelegateItem
            width: overView.width
            height: 42

            Rectangle {
                id: background
                anchors.fill: parent
                anchors { topMargin: 0; bottomMargin: 1 }
                color: params.bkgColor
            }

            Text {
                id: titleBox
                anchors { top: background.top; left: background.left; leftMargin: 5; topMargin: 10 }

                font.pixelSize: params.mktOverTs
                text: name
                font.bold: (type=="h") ? true : false
                color: params.labelColor
            }

            Text {
                id: priceBox
                anchors { top: background.top; topMargin: 10 }
                anchors { horizontalCenterOffset: 10; horizontalCenter: parent.horizontalCenter;  }

                // hide when entry is a header
                visible: type!="h"

                font.pixelSize: params.mktOverTs
                text: quotePrice
                color: params.labelColor
            }

            Text {
                id: changeBox
                anchors { top: background.top; right: background.right; rightMargin: 5; topMargin: 10 }

                // hide when entry is a header
                visible: type!="h"

                font.pixelSize: params.mktOverTs
                text: (type=="s") ? quoteChg + "(" + quoteChgPtg + "%)" : quoteChgPtg
                color: quoteChgColor
            }

            Flickable {
                id: overviewMouseArea
                anchors.fill: background
                contentWidth: background.width + 2

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (appWindow.useMktViewDefault)
                            container.state = "newsList";
                    }
                }

                onContentXChanged: {
                    // Flick Left
                    if (contentX >= params.flickMargin) {
                        contentX = 0;
                        container.state = "newsList";
                    }
                    // Flick right
                    else if (contentX <= -params.flickMargin) {
                        contentX = 0;
                        container.close();
                    }
                }
            }
        }
    }


    // News
    ListView {
        id: newsView
        opacity: 0
        anchors.top: header.bottom
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom ; topMargin: 2 }

        model: rssModel
        delegate: newsDelegate
        snapMode: ListView.SnapToItem

        visible: rssModel.status==XmlListModel.Ready
    }

    Component {
        id: newsDelegate

        Item {
            id: newsDelegateItem
            width: newsView.width
            height: titleBox.height + 55 //35 //80

            Rectangle {
                id: background
                y:1; width: parent.width; height: parent.height - y*2
                // anchor loop
                //anchors.fill: parent
                //anchors { topMargin: 1; bottomMargin: 1 }
                color: params.bkgColor
                radius: 0
            }

            Text {
                id: titleBox
                anchors { top: background.top; left: background.left; right: moreIndicator.left; }
//                anchors { top: background.top; left: background.left; right: background.right; }
                anchors { leftMargin: 10; topMargin: 10; rightMargin: 10 }

                font.pixelSize: params.mktNewsTs
                wrapMode: Text.WordWrap;
                text: title
                textFormat: Text.RichText
                color: params.labelColor
            }

            MoreIndicator {
                id: moreIndicator
                anchors { right: background.right; rightMargin: 10; top: background.top; topMargin: 15 }
//                anchors.verticalCenter: background.verticalCenter
                objectName: "indicatorObject"
            }

            Text {
                id: dateBox
                anchors { left: background.left; bottom: background.bottom; leftMargin: 10; rightMargin: 10; bottomMargin: 10 }

                font.pixelSize: params.mktNewsTs - 6
                text: date
                color: "grey"
            }

            Flickable {
                id: newsMouseArea
                anchors.fill: background
                contentWidth: background.width + 2

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        newsDelegateItem.ListView.view.currentIndex = index;
                        //myDescription = removeLinks(newsView.model.get(newsView.currentIndex).desc);
                        myDescription = parseDesc(newsView.model.get(newsView.currentIndex).desc);
                        myNewsLink = newsView.model.get(newsView.currentIndex).link;
                        //console.log(myDescription);

                        container.state = "newsDetail";
                    }
                }

                onContentXChanged: {
                    // Flick Left
//                    if (contentX >= params.flickMargin) {
//                    }
                    // Flick right
                    if (contentX <= -params.flickMargin) {
                        contentX = 0;
                        // myNewsLink is set from default to details so clear here.
                        myNewsLink = "";
                        container.state = "";
                    }
                }
            }
        }
    }

    Rectangle {
        id: descRect
        anchors.top: header.bottom
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom ; }

        color: params.bkgColor //(useDarkTheme) ? "#7A7A7A" : "ivory"
        opacity: 0

        Flickable {
            id: descFlick
            anchors.fill: parent
            anchors { topMargin: 10; bottomMargin: 10; }

            contentWidth: parent.width + 1
            contentHeight: descText.height + 80

            Text {
                id: descText;
                wrapMode: Text.WordWrap;
                anchors { top: parent.top; left: parent.left; right: parent.right; }
                anchors { leftMargin: 10; rightMargin: 10;}
                font.pixelSize: params.mktNewsTs
                //font.family: params.textFamily
                text: myDescription
                color: params.labelColor //(useDarkTheme) ? "#303030" : "black"
            }

            SimpleButton{
                id: readMoreText
                height: params.simpleButtonHeight
                anchors { left: descText.left; right: descText.right; top: descText.bottom; }
                anchors { topMargin: 20; }
                text: qsTr("Read More")
                textSize: params.mktNewsTs

                onClicked: {
                    Qt.openUrlExternally(myNewsLink);
                }
            }

            onContentXChanged: {
                // Flick Left
//                if (contentX >= params.flickMargin) {
//                }
                // Flick right
                if (contentX <= -params.flickMargin) {
                    contentX = 0;
                    myNewsLink = "";
                    container.state = "newsList";
                }
            }
        }
    }

    states: [
        State {
            name: ""

            PropertyChanges { target: pageIndicator; currentPage: (useMktViewDefault) ? 2 : 3 }
            PropertyChanges { target: overView; opacity: 1  }
            PropertyChanges { target: newsView; opacity: 0  }
            PropertyChanges { target: descRect; opacity: 0  }

            StateChangeScript { script: dbgStr = "State.mktOverview.default"; }
        },
        State {
            name: "newsList"

            PropertyChanges { target: pageIndicator; currentPage: (useMktViewDefault) ? 3 : 2 }
            PropertyChanges { target: overView; opacity: 0  }
            PropertyChanges { target: newsView; opacity: 1  }
            PropertyChanges { target: descRect; opacity: 0  }

            StateChangeScript { script: dbgStr = "State.mktOverview.news"; }
        },
        State {
            name: "newsDetail"

            PropertyChanges { target: pageIndicator; currentPage: (useMktViewDefault) ? 3 : 2 }
            PropertyChanges { target: overView; opacity: 0  }
            PropertyChanges { target: newsView; opacity: 0  }
            PropertyChanges { target: descRect; opacity: 1  }

            StateChangeScript { script: dbgStr = "State.mktOverview.details"; }
        }
    ]

    transitions: [
        Transition {
            ParallelAnimation {
                PropertyAnimation { target: descRect; properties: "opacity"; from:0; duration: 130}
                PropertyAnimation { target: newsView; properties: "opacity"; from:0; duration: 130}
            }
        }
    ]
}

