#ifndef SERVERCLOSECONNECTIONEXCEPTION_H
#define SERVERCLOSECONNECTIONEXCEPTION_H

#include <QString>

class ServerCloseConnectionException : public std::runtime_error {
public:
    explicit ServerCloseConnectionException(const QString& message = "Сервер закрыл соединение")
        : std::runtime_error(message.toStdString()) {}
};

#endif // SERVERCLOSECONNECTIONEXCEPTION_H
