#ifndef CHECKSUMEXCEPTION_H
#define CHECKSUMEXCEPTION_H

#include <stdexcept>
#include <QString>

class ChecksumException : public std::runtime_error {
public:
    explicit ChecksumException(quint16 expectedChecksum, quint16 realChecksum)
        : std::runtime_error((QString("Ошибка контрольной суммы: ожидалось - 0x") +
                              QString("%1").arg(expectedChecksum, 4, 16, QChar('0')).toUpper() +
                              QString(", получено - 0x") +
                              QString("%1.").arg(realChecksum, 4, 16, QChar('0')).toUpper()).toStdString()) {}
};

#endif // CHECKSUMEXCEPTION_H
