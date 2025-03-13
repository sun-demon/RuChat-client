#ifndef MESSAGEREADINGEXCEPTION_H
#define MESSAGEREADINGEXCEPTION_H

#include <stdexcept>

class MessageReadingException : public std::runtime_error {
public:
    MessageReadingException()
        : std::runtime_error("В буффере чтения ещё нет полного сообщения") {}
};


#endif // MESSAGEREADINGEXCEPTION_H
