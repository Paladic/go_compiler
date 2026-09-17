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
