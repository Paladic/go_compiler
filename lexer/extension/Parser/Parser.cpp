#include "Parser.h"

#include <string>

using std::string;

long long Parser::Integer(const string& text) {
    
    string value = removeLowLines(text); // удаляем _

    // Система счисления
    int base = 10;

    // индекс символа откуда начинаем
    size_t start = 0;

    // 
    if (value.size() >= 2 && value[0] == '0') {
        
        char secondSymbol = tolower(value[1]); // опускаем в нижний регистр, чтобы проверять условно только 'b', а не 'b' и 'B'

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

double Parser::Imaginary(const string& text) {
    
    string value = text.substr(0, text.size() - 1); // удаляем последний символ (i)

    // Если оставшийся текст - содержит признаки вещественного числа, то преобразуем его в него  
    if (
        value.find('.') != string::npos ||
        value.find('e') != string::npos ||
        value.find('E') != string::npos ||
        value.find('p') != string::npos ||
        value.find('P') != string::npos
    ) {
        return Float(value);
    }

    return static_cast<double>(Integer(value)); // иначе целочисленный
}

long long Parser::Rune(const string& text) {
    
    string value = text.substr(1, text.size() - 2); // удаляем кавычки

    if (value[0] != '\\') {
        return static_cast<unsigned char>(value[0]); // преобразовываем то что внутри в символ
    }

    return DecodeEscape(value); // преобразовываем из escape символа
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

string Parser::EscapeToString(const string& text) {
    
    long long code = DecodeEscape(text); // снчала декодируем его

    // 1 байт
    if (code <= 0x7F) {
        return string(1, static_cast<char>(code));
    }

    string result;

    // 2 байта
    if (code <= 0x7FF) {
        result += static_cast<char>(0xC0 | (code >> 6));
        result += static_cast<char>(0x80 | (code & 0x3F));
    }
    
    // 3 байта
    else if (code <= 0xFFFF) {
        result += static_cast<char>(0xE0 | (code >> 12));
        result += static_cast<char>(0x80 | ((code >> 6) & 0x3F));
        result += static_cast<char>(0x80 | (code & 0x3F));
    }
    
    // 4 байта
    else {
        result += static_cast<char>(0xF0 | (code >> 18));
        result += static_cast<char>(0x80 | ((code >> 12) & 0x3F));
        result += static_cast<char>(0x80 | ((code >> 6) & 0x3F));
        result += static_cast<char>(0x80 | (code & 0x3F));
    }

    return result;
}