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
    
    /// @brief Преобразовывает строку в тип данных с плавающей точкой
    /// @param text строка 
    /// @return число с плавающей точкой
    static double Float(const string& text);
    
    /// @brief Преобразовывает строку в мнимое число
    /// @param text строка
    /// @return мннимое число без мнимой части
    static double Imaginary(const string& text);
};

#endif