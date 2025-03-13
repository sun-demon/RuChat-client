import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

Popup {
    id: root
    visible: false
    width: 200
    height: 140
    modal: true
    focus: true
    closePolicy: Popup.CloseOnPressOutsideParent
    property alias text: textView.text
    background: Rectangle {
        color: "white"
        opacity: 0.9
        radius: 5
    }

    ColumnLayout {
        id: processingColumn
        anchors.centerIn: parent

        BusyIndicator {
            Layout.alignment: Qt.AlignHCenter
            running: true
            width: 48
            height: width
        }

        Text {
            id: textView
            Layout.alignment: Qt.AlignHCenter
            text: "Подождите"

            Text {
                text: ".".repeat(dotsTimer.animationPosition % 4)
                anchors.left: parent.right
            }
        }

        Timer {
            id: dotsTimer
            interval: 500
            onRunningChanged: animationPosition = 0
            running: parent.visible
            repeat: true
            onTriggered: animationPosition += 1;
            property int animationPosition: 0
        }
    }
}
