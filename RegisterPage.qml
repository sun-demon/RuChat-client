import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtGraphicalEffects 1.14

ApplicationWindow {
    id: root
    width: 340
    height: 560
    minimumWidth: width
    maximumWidth: width
    minimumHeight: height
    maximumHeight: height
    title: "РуЧат"
    onVisibleChanged: if (visible) loginSection.textfield.forceActiveFocus()
    signal toLoginWindow()
    signal toChatWindow(userId: int)

    Connections {
        id: connection
        target: tcpClient
        function onFreeCheckLogin(login) {
            if (login === loginSection.text) {
                loginSection.message = "Логин свободен";
                loginSection.isValid = true;
            }
        }
        function onBusyCheckLogin(login) {
            if (login === loginSection.text) {
                loginSection.message = "Логин уже занят!"
                loginSection.isValid = false;
            }
        }
        function onOkRegisterUser(userId) {
            waitPopup.close();
            loginSection.text = "";
            passwordSection.text = "";
            repeatPasswordSection.text = "";
            iconSelection.index = -1;
            root.toChatWindow(userId);
        }
        function onBadRegisterUser(error) {
            waitPopup.close();
            if (error === "login already exists") {
                loginSection.message = "Логин уже занят!";
                loginSection.isValid = false;
            } else if (error === "user limit has been reached") {
                loginSection.message = "Достигнут лимит пользователей!";
                loginSection.isValid = false;
            }
        }
        function onConnected() {
            waitPopup.close();
            loginSection.validateLogin();
            passwordSection.validatePassword();
            repeatPasswordSection.validateRepeatPassword();
        }
    }

    ConnectionPopup {
        id: connectionPopup
        anchors.centerIn: parent
    }

    WaitPopup {
        id: waitPopup
        anchors.centerIn: parent
        text: "Регистрация"
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter

        AuthenticationHeader {
            Layout.alignment: Qt.AlignHCenter
            text: "Регистрация"
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
                message = "";
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
            onTextChanged: validatePassword()
            textfield.onAccepted: repeatPasswordSection.textfield.forceActiveFocus()
            function validatePassword() {
                var password = text;
                message = "";
                passwordSection.isValid = false;
                const MIN_LENGTH = 8;
                const MAX_LENGTH = 100;
                const SPECIAL_CHARACTERS = /[\!\@\#\$\%\^\&\*\(\)\,\.\?\"\:\{\}\|\<\>\ ]/;

                if (password.length === 0) {
                    return;
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
                } else if (password === repeatPasswordSection.text){
                    message = "";
                    isValid = true;
                    repeatPasswordSection.message = "";
                    repeatPasswordSection.isValid = true;
                }
            }
        }

        AuthenticationInput {
            id: repeatPasswordSection
            Layout.alignment: Qt.AlignHCenter
            title: "повтор пароля"
            icon: "qrc:/lock.png"
            textfield.placeholderText: "Повторите пароль"
            textfield.echoMode: TextInput.Password
            onTextChanged: validateRepeatPassword()
            textfield.onAccepted: registerButton.tryRegister()
            function validateRepeatPassword() {
                var repeatPassword = text
                message = "";
                isValid = false;

                if (repeatPassword.length === 0) {
                    return;
                } else if (repeatPassword !== passwordSection.text) {
                    message = "Пароли не совпадают!";
                } else {
                    message = "";
                    isValid = true;
                    passwordSection.message = "";
                    passwordSection.isValid = true;
                }
            }
        }

        SelectIconSection {
            id: iconSelection
            Layout.alignment: Qt.AlignHCenter
            onFileReading: { waitPopup.text = "Чтение файла иконки"; waitPopup.open(); }
            onFileReaded: waitPopup.close();
            onCompressing: { waitPopup.text = "Компрессия иконки"; waitPopup.open(); }
            onCompressed: waitPopup.close();
            onErrorCompressIcon: waitPopup.close();
        }

        AuthenticationButton {
            id: registerButton
            Layout.alignment: Qt.AlignHCenter
            text: "Зарегистрироваться"
            Layout.preferredWidth: paintedWidth + 20
            Layout.preferredHeight: paintedHeight + 10
            onClicked: tryRegister()
            function tryRegister() {
                if (loginSection.textfield.text === "") {
                    loginSection.message = "Логин не может быть пустым!";
                }
                if (passwordSection.textfield.text === "") {
                    passwordSection.message = "Пароль не может быть пустым!";
                }
                if (repeatPasswordSection.textfield.text === "") {
                    repeatPasswordSection.message = "Повтор пароля не может быть пустым!";
                }
                if (iconSelection.index === -1) {
                    iconSelection.message = "Необходимо выбрать иконку!"
                }
                if (loginSection.isValid && passwordSection.isValid && repeatPasswordSection.isValid && iconSelection.index !== -1) {
                    waitPopup.text = "Регистрация"
                    waitPopup.open();
                    var icon = iconSelection.index === 0 ? iconSelection.base64 : utils.quint8ToBase64(iconSelection.index)
                    tcpClient.requestRegisterUser(loginSection.text, passwordSection.text, icon);
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10

            Text {
                text: "<u>Уже есть аккаунт?</u>"
                textFormat: Text.StyledText
                font.pointSize: 10
            }

            Button {
                id: toLoginButton
                focusPolicy: Qt.StrongFocus
                onClicked: {
                    loginSection.text = "";
                    passwordSection.text = "";
                    repeatPasswordSection.text = "";
                    iconSelection.index = -1;
                    root.toLoginWindow();
                }
                Keys.onPressed: if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) clicked()
                background: Text {
                    id: toLoginButtonText
                    scale: toLoginButton.focus | toLoginButton.hovered ? 1.05 : 1.0
                    font.bold: true
                    textFormat: Text.StyledText
                    style: Text.Outline
                    styleColor: toLoginButton.focus ? "black" : "transparent"
                    font.pointSize: 10
                    text: "Войти"
                    color: "#00b2ff"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: toLoginButton.clicked()
                    }
                }

                DropShadow {
                    anchors.fill: parent
                    source: toLoginButtonText
                    color: toLoginButton.hovered ? "black" : "blue"
                    radius: toLoginButton.hovered | toLoginButton.focus ? 10 : 4
                    samples: 20
                    spread: 0.3
                }
            }
        }
    }
}
