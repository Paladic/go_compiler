#include "ParserLogger.h"
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


void ParserLogger::Message(const string& message){

    #ifdef PARSER_DEBUG
    cout
        << Color::Gray << "[PARSER] "
        << Color::Cyan << message
        << Color::Reset << endl;
    #endif

}

void ParserLogger::Value(const string& message, const string& value){

    #ifdef PARSER_DEBUG
    cout
        << Color::Gray << "[PARSER] "
        << Color::Cyan << message
        << Color::Gray << " = "
        << Color::Green << value
        << Color::Reset << endl;
    #endif

}
void ParserLogger::Value(const string& message, long long value){

    #ifdef PARSER_DEBUG
    cout
        << Color::Gray << "[PARSER] "
        << Color::Cyan << message
        << Color::Gray << " = "
        << Color::Green << value
        << Color::Reset << endl;
    #endif

}
void ParserLogger::Value(const string& message, double value){

    #ifdef PARSER_DEBUG
    cout
        << Color::Gray << "[PARSER] "
        << Color::Cyan << message
        << Color::Gray << " = "
        << Color::Green << value
        << Color::Reset << endl;
    #endif

}
void ParserLogger::Error(int line, const string& message){

    cerr
        << Color::Gray << "[PARSER] [L:" 
        << line 
        << "]"
        << Color::Red << "ERROR: "
        << message
        << Color::Reset << endl;
        
}
