#include "tcpclient.h"

#include <QDebug>

#include "message.h"
#include "utils.h"
#include "checksumexception.h"
#include "messagereadingexception.h"
#include "versionexception.h"

const QString HOST = "ruchat.ddns.net";
const quint16 PORT = 50000;

TcpClient::TcpClient(QObject *parent) : QObject(parent), m_socket(this) {
    connect(&m_socket, &QTcpSocket::stateChanged, this, &TcpClient::socketStateChanged);
    connect(&m_socket, &QTcpSocket::connected, this, &TcpClient::socketConnected);
    connect(&m_socket, &QTcpSocket::disconnected, this, &TcpClient::socketDisconnected);
    connect(&m_socket, QOverload<QAbstractSocket::SocketError>::of(&QTcpSocket::error), this, &TcpClient::socketError);
    connect(&m_socket, &QTcpSocket::readyRead, this, &TcpClient::socketReadyRead);
}
TcpClient::~TcpClient() {
    m_socketMutex.lock();
    disconnectFromHost();
    m_socketMutex.unlock();
}

void TcpClient::connectToHost() {
    if (m_socket.state() == QTcpSocket::UnconnectedState) {
        m_socketMutex.lock();
        m_socket.connectToHost(HOST, PORT);
        m_socketMutex.unlock();
    }
}
void TcpClient::disconnectFromHost() {
    if (m_socket.state() == QAbstractSocket::ConnectedState) {
        m_socketMutex.lock();
        m_socket.disconnectFromHost();
        m_socketMutex.unlock();
    } else if (m_socket.state() != QAbstractSocket::ClosingState) {
        m_socketMutex.lock();
        m_socket.abort();
        m_socketMutex.unlock();
    }
}

void TcpClient::requestCheckLogin(const QString &login) {
    QByteArray message = Message::create(Message::Type::REQUEST_CHECK_LOGIN, login.toUtf8());
    sendMessage(message);
}
void TcpClient::requestRegisterUser(const QString &login, const QString &password, const QString &iconBase64) {
    QByteArray payload;
    payload.append(static_cast<quint8>(login.size()));
    payload.append(login.toUtf8());
    payload.append(Utils::hashPassword(password));
    payload.append(QByteArray::fromBase64(iconBase64.toUtf8()));
    QByteArray message = Message::create(Message::Type::REQUEST_REGISTER_USER, payload);
    sendMessage(message);
}
void TcpClient::requestLoginUser(const QString &login, const QString &password) {
    QByteArray payload;
    payload.append(login.toUtf8());
    payload.append(Utils::hashPassword(password));
    QByteArray message = Message::create(Message::Type::REQUEST_LOGIN_USER, payload);
    sendMessage(message);
}
void TcpClient::requestSendText(quint32 userMessageId, const QString& text) {
    QByteArray payload;
    Utils::appendQuint32(payload, userMessageId);
    payload.append(text.toUtf8());
    QByteArray message = Message::create(Message::Type::REQUEST_SEND_TEXT, payload);
    sendMessage(message);
}
void TcpClient::requestHistory(quint64 messageId) {
    QByteArray payload;
    Utils::appendQuint64(payload, messageId);
    QByteArray message = Message::create(Message::Type::REQUEST_HISTORY, payload);
    sendMessage(message);
}
void TcpClient::requestUserInfo(quint16 userId) {
    QByteArray payload;
    Utils::appendQuint16(payload, userId);
    QByteArray message = Message::create(Message::Type::REQUEST_USER_INFO, payload);
    sendMessage(message);
}
void TcpClient::requestSendFileInfo(quint32 userMessageId, quint32 chunksNumber, const QString& filename) {
    QByteArray payload;
    Utils::appendQuint32(payload, userMessageId);
    Utils::appendQuint32(payload, chunksNumber);
    payload.append(filename.toUtf8());
    QByteArray message = Message::create(Message::Type::REQUEST_SEND_FILE_INFO, payload);
    sendMessage(message);
}
void TcpClient::requestSendFileChunk(quint64 uploadId, quint32 chunkNumber, const QString& chunkBase64) {
    QByteArray payload;
    Utils::appendQuint64(payload, uploadId);
    Utils::appendQuint32(payload, chunkNumber);
    payload.append(QByteArray::fromBase64(chunkBase64.toUtf8()));
    QByteArray message = Message::create(Message::Type::REQUEST_SEND_FILE_CHUNK, payload);
    sendMessage(message);
}
void TcpClient::requestGetFileChunk(quint64 messageId, quint32 chunkNumber) {
    QByteArray payload;
    Utils::appendQuint64(payload, messageId);
    Utils::appendQuint32(payload, chunkNumber);
    QByteArray message = Message::create(Message::Type::REQUEST_GET_FILE_CHUNK, payload);
    sendMessage(message);
}

