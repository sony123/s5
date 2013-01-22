.pragma library

function aboutTxt(plus) {
    var str;
    str  =  (plus) ? "Stockona+" : "Stockona";
    str += " 0.6.6"
    return str;
}

function descTxt (plus) {
    var str;
    str  = qsTr("This app is under GPL license. ");
    str += qsTr("Quotes data from Google/Yahoo, the app is not responsible for quote accuracy. ");

    if (!plus)
        str += qsTr("Ad by inner-active. The app respects your privacy and doesn't send your location and device info to inner-active.");

    str += qsTr("<br><br><b>Privacy Notice</b><br>");
    str += qsTr("Your Google credential is stored securely on device and only used to authenticate Google finance. ");
    str += qsTr("Signout in settings clears the credential.");

    str += qsTr("<br><br><b>Project Website</b><br>http://projects.developer.nokia.com/<br>stockona");
    str += qsTr("<br><br><b>Credits</b><br>Tommi Laukkanen, MaeMoney, StockThis, Nokia Qt/Meego team");
    return str;
}

