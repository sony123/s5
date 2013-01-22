// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1

Item {
    property int symbianOffset: 4

    property bool useDarkTheme: true

    // Position: total -120
    property int busyIndicatorVerticalOffset: -90
    property int noSymbolVerticalOffset:  30

    // Header
    property int headerTxtTs: 28
    property int headerSubTs: 24
    property int headerLeftMargin: 20
    property int headerHeight: 50
    property color headerColor: "#6B90DA"

    // Text
    property string textFamily: "Nokia Pure Text"
    property int posViewWidgetHeight: 38
    property int posViewWidgetSymbolTxtTs: 32 - symbianOffset
    property int posViewSymbolTs : 34 - symbianOffset
    property int posViewPricelTs: 30 - symbianOffset
    property int posViewButtonTs: 24 - symbianOffset
    property int posViewInfoTs: 21 - symbianOffset

    property int aboutTitleTs: mm2pxl(3) // 28
    property int aboutTxtTs: mm2pxl(2) // 22

    property int helpTitleTs: 28 - symbianOffset
    property int helpTxtTs: 22 - symbianOffset

    property int mktOverTs: 23 - symbianOffset
    property int mktNewsTs: 27 - symbianOffset

    property int newsTxtTs: 27 - symbianOffset
    property int pfoTxtTs : 32 - symbianOffset
    property int posEditTxtTs : 32 - symbianOffset

    property int txViewTxtTs: 27 - symbianOffset
    property int rtViewTxtTs: 26 - symbianOffset

    property int sheetTxtTs: 20 - symbianOffset
    property int scTxtTs: 24 - symbianOffset
    property int settingTxtTs: 20 - symbianOffset

    // Color
    property color posViewBkgColor: (useDarkTheme) ? "black" : "#E4F5FF" //#B0D8FF"
    property color labelColor: (useDarkTheme) ? "#E8E8E8" : "#808080"
    property color excerptColor: (useDarkTheme) ? "#D5D5D5" : "black"
    property color bkgColor: (useDarkTheme) ? "#202020" : "ivory" // "#382D2C" : "ivory"
    property color statColor: (useDarkTheme) ? "#FAFAFA" : "#595454"
    property color pressColor: (useDarkTheme) ? "#4A4344" : "#FDE688"
    property color currentItemColor: (useDarkTheme) ? "#5F5A59" : "#FFF8C6"
    property color settingSepColor: "#D5D5D5"

    // Margin
    property int posViewStatTopMargin: 0
    property int pgiMargin: 4         // pageIndicator margin
    property int flickMargin: 45
    property int pfoBannerMargin: -parent.height/17

    // Height
    property int posViewHeight: 140
    property int simpleButtonHeight: 38

    // Ad
    property bool usePosition: false
    property color adBkgColor: "grey"
    property int reloadAdInterval: 40
    property string adStr: qsTr("Upgdrade to Stockona+\nSay goodbye to ad banner!")
    property string appId: "Stockona_stockona_ad_OVI"

    // Symbian-specific 
    property int busyIndicatorSize: 80
    property int buttonSize: 200

    // Scalable UI
    function mm2pxl(number) {
        return Math.round(number * screen.dpi / 25.4);
    }
}
