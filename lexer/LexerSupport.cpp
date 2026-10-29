#include "LexerSupport.h"
#include "UnicodeRanges.h"
#include <charconv>
#include <cstdint>
#include <iostream>
#include <deque>
#include <vector>
#include "parser.tab.hpp"

namespace {
    std::string source;
    std::string filename;
    int line = 1;
    int column = 1;
    std::size_t offset = 0;
    SourceRange literalStart{};
    std::deque<std::string> tokenText;
    struct Delimiter {
        int closing;
        bool header;
    };
    std::vector<Delimiter> delimiters;
    bool headerPending = false;

    unsigned Utf8Width(unsigned char first) {
        if (first < 0x80) return 1;
        if (first >= 0xC2 && first <= 0xDF) return 2;
        if (first >= 0xE0 && first <= 0xEF) return 3;
        if (first >= 0xF0 && first <= 0xF4) return 4;
        return 0;
    }

    bool IsUnicodeScalar(std::uint32_t value) {
        return value <= 0x10FFFF && !(value >= 0xD800 && value <= 0xDFFF);
    }

    // Called only after the bytes of this character have been validated.
    std::uint32_t DecodeUtf8(std::size_t& index) {
        unsigned char first = source[index++];
        unsigned width = Utf8Width(first);
        if (width == 1) return first;
        std::uint32_t value = first & ((1u << (7 - width)) - 1);
        for (unsigned byte = 1; byte < width; ++byte) {
            value = (value << 6) | (static_cast<unsigned char>(source[index++]) & 0x3F);
        }
        return value;
    }

    template<std::size_t Count>
    bool InRanges(std::uint32_t value, const UnicodeRange (&ranges)[Count]) {
        std::size_t begin = 0;
        std::size_t end = Count;
        while (begin < end) {
            std::size_t middle = begin + (end - begin) / 2;
            if (value < ranges[middle].first) end = middle;
            else if (value > ranges[middle].last) begin = middle + 1;
            else return true;
        }
        return false;
    }
}

bool LexerSupport::failed = false;

void LexerSupport::Reset(const std::string& input, const std::string& name) {
    source = input;
    filename = name;
    failed = false;
    line = 1;
    column = 1;
    offset = 0;
    literalStart = {};
    tokenText.clear();
    delimiters.clear();
    headerPending = false;
    if (source.compare(0, 3, "\xEF\xBB\xBF") == 0) {
        offset = 3;
        column = 4;
    }
}

void LexerSupport::Advance(const char* text, int length, SourceRange& location) {
    location = {line, column, line, column, offset, offset};
    for (int index = 0; index < length; ++index) {
        if (text[index] == '\n') {
            ++line;
            column = 1;
        } else {
            ++column;
        }
    }
    offset += length;
    location.last_line = line;
    location.last_column = column;
    location.end = offset;
}

void LexerSupport::End(SourceRange& location) {
    location = {line, column, line, column, offset, offset};
}

void LexerSupport::BeginLiteral(SourceRange location) {
    literalStart = location;
}

void LexerSupport::FinishLiteral(SourceRange& location) {
    location.first_line = literalStart.first_line;
    location.first_column = literalStart.first_column;
    location.begin = literalStart.begin;
}


const std::string* LexerSupport::Text(SourceRange location) {
    tokenText.push_back(source.substr(location.begin, location.end - location.begin));
    return &tokenText.back();
}

long long LexerSupport::RuneValue(std::string_view spelling) {
    spelling = spelling.substr(1, spelling.size() - 2);
    if (spelling.front() != '\\') {
        unsigned char first = spelling.front();
        unsigned width = Utf8Width(first);
        if (width == 1) return first;
        long long value = first & ((1u << (7 - width)) - 1);
        for (unsigned index = 1; index < width; ++index) {
            value = (value << 6) | (static_cast<unsigned char>(spelling[index]) & 0x3F);
        }
        return value;
    }
    switch (spelling[1]) {
        case 'a': return '\a';
        case 'b': return '\b';
        case 'f': return '\f';
        case 'n': return '\n';
        case 'r': return '\r';
        case 't': return '\t';
        case 'v': return '\v';
        case '\\': return '\\';
        case '\'': return '\'';
        default: {
            bool hexadecimal = spelling[1] == 'x' || spelling[1] == 'u' || spelling[1] == 'U';
            long long value = 0;
            std::from_chars(spelling.data() + (hexadecimal ? 2 : 1), spelling.data() + spelling.size(), value, hexadecimal ? 16 : 8);
            return value;
        }
    }
}


