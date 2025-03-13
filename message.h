#ifndef MESSAGE_H
#define MESSAGE_H

#include <QByteArray>

#include "utils.h"
#include "messagereadingexception.h"
#include "versionexception.h"

const quint8 VERSION = 0;

namespace Message {
    namespace Content {
        enum class Type : quint8{
            TEXT,
            FILE
        };
    }

    enum class Type : quint8 {
        REQUEST_CHECK_LOGIN, // login
        RESPONSE_FREE_LOGIN, // login
        RESPONSE_BUSY_LOGIN, // login

        REQUEST_REGISTER_USER,      // login_length (1 byte), login (login_length bytes), password_hash (32 bytes), icon (max_size = 65482 bytes)
        RESPONSE_OK_REGISTER_USER,  // user_id (2 bytes)
        RESPONSE_BAD_REGISTER_USER, // error (max_size = 1024 bytes)

        REQUEST_LOGIN_USER,      // login, password_hash (32 bytes)
        RESPONSE_OK_LOGIN_USER,  // user_id (2 bytes), icon (max_size = 65482 bytes)
        RESPONSE_BAD_LOGIN_USER, // error (max_size = 1024 bytes)

        REQUEST_SEND_TEXT,      // user_message_id (4 bytes), text(max_size = 4096 bytes)
        RESPONSE_OK_SEND_TEXT,  // user_message_id (4 bytes), message_id (8 bytes), timestamp (8 bytes)
        RESPONSE_BAD_SEND_TEXT, // user_message_id (4 bytes), error (max_size = 1024 bytes)

        REQUEST_HISTORY,     // message_id (8 bytes)
        RESPONSE_OK_HISTORY, // [...] (max_size = 65535)
                             //                                                                                               / content (max_size = 4095)
                             // meta_info_length (2 bytes), user_id (2 bytes), message_id (8 bytes), timestamp (8 bytes), type (1 byte) (0 or 1)
                             //                                                                                               \ chunks_number (4 bytes), filename (max_size = 255 bytes)
        RESPONSE_BAD_HISTORY,// error (max_size = 1024 bytes)

        REQUEST_USER_INFO,      // user_id (2 bytes)
        RESPONSE_OK_USER_INFO,  // user_id (2 bytes), login_length (1 byte), login (login_length bytes), icon (max_size = 65482 bytes)
        RESPONSE_BAD_USER_INFO, // user_id (2 bytes), error (max_size = 1024 bytes)

        REQUEST_SEND_FILE_INFO,      // user_message_id (4 bytes), chunks_number (4 bytes), filename (max_size = 255 bytes)
        RESPONSE_OK_SEND_FILE_INFO,  // user_message_id (4 bytes), upload_id (8 bytes)
        RESPONSE_BAD_SEND_FILE_INFO, // user_message_id (4 bytes), error (max_size = 1024 bytes)

        REQUEST_SEND_FILE_CHUNK,      // upload_id (8 bytes), chunk_number (4 bytes), chunk (32768 bytes) (only last must be lower)
        RESPONSE_OK_SEND_FILE_CHUNK,  // upload_id (8 bytes), chunk_number (4 bytes)
        RESPONSE_BAD_SEND_FILE_CHUNK, // upload_id (8 bytes), chunk_number (4 bytes), error (max_size = 1024 bytes)
        RESPONSE_OK_SEND_FILE,        // upload_id (8 bytes), message_id (8 bytes), timestamp (8 bytes)

        REQUEST_GET_FILE_CHUNK,      // message_id (8 bytes), chunk_number (4 bytes)
        RESPONSE_OK_GET_FILE_CHUNK,  // message_id (8 bytes), chunk_number (4 bytes), chunk (32768 bytes) (only last must be lower)
        RESPONSE_BAD_GET_FILE_CHUNK  // message_id (8 bytes), chunk_number (4 bytes), error (max_size = 1024 bytes)
    };

    enum class Part : quint8 {
        VERSION,            // 1 byte
        TYPE,               // 1 byte
        PAYLOAD_LENGTH,     // 2 bytes
        PAYLOAD,            // PAYLOAD_LENGTH byte(s) (max_value = 65535 bytes)
        CHECKSUM            // 2 bytes
    };

    static QByteArray create(Type type, const QByteArray& payload) {
        QByteArray message;
        message.append(VERSION);
        message.append(static_cast<quint8>(type));
        Utils::appendQuint16(message, static_cast<quint16>(payload.size()));
        message.append(payload);
        Utils::appendQuint16(message, Utils::calculateChecksum(payload));
        return message;
    }
    static void checkVersion(QByteArray& bytearray) {
        if (bytearray.size() < 1) {
            throw MessageReadingException();
        }
        quint8 serverVersion = static_cast<quint8>(bytearray[0]);
        if (VERSION != serverVersion) {
            throw VersionException(VERSION, serverVersion);
        }
    }
    static quint16 getPayloadLength(const QByteArray& bytearray) {
        if (bytearray.size() < 4) {
            throw MessageReadingException();
        }
        return Utils::readQuint16(bytearray, 2);
    }
    static quint16 getChecksum(QByteArray& bytearray) {
        quint16 payloadLength = Message::getPayloadLength(bytearray);
        if (bytearray.size() < payloadLength + 6) {
            throw MessageReadingException();
        }
        quint16 checksum = Utils::readQuint16(bytearray, payloadLength + 4);
        return checksum;
    }
    static Message::Type getType(const QByteArray& bytearray) {
        if (bytearray.size() < 2) {
            throw MessageReadingException();
        }
        return static_cast<Message::Type>((static_cast<quint8>(bytearray[1])));
    }
    static QByteArray getPayload(const QByteArray& bytearray) {
        quint16 payloadLength = Message::getPayloadLength(bytearray);
        if (bytearray.size() < payloadLength + 6) {
            throw MessageReadingException();
        }
        return bytearray.mid(4, payloadLength);
    }
}

#endif // MESSAGE_H
