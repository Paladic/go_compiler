#ifndef COMPILER_LOGGER_H
#define COMPILER_LOGGER_H

#include <string>

using std::string;

class Logger {
public:
    static void Token(const string& token);

    static void Value(const string& token, const string& value);
    static void Value(const string& token, long long value);
    static void Value(const string& token, double value);
    static void Value(const string& token, char value);

    static void Warning(const string& message);
    static void Error(const string& message);
};

#endif