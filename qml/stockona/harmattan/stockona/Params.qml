// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1

Item {
    property bool useDarkTheme: false

    // Position: total -120
    property int busyIndicatorVerticalOffset: -90
    property int noSymbolVerticalOffset:  30

    // Header
    property int headerTxtTs: 35
    property int headerSubTs: 24
    property int headerLeftMargin: 30
    property int headerHeight: 65
    property color headerColor: "#6B90DA"

    // Text
    property string textFamily: "Nokia Pure Text"
    property int posViewWidgetSymbolTxtTs: 34
    property int posViewSymbolTs : 40
    property int posViewPricelTs: 33
    property int posViewButtonTs: 24
    property int posViewInfoTs: 23

    property int aboutTitleTs: 28
    property int aboutTxtTs: 22

    property int helpTitleTs: 28
    property int helpTxtTs: 22

    property int mktOverTs: 23
    property int mktNewsTs: 27

    property int newsTxtTs: 27
    property int pfoTxtTs : 32
    property int posEditTxtTs : 32

    property int txViewTxtTs: 27
    property int rtViewTxtTs: 26

    property int sheetTxtTs: 20
    property int scTxtTs: 24
    property int settingTxtTs: 20

    // Color
    property color posViewBkgColor: (useDarkTheme) ? "black" : "#E4F5FF" //#B0D8FF"
    property color labelColor: (useDarkTheme) ? "#E8E8E8" : "black"
    property color excerptColor: (useDarkTheme) ? "#CBCBCB" : "#808080"
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
    property int posViewHeight: 160
    property int posViewWidgetHeight: 50
    property int simpleButtonHeight: 50

    // Ad
    property bool usePosition: false// true
    property color adBkgColor: "grey"
    property int reloadAdInterval: 50
    property string adStr: qsTr("Upgdrade to Stockona+\nSay goodbye to ad banner!")
    property string adUrl: "http://store.ovi.com/content/216413"
    property string appId: "Stockona_stockona_ad_OVI"

    // Scalable UI
    function mm2pxl(number) {
        return Math.round(number * screen.dpi / 25.4);
    }
}
