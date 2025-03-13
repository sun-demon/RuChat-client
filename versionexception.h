#ifndef VERSIONEXCEPTION_H
#define VERSIONEXCEPTION_H

#include <QString>

class VersionException : public std::runtime_error {
public:
    explicit VersionException(quint8 clientVersion, quint8 serverVersion)
        : std::runtime_error(QString("Ошибка версий: версия клиента - %1, версия сервера - %2.")
                             .arg(clientVersion)
                             .arg(serverVersion)
                             .toStdString()) {}
};

#endif // VERSIONEXCEPTION_H
