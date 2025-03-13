#ifndef TCPCLIENT_H
#define TCPCLIENT_H

#include <QObject>
#include <QTcpSocket>
#include <QMutex>
#include <QWaitCondition>

#include "message.h"

class TcpClient : public QObject {
    Q_OBJECT

public:
    explicit TcpClient(QObject* parent = nullptr);
    ~TcpClient() override;

    Q_INVOKABLE void connectToHost();
    Q_INVOKABLE void disconnectFromHost();

    Q_INVOKABLE void requestCheckLogin(const QString& login);
    Q_INVOKABLE void requestRegisterUser(const QString& login, const QString& password, const QString& iconBase64);
    Q_INVOKABLE void requestLoginUser(const QString& login, const QString& password);
    Q_INVOKABLE void requestSendText(quint32 userMessageId, const QString& text);
    Q_INVOKABLE void requestHistory(quint64 messageId);
    Q_INVOKABLE void requestUserInfo(quint16 userId);
    Q_INVOKABLE void requestSendFileInfo(quint32 userMessageId, quint32 chunksNumber, const QString& filename);
    Q_INVOKABLE void requestSendFileChunk(quint64 uploadId, quint32 chunkNumber, const QString& chunkBase64);
    Q_INVOKABLE void requestGetFileChunk(quint64 messageId, quint32 chunkNumber);

signals:
    void connecting();
    void connected();
    void disconnected();
    void error(const QString& error);

    void freeCheckLogin(const QString& login);
    void busyCheckLogin(const QString& login);
    void okRegisterUser(quint16 userId);
    void badRegisterUser(const QString& error);
    void okLoginUser(quint16 userId);
    void badLoginUser(const QString& error);
    void okSendText(quint32 userMessageId, quint64 messageId, quint64 timestamp);
    void badSendText(quint32 userMessageId, const QString& error);
    void getTextMessage(quint16 userId, quint64 messageId, quint64 timestamp, const QString& content);
    void getFileMessageInfo(quint16 userId, quint64 messageId, quint64 timestamp, quint32 chunksNumber, const QString& filename);
    void okHistory();
    void badHistory(const QString& error);
    void okUserInfo(quint16 userId, const QString& login, const QString& iconBase64);
    void badUserInfo(quint16 userId, const QString& error);
    void okSendFileInfo(quint32 userMessageId, quint64 uploadId);
    void badSendFileInfo(quint32 userMessageId, const QString& error);
    void okSendFileChunk(quint64 uploadId, quint32 chunkNumber);
    void badSendFileChunk(quint64 uploadId, quint32 chunkNumber, const QString& error);
    void okSendFile(quint64 uploadId, quint64 messageId, quint64 timestamp);
    void okGetFileChunk(quint64 messageId, quint32 chunkNumber, const QString& chunkBase64);
    void badGetFileChunk(quint64 messageId, quint32 chunkNumber, const QString& error);

private slots:
    void socketStateChanged(QAbstractSocket::SocketState socketState);
    void socketConnected();
    void socketDisconnected();
    void socketError(QAbstractSocket::SocketError socketError);
    void socketReadyRead();

private:
    void processOkHistory(const QByteArray& payload);
    void processMessage(Message::Type type, const QByteArray& payload);
    void sendMessage(const QByteArray& message);

    QTcpSocket m_socket;
    QMutex m_socketMutex;
    QByteArray m_socketReadBuffer;
    QMutex m_socketReadBufferMutex;
};

#endif // TCPCLIENT_H