void TcpClient::socketStateChanged(QAbstractSocket::SocketState socketState) {
    switch (socketState) {
    case QAbstractSocket::HostLookupState:
    case QAbstractSocket::ConnectingState:
        emit connecting();
    default:
        return;
    }
}
void TcpClient::socketConnected() {
    emit connected();
}
void TcpClient::socketDisconnected() {
    emit disconnected();
}
void TcpClient::socketError(QAbstractSocket::SocketError socketError) {
    QString errorMessage;
    switch (socketError) {
    case QAbstractSocket::HostNotFoundError:
        errorMessage = "Узел не найден.";
        break;
    case QAbstractSocket::ConnectionRefusedError:
        errorMessage = "Соединение отклонено.";
        break;
    default:
        errorMessage = "Ошибка сокета: " + m_socket.errorString();
    }
    emit error(errorMessage);
}
void TcpClient::socketReadyRead() {
    m_socketReadBufferMutex.lock();
    m_socketReadBuffer.append(m_socket.readAll());
    try {
        while (true) {
            Message::checkVersion(m_socketReadBuffer);
            quint16 realChecksum = Message::getChecksum(m_socketReadBuffer);
            Message::Type type = Message::getType(m_socketReadBuffer);
            QByteArray payload = Message::getPayload(m_socketReadBuffer);
            quint16 expectedChecksum = Utils::calculateChecksum(payload);
            if (expectedChecksum != realChecksum) {
                throw ChecksumException(expectedChecksum, realChecksum);
            }
            processMessage(type, payload);
            m_socketReadBuffer.remove(0, payload.length() + 6);
        }
    } catch (const MessageReadingException& _) {
        m_socketReadBufferMutex.unlock();
    } catch (const VersionException& exc) {
        m_socketReadBuffer.clear();
        m_socketReadBufferMutex.unlock();
        qDebug() << exc.what();
        disconnectFromHost();
        emit error(exc.what());
    } catch (const ChecksumException& exc) {
        m_socketReadBuffer.clear();
        m_socketReadBufferMutex.unlock();
        qDebug() << exc.what();
        disconnectFromHost();
        emit error(exc.what());
    } catch (const std::runtime_error& exc) {
        m_socketReadBuffer.clear();
        m_socketReadBufferMutex.unlock();
        throw exc;
    }
}

