import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtGraphicalEffects 1.14

Button {
    id: root
    focusPolicy: Qt.StrongFocus
    Keys.onPressed: if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) clicked()
    property alias paintedWidth: textView.paintedWidth
    property alias paintedHeight: textView.paintedHeight
    contentItem: Item {}
    background: Rectangle {
        id: rectangle
        color: "lime"
        radius: height / 3
        border.color: "black"
        signal clicked()

        Text {
            id: textView
            anchors.centerIn: parent
            text: root.text
            font.pointSize: 12
            color: mouseArea.pressed ? "gray" : "black"
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: root.clicked()
        }

        layer.enabled: true
        layer.effect: DropShadow {
            color: root.hovered ? rectangle.color : "blue"
            radius: 15
            samples: root.focus || root.hovered ? 20 : 0
            spread: 0.3
        }
    }
}
