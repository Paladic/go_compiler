#include "Logger.h"

#include <iostream>

using std::cout;
using std::cerr;
using std::endl;

namespace Color {
    constexpr const char* Reset  = "\033[0m";
    constexpr const char* Gray   = "\033[90m";
    constexpr const char* Cyan   = "\033[96m";
    constexpr const char* Green  = "\033[92m";
    constexpr const char* Yellow = "\033[93m";
    constexpr const char* Red    = "\033[91m";
}

void Logger::Token(const string& token) {
    cout
        << Color::Cyan << token
        << Color::Reset << endl;
}

void Logger::Value(const string& token, const string& value) {
    cout
        << Color::Cyan << token
        << Color::Gray << " = "
        << Color::Green << value
        << Color::Reset << endl;
}

void Logger::Value(const string& token, long long value) {
    cout
        << Color::Cyan << token
        << Color::Gray << " = "
        << Color::Green << value
        << Color::Reset << endl;
}

void Logger::Value(const string& token, double value) {
    cout
        << Color::Cyan << token
        << Color::Gray << " = "
        << Color::Green << value
        << Color::Reset << endl;
}

void Logger::Value(const string& token, char value) {
    cout
        << Color::Cyan << token
        << Color::Gray << " = "
        << Color::Green << value
        << Color::Reset << endl;
}

void Logger::Warning(const string& message) {
    cout
        << Color::Yellow << "WARNING: "
        << message
        << Color::Reset << endl;
}

void Logger::Error(const string& message) {
    cerr
        << Color::Red << "ERROR: "
        << message
        << Color::Reset << endl;
}