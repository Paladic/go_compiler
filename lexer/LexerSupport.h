#pragma once
#include "SourceRange.h"
#include <string>
#include <string_view>

namespace LexerSupport {
    extern bool failed;

    void Reset(const std::string& input, const std::string& name);
    bool ValidateSource();
    void Advance(const char* text, int length, SourceRange& location);
    void End(SourceRange& location);
    void BeginLiteral(SourceRange location);
    void FinishLiteral(SourceRange& location);

    const std::string* Text(SourceRange location);
    long long RuneValue(std::string_view spelling);
    int ClassifyToken(int token);
    void ResumeHeader();
    bool Identifier(SourceRange location);
    // Flex checks the spelling; these check the Unicode scalar value of an escape.
    bool ValidUnicodeEscape(std::string_view spelling);
    bool ValidRune(std::string_view spelling);
    void Error(SourceRange location, const std::string& message);
}
