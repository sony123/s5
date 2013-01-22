import QtQuick 1.1
import com.nokia.meego 1.0
import "js/aboutDesc.js" as T

QueryDialog {
    id: deleteDialog

    acceptButtonText: qsTr("Project Website")
    rejectButtonText: qsTr("Close")

    icon: "gfx/stockona80.png"
    titleText: T.aboutTxt(plus)
    message: T.descTxt(plus)

    onAccepted: {
        Qt.openUrlExternally("http://projects.developer.nokia.com/stockona");
    }

    onRejected: {
        deleteDialog.close();
    }
}
