import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtGraphicalEffects 1.14
import Qt.labs.platform 1.1

ApplicationWindow {
    id: root
    width: 380
    maximumWidth: width
    minimumWidth: width
    height: 760
    title: "РуЧат"
    property int userId: 0
    property var uploads: ({})
    signal toLoginWindow()
    onVisibleChanged: if (visible) textEdit.forceActiveFocus()
    onUserIdChanged: if (userId) {
        while (usersModel.count < userId + 1) {
            usersModel.append({login: "", iconIndex: 0, iconBase64: "", lastRequest: 0});
        }
        var userInfo = usersModel.get(userId);
        userInfo.lastRequest = getQuint64Timestamp();
        usersModel.set(userId, userInfo);
        tcpClient.requestUserInfo(userId);
        tcpClient.requestHistory(0);
        headerTimer.start();
    }
    function getQuint64Timestamp() {
        var currentTime = new Date().getTime();
        return Math.round(currentTime);
    }

    Timer {
        interval: 1000
        running: root.visible && root.userId > 0
        repeat: false
        onTriggered: messagesScrollView.scrollToEnd()
    }

    Connections {
        id: connection
        target: tcpClient
        function onOkSendText(userMessageId, messageId, timestamp) {
            var content = userMessagesModel.get(userMessageId).content;
            while (messagesModel.count < messageId + 1) {
                messagesModel.append({userId: 0, timestamp: 0, type: -1, content: "", chunksNumber: 0, chunkNumber: 0, filename: "", path: ""});
            }
            var messageInfo = messagesModel.get(messageId);
            messageInfo.userId = root.userId;
            messageInfo.timestamp = timestamp;
            messageInfo.type = 0;
            messageInfo.content = content;
            messagesModel.set(messageId, messageInfo);
            userMessagesModel.set(userMessageId, {type: -1});
        }
        function onBadSendText(userMessageId, error) {
            userMessagesModel.set(userMessageId, {type: -1});
            if (error === 'session not found') {
                logoutButton.clicked();
            } else {
                console.log('Получен неизвестный серверный код ошибки отправки текстового сообщения: ' + error);
            }
        }
        function onGetTextMessage(userId, messageId, timestamp, content) {
            while (messagesModel.count < messageId + 1) {
                messagesModel.append({userId: 0, timestamp: 0, type: -1, content: "", chunksNumber: 0, chunkNumber: 0, filename: "", path: ""});
            }
            var messageInfo = messagesModel.get(messageId);
            messageInfo.userId = userId;
            messageInfo.timestamp = timestamp;
            messageInfo.type = 0;
            messageInfo.content = content;
            messagesModel.set(messageId, messageInfo);
            while (usersModel.count < userId + 1) {
                usersModel.append({login: "", iconIndex: 0, iconBase64: "", lastRequest: 0});
            }
            var nowTimestamp = root.getQuint64Timestamp();
            var userInfo = usersModel.get(userId);
            if (!userInfo.login && nowTimestamp - userInfo.lastRequest > 3000) {
                userInfo.lastRequest = nowTimestamp;
                usersModel.set(userId, userInfo);
                tcpClient.requestUserInfo(userId);
            }
        }
        function onGetFileMessageInfo(userId, messageId, timestamp, chunksNumber, filename) {
            while (messagesModel.count < messageId + 1) {
                messagesModel.append({userId: 0, timestamp: 0, type: -1, content: "", chunksNumber: 0, chunkNumber: 0, filename: "", path: ""});
            }
            var messageInfo = messagesModel.get(messageId);
            messageInfo.userId = userId;
            messageInfo.timestamp = timestamp;
            messageInfo.type = 1;
            messageInfo.chunksNumber = chunksNumber;
            messageInfo.filename = filename;
            messagesModel.set(messageId, messageInfo);
            while (usersModel.count < userId + 1) {
                usersModel.append({login: "", iconIndex: 0, iconBase64: "", lastRequest: 0});
            }
            var nowTimestamp = root.getQuint64Timestamp();
            var userInfo = usersModel.get(userId);
            if (!userInfo.login && nowTimestamp - userInfo.lastRequest > 3000) {
                userInfo.lastRequest = nowTimestamp;
                usersModel.set(userId, userInfo);
                tcpClient.requestUserInfo(userId);
            }
        }
        function onOkHistory() {
            historyTimer.start();
        }
        function onBadHistory(error) {
            if (error === 'session not found') {
                logoutButton.clicked();
            } else {
                console.log("Получен неизвестный тип ошибки истории сообщений: " + error);
            }
        }
        function onOkUserInfo(userId, login, iconBase64) {
            while (usersModel.count < userId + 1) {
                usersModel.append({login: "", iconIndex: 0, iconBase64: "", lastRequest: 0});
            }
            var userInfo = usersModel.get(userId);
            userInfo.login = login;
            var isIconIndex = (utils.lengthBase64(iconBase64) === 1);
            if (isIconIndex) {
                userInfo.iconIndex = utils.base64ToQuint8(iconBase64);
            } else {
                userInfo.iconBase64 = iconBase64
            }
            usersModel.set(userId, userInfo);
        }
        function onOkSendFileInfo(userMessageId, uploadId) {
            root.uploads[uploadId] = userMessageId;
            var filePath = userMessagesModel.get(userMessageId).path;
            var base64Chunk = utils.readBase64Chunk(filePath);
            // var userMessageInfo = userMessagesModel.get(userMessageId);
            // userMessageInfo.chunkNumber = 1;
            // userMessagesModel.set(userMessageId, userMessageInfo);
            tcpClient.requestSendFileChunk(uploadId, 1, base64Chunk);
        }
        function onOkSendFileChunk(uploadId, chunkNumber) {
            var userMessageId = root.uploads[uploadId];
            var filePath = userMessagesModel.get(userMessageId).path;
            var base64Chunk = utils.readBase64Chunk(filePath, chunkNumber);
            var userMessageInfo = userMessagesModel.get(userMessageId);
            userMessageInfo.chunkNumber = chunkNumber;
            userMessagesModel.set(userMessageId, userMessageInfo);
            tcpClient.requestSendFileChunk(uploadId, chunkNumber + 1, base64Chunk);
        }
        function onBadSendFileChunk(uploadId, chunkNumber, error) {
            if (error === 'session not found') {
                logoutButton.clicked();
            } else {
                console.log('Получена не обрабатываемая ошибка отправки чанка: ' + error);
            }
        }
        function onOkSendFile(uploadId, messageId, timestamp) {
            while (messagesModel.count < messageId + 1) {
                messagesModel.append({userId: 0, timestamp: 0, type: -1, content: "", chunksNumber: 0, chunkNumber: 0, filename: "", path: ""});
            }
            var userMessageId = root.uploads[uploadId];
            var userMessageInfo = userMessagesModel.get(userMessageId);
            var messageInfo = messagesModel.get(messageId);
            messageInfo.userId = root.userId;
            messageInfo.timestamp = timestamp;
            messageInfo.type = 1;
            messageInfo.chunksNumber = userMessageInfo.chunksNumber;
            messageInfo.chunkNumber = userMessageInfo.chunksNumber;
            messageInfo.filename = userMessageInfo.filename;
            messageInfo.path = userMessageInfo.path;
            messagesModel.set(messageId, messageInfo);
            userMessagesModel.set(userMessageId, {type: -1});
        }
        function onOkGetFileChunk(messageId, chunkNumber, chunkBase64) {
            var messageInfo = messagesModel.get(messageId);
            var result = utils.appendBase64ChunkToFile(messageInfo.path, chunkBase64);
            if (result) {
                if (messageInfo.chunkNumber === chunkNumber - 1) {
                    messageInfo.chunkNumber = chunkNumber;
                    if (messageInfo.chunkNumber !== messageInfo.chunksNumber) {
                        tcpClient.requestGetFileChunk(messageId, chunkNumber + 1);
                    }
                    messagesModel.set(messageId, messageInfo);
                } else {
                    console.log("Ошибка получения чанка файла: получен не тот номер чанка.");
                }
            } else {
                console.log("Ошибка записи чанка в файл!");
            }
        }
        function onBadGetFileChunk(messageId, chunkNumber, error) {
            if (error === 'session not found') {
                logoutButton.clicked();
            } else {
                console.log('Получен неизвестный тип ошибки получения чанка файла: ' + error);
            }
        }
    }

    Timer {
        id: historyTimer
        interval: 3000
        running: false
        repeat: false
        onTriggered: { tcpClient.requestHistory(getMessageIdForRequestHistory()); }
        function getMessageIdForRequestHistory() {
            if (messagesModel.count <= 1) {
                return 0;
            }
            for (var i = 1; i < messagesModel.count; ++i) {
                if (messagesModel.get(i).userId === 0) {
                    return i - 1;
                }
            }
            return messagesModel.count - 1;
        }
    }

    ConnectionPopup {
        id: connectionPopup
        anchors.centerIn: parent
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.alignment: Qt.AlignTop
            color: "black"
        }

        Rectangle {
            id: header
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            Layout.alignment: Qt.AlignTop
            color: "lime"

            property alias login: userLogin.text
            property alias source: userIcon.source

            Timer {
                id: headerTimer
                interval: 100
                running: root.userId > 0
                repeat: false
                onTriggered: {
                    if (usersModel.count > root.userId) {
                        var userInfo = usersModel.get(root.userId);
                        if (userInfo && userInfo.login && (userInfo.iconIndex || userInfo.iconBase64)) {
                            header.login = userInfo.login;
                            header.source = userInfo.iconIndex ? `qrc:/icon${userInfo.iconIndex}.png` : utils.getImageUrlFromBase64(userInfo.iconBase64);
                            running = false;
                            return;
                        }
                    }
                    start();
                }
            }

            RowLayout {
                anchors.fill: parent

                Rectangle {
                    id: iconRectangle
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 10
                    clip: true
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: width
                    radius: width / 2
                    border.color: "black"
                    layer.enabled: true

                    Item {
                        width: parent.width
                        height: parent.height
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: iconRectangle.width
                                height: iconRectangle.height
                                radius: width / 2
                            }
                        }

                        Image {
                            id: userIcon
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                        }
                    }
                }

                Text {
                    id: userLogin
                    visible: false
                }

                Text {
                    id: userStyledLogin
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    Layout.leftMargin: 4
                    font.pointSize: 13
                    textFormat: Text.StyledText
                    style: Text.Outline
                    text: `<u>${userLogin.text}</u>`
                    styleColor: "white"
                    color: "black"
                }

                Button {
                    id: logoutButton
                    Layout.alignment: Qt.AlignRight || Qt.AlignVCenter
                    Layout.rightMargin: 2
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: width
                    onClicked: {
                        root.userId = 0;
                        usersModel.clear();
                        messagesModel.clear();
                        userMessagesModel.clear();
                        header.login = "";
                        header.source = "";
                        root.toLoginWindow();
                    }
                    background: Image {
                        id: logoutButtonImage
                        width: logoutButton.width
                        height: width
                        source: "qrc:/logout.png"

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: logoutButton.clicked()
                        }
                    }

                    DropShadow {
                        visible: logoutButton.hovered || logoutButton.activeFocus
                        anchors.fill: logoutButtonImage
                        source: logoutButtonImage
                        color: logoutButton.hovered ? "black" : "gray"
                        radius: 10
                        samples: 20
                        spread: 0.3
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.alignment: Qt.AlignTop
            color: "black"
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListModel {
                id: usersModel
                //                     /iconIndex
                // lastRequest, login
                //                     \iconUrl
            }

            ListModel {
                id: messagesModel
                //                        /content
                // userId, timestamp, type
                //                        \chunksNumber, chunkNumber, filename, path
            }

            ListModel {
                id: userMessagesModel
                //     /content
                // type
                //     \chunksNumber, chunkNumber, filename, path
            }

            ScrollView {
                id: messagesScrollView
                anchors.fill: parent
                contentHeight: messagesLayout.height
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                // @disable-check M300
                ScrollBar.vertical {
                    id: verticalScrollBar
                    policy: ScrollBar.AsNeeded
                }
                function scrollToEnd() {
                    verticalScrollBar.position = 1.0 - verticalScrollBar.size;
                }

                ColumnLayout {
                    id: messagesLayout
                    Layout.alignment: Qt.AlignTop
                    width: parent.width

                    ListView {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        Layout.preferredHeight: contentHeight
                        model: messagesModel
                        spacing: 5
                        delegate: RowLayout {
                            id: messageView
                            visible: userId > 0
                            width: messagesLayout.width
                            height: userId > 0 ? implicitHeight : 0
                            layoutDirection: model.userId === root.userId ? Qt.LeftToRight : Qt.RightToLeft
                            spacing: 6
                            property alias login: messageLogin.text
                            property alias source: messageIcon.source

                            Timer {
                                interval: 100
                                running: root.visible && userId > 0
                                repeat: false
                                onTriggered: {
                                    if (usersModel.count > userId) {
                                        var userInfo = usersModel.get(userId);
                                        if (userInfo && userInfo.login && (userInfo.iconIndex || userInfo.iconBase64)) {
                                            messageView.login = userInfo.login;
                                            messageView.source = userInfo.iconIndex ? `qrc:/icon${userInfo.iconIndex}.png` : utils.getImageUrlFromBase64(userInfo.iconBase64);
                                            running = false;
                                            return;
                                        }
                                    }
                                    start();
                                }
                            }

                            Rectangle {
                                id: messageIconRectangle
                                Layout.topMargin: 2
                                Layout.leftMargin: 5
                                Layout.rightMargin: 5
                                Layout.alignment: Qt.AlignTop
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: width
                                clip: true
                                radius: width / 2
                                color: model.userId === root.userId ? "#cbffcb" : "#d7d7d7"
                                border.color: "black"
                                layer.enabled: true

                                Item {
                                    width: parent.width
                                    height: parent.height
                                    layer.enabled: true
                                    layer.effect: OpacityMask {
                                        maskSource: Rectangle {
                                            width: messageIconRectangle.width
                                            height: messageIconRectangle.height
                                            radius: width / 2
                                        }
                                    }

                                    Image {
                                        id: messageIcon
                                        anchors.fill: parent
                                        fillMode: Image.PreserveAspectCrop
                                    }
                                }
                            }

                            RowLayout {
                                layoutDirection: parent.layoutDirection
                                spacing: -10

                                Canvas {
                                    Layout.alignment: Qt.AlignTop
                                    id: canvas
                                    width: 20
                                    height: 10
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.reset();
                                        ctx.beginPath();
                                        ctx.moveTo(0, 0);
                                        ctx.lineTo(width, 0);
                                        ctx.lineTo(width / 2, height);
                                        ctx.closePath();
                                        ctx.fillStyle = messageIconRectangle.color;
                                        ctx.fill();
                                    }
                                }

                                Rectangle {
                                    color: messageIconRectangle.color
                                    Layout.preferredWidth: Math.max(Math.max(messageBody.width, messageLogin.width), messageTime.width) + 20
                                    Layout.preferredHeight: messageText.height + 30
                                    Layout.alignment: Qt.AlignTop | (userId === root.userId ? Qt.AlignLeft : Qt.AlignRight)
                                    radius: 5

                                    TextEdit {
                                        id: messageLogin
                                        readOnly: true
                                        selectByMouse: true
                                        anchors.top: parent.top
                                        anchors.topMargin: 2
                                        anchors.left: parent.left
                                        anchors.leftMargin: 5
                                        color: "dimgray"
                                    }

                                    RowLayout {
                                        id: messageBody
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter

                                        TextEdit {
                                            id: messageText
                                            visible: type === 0
                                            font.pointSize: 10
                                            readOnly: true
                                            selectByMouse: true
                                            Layout.preferredWidth: Math.min(228, implicitWidth)
                                            wrapMode: TextEdit.Wrap
                                            text: visible ? content : ""
                                        }

                                        Image {
                                            id: messageFileIcon
                                            visible: type === 1
                                            Layout.alignment: Qt.AlignVCenter
                                            fillMode: Image.PreserveAspectCrop
                                            source: "qrc:/file.png"
                                            Layout.preferredWidth: 20
                                            Layout.preferredHeight: width

                                            Text {
                                                anchors.centerIn: parent
                                                visible: parent.visible && chunksNumber === chunkNumber && path
                                                color: "lime"
                                                text: "✓"
                                            }

                                            MouseArea {
                                                id: messageFileIconMouseArea
                                                anchors.fill: parent
                                                visible: parent.visible && (chunkNumber === 0 || chunkNumber === chunksNumber)
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: clickToFile()
                                                function clickToFile() {
                                                    var messageInfo;
                                                    if (chunkNumber === 0 && !path) {
                                                        var filePath = (StandardPaths.writableLocation(StandardPaths.DownloadLocation) + "/" + filename).replace("file:///", "");
                                                        var uniqueFilePath = utils.generateUniqueFilePath(filePath);
                                                        utils.createEmptyFile(uniqueFilePath);
                                                        messageInfo = messagesModel.get(model.index);
                                                        messageInfo.path = uniqueFilePath;
                                                        tcpClient.requestGetFileChunk(model.index, 1);
                                                        messagesModel.set(model.index, messageInfo);
                                                    } else if (chunkNumber === chunksNumber && path) {
                                                        if (!utils.fileExists(path)) {
                                                            messageInfo = messagesModel.get(model.index);
                                                            messageInfo.path = "";
                                                            messageInfo.chunkNumber = 0;
                                                            messagesModel.set(model.index, messageInfo);
                                                        } else {
                                                            Qt.openUrlExternally("file:///" + path);
                                                        }
                                                    }
                                                }
                                            }

                                            ProgressBar {
                                                visible: parent.visible && chunkNumber !== 0 && chunkNumber !== chunksNumber
                                                width: parent.width
                                                height: 3
                                                anchors.centerIn: parent
                                                from: 0
                                                to: visible ? chunksNumber : 0
                                                value: visible ? chunkNumber : 0
                                            }
                                        }

                                        Text {
                                            id: messageFileName
                                            visible: type === 1
                                            Layout.maximumWidth: 200
                                            elide: Text.ElideRight
                                            Layout.alignment: Qt.AlignVCenter
                                            text: visible ? `<u>${filename}</u>` : ""
                                            textFormat: Text.StyledText
                                            color: visible && messageFileNameMouseArea.containsMouse ? "blue" : "black"

                                            MouseArea {
                                                id: messageFileNameMouseArea
                                                anchors.fill: parent
                                                visible: messageFileIconMouseArea.visible
                                                cursorShape: Qt.PointingHandCursor
                                                hoverEnabled: true
                                                onClicked: messageFileIconMouseArea.clickToFile()
                                            }
                                        }
                                    }

                                    TextEdit {
                                        id: messageTime
                                        readOnly: true
                                        selectByMouse: true
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 2
                                        anchors.right: parent.right
                                        anchors.rightMargin: 5
                                        color: "gray"
                                        text: timestamp !== 0 ? utils.timestampToText(timestamp) : ""
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        Layout.preferredHeight: contentHeight
                        model: userMessagesModel
                        spacing: 5
                        delegate: RowLayout {
                            id: userMessageView
                            visible: type !== -1
                            height: visible ? implicitHeight : 0
                            width: parent.width
                            layoutDirection: Qt.LeftToRight
                            spacing: 6

                            Rectangle {
                                id: userMessageIconRectangle
                                Layout.topMargin: 2
                                Layout.leftMargin: 5
                                Layout.rightMargin: 5
                                Layout.alignment: Qt.AlignTop
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: width
                                clip: true
                                radius: width / 2
                                color: "#cbffcb"
                                border.color: "black"
                                layer.enabled: true

                                Item {
                                    width: parent.width
                                    height: parent.height
                                    layer.enabled: true
                                    layer.effect: OpacityMask {
                                        maskSource: Rectangle {
                                            width: userMessageIconRectangle.width
                                            height: userMessageIconRectangle.height
                                            radius: width / 2
                                        }
                                    }

                                    Image {
                                        id: userMessageIcon
                                        anchors.fill: parent
                                        source: userIcon.source
                                        fillMode: Image.PreserveAspectCrop
                                    }
                                }
                            }

                            RowLayout {
                                layoutDirection: parent.layoutDirection
                                spacing: -10

                                Canvas {
                                    Layout.alignment: Qt.AlignTop
                                    id: userCanvas
                                    width: 20
                                    height: 10
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.reset();
                                        ctx.beginPath();
                                        ctx.moveTo(0, 0);
                                        ctx.lineTo(width, 0);
                                        ctx.lineTo(width / 2, height);
                                        ctx.closePath();
                                        ctx.fillStyle = userMessageIconRectangle.color;
                                        ctx.fill();
                                    }
                                }

                                Rectangle {
                                    color: userMessageIconRectangle.color
                                    Layout.preferredWidth: Math.max(Math.max(userMessageBody.width, userMessageLogin.width), userMessageTime.width) + 20
                                    Layout.preferredHeight: userMessageText.height + 30
                                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                                    radius: 5

                                    TextEdit {
                                        id: userMessageLogin
                                        readOnly: true
                                        selectByMouse: true
                                        anchors.top: parent.top
                                        anchors.topMargin: 2
                                        anchors.left: parent.left
                                        anchors.leftMargin: 5
                                        color: "dimgray"
                                        text: userLogin.text
                                    }

                                    RowLayout {
                                        id: userMessageBody
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter

                                        TextEdit {
                                            id: userMessageText
                                            visible: type === 0
                                            font.pointSize: 10
                                            readOnly: true
                                            selectByMouse: true
                                            Layout.preferredWidth: Math.min(228, implicitWidth)
                                            wrapMode: TextEdit.Wrap
                                            text: visible ? content : ""
                                        }

                                        Image {
                                            id: userMessageFileIcon
                                            visible: type === 1
                                            Layout.alignment: Qt.AlignVCenter
                                            source: "qrc:/file.png"
                                            fillMode: Image.PreserveAspectCrop
                                            Layout.preferredWidth: 20
                                            Layout.preferredHeight: width

                                            Text {
                                                id: errorUserMessageFileIcon
                                                anchors.centerIn: parent
                                                visible: parent.visible && chunksNumber && chunksNumber <= 0
                                                color: "red"
                                                text: "✕"

                                                Timer {
                                                    interval: 5000
                                                    running: parent.visible
                                                    repeat: false
                                                    onTriggered: userMessagesModel.set(model.index, {type: -1})
                                                }
                                            }

                                            ProgressBar {
                                                visible: parent.visible && !errorUserMessageFileIcon.visible
                                                width: parent.width
                                                height: 3
                                                anchors.centerIn: parent
                                                from: 0
                                                to: visible ? chunksNumber : 0
                                                value: visible ? chunkNumber : 0
                                            }
                                        }

                                        Text {
                                            id: userMessageFileName
                                            visible: type === 1
                                            Layout.maximumWidth: 200
                                            elide: Text.ElideRight
                                            Layout.alignment: Qt.AlignVCenter
                                            text: visible ? filename : ""
                                        }
                                    }

                                    TextEdit {
                                        id: userMessageTime
                                        readOnly: true
                                        selectByMouse: true
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 2
                                        anchors.right: parent.right
                                        anchors.rightMargin: 5
                                        color: "gray"
                                        text: utils.timestampToText(root.getQuint64Timestamp())
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }
                        }
                    }

                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.alignment: Qt.AlignTop
            color: "lightgray"
        }

        RowLayout {
            Layout.preferredHeight: textEditBackground.height + 20
            Layout.alignment: Qt.AlignHCenter

            Rectangle {
                id: textEditBackground
                Layout.preferredWidth: 320
                Layout.preferredHeight: textEditScrollView.height
                Layout.alignment: Qt.AlignVCenter
                radius: 10
                color: "#ccffcc"
                border.color: "lime"
                clip: true

                Text {
                    id: textEditPlaceholder
                    anchors.verticalCenter: textEditBackground.verticalCenter
                    font.pointSize: 10
                    x: textEditBackground.x + 10
                    text: "Введите сообщение..."
                    color: "gray"
                    visible: textEdit.text === ""
                }

                ScrollView {
                    id: textEditScrollView
                    width: 256
                    height: Math.max(20, Math.min(100, textEditWrapper.height))
                    x: textEditBackground.x + 10
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded
                    ScrollBar.vertical.x: x + 260
                    contentHeight: textEditWrapper.height

                    Item {
                        id: textEditWrapper
                        width: 258
                        height: textEdit.contentHeight + 20

                        TextEdit {
                            id: textEdit
                            width: parent.width
                            anchors.verticalCenter: parent.verticalCenter
                            wrapMode: TextEdit.Wrap
                            font.pointSize: 11
                            selectByMouse: true
                            Keys.onPressed: {
                                if (event.key === Qt.Key_Return && !(event.modifiers & Qt.ShiftModifier)) {
                                    sendButton.clicked();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Tab) {
                                    sendButton.forceActiveFocus();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Backtab) {
                                    logoutButton.forceActiveFocus();
                                    event.accepted = true;
                                }
                            }

                            TextField {
                                opacity: 0
                                width: 0
                                height: 0
                                onFocusChanged: if (focus) textEdit.forceActiveFocus()
                            }
                        }
                    }
                }

                Button {
                    id: sendButton
                    anchors.right: parent.right
                    anchors.verticalCenter: textEditBackground.verticalCenter
                    width: 30
                    height: width
                    anchors.rightMargin: 3
                    onClicked: {
                        var userMessageId = userMessagesModel.count;
                        var text = textEdit.text;
                        textEdit.text = "";
                        userMessagesModel.append({type: 0, content: text});
                        tcpClient.requestSendText(userMessageId, text);
                        messagesScrollView.scrollToEnd();
                    }

                    background: Image {
                        id: sendButtonImage
                        width: sendButton.width
                        height: width
                        source: "qrc:/send.png"
                        fillMode: Image.PreserveAspectCrop

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sendButton.clicked()
                        }
                    }

                    DropShadow {
                        visible: sendButton.hovered || sendButton.focus
                        anchors.fill: sendButtonImage
                        source: sendButtonImage
                        color: sendButton.hovered ? "black" : "gray"
                        radius: 10
                        samples: 20
                        spread: 0.3
                    }
                }
            }

            Button {
                id: attachFileButton
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 26
                Layout.preferredHeight: width
                onClicked: attachFileDialog.open()

                background: Image {
                    id: attachFileButtonImage
                    width: attachFileButton.width
                    height: width
                    source: "qrc:/attach_file.png"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: attachFileButton.clicked()
                    }
                }

                DropShadow {
                    anchors.fill: attachFileButtonImage
                    source: attachFileButtonImage
                    color: attachFileButton.hovered ? "lightgreen" : "gray"
                    radius: attachFileButton.hovered || attachFileButton.focus ? 10 : 1
                    samples: 20
                    spread: 0.3
                }
            }

            FileDialog {
                id: attachFileDialog
                title: "Выберите файл"
                nameFilters: ["Все файлы (*)"]
                onAccepted: {
                    var filePath = file.toString();
                    var userMessageId = userMessagesModel.count;
                    var filename = filePath.split('/').pop();
                    var fileSize = utils.getFileSize(filePath);
                    if (fileSize > 5 * 1024 * 1024 * 1024) {
                        userMessagesModel.append({type: 1, chunksNumber: -1, filename: filename});
                    } else if (fileSize === 0) {
                        userMessagesModel.append({type: 1, chunksNumber: 0, filename: filename});
                    } else {
                        var specificFilePath = filePath.replace("file:///", "");
                        var chunksNumber = Math.floor((fileSize - 1) / 32768) + 1;
                        userMessagesModel.append({type: 1, chunksNumber: chunksNumber, chunkNumber: 0, filename: filename, path: specificFilePath});
                        tcpClient.requestSendFileInfo(userMessageId, chunksNumber, filename);
                    }
                    messagesScrollView.scrollToEnd();
                }
            }
        }
    }
}
