#pragma once

#include <string>

using std::string;

class ParserLogger {
public:
    
    static void Message(const string& message);
    static void Value(const string& message, const string& value);
    static void Value(const string& message, long long value);
    static void Value(const string& message, double value);
    static void Error(int line, const string& message);

};