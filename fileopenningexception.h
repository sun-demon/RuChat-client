#ifndef FILEOPENNINGEXCEPTION_H
#define FILEOPENNINGEXCEPTION_H

#include <QString>

class FileOpenningException : public std::runtime_error {
public:
    FileOpenningException(const QString& filepath)
        : std::runtime_error("Ошибка чтения файла по пути: " + filepath.toStdString()) {}
};


#endif // FILEOPENNINGEXCEPTION_H