void TcpClient::processOkHistory(const QByteArray& payload) {
    for (quint16 metaInfoLength = 0, i = 0; i < payload.length(); i += metaInfoLength) {
        metaInfoLength = Utils::readQuint16(payload, i);
        quint16 userId = Utils::readQuint16(payload, i + 2);
        quint64 messageId = Utils::readQuint64(payload, i + 4);
        quint64 timestamp = Utils::readQuint64(payload, i + 12);
        quint8 messageType = static_cast<quint8>(payload[i + 20]);
        if (messageType == 0) {
            QString content = QString::fromUtf8(payload.mid(i + 21, metaInfoLength - 21));
            emit getTextMessage(userId, messageId, timestamp, content);
        } else if (messageType == 1) {
            quint32 chunksNumber = Utils::readQuint32(payload, i + 21);
            QString filename = QString::fromUtf8(payload.mid(i + 25, metaInfoLength - 25));
            emit getFileMessageInfo(userId, messageId, timestamp, chunksNumber,filename);
        } else {
            qDebug() << "Получен неверный тип сообщения!";
            return;
        }
    }
    emit okHistory();
}
void TcpClient::processMessage(Message::Type type, const QByteArray& payload) {
    switch (type) {
    case Message::Type::RESPONSE_FREE_LOGIN:
        emit freeCheckLogin(QString::fromUtf8(payload));
        break;
    case Message::Type::RESPONSE_BUSY_LOGIN:
        emit busyCheckLogin(QString::fromUtf8(payload));
        break;
    case Message::Type::RESPONSE_OK_REGISTER_USER:
        emit okRegisterUser(Utils::readQuint16(payload));
        break;
    case Message::Type::RESPONSE_BAD_REGISTER_USER:
        emit badRegisterUser(QString::fromUtf8(payload));
        break;
    case Message::Type::RESPONSE_OK_LOGIN_USER:
        emit okLoginUser(Utils::readQuint16(payload));
        break;
    case Message::Type::RESPONSE_BAD_LOGIN_USER:
        emit badLoginUser(QString::fromUtf8(payload));
        break;
    case Message::Type::RESPONSE_OK_SEND_TEXT:
        emit okSendText(Utils::readQuint32(payload), Utils::readQuint64(payload, 4), Utils::readQuint64(payload, 12));
        break;
    case Message::Type::RESPONSE_BAD_SEND_TEXT:
        emit badSendText(Utils::readQuint32(payload), QString::fromUtf8(payload.mid(4)));
        break;
    case Message::Type::RESPONSE_OK_HISTORY:
        processOkHistory(payload);
        break;
    case Message::Type::RESPONSE_BAD_HISTORY:
        emit badHistory(QString::fromUtf8(payload));
        break;
    case Message::Type::RESPONSE_OK_USER_INFO:
        emit okUserInfo(Utils::readQuint16(payload), QString::fromUtf8(payload.mid(3, static_cast<quint8>(payload[2]))), QString::fromUtf8(payload.mid(3 + static_cast<quint8>(payload[2])).toBase64()));
        break;
    case Message::Type::RESPONSE_BAD_USER_INFO:
        emit badUserInfo(Utils::readQuint16(payload), QString::fromUtf8(payload.mid(2)));
        break;
    case Message::Type::RESPONSE_OK_SEND_FILE_INFO:
        emit okSendFileInfo(Utils::readQuint32(payload), Utils::readQuint64(payload, 4));
        break;
    case Message::Type::RESPONSE_BAD_SEND_FILE_INFO:
        emit badSendFileInfo(Utils::readQuint32(payload), QString::fromUtf8(payload.mid(4)));
        break;
    case Message::Type::RESPONSE_OK_SEND_FILE_CHUNK:
        emit okSendFileChunk(Utils::readQuint64(payload), Utils::readQuint32(payload, 8));
        break;
    case Message::Type::RESPONSE_BAD_SEND_FILE_CHUNK:
        emit badSendFileChunk(Utils::readQuint64(payload), Utils::readQuint32(payload, 8), QString::fromUtf8(payload.mid(12)));
        break;
    case Message::Type::RESPONSE_OK_SEND_FILE:
        emit okSendFile(Utils::readQuint64(payload), Utils::readQuint64(payload, 8), Utils::readQuint64(payload, 16));
        break;
    case Message::Type::RESPONSE_OK_GET_FILE_CHUNK:
        emit okGetFileChunk(Utils::readQuint64(payload), Utils::readQuint32(payload, 8), QString::fromUtf8(payload.mid(12).toBase64()));
        break;
    case Message::Type::RESPONSE_BAD_GET_FILE_CHUNK:
        emit badGetFileChunk(Utils::readQuint64(payload), Utils::readQuint32(payload, 8), QString::fromUtf8(payload.mid(12)));
        break;
    default:
        throw std::runtime_error("Получен необрабатываемый тип сообщения!");
    }
}
void TcpClient::sendMessage(const QByteArray& message) {
    if (m_socket.state() != QTcpSocket::ConnectedState) {
        emit error("Соединение разорвано!");
        return;
    }
    m_socketMutex.lock();
    m_socket.write(message);
    m_socket.flush();
    m_socketMutex.unlock();
}
