.pragma library

function msg() {
    var str = qsTr("Google have shut down Finance API. This means Google login can stop working anytime without notice. ");
//    str += qsTr("Please sync Google portfolios to device while service is available. ");
    str += qsTr("When Google login stops working, you can continue using Stockona by turning on 'Bypass Google login' in the settings menu. ");
    str += qsTr("Remember to signout in order to remove the credential stored on device. ");
    str += qsTr("Thank you for using Stockona.") + "<br>"
    return str;
}

