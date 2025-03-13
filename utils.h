#ifndef UTILS_H
#define UTILS_H

#include <QObject>
#include <QByteArray>
#include <QCryptographicHash>
#include <QUrl>


class Utils : public QObject {
    Q_OBJECT
public:
    Utils(QObject *parent = nullptr): QObject(parent) {}

    Q_INVOKABLE QString readFile(const QString& filePath);
    Q_INVOKABLE void compressIcon(const QString& filePath);
    Q_INVOKABLE QUrl getImageUrlFromBase64(const QString& base64);

    Q_INVOKABLE QString quint8ToBase64(int value);
    Q_INVOKABLE int lengthBase64(const QString& base64);
    Q_INVOKABLE quint8 base64ToQuint8(const QString& base64);
    Q_INVOKABLE QString timestampToText(quint64 timestamp);
    Q_INVOKABLE quint64 getFileSize(const QString& fileUrl);
    Q_INVOKABLE QString readBase64Chunk(const QString& filePath, quint32 chunkNumber = 0);
    Q_INVOKABLE QString generateUniqueFilePath(const QString &originalPath);
    Q_INVOKABLE void createEmptyFile(const QString &filePath);
    Q_INVOKABLE bool fileExists(const QString& filePath);
    Q_INVOKABLE bool appendBase64ChunkToFile(const QString& filepath, const QString& base64Chunk);
    // Q_INVOKABLE QString getFileName(const QString& filePath);

    static quint16 readQuint16(const QByteArray& byteArray, quint16 position = 0) {
        return ((static_cast<quint16>(byteArray[position]) & 0xFF) << 8) | (static_cast<quint16>(byteArray[position + 1]) & 0xFF);
    }
    static quint32 readQuint32(const QByteArray& byteArray, quint16 position = 0) {
        quint32 result = 0;
        for (int i = 0; i < 4; ++i)
            result += ((static_cast<quint32>(byteArray[position + 3 - i]) & 0xFF) << (8 * i));
        return result;
    }
    static quint64 readQuint64(const QByteArray& byteArray, quint16 position = 0) {
        quint64 result = 0;
        for (int i = 0; i < 8; ++i)
            result += ((static_cast<quint64>(byteArray[position + 7 - i]) & 0xFF) << (8 * i));
        return result;
    }

    static QByteArray& appendQuint16(QByteArray& source, quint16 number) {
        source.append((number >> 8) & 0xFF);
        source.append(number & 0xFF);
        return source;
    }
    static QByteArray& appendQuint32(QByteArray& source, quint32 number) {
        for (int i = 3; i >= 0; --i) {
            source.append((number >> (8 * i)) & 0xFF);
        }
        return source;
    }
    static QByteArray& appendQuint64(QByteArray& source, quint64 number) {
        for (int i = 7; i >= 0; --i) {
            source.append((number >> (8 * i)) & 0xFF);
        }
        return source;
    }

    static QByteArray hashPassword(const QString& password) {
        QByteArray saltedPassword = password.toUtf8() + "a little seasoning";
        QByteArray hashedPassword = QCryptographicHash::hash(saltedPassword, QCryptographicHash::Sha256);
        return hashedPassword;
    }


    static quint16 calculateChecksum(const QByteArray& data) {
        quint32 checksum = 0;
        int length = data.size();
        for (int i = 0; i < length; i += 2) {
            quint16 word = (static_cast<quint8>(data[i]) << 8) | (i + 1 < length ? static_cast<quint8>(data[i + 1]) : 0);
            checksum += word;
        }
        while (checksum >> 16) {
            checksum = (checksum & 0xFFFF) + (checksum >> 16);
        }
        return static_cast<quint16>(~checksum);
    }

signals:
    void compressed(const QString& base64);
    void errorCompressIcon(const QString& error);

};

#endif // UTILS_H
