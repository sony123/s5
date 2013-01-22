import QtQuick 1.1
import com.nokia.symbian 1.1
import "js/noticeDesc.js" as T

QueryDialog {
    acceptButtonText: qsTr("Ok")
    rejectButtonText: ""

    titleText: qsTr("Notice")
    message: T.msg()
}
