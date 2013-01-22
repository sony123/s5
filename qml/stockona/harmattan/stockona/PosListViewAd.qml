import QtQuick 1.1
import com.nokia.meego 1.0
import com.nokia.extras 1.1
import "inneractive"

Page {
    id: container

    property bool usePortfolioView: appWindow.usePortfolioView
    property bool useWidgetView: appWindow.useWidgetView
    property bool showSection: false

    property int selectedIdx: 0
    property string chartView: ""
    property string chartCmp: ""
    property bool isLandscape: ( width > height )
    property int refWidth: parent.width - 20 // minus margin
    property string txLink: ""

    property string pfoBannerValue;
    property string pfoBannerGain;
    property string pfoBannerGainPtg;
    property bool pfoBannerStart: false

    signal inTxView
    signal inRtView
    signal inNewsView
    signal inStatsView
    signal back

    //* Internal data. The ListModel get method can be invalid so binding is not good.
    property string myName            : ""
    property string myExg             : ""
    property string myFullname        : ""

    property string myQuotePrice      : ""
    property color  myQuoteChgColor   : "green"
    property string myQuoteChg        : ""
    property string myQuoteChgPtg     : ""
    property string myQuoteAsk        : ""
    property string myQuoteBid        : ""
    property string myShare           : ""
    property string myShareValue      : ""
    property string myShareCost       : ""
    property string myShareDayGain    : ""
    property string myShareGain       : ""
    property string myShareGainPercent: ""

    property string myQuoteDayHi      : ""
    property string myQuoteDayLo      : ""
    property string myQuote52wHi      : ""
    property string myQuote52wLo      : ""
    property string myQuoteMktCap     : ""

    property string myQuoteEps        : ""
    property string myQuotePe         : ""
    property string myQuoteBeta       : ""
    property string myQuoteVol        : ""
    property string myQuoteAvgVol     : ""

    property string myQuoteDiv        : ""
    property string myQuoteYld        : ""

    property string myAfterPrice      : ""
    property string myAfterChg        : ""
    property string myAfterChgPtg     : ""
    property color  myAfterChgColor   : "green"

    function activateBannerAd() {
        if (adBannerLoader.status==Loader.Null) {
            adBannerLoader.sourceComponent = adBannerComponent;
        }
        adBannerLoader.item.requestAd();
    }

    ///////////////////////////////
    // ToolBar
    ///////////////////////////////
    tools: ToolBarLayout {
        ToolIcon {
            id: viewButton
            visible: container.state!="details" && !settingMenu.useSearchShortcut
            platformIconId: "toolbar-pages-all";
            anchors.left: parent.left
            onClicked: { toggleView(); }
        }
        ToolIcon {
            id: searchButton
            platformIconId: "toolbar-search";
            anchors.left: parent.left
            visible: container.state!="details" && settingMenu.useSearchShortcut
            opacity: (appWindow.state == "inMainView") ? 1 : 0.5
            enabled: appWindow.state == "inMainView"
            onClicked: {
                activatePosFinder();
            }
        }
        ToolIcon {
            id: backButton
            visible: container.state=="details"
            platformIconId: "toolbar-back";
            anchors.left: parent.left
            onClicked: {
                txMenu.close();
                container.back();
            }
        }
        // Refresh button in detailed view
        ToolIcon {
            id: detailRefreshButton
            anchors.centerIn: parent
            platformIconId: "toolbar-refresh1";
            visible: container.state=="details"
            opacity: (waitState.state!="hidden") ? 0.3 : 1
            onClicked: {
                //if (!plus) { activateBannerAd(); }
                if (waitState.state=="hidden")
                    appWindow.__loadPosition();
            }
        }

        Button {
            id: mainRefreshButton
            text: signature
            anchors.centerIn: parent
            visible: container.state!="details"
            platformStyle: ButtonStyle {
                background: "image://theme/meegotouch-toolbar-portrait"+__invertedString+"-background"
                pressedTextColor: "#B0D8FF"
                pressedBackground: "image://theme/meegotouch-button"+__invertedString+"-background"
            }
            onClicked: {
                if (!plus) { activateBannerAd(); }
                if (waitState.state=="hidden")
                    appWindow.__loadPosition();
            }
        }
        ToolIcon {
            platformIconId: "toolbar-view-menu";
            visible: !((container.state=="details") && pfoIsYahoo)
            anchors.right: parent===undefined ? undefined : parent.right
            onClicked: {
                // normal menu
                if (container.state!="details") {
                    if (menu.status == DialogStatus.Closed) { menu.open(); }
                    else { menu.close(); }
                }
                else {
                    if (txMenu.status == DialogStatus.Closed) { txMenu.open(); }
                    else { txMenu.close(); }
                }
            }
        }
    }

    Menu {
        id: txMenu
        visualParent: pageStack
        MenuLayout {
            MenuItem {
                text: qsTr("Related Symbols");
                onClicked: {
                    appWindow.__loadGoogleRelated(myName, myExg);
                    container.inRtView();
                }
            }
            MenuItem {
                text: qsTr("Show Transactions");
                visible: !pfoIsYahoo
                onClicked: {
                    if (pfoIsLocal) {
//                        console.log("selectedIdx=" + selectedIdx + " (sym,exg)=("
//                                    + fileHandler.localUniSymbol[selectedIdx] + ","
//                                    + fileHandler.localUniExg[selectedIdx] + ")");

                        // Reload pos, localPos is cleared when leaving pfoView
                        fileHandler.loadPos(appWindow.activePos);

                        if (fileHandler.localUniExg[selectedIdx]=="")
                            appWindow.loadLocalTx(appWindow.activePos, myName, "");
                        else
                            appWindow.loadLocalTx(appWindow.activePos, myName, myExg);
                        txView.editMode = false;
                        container.inTxView();
                    }
                    else {
                        appWindow.__loadTx(txLink);
                        txView.txLink = txLink;
                        container.inTxView();
                    }
                }
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
        visible: false
    }

    ///////////////////////////////
    // function
    ///////////////////////////////
    function toggleView () {
        // normal - portfolio - widget
        if (container.usePortfolioView==true) {
            container.useWidgetView    = true;
            container.usePortfolioView = false;
        }
        else if (container.useWidgetView == false) {
            container.useWidgetView    = false;
            container.usePortfolioView = true;
        }
        else {
            container.useWidgetView    = false;
            container.usePortfolioView = false;
        }
    }

    function changeState() {
        container.state = 'details';
        container.inStatsView();
    }

    function chartUrl(sym, exg, chartType, google) {
        var url;
        var iParam;

        if (exg=="TYO") {
            // 5d: i=240
            // 1,3,6M,1Y: i=86400
            // 5Y: i=604800
            chartType = (chartType=="5d") ? chartType : chartType.toUpperCase();

            if (chartType=="5d")      { iParam = "240"; }
            else if (chartType=="5y") { iParam = "604800"; }
            else                      { iParam = "86400"; }

            url = (chartType=="") ? "" : "http://www.google.com/finance/getchart?q=" + sym + "&x=" + exg + "&p=" + chartType.toUpperCase() + "&i=" + iParam;

        }
        else
            url = (chartType=="") ? "" : "http://chart.finance.yahoo.com/z?s=" + __convertExchangeForYahoo(sym, exg) + "&t=" + chartType + "&q=l&l=off&z=m&a=v" + chartCmp;

        //console.log(url);
        return url;
    }

    function showPfoBanner() {
        pfoBannerValue = pfoBannerGain = pfoBannerGainPtg = "";
        if (pfoModel.count > appWindow.pfoSelectedIdx) {
            pfoName = pfoModel.get(pfoSelectedIdx).name;
            pfoBannerValue = pfoModel.get(appWindow.pfoSelectedIdx).value;
            pfoBannerGain  = pfoModel.get(appWindow.pfoSelectedIdx).gain;
            var pfoBannerCost = pfoModel.get(appWindow.pfoSelectedIdx).cost;
            pfoBannerGainPtg = fileHandler.calcGainPtg(pfoBannerCost, pfoBannerGain);
            //pfoBannerGainPtg = 100*jRound(pfoModel.get(appWindow.pfoSelectedIdx).gain/pfoBannerCost);
            pfoBanner.state = "show";
            //console.log("cost="+pfoBannerCost+" gain="+pfoBannerGain);
        }
    }

    Rectangle {
        id: posViewBackground
        anchors.fill: parent
        color: params.posViewBkgColor
    }

    // Portrait detail windows
    Loader {
        id: viewLoader
        anchors.fill: parent
        sourceComponent: useWidgetView ? widgetViewComp : containerComp
        onLoaded: viewLoaderAnim.start()
    }

    PropertyAnimation { id:viewLoaderAnim; target: viewLoader; properties: "opacity"; easing.type: Easing.InBack; duration: 130 }

    Item {
        id: portraitDetail
        anchors.fill: parent
        opacity: 0

        // 0.3.2: Re-layout to address potential overflown issue because elide doesn't work for infoTxt.
        Text {
            id: symbolBox
            anchors { left: parent.left; leftMargin: 10 }

            font.bold: true
            font.pixelSize: params.posViewSymbolTs
            color: params.labelColor
            text: myName
        }

        Text {
            id: priceBox
            anchors { top: parent.top; right: parent.right; rightMargin: 10; topMargin: 3 }
            font.pixelSize: params.posViewPricelTs
            color: params.labelColor
            text: myQuotePrice
        }

        Text {
            id: gainBox
            anchors { top: priceBox.bottom; right: parent.right; topMargin: 0; rightMargin: 10; }

            color: myQuoteChgColor
            font.pixelSize: params.posViewPricelTs
            text: myQuoteChg + " (" + myQuoteChgPtg + "%)"
        }

        Text {
            id: afterPriceBox
            anchors { top: gainBox.bottom; right: parent.right; rightMargin: 10; topMargin: 2 }

            color: params.statColor
            font.pixelSize: params.posViewInfoTs
            visible: (myAfterPrice != "-")
            text: qsTr("After: ") + myAfterPrice
        }

        Text {
            id: afterChgBox
            anchors { top: afterPriceBox.bottom; right: parent.right; rightMargin: 10; topMargin: 0 }

            color: myAfterChgColor
            font.pixelSize: params.posViewInfoTs
            visible: (myAfterPrice != "-")
            text: myAfterChg + " (" + myAfterChgPtg + "%)"
        }

        // Line separator
        Rectangle {
            id: separator0
//            anchors.top: afterChgBox.bottom;
            anchors.top: (myAfterPrice=="-") ? gainBox.bottom : afterChgBox.bottom;
            anchors {left: parent.left; right: parent.right }
            anchors { topMargin: 10; leftMargin: 10; rightMargin: 10 }
            height: 2
            color: "#D5D5D5"
        }

        Text {
            id: infoBox
            anchors { top: separator0.bottom; left: parent.left; }
            anchors { topMargin: 10; leftMargin: 10; }

            color: params.statColor
            font.pixelSize: params.posViewInfoTs
            text: qsTr("Share: ") + myShare + "<br>" + qsTr("Value: ") + myShareValue + "<br>" + qsTr("Cost: ") + myShareCost
        }

        Text {
            id: infoBoxExt
            anchors { top: separator0.bottom; right: parent.right }
            anchors { topMargin: 10; rightMargin: 10 }

            color: params.statColor
            font.pixelSize: params.posViewInfoTs
            horizontalAlignment: Text.AlignRight
            text: qsTr("DayG: ") + myShareDayGain + "<br>" + qsTr("Gain: ") + myShareGain + "<br>" + qsTr("Return: ") + myShareGainPercent + "%"
        }

        // Line separator
        Rectangle {
            id: separator1
            anchors { top: infoBox.bottom; left: parent.left; right: parent.right }
            anchors { topMargin: 10; leftMargin: 10; rightMargin: 10 }
            height: 2
            color: "#D5D5D5"
        }

        Flickable {
            id: detailFlick
            anchors { top: separator1.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
            anchors { topMargin: 10; bottomMargin: 10; leftMargin: 10; rightMargin: 10 }

            contentWidth:  (chartView == "") ? (parent.width-20+2) : ((pfoIsYahoo) ? 512 : 500)
            contentHeight: (chartView == "") ? 500 : ((pfoIsYahoo) ? 750 : 850)
            clip: true

            Text {
                id: detailSymText;
                anchors { left: parent.left; top: parent.top; right: parent.right }
                color: params.statColor
                font.pixelSize: params.posViewInfoTs
                elide: Text.ElideRight
                text: myExg + " - " + myFullname
            }

            SimpleButton {
                id: newsButton
                width: refWidth
                height: params.simpleButtonHeight
                anchors { left: detailSymText.left; top: detailSymText.bottom; topMargin: 10 }
                text: qsTr("Related News")
                textSize: params.posViewInfoTs

                onClicked: {
                    rssModel.source = "http://www.google.com/finance/company_news?q=" + myExg + ":" + myName + "&output=rss";
                    container.inNewsView();
                }
            }

            Text {
                id: detailRangeText;
                anchors { top: newsButton.bottom; left: parent.left; topMargin: 10;  }
                color: params.statColor
                wrapMode: Text.WordWrap
                font.pixelSize: params.posViewInfoTs
                text: qsTr("Ask: ") + myQuoteAsk + "\n" + qsTr("Bid: ") + myQuoteBid + "\n" + qsTr("Day High: ") + myQuoteDayHi + "\n" + qsTr("Day Low: ") + myQuoteDayLo + "\n" + qsTr("52w High: ") + myQuote52wHi + "\n" + qsTr("52w Low: ") + myQuote52wLo + "\n" + qsTr("Mkt Cap: ") + myQuoteMktCap;
            }

            Text {
                id: detailStatsText;
                anchors { top: newsButton.bottom; right: separator3.right; topMargin: 10; }
                color: params.statColor
                wrapMode: Text.WordWrap
                font.pixelSize: params.posViewInfoTs
                text: qsTr("EPS: ") + myQuoteEps + "\n" + qsTr("PE: ") + myQuotePe + "\n" + qsTr("Beta: ") + myQuoteBeta + "\n" + qsTr("Vol: ") + myQuoteVol + "\n" + qsTr("Avg Vol: ") + myQuoteAvgVol + "\n" + qsTr("Div (ttm): ") + myQuoteDiv + "\n" + qsTr("Yld (ttm): ") + myQuoteYld
            }

            // Line separator
            Rectangle {
                id: separator3
                anchors { top: detailStatsText.bottom; topMargin: 10 }
                width: refWidth //parent.width
                height: 2
                color: "#D5D5D5"
            }

            SimpleButton{
                id: chartSel1
                width: (refWidth - 20)/6
                height: params.simpleButtonHeight
                anchors { top: separator3.bottom; topMargin: 10 }
                text: qsTr("5d")
                textSize: params.posViewButtonTs

                onClicked: { container.chartView = "5d"; }
            }
            SimpleButton{
                id: chartSel2
                width: (refWidth - 20)/6
                height: params.simpleButtonHeight
                anchors { top: separator3.bottom; left: chartSel1.right; topMargin: 10; leftMargin: 5 }
                text: qsTr("3m")
                textSize: params.posViewButtonTs

                onClicked: { container.chartView = "3m"; }
            }
            SimpleButton{
                id: chartSel3
                width: (refWidth - 20)/6
                height: params.simpleButtonHeight
                anchors { top: separator3.bottom; left: chartSel2.right; topMargin: 10; leftMargin: 5 }
                text: qsTr("6m")
                textSize: params.posViewButtonTs

                onClicked: { container.chartView = "6m"; }
            }
            SimpleButton{
                id: chartSel4
                width: (refWidth - 20)/6
                height: params.simpleButtonHeight
                anchors { top: separator3.bottom; left: chartSel3.right; topMargin: 10; leftMargin: 5 }
                text: qsTr("1y")
                textSize: params.posViewButtonTs

                onClicked: { container.chartView = "1y"; }
            }
            SimpleButton{
                id: chartSel5
                width: (refWidth - 20)/6
                height: params.simpleButtonHeight
                anchors { top: separator3.bottom; left: chartSel4.right; topMargin: 10; leftMargin: 5 }
                text: qsTr("2y")
                textSize: params.posViewButtonTs

                onClicked: { container.chartView = "2y"; }
            }
            SimpleButton{
                id: chartSel6
                width: (refWidth - 20)/6
                height: params.simpleButtonHeight
                anchors { top: separator3.bottom; left: chartSel5.right; right: separator3.right; topMargin: 10; leftMargin: 5 }
                text: qsTr("5y")
                textSize: params.posViewButtonTs

                onClicked: { container.chartView = "5y"; }
            }
            ProgressBar {
                id: chartProgress
                width: parent.width
                anchors { top: chartSel1.bottom; topMargin: 5; }

                indeterminate: true

                states: State {
                    name: "hideProgress"
                    when: (chart.status!=Image.Loading)
                    PropertyChanges { target: chartProgress; opacity: 0 }
                }
            }

            //            Item {
            //                id: chartItem
            //                anchors { left: parent.left; top: chartSel1.bottom; topMargin: 20; }
            //                anchors.horizontalCenter: parent.horizontalCenter

                Image {
                    id: chart

                    anchors { left: parent.left; top: chartSel1.bottom; topMargin: 20; }
                    anchors.horizontalCenter: parent.horizontalCenter

                    width:  512 //(pfoIsYahoo) ? 512 : 500
                    height: 288 //(pfoIsYahoo) ? 288 : 342
                    source: chartUrl(myName, myExg, chartView, !pfoIsYahoo)
//                    source: (chartView=="") ? "" : "http://chart.finance.yahoo.com/z?s=" + __convertExchangeForYahoo(myName, myExg) + "&t=" + chartView + "&q=l&l=off&z=m&a=v" + chartCmp;

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (chartCmp=="") { chartCmp = "&c=^GSPC,^DJI"; }
                            else              { chartCmp = "";         }
                        }
                    }
                }
//            }

            onContentXChanged: {
                if (chartView == "") {
                    // Flick Left
                    //if (contentX >= params.flickMargin) {}
                    // Flick right
                    if (contentX <= -params.flickMargin) {
                        contentX = 0;
                        container.back();
                    }
                }
            }
        }
    }

    // Landscape detail windows
    Item {
        id: landscapeDetail
        anchors.fill: parent
        opacity: 0

        Text {
            id: symbolBoxLs
            anchors { left: parent.left; leftMargin: 10; topMargin: 10 }

            font.bold: true
            font.pixelSize: params.posViewSymbolTs
            color: params.labelColor
            text: myName
        }

        Text {
            id: priceBoxLs
            anchors { top: parent.top; left: symbolBoxLs.right; leftMargin: 10; topMargin: 5 }

            font.pixelSize: params.posViewPricelTs
            color: params.labelColor
            text: myQuotePrice
        }

        Text {
            id: gainBoxLs
            anchors { top: priceBoxLs.bottom; left: parent.left; leftMargin: 10; topMargin: 5 }

            color: myQuoteChgColor
            font.pixelSize: params.posViewPricelTs
            text: myQuoteChg + " (" + myQuoteChgPtg + "%)"
        }

//        Text {
//            id: askBidBoxLs
//            anchors { top: gainBoxLs.bottom; left: parent.left; leftMargin: 20; rightMargin: 10; topMargin: 5 }

//            color: params.statColor
//            font.pixelSize: params.posViewInfoTs
//            text: "Ask: " + myQuoteAsk + "\nBid: " + myQuoteBid

//        }

        Text {
            id: afterPriceBoxLs
            anchors { top: gainBoxLs.bottom; left: parent.left; leftMargin: 20; topMargin: 5 }

            color: params.statColor
            font.pixelSize: params.posViewInfoTs
            visible: (myAfterPrice != "-")
            text: qsTr("After: ") + myAfterPrice
        }

        Text {
            id: afterChgBoxLs
            anchors { top: afterPriceBoxLs.bottom; left: parent.left; leftMargin: 20; topMargin: 2 }

            color: myAfterChgColor
            font.pixelSize: params.posViewInfoTs
            visible: (myAfterPrice != "-")
            text: myAfterChg + " (" + myAfterChgPtg + "%)"
        }

        Rectangle {
            id: separator0Ls
            anchors { top: afterChgBoxLs.bottom; left: parent.left; topMargin: 5; leftMargin: 10; }
            width: (gainBoxLs.width > (symbolBoxLs.width+priceBoxLs.width)) ? gainBoxLs.width : (symbolBoxLs.width + priceBoxLs.width)
            height: 2
            color: "#D5D5D5"
        }

        Text {
            id: infoBoxLs
            anchors { top: separator0Ls.bottom; left: parent.left; leftMargin: 20; topMargin: 5}

            color: params.statColor
            font.pixelSize: params.posViewInfoTs
            text: qsTr("Share: ") + myShare + "\n" + qsTr("Value: ") + myShareValue + "\n" + qsTr("Cost: ") + myShareCost + "\n" + qsTr("DayG: ") + myShareDayGain + "\n" + qsTr("Gain: ") + myShareGain + "\n" + qsTr("Return: ") + myShareGainPercent + "%"
        }

        Flickable {
            id: detailFlickLs
            anchors { top: parent.top; left: separator0Ls.right; right: parent.right; bottom: parent.bottom }
            anchors { topMargin: 5; bottomMargin: 10; leftMargin: 15; rightMargin: 10; }
            contentWidth: (chartView == "") ? (parent.width-separator0Ls.width-35) : ( (detailFlickLs.width>512) ? detailFlickLs.width : 512 )
            contentHeight: (chartView == "") ? 500 : 700 // chart.width
            clip: true

            // Line separator
            Text {
                id: detailSymTextLs;
                anchors { left: parent.left; top: parent.top; right: parent.right}
                //wrapMode: Text.WordWrap;
                color: params.statColor
                font.pixelSize: params.posViewInfoTs
                elide: Text.ElideRight
                text: myExg + " - " + myFullname
                //text: container.model.get(container.currentIndex).exchange + " - " + container.model.get(container.currentIndex).fullName;
            }

            SimpleButton {
                id: newsButtonLs
                width: parent.width
                height: params.simpleButtonHeight
                anchors { left: detailSymTextLs.left; top: detailSymTextLs.bottom; topMargin: 10 }
                text: qsTr("Related News")
                textSize: params.posViewInfoTs

                onClicked: {
                    rssModel.source = "http://www.google.com/finance/company_news?q=" + myExg + ":" + myName + "&output=rss";
                    container.inNewsView();
                }
            }

            Text {
                id: detailRangeTextLs;
                anchors { top: newsButtonLs.bottom; left: parent.left; topMargin: 10;  }
                color: params.statColor
                wrapMode: Text.WordWrap;
                font.pixelSize: params.posViewInfoTs
                //text: "Day High: " + myQuoteDayHi + "\nDay Low: " + myQuoteDayLo + "\n52w High: " + myQuote52wHi + "\n52w Low: " + myQuote52wLo + "\nMkt Cap: " + myQuoteMktCap;
                text: qsTr("Ask: ") + myQuoteAsk + "\n" + qsTr("Bid: ") + myQuoteBid + "\n" + qsTr("Day High: ") + myQuoteDayHi + "\n" + qsTr("Day Low: ") + myQuoteDayLo + "\n" + qsTr("52w High: ") + myQuote52wHi + "\n" + qsTr("52w Low: ") + myQuote52wLo + "\n" + qsTr("Mkt Cap: ") + myQuoteMktCap;
            }

            Text {
                id: detailStatsTextLs;
                anchors { top: newsButtonLs.bottom; right: parent.right; topMargin: 10; }
                color: params.statColor
                wrapMode: Text.WordWrap;
                font.pixelSize: params.posViewInfoTs
                text: qsTr("EPS: ") + myQuoteEps + "\n" + qsTr("PE: ") + myQuotePe + "\n" + qsTr("Beta: ") + myQuoteBeta + "\n" + qsTr("Vol: ") + myQuoteVol + "\n" + qsTr("Avg Vol: ") + myQuoteAvgVol + "\n" + qsTr("Div (ttm): ") + myQuoteDiv + "\n" + qsTr("Yld (ttm): ") + myQuoteYld
            }

            // Line separator
            Rectangle {
                id: separator3Ls
                anchors { top: detailStatsTextLs.bottom; topMargin: 10 }
                width: parent.width
                height: 2
                color: "#D5D5D5"
            }

            SimpleButton{
                id: chartSel1Ls
                width: (parent.width - 20)/6
                height: params.simpleButtonHeight
                anchors { top: separator3Ls.bottom; topMargin: 10 }
                text: qsTr("5d")
                textSize: params.posViewButtonTs

                onClicked: { container.chartView = "5d"; }
            }
            SimpleButton{
                id: chartSel2Ls
                width: (parent.width - 20)/6
                height: params.simpleButtonHeight
                anchors { top: separator3Ls.bottom; left: chartSel1Ls.right; topMargin: 10; leftMargin: 5 }
                text: qsTr("3m")
                textSize: params.posViewButtonTs

                onClicked: { container.chartView = "3m"; }
            }
            SimpleButton{
                id: chartSel3Ls
                width: (parent.width - 20)/6
                height: params.simpleButtonHeight
                anchors { top: separator3Ls.bottom; left: chartSel2Ls.right; topMargin: 10; leftMargin: 5 }
                text: qsTr("6m")
                textSize: params.posViewButtonTs

                onClicked: { container.chartView = "6m"; }
            }
            SimpleButton{
                id: chartSel4Ls
                width: (parent.width - 20)/6
                height: params.simpleButtonHeight
                anchors { top: separator3Ls.bottom; left: chartSel3Ls.right; topMargin: 10; leftMargin: 5 }
                text: qsTr("1y")
                textSize: params.posViewButtonTs

                onClicked: { container.chartView = "1y"; }
            }
            SimpleButton{
                id: chartSel5Ls
                width: (parent.width - 20)/6
                height: params.simpleButtonHeight
                anchors { top: separator3Ls.bottom; left: chartSel4Ls.right; topMargin: 10; leftMargin: 5 }
                text: qsTr("2y")
                textSize: params.posViewButtonTs

                onClicked: { container.chartView = "2y"; }
            }
            SimpleButton{
                id: chartSel6Ls
                width: (parent.width - 20)/6
                height: params.simpleButtonHeight
                anchors { top: separator3Ls.bottom; left: chartSel5Ls.right; right: separator3Ls.right; topMargin: 10; leftMargin: 5 }
                text: qsTr("5y")
                textSize: params.posViewButtonTs

                onClicked: { container.chartView = "5y"; }
            }
            ProgressBar {
                id: chartProgressLs
                width: parent.width
                anchors { top: chartSel1Ls.bottom; topMargin: 5; }

                indeterminate: true
                //value: chartLs.progress

                states: State {
                    name: "hideProgress"
                    when: (chartLs.status!=Image.Loading)
                    PropertyChanges { target: chartProgressLs; opacity: 0 }
                }
            }

//             Helper: http://developer.qt.nokia.com/forums/viewthread/5639
//            Item {
//                id: chartItemLs
//                anchors { top: chartSel1Ls.bottom; topMargin: 20; }
//                anchors.horizontalCenter: parent.horizontalCenter

                Image {
                    id: chartLs
                    anchors { top: chartSel1Ls.bottom; topMargin: 20; }
                    anchors.horizontalCenter: parent.horizontalCenter

                    width: 512
                    height: 288
                    source: chartUrl(myName, myExg, chartView, !pfoIsYahoo)

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (chartCmp=="") { chartCmp = "&c=^GSPC,^DJI"; }
                            else             { chartCmp = "";         }
                        }
                    }

                }
//            }
        }
    }

    Component {
        id: containerComp
        ListView {
            id: container
            anchors.fill: parent
            anchors.bottomMargin: adBannerLoader.height
            model: posModel
            section.property: (showSection) ? "fullName" : ""
            section.delegate: containerSection

            delegate: posDelegate
            snapMode: ListView.SnapToItem
            onContentYChanged: {
                // flick down is negative velocity
                if (pfoBannerStart && (contentY <= params.pfoBannerMargin)) { showPfoBanner(); }
            }
            // Start of motion
            onMovementStarted: {
                if (contentY==0) pfoBannerStart = true;
                else             pfoBannerStart = false;
            }
            // Abort if direction changed to scrolling down
            onVerticalVelocityChanged: {
                if (verticalVelocity>0) pfoBannerStart = false;
            }
            onMovementEnded: {
                pfoBannerStart = false;
                pfoBannerTimer.restart();
            }
        }
    }

    Component {
        id: containerSection
        Text {
            anchors { left: parent.left; leftMargin: 10 }
            text: section
            font.pixelSize: 20
            color: "black"
        }
    }

    // Qt Quick 1.0 doesn't store state, so use ugly conditional operator for now
    Component {
        id: posDelegate

        Item {
            id: posDelegateItem
            width: container.width
            height: infoBox1.height + 4

            Rectangle {
                id: background
                anchors.fill: parent
                anchors { topMargin: 1; bottomMargin: 1 }

                color: params.bkgColor
                radius: 5
            }

            Text {
                id: symbolBox
                anchors { left: background.left; leftMargin: 10 }

                font.bold: true
                font.pixelSize: params.posViewSymbolTs
                color: params.labelColor
                text: name
            }

            Text {
                id: priceBox
                anchors { top: (isLandscape) ? background.top : symbolBox.bottom; left: (isLandscape) ? symbolBox.right : parent.left; }
                anchors { leftMargin: 20; topMargin: (isLandscape) ? 5 : 0 }

                font.pixelSize: params.posViewPricelTs
                color: params.labelColor
                text: quotePrice
            }

            Text {
                id: gainBox
                anchors { top: priceBox.bottom; left: background.left; }
                anchors { leftMargin: (isLandscape) ? 10 : 20; topMargin: (isLandscape) ? 5 : 0 }
                color: quoteChgColor
                font.pixelSize: params.posViewPricelTs
                text: quoteChg + " (" + quoteChgPtg + "%)"
            }

            function infoBoxElideLength() {
                return (isLandscape) ? parent.width : (parent.width - gainBox.width - 32)
            }

            Text {
                id: infoBox1
                anchors { top: background.top; right: background.right; rightMargin: 10; topMargin: params.posViewStatTopMargin }
                width: infoBoxElideLength()
                elide: Text.ElideRight

                color: params.statColor
                font.pixelSize: params.posViewInfoTs
                horizontalAlignment: Text.AlignRight

                //text: usePortfolioView ? ("Share: " + share) : ("High: " + quoteDayHi)

                // Using <br> slows down rendering.
                // Breaking up to 5 Text elements rendering also slow.
                // \n is acceptable
                text: usePortfolioView ? (qsTr("Share: ") + share + "\n" + qsTr("Value: ") + shareValue + "\n" + qsTr("Cost: ") + shareCost + "\n" + qsTr("Gain: ") + shareGain + "\n" + qsTr("Return: ") + shareGainPercent + "%") :
                (qsTr("High: ") + quoteDayHi + "\n" + qsTr("Low: ") + quoteDayLo + "\n" + qsTr("Ask: ") + quoteAsk + "\n" + qsTr("Bid: ") + quoteBid + "\n" + qsTr("Vol: ") + quoteVol)
            }

            /*
            Text {
                id: infoBox2
                anchors { top: infoBox1.bottom; right: background.right; rightMargin: 10; topMargin: params.posViewStatTopMargin }
                anchors { left: infoBox1.left }
//                width: infoBoxElideLength()
                elide: Text.ElideRight

                color: params.statColor
                font.pixelSize: params.posViewInfoTs
                horizontalAlignment: Text.AlignRight

                text: usePortfolioView ? ("Value: " + shareValue) : ("Low: " + quoteDayLo)
            }

            Text {
                id: infoBox3
                anchors { top: infoBox2.bottom; right: background.right; rightMargin: 10; topMargin: params.posViewStatTopMargin }
                anchors { left: infoBox1.left }
//                width: infoBoxElideLength()
                elide: Text.ElideRight

                color: params.statColor
                font.pixelSize: params.posViewInfoTs
                horizontalAlignment: Text.AlignRight

                text: usePortfolioView ? ("Cost: " + shareCost) : ("Ask: " + quoteAsk)
            }

            Text {
                id: infoBox4
                anchors { top: infoBox3.bottom; right: background.right; rightMargin: 10; topMargin: params.posViewStatTopMargin }
                anchors { left: infoBox1.left }
//                width: infoBoxElideLength()
                elide: Text.ElideRight

                color: params.statColor
                font.pixelSize: params.posViewInfoTs
                horizontalAlignment: Text.AlignRight

                text: usePortfolioView ? ("Gain: " + shareGain) : ("Bid: " + quoteBid)
            }

            Text {
                id: infoBox5
                anchors { top: infoBox4.bottom; right: background.right; rightMargin: 10; topMargin: params.posViewStatTopMargin }
                anchors { left: infoBox1.left }
//                width: infoBoxElideLength()
                elide: Text.ElideRight

                color: params.statColor
                font.pixelSize: params.posViewInfoTs
                horizontalAlignment: Text.AlignRight

                text: usePortfolioView ? ("Return: " + shareGainPercent + "%") : ("Vol: " + quoteVol)
            }
            */

            MouseArea {
                anchors.fill: background
                onPressAndHold: { showSection = !showSection }
                onClicked: {
                    selectedIdx = index;
                    appWindow.posName = name;
                    appWindow.posExg  = exchange;

                    posDelegateItem.ListView.view.currentIndex = index;
                    fetchPosData(index);
                    //if (!plus) { activateBannerAd(); }

                    txLink = appWindow.activePos + "/" + myExg + "%3A" + myName + "/transactions";
                    changeState();
                }
            }
        }
    }

    Component {
        id: widgetViewComp

        ListView {
            id: widgetView
            anchors.fill: parent
            anchors.bottomMargin: adBannerLoader.height
            model: posModel
            section.property: (showSection) ? "fullName" : ""
            section.delegate: widgetSection

            delegate: widgetDelegate
            snapMode: ListView.SnapToItem
            // No velocity at start of movement.
            onContentYChanged: {
                // flick down is negative velocity
                if (pfoBannerStart && (contentY <= params.pfoBannerMargin)) { showPfoBanner(); }
            }
            // Start of motion
            onMovementStarted: {
                if (contentY==0) pfoBannerStart = true;
                else             pfoBannerStart = false;
            }
            // Abort if direction changed to scrolling down
            onVerticalVelocityChanged: {
                if (verticalVelocity>0) pfoBannerStart = false;
            }
            onMovementEnded: {
                pfoBannerStart = false;
                pfoBannerTimer.restart();
            }
        }
    }

    Component {
        id: widgetSection
        Rectangle {
            radius: 2
            width:  parent.width
            height: childrenRect.height

            color: "#111111"
            Text {
                anchors { left: parent.left; leftMargin: 4 }
                text: section
                font.pixelSize: 20
                color: "white"
            }
        }
    }

    Component {
        id: widgetDelegate

        Item {
            id: posDelegateItem
            width: widgetView.width
            height: params.posViewWidgetHeight

            Rectangle {
                id: background
                anchors.fill: parent
                color: "black"
            }

            Text {
                id: symbolBox
                width: 0.3*parent.width
                anchors { top: background.top; bottom: background.bottom; left: background.left; leftMargin: 2; }
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight

                color: "white"
                font.bold: true
                font.pixelSize: params.posViewWidgetSymbolTxtTs
                //font.family: params.textFamily
                text: name
            }

            Text {
                id: priceBox
                anchors { top: background.top; bottom: background.bottom; right: gainBox.left; rightMargin: 10;  }
                //anchors { top: background.top; bottom: background.bottom; left: symbolBox.right; leftMargin: 10;  }
                verticalAlignment: Text.AlignVCenter

                color: "#E8E8E8"
                font.pixelSize: symbolBox.font.pixelSize - 8
                //font.family: params.textFamily
                text: quotePrice
            }

            Text {
                id: gainBox
                anchors { top: background.top; bottom: background.bottom; right: background.right; rightMargin: 2; }
                verticalAlignment: Text.AlignVCenter

                color: quoteChgColor
                font.pixelSize: symbolBox.font.pixelSize - 8
                //font.family: params.textFamily
                text: quoteChg + " (" + quoteChgPtg + "%)"
            }

            MouseArea {
                id: posMouseArea
                anchors.fill: background
                onPressAndHold: { showSection = !showSection }
                onClicked: {
                    selectedIdx = index;
                    appWindow.posName = name;
                    appWindow.posExg  = exchange;

                    posDelegateItem.ListView.view.currentIndex = index;
                    fetchPosData(index);
                    //if (!plus) { activateBannerAd(); }

                    txLink = appWindow.activePos + "/" + myExg + "%3A" + myName + "/transactions";
                    changeState();
                }
            }
        }
    }

    Loader {
        id: adBannerLoader
        anchors { bottom: parent.bottom; bottomMargin: 0 }
        anchors { left: parent.left; right: parent.right }
    }

    Component {
        id: adBannerComponent
        Rectangle {
            id: adBanner
            color: params.adBkgColor
            height: 76
            visible: !plus

            Text {
                anchors.centerIn: parent
                font.pixelSize: 18
                color: "white"
                visible: (adRow.status != "Done" && adRow.status != "Loading")
                text: params.adStr
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Qt.openUrlExternally(params.adUrl);
                    }
                }
            }

            AdItem {
                id: adRow
                parameters: AdParameters {
                    applicationId: params.appId
                    usePositioning: params.usePosition
                }
                anchors.centerIn: parent

                showText: false
                reloadInterval: params.reloadAdInterval
                timerActive: appWindow.updateTimerActiveAd()
            }

            function requestAd() {
                adRow.requestAd();
            }
        }
    }

    // Detect transition from thumbmail to fullscreen
    Connections {
        target: platformWindow

        onViewModeChanged: {
            if (platformWindow.viewMode == WindowState.Fullsize) {
                console.log("Re-load ad when switching back to app")
                if (!plus) activateBannerAd();
            }
        }
    }

    Text {
        id: noSymbolText
        anchors.centerIn: parent
        anchors.verticalCenterOffset: params.noSymbolVerticalOffset
        color: container.state=="widgetView" ? "white" : params.labelColor
        opacity: 0.5
        font.pixelSize: 50
        visible: (posModel.count==0)
        text: qsTr("No Symbol")
    }

    Timer {
        id: pfoBannerTimer
        interval: 700
        onTriggered: { pfoBanner.state = "" }
    }

    Rectangle {
        id: pfoBanner
        anchors { top: parent.top; left: parent.left; right: parent.right }
        color: "#2B60DE"
        height: 0
        opacity: 0

        Text {
            id: pfoBannerTxt
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            color: "white"
            font.pixelSize: 28
            text: pfoName + "\n" +
                  ((pfoBannerValue=="") ? qsTr("No performance info") :
//                                          (pfoBannerValue + "   (" + signModifier(pfoBannerGain) + ":" + pfoBannerGainPtg + "%)"))
                                          (pfoBannerValue + " | " + signModifier(pfoBannerGain) + " (" + pfoBannerGainPtg + "%)"))
        }

        states: [
            State {
                name: "show"
                PropertyChanges { target: pfoBanner; opacity: 0.9; height: 80 }
            }
        ]

        transitions: [
            Transition {
                PropertyAnimation { properties: "opacity, height"; duration: 200 }
            }
        ]
    }

    states: [
        State {
            name: ""
            PropertyChanges { target: posViewBackground; color: params.posViewBkgColor }
            StateChangeScript { script: { dbgStr = "posView.default"; } }
        },

        State {
            name: "details"

            PropertyChanges { target: pageIndicator; visible: true }
            PropertyChanges { target: portraitDetail; opacity: !isLandscape  }
            PropertyChanges { target: landscapeDetail; opacity: isLandscape  }
            PropertyChanges { target: viewLoader; opacity: 0  }

            PropertyChanges { target: posViewBackground; color: params.bkgColor }
            StateChangeScript { script: { dbgStr = "posView.details"; } }
       },

        State {
            name: "widgetView"
            when: useWidgetView

            PropertyChanges { target: pageIndicator; inverted: true }
            PropertyChanges { target: posViewBackground; color: "black" }
            StateChangeScript { script: { dbgStr = "posView.widget"; } }
        }
    ]
}
