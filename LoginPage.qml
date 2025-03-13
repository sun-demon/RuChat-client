import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtGraphicalEffects 1.14

ApplicationWindow {
    id: root
    width: 320
    height: 380
    minimumWidth: width
    maximumWidth: width
    minimumHeight: height
    maximumHeight: height
    title: "РуЧат"
    onVisibleChanged: if (visible) loginSection.textfield.forceActiveFocus()
    signal toRegisterWindow()
    signal toChatWindow(userId: int)

    Connections {
        id: connection
        target: tcpClient
        function onFreeCheckLogin(login) {
            if (login === loginSection.text) {
                loginSection.message = "Логин не зарегистрирован!";
                loginSection.isValid = false;
            }
        }
        function onBusyCheckLogin(login) {
            if (login === loginSection.text) {
                loginSection.message = "";
                loginSection.isValid = true;
            }
        }
        function onOkLoginUser(userId) {
            loginPopup.close();
            loginSection.text = "";
            passwordSection.text = "";
            root.toChatWindow(userId);
        }
        function onBadLoginUser(error) {
            loginPopup.close();
            if (error === "invalid login") {
                loginSection.message = "Неверный логин!";
                loginSection.isValid = false;
            } else if (error === "invalid password") {
                passwordSection.message = "Неверный пароль!";
                passwordSection.isValid = false;
            }
        }
        function onConnected() {
            loginPopup.close();
            loginSection.validateLogin();
            passwordSection.validatePassword();
        }
    }

    ConnectionPopup {
        id: connectionPopup
        anchors.centerIn: parent
    }

    WaitPopup {
        id: loginPopup
        anchors.centerIn: parent
        text: "Вход"
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter

        AuthenticationHeader {
            Layout.alignment: Qt.AlignHCenter
            text: "Авторизация"
        }

        AuthenticationInput {
            id: loginSection
            Layout.topMargin: 10
            Layout.alignment: Qt.AlignHCenter
            title: "логин"
            icon: "qrc:/person.png"
            textfield.placeholderText: "Введите логин"
            onTextChanged: validateLogin()
            textfield.onAccepted: passwordSection.textfield.forceActiveFocus()
            function validateLogin() {
                var login = text;
                isValid = false;
                const MIN_LENGTH = 3;
                const MAX_LENGTH = 20;
                if (text.length === 0) {
                    message = "";
                } else if (!/^[a-zA-Z0-9_]+$/.test(login)) {
                    message = "Логин содержит недопустимый символ!";
                } else if (!/^[a-zA-Z]/.test(login[0])) {
                    message = "Логин должен начинаться с буквы!";
                } else if (login.length < MIN_LENGTH) {
                    message = "Логин слишком короткий!";
                } else if (login.length > MAX_LENGTH) {
                    message = "Логин слишком длинный!";
                } else {
                    message = "";
                    tcpClient.requestCheckLogin(login);
                }
            }
        }

        AuthenticationInput {
            id: passwordSection
            Layout.alignment: Qt.AlignHCenter
            title: "пароль"
            icon: "qrc:/lock.png"
            textfield.placeholderText: "Введите пароль"
            textfield.echoMode: TextInput.Password
            isValid: false
            onTextChanged: validatePassword()
            textfield.onAccepted: loginButton.tryLogin()
            function validatePassword() {
                var password = text;
                const MIN_LENGTH = 8;
                const MAX_LENGTH = 100;
                const SPECIAL_CHARACTERS = /[\!\@\#\$\%\^\&\*\(\)\,\.\?\"\:\{\}\|\<\>\ ]/;

                if (password.length === 0) {
                    message = "";
                } else if (password.length < MIN_LENGTH) {
                    message = "Пароль слишком короткий!";
                } else if (password.length > MAX_LENGTH) {
                    message = "Пароль слишком длинный!";
                } else if (!/[a-z]/.test(password)) {
                    message = "Пароль должен содержать строчную букву!";
                } else if (!/[A-Z]/.test(password)) {
                    message = "Пароль должен содержать заглавную букву!";
                } else if (!/[0-9]/.test(password)) {
                    message = "Пароль должен содержать цифру!";
                }  else if (!SPECIAL_CHARACTERS.test(password)) {
                    message = "Пароль должен содержать спец. символ!";
                } else {
                    message = "";
                }
            }
        }

        AuthenticationButton {
            id: loginButton
            Layout.alignment: Qt.AlignHCenter
            text: "Войти"
            Layout.preferredWidth: paintedWidth + 20
            Layout.preferredHeight: paintedHeight + 10
            onClicked: tryLogin()
            function tryLogin() {
                if (loginSection.textfield.text === "") {
                    loginSection.message = "Логин не может быть пустым!";
                }
                if (passwordSection.textfield.text === "") {
                    passwordSection.message = "Пароль не может быть пустым!";
                }
                if (loginSection.isValid && passwordSection.text !== "" && passwordSection.message === "") {
                    loginPopup.open()
                    tcpClient.requestLoginUser(loginSection.text, passwordSection.text);
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10

            Text {
                text: "<u>Нет аккаунта?</u>"
                textFormat: Text.StyledText
                font.pointSize: 10
            }

            Button {
                id: toRegisterButton
                focusPolicy: Qt.StrongFocus
                onClicked: {
                    loginSection.text = "";
                    passwordSection.text = "";
                    root.toRegisterWindow();
                }
                Keys.onPressed: if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) clicked()
                background: Text {
                    id: toRegisterButtonText
                    scale: toRegisterButton.focus | toRegisterButton.hovered ? 1.05 : 1.0
                    font.bold: true
                    font.pointSize: 10
                    text: "Регистрация"
                    color: "#00b2ff"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: toRegisterButton.clicked()
                    }
                }

                DropShadow {
                    anchors.fill: parent
                    source: toRegisterButtonText
                    color: toRegisterButton.hovered ? "black" : "blue"
                    radius: toRegisterButton.hovered | toRegisterButton.focus ? 10 : 4
                    samples: 20
                    spread: 0.3
                }
            }
        }
    }
}