int LexerSupport::ClassifyToken(int token) {
    switch (token) {
        case KW_IF: case KW_FOR: case KW_SWITCH: case KW_SELECT:
            headerPending = true;
            break;
        case LEFT_PAREN: case LEFT_BRACKET:
            delimiters.push_back({token == LEFT_PAREN ? RIGHT_PAREN : RIGHT_BRACKET, headerPending});
            headerPending = false;
            break;
        case LEFT_BRACE: {
            bool body = headerPending;
            delimiters.push_back({RIGHT_BRACE, false});
            headerPending = false;
            if (body) return BODY_BRACE;
            break;
        }
        case RIGHT_PAREN: case RIGHT_BRACKET: case RIGHT_BRACE:
            if (!delimiters.empty() && delimiters.back().closing == token) {
                headerPending = delimiters.back().header;
                delimiters.pop_back();
            }
            break;
        default:
            break;
    }
    return token;
}

void LexerSupport::ResumeHeader() {
    if (!delimiters.empty() && delimiters.back().closing == RIGHT_BRACE) delimiters.back().header = true;
}

bool LexerSupport::Identifier(SourceRange location) {
    bool first = true;
    for (std::size_t index = location.begin; index < location.end;) {
        std::uint32_t value = DecodeUtf8(index);
        bool letter = value == '_' || InRanges(value, unicodeLetter);
        bool digit = !first && InRanges(value, unicodeDigit);
        if (!letter && !digit) {
            Error(location, "identifier must contain Unicode letters, decimal digits, or underscore");
            return false;
        }
        first = false;
    }
    return true;
}

bool LexerSupport::ValidUnicodeEscape(std::string_view spelling) {
    if (spelling[1] != 'u' && spelling[1] != 'U') return true;
    std::uint32_t value = 0;
    auto result = std::from_chars(spelling.data() + 2, spelling.data() + spelling.size(), value, 16);
    return result.ec == std::errc{} && IsUnicodeScalar(value);
}

bool LexerSupport::ValidRune(std::string_view spelling) {
    if (spelling[1] != '\\') return true;
    return ValidUnicodeEscape(spelling.substr(1, spelling.size() - 2));
}

bool LexerSupport::ValidateSource() {
    int row = 1;
    int col = 1;
    for (std::size_t index = 0; index < source.size();) {
        std::size_t begin = index;
        unsigned width = Utf8Width(static_cast<unsigned char>(source[index]));
        bool valid = width != 0 && index + width <= source.size();
        for (unsigned byte = 1; valid && byte < width; ++byte) {
            valid = (static_cast<unsigned char>(source[index + byte]) & 0xC0) == 0x80;
        }
        std::uint32_t value = valid ? DecodeUtf8(index) : 0;
        const std::uint32_t minimum[] = {0, 0, 0x80, 0x800, 0x10000};
        valid = valid && value >= minimum[width] && IsUnicodeScalar(value);
        SourceRange location{row, col, row, col + int(width), begin, begin + width};
        if (!valid) {
            Error(location, "invalid UTF-8 encoding");
            return false;
        }
        if (value == 0) {
            Error(location, "NUL character is not allowed in source");
            return false;
        }
        if (value == 0xFEFF && begin != 0) {
            Error(location, "BOM is only allowed at the start of a file");
            return false;
        }
        if (value == '\n') {
            ++row;
            col = 1;
        } else {
            col += width;
        }
    }
    return true;
}

void LexerSupport::Error(SourceRange location, const std::string& message) {
    failed = true;
    std::cerr << filename << ':' << location.first_line << ':' << location.first_column
              << ": " << message << '\n';
}
