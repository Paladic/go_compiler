#ifndef COMPILER_LITERAL_H
#define COMPILER_LITERAL_H

#include <string>
#include <cctype>


// Вопросы
//  1. Парс ИД - у нас поддерживаются символы, но смайлики нельзя - варианты либо заводить таблицу символов либо что-то еще делать?
//  2. Проблема с большими интами. GO поддерживает int 1267650600228229401496703205376
//  3. double аналогично
//
//
//

using std::string;

class Parser {
    
private:

    /// @brief удаляет _ из строки
    /// @param text строка
    /// @return строка из которого удалены все _
    static string removeLowLines(const string& text);

    /// @brief Декодирует escape символы в значение
    /// @param value escape символ
    /// @return восьмиричное число соответсвующее escape символу
    static long long DecodeEscape(const string& text);

    /// @brief получает код UTF8 из строки-значения
    /// @param text строка-значение
    /// @return код UTF8
    static long long DecodeUTF8(const string& text);

    /// @brief Получает строку-значение из кода UTF8
    /// @param code код UTF8
    /// @return строка-значение
    static string EncodeUTF8(long long code);

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
    
    /// @brief Преобразовывает строку в отдельный символ
    /// @param text строка
    /// @return восьмиричное число соответсвующее escape символу
    static long long Rune(const string& text);
    
    /// @brief преобразует escape последовательность в символ
    /// @param text escape послеодвательность
    /// @return декодированный символ 
    static string EscapeToString(const string& text);

    /// @brief Проверяет допустимый ли символ
    /// @param value 
    /// @return 
    static bool IsValidUnicodeCodePoint(long long value);

    static long long EscapeValue(const string& text);
    
};

#endif