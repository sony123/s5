import QtQuick 1.0
import com.nokia.meego 1.0
import "inneractive"
//full screen interstitial ad
//(well should be used fullscreen but you need to specify width and height still
//options:
//      message text: something like "A quick word from our sponsors
//      color: background color for panel
//      skip in: number of seconds before ad can be skipped

Rectangle {
    id: adWrapper

    //specific to interstitials
    color: "black"
    property alias messageText: sponsorText.text
//    property alias appid: ad.appid
    property int skipIn:  0

    //private
    property int __skippingIn:  -1

    function requestAd() {
        console.log("--- Request Ad ---");
        ad.requestAd();
        //rotateTimer.start();

        //disable skip button and restart timer
        if(skipIn > 0) {
            __skippingIn = skipIn
            skipButton.disabled = true;
            skipTimer.start();
        }
    }

    function hide() {
        visible = false;
        adWrapper.state = "";
    }

    function show() {
        visible = true;
        adWrapper.state = "shown";
    }

    Text {
        id: sponsorText
        text: qsTr("Stockona is free thanks to ads. Please consider supporting us by clicking the banner.")
        anchors { top: parent.top; left: parent.left; right: parent.right }
        anchors { topMargin: 25; leftMargin: 50; rightMargin: 50 }
        font.pointSize: 18
        opacity: 0.7
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        color: "white"
    }

    // Dummy MouseArea to capture focus
    MouseArea {
        anchors.fill: parent
    }

    Column {
        id: buttons
        spacing: 10
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:  parent.bottom
        anchors.bottomMargin: 25

        //skip button
        Button {
            id: skipButton
            platformStyle: ButtonStyle { inverted: true }
            text: (__skippingIn+1 > 0) ? qsTr("Skip in ") + __skippingIn + " s" : qsTr("Skip")
            property bool disabled: false

            onClicked: {
                console.log("skip pressed");
                if(skipButton.disabled == false) {
                    console.log("skipTimer stopped");
                    skipTimer.stop();
                    //rotateTimer.stop();
                    adWrapper.hide();
                }
            }
        }

        //visit link button
        Button {
            text: qsTr("Open Link")
            platformStyle: ButtonStyle { inverted: true }

            onClicked: {
                //rotateTimer.stop();
                skipButton.disabled = false;
                ad.clickAd();
            }
        }
    }

//    InnerActiveAd {
//        id: ad
//        width: parent.width
//        screenWidth: 640
//        screenHeight: 360
//        anchors { top: sponsorText.bottom; bottom: buttons.top; topMargin: 10; bottomMargin: 10 }
//    }

//    Timer {
//        id: rotateTimer
//        interval: 60000      //countdown timer
//        repeat: true
//        running: appWindow.updateTimerActive()

//        onTriggered: {
//            console.log("--- Rotate ad ---");
//            ad.requestAd();
//        }
//    }

    Text {
        anchors.centerIn: parent
        font.pixelSize: 18
        color: "white"
        visible: ad.status != "Done" && ad.status != "Loading"
        text: params.adStr
        MouseArea {
            anchors.fill: parent
            onClicked: {
                Qt.openUrlExternally(params.adUrl);
            }
        }
    }

    AdItem {
        id: ad

        parameters: AdParameters {
            applicationId: params.appId
            usePositioning: params.usePosition
        }
        anchors.centerIn: parent

        showText: false
        reloadInterval: params.reloadAdInterval
        timerActive: (adWrapper.state=="shown") && Qt.application.active
    }

    Timer {
        id: skipTimer
        interval: 1000      //countdown timer
        repeat: true

        onTriggered: {
            __skippingIn--;
            console.log(__skippingIn);
            if(__skippingIn == -1) {
                skipButton.disabled = false;
                skipTimer.stop();
                console.log("Ad finished");
            }
//            else {
//                __skippingIn--;
//            }
        }
    }

    states: [
        State { name: "shown" }
    ]
}
