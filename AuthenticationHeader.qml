import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtGraphicalEffects 1.14


ColumnLayout {
    property alias text: textView.text

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 20

        Image {
            source: "qrc:/forum.png"
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48
        }

        Text {
            text: "РуЧат"
            font.pointSize: 18
            style: Text.Outline
            styleColor: "black"
            color: "lime"
        }
    }

    Text {
        id: textView
        Layout.alignment: Qt.AlignHCenter
        text: "Аутентификация"
        font.pointSize: 24
        layer.enabled: true
        layer.effect: DropShadow {
            verticalOffset: 4
            horizontalOffset: 2
            color: "#80000000"
            radius: 3
            samples: 5
        }
    }
}
