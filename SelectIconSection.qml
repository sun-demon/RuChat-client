import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14
import QtGraphicalEffects 1.14
import Qt.labs.platform 1.1


ColumnLayout {
    id: root
    property int index: -1
    onIndexChanged: if (index !== -1 && message !== "") message = ""
    property string message: ""
    onMessageChanged: if (index !== -1 && message !== "") index = -1
    property var base64
    onBase64Changed: customImage.source = utils.getImageUrlFromBase64(base64)
    signal fileReading()
    signal fileReaded()
    signal compressing()
    signal compressed()
    signal errorCompressIcon()

    Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 190
        text: "выбор иконки"
        font.pointSize: 13
    }

    RowLayout {

        Repeater {
            model: [1, 2, 3]
            delegate: Button {
                id: iconButton
                onClicked: root.index = modelData
                focusPolicy: Qt.StrongFocus
                Keys.onPressed: if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) clicked()
                Layout.preferredWidth: 60
                Layout.preferredHeight: width
                background: Rectangle {
                    clip: true
                    radius: width / 2
                    border.color: iconButton.focus ? "black" : root.index === modelData ? "blue" : iconButton.hovered ? "dimgray" : "#808080"
                    color: root.index === modelData ? "lightblue" : iconButton.hovered ? "#f0f0f0" : "#d0d0d0"
                    layer.enabled: true
                    layer.effect: DropShadow {
                        color: iconButton.focus ? "black" : root.index === modelData ? "blue" : iconButton.hovered ? "gray" : "transparent"
                        radius: 10
                        samples: 20
                        spread: 0.3
                    }

                    Image {
                        anchors.fill: parent
                        source: `qrc:/icon${modelData}.png`
                        fillMode: Image.PreserveAspectFit
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: iconButton.clicked()
                    }
                }
            }
        }

        Button {
            id: customIconButton
            Layout.preferredWidth: 60
            Layout.preferredHeight: width
            focusPolicy: Qt.StrongFocus
            Keys.onPressed: if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) clicked()
            onClicked: selectImageFileDialog.open()
            background: Rectangle {
                clip: true
                radius: width / 2
                border.color: customIconButton.focus ? "black" : root.index === 0 ? "blue" : customIconButton.hovered ? "dimgray" : "#808080"
                color: root.index === 0 ? "lightblue" : customIconButton.hovered ? "#f0f0f0" : "#d0d0d0"
                layer.enabled: true
                layer.effect: DropShadow {
                    color: customIconButton.focus ? "black" : root.index === 0 ? "blue" : customIconButton.hovered ? "gray" : "transparent"
                    radius: 10
                    samples: 20
                    spread: 0.3
                }

                Item {
                    width: parent.width
                    height: parent.height
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: customImage.width
                            height: customImage.height
                            radius: width / 2
                        }
                    }

                    Image {
                        id: customImage
                        anchors.fill: parent
                        visible: root.index === 0
                        fillMode: Image.PreserveAspectCrop
                        source: ""
                        onSourceChanged: root.index = 0
                        onStatusChanged: if (status === Image.Error) root.message = "Файл не является изображением!"
                    }
                }

                Text {
                    visible: root.index !== 0 || customIconButton.hovered
                    text: "+"
                    font.pixelSize: 24
                    color: parent.border.color
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: customIconButton.clicked()
                }
            }

            FileDialog {
                id: selectImageFileDialog
                title: "Выберите файл"
                nameFilters: ["Изображения (*.png *.jpg *.jpeg *.bmp)", "Все файлы (*)"]
                onAccepted: {
                    root.fileReading();
                    var MAX_ICON_SIZE = 65482;
                    var filePath = file.toString();
                    var specificFilePath = filePath.replace("file:///", "");
                    var base64 = utils.readFile(specificFilePath);
                    if (utils.lengthBase64(base64) > MAX_ICON_SIZE) {
                        root.compressing();
                        utils.compressIcon(specificFilePath);
                        return;
                    }
                    root.base64 = base64;
                    root.fileReaded();
                }
            }

            Connections {
                target: utils
                function onCompressed(base64) {
                    root.base64 = base64;
                    root.compressed();
                }
                function onErrorCompressIcon(message) {
                    root.message = message;
                    root.errorCompressIcon();
                }
            }
        }
    }

    Text {
        id: textImageException
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 225
        text: root.index === -1 ? root.message : ""
        font.pointSize: 10
        color: "red"
        wrapMode: Text.Wrap
        elide: Text.ElideNone
        horizontalAlignment: Text.AlignHCenter
    }
}
