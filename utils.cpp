#include "utils.h"

#include <QFileInfo>
#include "fileopenningexception.h"
#include <QDebug>
#include <QImage>
#include <QBuffer>
#include <QFile>
#include <QDateTime>

QString Utils::readFile(const QString &filePath) {
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        throw FileOpenningException(filePath);
    }
    QByteArray data = file.readAll();
    file.close();
    return QString::fromUtf8(data.toBase64());
}

void Utils::compressIcon(const QString& filePath) {
    int targetSize = 65482;
    QImage image(filePath);
    if (image.isNull()) {
        emit errorCompressIcon("Ошибка загрузки изображения!");
        return;
    }

    QImage scaledImage = image.scaled(128, 128, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    QImage convertedImage = scaledImage.convertToFormat(QImage::Format_ARGB32);

    QByteArray byteArray;
    QBuffer buffer(&byteArray);
    buffer.open(QIODevice::WriteOnly);

    int quality = 100;
    int step = 5;
    QByteArray bestByteArray;

    while (quality >= 0) {
        byteArray.clear();
        buffer.seek(0);
        convertedImage.save(&buffer, "PNG", quality);

        if(byteArray.size() <= targetSize){
           bestByteArray = byteArray;
        }
        if (byteArray.size() > targetSize) {
            if(bestByteArray.isEmpty()){
                quality = 100;
                while (quality >= 0) {
                    byteArray.clear();
                    buffer.seek(0);
                    convertedImage.save(&buffer, "JPEG", quality);

                    if (byteArray.size() <= targetSize) {
                        bestByteArray = byteArray;
                    }

                    if (byteArray.size() > targetSize) {
                        if (bestByteArray.isEmpty()) {
                            emit errorCompressIcon("Не удалось сжать изображение!");
                            return;
                        }
                        break;
                    }

                    quality -= step;
                }
            }
            break;
        }

        quality -= step;
    }
    emit compressed(QString::fromUtf8(bestByteArray.toBase64()));
}

QUrl Utils::getImageUrlFromBase64(const QString& base64) {
    // QByteArray byteArray = QByteArray::fromBase64(base64.toUtf8());
    // QImage image;
    // image.loadFromData(byteArray);
    // if (image.isNull()) {
    //     qDebug() << "Ошибка: Не удалось создать QImage из QByteArray";
    //     return QUrl();
    // }

    // QByteArray imageByteArray;
    // QBuffer buffer(&imageByteArray);
    // buffer.open(QIODevice::WriteOnly);
    // image.save(&buffer, "PNG");
    // buffer.close();

    // QString base64Image = imageByteArray.toBase64();
    // QUrl imageUrl = QUrl("data:image/png;base64," + base64Image);
    QUrl imageUrl = QUrl("data:image/png;base64," + base64);

    return imageUrl;
}

QString Utils::quint8ToBase64(int value) {
    quint8 byteValue = static_cast<quint8>(value & 0xFF);
    QByteArray byteArray;
    byteArray.append(byteValue);
    QString base64 = QString::fromUtf8(byteArray.toBase64());
    return base64;
}

int Utils::lengthBase64(const QString& base64) {
    return QByteArray::fromBase64(base64.toUtf8()).size();
}

quint8 Utils::base64ToQuint8(const QString& base64) {
    QByteArray byteArray =  QByteArray::fromBase64(base64.toUtf8());
    if (byteArray.size() != 1)
        qDebug() << "base64ToQuint8 - неверный размер бинарных данных";
    return static_cast<quint8>(byteArray[0]);
}

QString Utils::timestampToText(quint64 timestamp) {
    QDateTime dateTime = QDateTime::fromMSecsSinceEpoch(timestamp);
    dateTime.toLocalTime();
    QString formattedTime = dateTime.toString("HH:mm");
    return formattedTime;;
}

quint64 Utils::getFileSize(const QString& fileUrl) {
    QUrl url(fileUrl);
    QString filePath = url.toLocalFile();

    QFile file(filePath);
    if (file.exists()) {
        return file.size();
    } else {
        qDebug() << "Файл не найден:" << filePath;
        return -1; // Or some other error code
    }
}

QString Utils::readBase64Chunk(const QString& filePath, quint32 chunkNumber) {
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        qDebug() << "Ошибка открытия файла:" << file.errorString();
        return QString();
    }

    quint64 fileSize = file.size();
    quint64 offset = chunkNumber * 32768;

    if (offset >= fileSize) {
        qDebug() << "Ошибка чтения чанка: в файле нет столько данных!";
        file.close();
        return QString();
    }

    if (!file.seek(offset)) {
        qDebug() << "Ошибка поиска смещения в файле:" << file.errorString();
        file.close();
        return QString();
    }

    QString base64Chunk = QString::fromUtf8(file.read(qMin(fileSize - offset, static_cast<quint64>(32768))).toBase64());
    file.close();
    return base64Chunk;
}

QString Utils::generateUniqueFilePath(const QString &originalPath) {
    QFileInfo fileInfo(originalPath);
    QString baseName = fileInfo.completeBaseName();  // Имя файла без расширения
    QString extension = fileInfo.suffix();           // Расширение файла
    QString directory = fileInfo.absolutePath();     // Папка, где будет файл

    QString newFilePath = originalPath;
    int counter = 1;

    while (QFileInfo::exists(newFilePath)) {
        newFilePath = QString("%1/%2 (%3).%4")
                          .arg(directory)
                          .arg(baseName)
                          .arg(counter++)
                          .arg(extension);
    }

    return newFilePath;
}


void Utils::createEmptyFile(const QString &filePath) {
    QFile file(filePath);
    if (file.open(QIODevice::WriteOnly)) {  // Open for writing (truncates if exists)
        file.close();
        qDebug() << "Empty file created at:" << filePath;
    } else {
        qDebug() << "Failed to create file at:" << filePath;
    }
}

bool Utils::fileExists(const QString &filePath) {
    return QFile::exists(filePath);
}

bool Utils::appendBase64ChunkToFile(const QString &filePath, const QString &base64Chunk) {
    // Decode Base64 chunk
    QByteArray decodedChunk = QByteArray::fromBase64(base64Chunk.toUtf8());

    // Open file in append mode
    QFile file(filePath);
    if (!file.open(QIODevice::Append)) {
        qWarning() << "Failed to open file:" << filePath << file.errorString();
        return false;
    }

    // Write the decoded data
    if (file.write(decodedChunk) == -1) {
        qWarning() << "Failed to write to file:" << filePath << file.errorString();
        file.close();
        return false;
    }

    file.close();
    return true;
}

// QString Utils::getFileName(const QString& filePath) {
//     return filePath.mid(filePath.lastIndexOf("/"));
// }
