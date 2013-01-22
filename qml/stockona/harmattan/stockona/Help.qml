import QtQuick 1.1
import com.nokia.meego 1.0
import "js/helpDesc.js" as T

Page {
    id: helpPage
    width: 600
    height: 480

    function helpPageHeight() {
        return (mainTitle.height + mainText.height +
                syncTitle.height + syncText.height +
                localPfoTitle.height + localPfoText.height +
                mktTitle.height + mktText.height + 250)
    }

    ///////////////////////////////
    // ToolBar
    ///////////////////////////////
    tools: ToolBarLayout {
        ToolIcon {
            id: backButton
            platformIconId: "toolbar-back";
            anchors.left: parent.left
            onClicked: { pageStack.pop(); }
        }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: "black"

        Flickable {
            anchors.fill: parent
            anchors { leftMargin: 20; rightMargin: 20; topMargin: 20; bottomMargin: 20 }
            contentHeight: helpPageHeight()

            Column {
                id: col
                anchors { top: parent.top; left: parent.left; right: parent.right }
                spacing: 20

                Text {
                    id: mainTitle

                    font.pixelSize: params.helpTitleTs
                    font.bold: true
                    color: "white"
                    text: qsTr("Overview")
                    font.family: params.textFamily
                }

                Text {
                    id: mainText
                    width: parent.width

                    font.pixelSize: params.helpTxtTs
                    font.family: params.textFamily
                    color: "white"
                    text: T.generalTxt();
                    wrapMode: Text.WordWrap
                }

                Text {
                    id: localPfoTitle

                    font.pixelSize: params.helpTitleTs
                    font.family: params.textFamily
                    font.bold: true
                    color: "white"
                    text: qsTr("Portfolio Editing")
                }

                Text {
                    id: localPfoText
                    width: parent.width

                    font.pixelSize: params.helpTxtTs
                    font.family: params.textFamily
                    color: "white"
                    text: T.localPfoTxt();
                    wrapMode: Text.WordWrap
                }

                Text {
                    id: syncTitle

                    font.pixelSize: params.helpTitleTs
                    font.family: params.textFamily
                    font.bold: true
                    color: "white"
                    text: qsTr("Portfolio Syncing/Import")
                }

                Text {
                    id: syncText
                    width: parent.width

                    font.pixelSize: params.helpTxtTs
                    font.family: params.textFamily
                    color: "white"
                    text: T.syncTxt();
                    wrapMode: Text.WordWrap
                }

                Text {
                    id: mktTitle

                    font.pixelSize: params.helpTitleTs
                    font.family: params.textFamily
                    font.bold: true
                    color: "white"
                    text: qsTr("Market Overview")
                }

                Text {
                    id: mktText
                    width: parent.width

                    font.pixelSize: params.helpTxtTs
                    font.family: params.textFamily
                    color: "white"
                    text: T.mktOverviewTxt();
                    wrapMode: Text.WordWrap
                }
                Text {
                    id: rev

	                font.pixelSize: params.helpTitleTs - 10
                    color: "white"
                    text: T.revTxt()
                    font.family: params.textFamily
                }
            }
        }
    }
}
