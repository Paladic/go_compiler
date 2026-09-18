#include "Parser.h"

using std::string;

long long Parser::Integer(const string& text) {
    
    string value = removeLowLines(text); // удаляем _

    // Система счисления
    int base = 10;

    // индекс символа откуда начинаем
    size_t start = 0;

    // 
    if (value.size() >= 2 && value[0] == '0') {
        
        char secondSymbol = static_cast<char>(std::tolower(static_cast<unsigned char>(value[1]))); // опускаем в нижний регистр, чтобы проверять условно только 'b', а не 'b' и 'B'

        // Двоичные числа - 0b1010
        if (secondSymbol == 'b') {
            base = 2;
            start = 2;
        }

        // Восьмиричные числа - 
        else if (secondSymbol == 'o') {
            base = 8;
            start = 2;
        }

        // Шестнадцатиричные числа
        else if (secondSymbol == 'x') {
            base = 16;
            start = 2;
        }

        // старая восьмиричная система исчисления
        else {
            base = 8;
            start = 1;
        }
    }

    return std::stoll(value.substr(start), nullptr, base);
}

double Parser::Float(const string& text) {
    
    string value = removeLowLines(text); // удаляем _
    return std::stod(value); // приводим к числу

}

string Parser::removeLowLines(const string& text) {

    string value;

     for (char ch : text) {
        if (ch != '_') {
            value += ch;
        }
    }

    return value;

}

double Parser::Imaginary(const string& text)
{
    string value = removeLowLines(
        text.substr(0, text.size() - 1)
    );

    if (value.size() >= 2 && value[0] == '0') {

        char secondSymbol =
            static_cast<char>(
                std::tolower(
                    static_cast<unsigned char>(value[1])
                )
            );

        // Явные binary/octal literals
        if (
            secondSymbol == 'b' ||
            secondSymbol == 'o'
        ) {
            return static_cast<double>(
                Integer(value)
            );
        }

        // Hexadecimal
        if (secondSymbol == 'x') {

            // Только p/P превращает hex literal в float
            if (
                value.find('p') != string::npos ||
                value.find('P') != string::npos
            ) {
                return Float(value);
            }

            return static_cast<double>(
                Integer(value)
            );
        }
    }

    // Decimal float
    if (
        value.find('.') != string::npos ||
        value.find('e') != string::npos ||
        value.find('E') != string::npos
    ) {
        return Float(value);
    }

    // Особое правило Go:
    // 0123i == 123i, а не octal 0123
    return static_cast<double>(
        std::stoll(value, nullptr, 10)
    );
}


long long Parser::Rune(const string& text) {
    
    string value = text.substr(1, text.size() - 2); // удаляем кавычки

    if (value[0] == '\\') {
        return DecodeEscape(value); // преобразовываем из escape символа
    }

    return DecodeUTF8(value); // преобразовываем то что внутри в символ

}

long long Parser::DecodeEscape(const string& text) {
    
    // Если строка содержит всего два символа, то прогоняем ее из предопределенных последовательностей
    if (text.size() == 2) {
       
        switch (text[1]) {
            case 'a':  return '\a';
            case 'b':  return '\b';
            case 'f':  return '\f';
            case 'n':  return '\n';
            case 'r':  return '\r';
            case 't':  return '\t';
            case 'v':  return '\v';
            case '\\': return '\\';
            case '\'': return '\'';
            case '"':  return '"';
        }
    
    }

    // если записано в шестнадцатиричной системе то расшифровываем
    if (text[1] == 'x' || text[1] == 'u' || text[1] == 'U') {
        return std::stoll(text.substr(2), nullptr, 16);
    }

    return std::stoll(text.substr(1), nullptr, 8); // читаем как восьмиричный
}

long long Parser::DecodeUTF8(const string& text)
{
    unsigned char b1 = static_cast<unsigned char>(text[0]);

    // 1 байт
    if (b1 <= 0x7F) {
        return b1;
    }

    // 2 байта
    if ((b1 & 0xE0) == 0xC0) {

        unsigned char b2 =
            static_cast<unsigned char>(text[1]);

        return ((b1 & 0x1F) << 6) |
               (b2 & 0x3F);
    }

    // 3 байта
    if ((b1 & 0xF0) == 0xE0) {

        unsigned char b2 =
            static_cast<unsigned char>(text[1]);

        unsigned char b3 =
            static_cast<unsigned char>(text[2]);

        return ((b1 & 0x0F) << 12) |
               ((b2 & 0x3F) << 6) |
               (b3 & 0x3F);
    }

    // 4 байта
    unsigned char b2 =
        static_cast<unsigned char>(text[1]);

    unsigned char b3 =
        static_cast<unsigned char>(text[2]);

    unsigned char b4 =
        static_cast<unsigned char>(text[3]);

    return ((b1 & 0x07) << 18) |
           ((b2 & 0x3F) << 12) |
           ((b3 & 0x3F) << 6) |
           (b4 & 0x3F);
}

string Parser::EncodeUTF8(long long code)
{
    string result;

    // 1 байт
    if (code <= 0x7F) {
        result += static_cast<char>(code);
    }

    // 2 байта
    else if (code <= 0x7FF) {
        result += static_cast<char>(
            0xC0 | (code >> 6)
        );

        result += static_cast<char>(
            0x80 | (code & 0x3F)
        );
    }

    // 3 байта
    else if (code <= 0xFFFF) {
        result += static_cast<char>(
            0xE0 | (code >> 12)
        );

        result += static_cast<char>(
            0x80 | ((code >> 6) & 0x3F)
        );

        result += static_cast<char>(
            0x80 | (code & 0x3F)
        );
    }

    // 4 байта
    else {
        result += static_cast<char>(
            0xF0 | (code >> 18)
        );

        result += static_cast<char>(
            0x80 | ((code >> 12) & 0x3F)
        );

        result += static_cast<char>(
            0x80 | ((code >> 6) & 0x3F)
        );

        result += static_cast<char>(
            0x80 | (code & 0x3F)
        );
    }

    return result;
}

string Parser::EscapeToString(const string& text)
{
    long long value = DecodeEscape(text);

    // 1 байт
    if (text[1] == 'x' ||
        (text[1] >= '0' && text[1] <= '7')) {

        return string(
            1,
            static_cast<char>(value)
        );
    }

    // escape последовательности
    if (text.size() == 2) {
        return string(
            1,
            static_cast<char>(value)
        );
    }

    return EncodeUTF8(value);
}

bool Parser::IsValidUnicodeCodePoint(long long value)
{
    return
        value >= 0 &&
        value <= 0x10FFFF &&
        !(value >= 0xD800 && value <= 0xDFFF);
}

long long Parser::EscapeValue(const string& text)
{
    return DecodeEscape(text);
}