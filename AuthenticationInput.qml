import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14
import QtGraphicalEffects 1.14


GridLayout {
    id: root
    columns: 3
    rows: 3
    property alias text: textField.text
    property alias title: header.text
    property alias icon: image.source
    property alias textfield: textField
    property alias message: messageField.text
    property bool isValid: false

    Text {
        id: header
        Layout.row: 0
        Layout.column: 1
        font.pointSize: 13
        Layout.leftMargin: 5
    }

    Image {
        id: image
        Layout.row: 1
        Layout.column: 0
        Layout.preferredWidth: 24
        Layout.preferredHeight: width
    }

    TextField {
        id: textField
        Layout.row: 1
        Layout.column: 1
        font.pointSize: 11
        Layout.preferredWidth: 200
        Layout.preferredHeight: 20
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignLeft
        padding: 0
        selectByMouse: true
        leftPadding: 5
        rightPadding: 5
        implicitWidth: width
        implicitHeight: height
        selectionColor: "#059fff"
        selectedTextColor: "white"
        background: Rectangle {
            border.color: root.isValid ? "lime" : messageField.text !== "" ? "red" : textField.focus ? "blue" : root.text === "" ? "#a0a0a0" : "black"
            radius: 5
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 0
                color: textField.background.border.color
                radius: 3
                samples: 5
            }
        }
    }

    Text {
        Layout.row: 1
        Layout.column: 2
        Layout.preferredWidth: 24
        color: messageField.text === "" ? "transparent" : root.isValid ? "lime" : "red"
        text: messageField.text === "" ? "" : root.isValid ? "✓" : "✕"
        font.pointSize: 10
    }

    Text {
        id: messageField
        Layout.row: 3
        Layout.topMargin: -7
        Layout.alignment: Qt.AlignHCenter
        Layout.column: 0
        Layout.columnSpan: 3
        Layout.maximumWidth: 225
        text: ""
        color: text === "" ? "transparent" : root.isValid ? "lime" : "red"
        font.pointSize: 8
        wrapMode: Text.Wrap
        elide: Text.ElideNone
        horizontalAlignment: Text.AlignHCenter
    }
}
