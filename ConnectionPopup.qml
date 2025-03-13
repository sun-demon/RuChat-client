import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

Popup {
    id: root
    visible: false
    width: 200
    height: 140 + errorMessage.height
    modal: true
    focus: true
    closePolicy: Popup.CloseOnPressOutsideParent
    background: Rectangle {
        color: "white"
        opacity: 0.9
        radius: 5
    }

    ColumnLayout {
        id: processingColumn
        anchors.centerIn: parent
        visible: false

        BusyIndicator {
            Layout.alignment: Qt.AlignHCenter
            running: true
            width: 48
            height: width
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Подключение"

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

    ColumnLayout {
        id: successColumn
        anchors.centerIn: parent
        visible: false

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 30
            Layout.preferredHeight: width
            radius: width / 2
            border.color: "lime"
            color: "transparent"

            Text {
                anchors.centerIn: parent
                font.pointSize: 16
                text: "✓"
                color: "lime"
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Подключено!"
        }

        Timer {
            interval: 1500
            running: successColumn.visible
            repeat: false
            onTriggered: root.visible = false;
        }
    }

    ColumnLayout {
        id: errorColumn
        anchors.centerIn: parent
        visible: false

        Text {
            Layout.alignment: Qt.AlignHCenter
            font.pointSize: 32
            text: "⊗"
            color: "red"
        }

        Text {
            id: errorMessage
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: root.width
            wrapMode: Text.Wrap
            elide: Text.ElideNone
            horizontalAlignment: Text.AlignHCenter
            text: ""
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Повтор через: " + (errorTimer.repeatTime - errorTimer.animationPosition) + " секунд"
        }

        Timer {
            id: errorTimer
            interval: 1000
            running: errorColumn.visible
            onRunningChanged: animationPosition = 0
            repeat: true
            onTriggered: {
                if (animationPosition === repeatTime - 1) {
                    errorMessage.text = "";
                    tcpClient.connectToHost();
                } else {
                    animationPosition += 1;
                }
            }
            property int repeatTime: 3
            property int animationPosition: 0
        }
    }

    Connections {
        target: tcpClient
        function onConnecting() {
            root.visible = true;
            processingColumn.visible = true;
            successColumn.visible = false;
            errorColumn.visible = false;
        }
        function onConnected() {
            root.visible = true;
            processingColumn.visible = false;
            successColumn.visible = true;
            errorColumn.visible = false;
        }
        function onError(error) {
            root.visible = true;
            processingColumn.visible = false;
            successColumn.visible = false;
            errorColumn.visible = true;
            errorMessage.text = error;
        }
    }
}
