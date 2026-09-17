#ifndef COMPILER_LITERAL_H
#define COMPILER_LITERAL_H

#include <string>

using std::string;

class Parser {
    
private:

    /// @brief удаляет _ из строки
    /// @param text строка
    /// @return строка из которого удалены все _
    static string removeLowLines(const string& text);

public:

    /// @brief Преобразовывает строку в целочисленный тип данных
    /// @param text строка
    /// @return целое число
    static long long Integer(const string& text);
    
};

#endif