import QtQuick 2.14
import QtQuick.Window 2.14

Item {
    id: root
    Component.onCompleted: tcpClient.connectToHost()

    RegisterPage {
        id: registerWindow
        onToLoginWindow: {
            loginWindow.x = x;
            loginWindow.y = y;
            close();
            loginWindow.show();
        }
        onToChatWindow: function (userId) {
            chatWindow.x = x;
            chatWindow.y = y;
            close();
            chatWindow.userId = userId;
            chatWindow.show();
        }
    }

    LoginPage {
        id: loginWindow
        Component.onCompleted: show()
        onToRegisterWindow: {
            registerWindow.x = x;
            registerWindow.y = y;
            close();
            registerWindow.show();
        }
        onToChatWindow: function (userId) {
            chatWindow.x = x;
            chatWindow.y = y;
            close();
            chatWindow.userId = userId;
            chatWindow.show();
        }
    }

    ChatPage {
        id: chatWindow
        onToLoginWindow:  {
            loginWindow.x = x;
            loginWindow.y = y;
            close();
            loginWindow.show();
        }
    }
}
