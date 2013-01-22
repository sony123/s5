import QtQuick 1.1
import com.nokia.meego 1.0
import com.nokia.extras 1.1

//Component {
//    id: newsViewComp
Page {
    id: container
    width: 600
    height: 480

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
                if (container.state == "details") {
                    // myNewsLink is set from default to details so clear here.
                    myNewsLink = "";
                    container.state = "";
                }
                else {
//                    if (rssModel.status==XmlListModel.Error) {
                        rssModel.source = "";
//                    }

                    container.close();
                }
            }
        }
        ToolIcon {
            id: homeButton
            platformIconId: "toolbar-home";
            anchors.centerIn: parent
            visible: plus
            onClicked: {
                myNewsLink = "";
                container.state = "";
                if (rssModel.status==XmlListModel.Error) {
                    rssModel.source = "";
                }
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
        height: params.headerHeight
        color: params.headerColor
        z: 1

        Label {
            id: label
            text: appWindow.posName + qsTr(" News")
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

    Rectangle {
        id: descRect
//        x: parent.width; y: header.height
//        width: parent.width
//        height: parent.height

        anchors.top: header.bottom
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom ; }
        opacity: 0

        color: params.bkgColor

        Flickable {
            id: descFlick
            anchors.fill: parent
            anchors { topMargin: 10; bottomMargin: 10; }

            contentWidth: parent.width + 2
            contentHeight: descText.height + 80

            Text {
                id: descText;
                wrapMode: Text.WordWrap;
                anchors { top: parent.top; left: parent.left; right: parent.right; }
                anchors { leftMargin: 10; rightMargin: 10;}
                font.pixelSize: params.newsTxtTs
                //font.family: params.textFamily
                text: myDescription
                color: params.labelColor
            }

            SimpleButton{
                id: readMoreText
                height: params.simpleButtonHeight
                anchors { left: descText.left; right: descText.right; top: descText.bottom; }
                anchors { topMargin: 20; }
                text: qsTr("Read More")
                textSize: params.newsTxtTs

                onClicked: {
                    Qt.openUrlExternally(myNewsLink);
                }
            }

            onContentXChanged: {
                // Flick Left
                //if (contentX >= params.flickMargin) {}
                // Flick right
                if (contentX <= -params.flickMargin) {
                    if (container.state == "details") {
                        // myNewsLink is set from default to details so clear here.
                        contentX = 0;
                        myNewsLink = "";
                        container.state = "";
                    }
                }
            }
        }
    }

    ListView {
        id: newsView
//        x: 0; y: header.height+2
//        width: parent.width
//        height: parent.height

        anchors.top: header.bottom
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom ; topMargin: 2 }

        model: rssModel
        delegate: newsDelegate
        snapMode: ListView.SnapToItem

        // Section header
//        section.property: "date"
//        section.criteria: ViewSection.FullString
//        section.delegate: sectionComp

        visible: rssModel.status==XmlListModel.Ready
    }

    Component {
        id: newsDelegate

        Item {
            id: newsDelegateItem
            width: newsView.width
            height: titleBox.height + 55

            Rectangle {
                id: background
                y:1; width: parent.width; height: parent.height - y*2
                // anchors loop
//                anchors.fill: parent
//                anchors { topMargin: 1; bottomMargin: 1 }
                color: params.bkgColor
                radius: 5
            }

            Text {
                id: titleBox
                anchors { top: background.top; left: background.left; right: moreIndicator.left; leftMargin: 10; topMargin: 10 }

                font.pixelSize: params.newsTxtTs
                //font.family: params.textFamily
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

                font.pixelSize: params.newsTxtTs - 6
                //font.family: params.textFamily
                //wrapMode: Text.WordWrap;
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
                        myDescription = removeLinks(parseDesc(newsView.model.get(newsView.currentIndex).desc));
                        myNewsLink = newsView.model.get(newsView.currentIndex).link;

                        container.state="details";
//                        if (container.state == "details") { container.state=''; }
//                        else                              { container.state='details'; }
                    }
                }

                onContentXChanged: {
                    // Flick Left
//                    if (contentX >= params.flickMargin) {
//                        newsDelegateItem.ListView.view.currentIndex = index;
//                        myDescription = removeLinks(newsView.model.get(newsView.currentIndex).desc);
//                        myNewsLink = newsView.model.get(newsView.currentIndex).link;

//                        container.state="details";
//                    }
                    // Flick right
                    if (contentX <= -params.flickMargin) {
                        contentX = 0;
                        if (rssModel.status==XmlListModel.Error) {
                            rssModel.source = "";
                        }

                        container.close();
                    }
                }
            }
        }
    }

    states: [
        State {
            name: "details"

            PropertyChanges { target: descRect; opacity: 1  }
            PropertyChanges { target: newsView; opacity: 0  }

            StateChangeScript { script: dbgStr = "State.newsView.details"; }
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
//}

