%option noyywrap yylineno

%{

/* 
Нюансы:
1. все варианты идентификаторов реализовывать не надо - это на доп. баллы
2. супер длинные числа реализовывать не надо - это на доп. баллы
3. Момент с a multiline-comment + b - будет a; +b;

 */

/* глобальные переменные, бибилотеки, функции и т.д. */

#include <cstdio>
#include <iostream>
#include <string>
#include "extension/logger/logger.h"
#include "extension/Parser/Parser.h"
#include "extension/buffer/Buffer.h"
#include "../parser/parser.tab.hpp"

#ifdef _WIN32
#include <windows.h>
#endif

using std::string;

/* буфер где будем хранить текст для строковых литералов */
Buffer buffer;

/* флаг проверки на корректность строковых литералов */
bool stringInvalid = false;

bool rawStringInvalid = false;

/* Флаг автоматической вставки точки с запятой */
bool autoSemi = false;

#define RETURN_TOKEN(token, semi)       \
    do {                                \
        Logger::Token(#token);          \
        autoSemi = (semi);              \
        return token;                   \
    } while (0)


#define RETURN_INTEGER(token, expr, semi)   \
    do {                                    \
        long long value = (expr);           \
        Logger::Value(#token, value);       \
        yylval.integerValue = value;        \
        autoSemi = (semi);                  \
        return token;                       \
    } while (0)


#define RETURN_FLOAT(token, expr, semi)     \
    do {                                    \
        double value = (expr);              \
        Logger::Value(#token, value);       \
        yylval.floatValue = value;          \
        autoSemi = (semi);                  \
        return token;                       \
    } while (0)


#define RETURN_STRING(token, expr, semi)    \
    do {                                    \
        std::string value = (expr);         \
        Logger::Value(#token, value);       \
        yylval.stringValue =                \
            new std::string(value);         \
        autoSemi = (semi);                  \
        return token;                       \
    } while (0)

%}

/* состояние для строк */
%x STRING

/* состояние для строк которые не обрабатываются */
%x RAW_STRING
/* Состояние для многострочных комментариев */
%x COMMENT

/* ---------- Идентификаторы ---------- */

ASCII_LETTER    [A-Za-z_]
ASCII_DIGIT     [0-9]

UTF8_CONT       [\200-\277]

UTF8_2          [\302-\337]{UTF8_CONT}

UTF8_3          (\340[\240-\277]{UTF8_CONT}|[\341-\354]{UTF8_CONT}{UTF8_CONT}|\355[\200-\237]{UTF8_CONT}|[\356-\357]{UTF8_CONT}{UTF8_CONT})

UTF8_4          (\360[\220-\277]{UTF8_CONT}{UTF8_CONT}|[\361-\363]{UTF8_CONT}{UTF8_CONT}{UTF8_CONT}|\364[\200-\217]{UTF8_CONT}{UTF8_CONT})

UTF8_CHAR       ({UTF8_2}|{UTF8_3}|{UTF8_4})

LETTER          ({ASCII_LETTER}|{UTF8_CHAR})
DIGIT           {ASCII_DIGIT}

IDENTIFIER      {LETTER}({LETTER}|{DIGIT})*


/* ---------- Целочисленные литералы ---------- */

DECIMAL_DIGIT       [0-9]
BINARY_DIGIT        [01]
OCTAL_DIGIT         [0-7]
HEX_DIGIT           [0-9a-fA-F]

DECIMAL_DIGITS      {DECIMAL_DIGIT}(_?{DECIMAL_DIGIT})*
BINARY_DIGITS       {BINARY_DIGIT}(_?{BINARY_DIGIT})*
OCTAL_DIGITS        {OCTAL_DIGIT}(_?{OCTAL_DIGIT})*
HEX_DIGITS          {HEX_DIGIT}(_?{HEX_DIGIT})*

DECIMAL_LITERAL     0|[1-9](_?{DECIMAL_DIGITS})?
BINARY_LITERAL      0[bB]_?{BINARY_DIGITS}
OCTAL_LITERAL       0[oO]_?{OCTAL_DIGITS}
OLD_OCTAL_LITERAL   0_?{OCTAL_DIGITS}
HEX_LITERAL         0[xX]_?{HEX_DIGITS}

BINARY_CANDIDATE  0[bB][0-9_]*(\.[0-9_]*|[eEpP][+-]?[0-9_]*)?i?
/* 0[bB][0-9_]+ */
OCTAL_CANDIDATE   0[oO][0-9_]*(\.[0-9_]*|[eEpP][+-]?[0-9_]*)?i?

HEX_CANDIDATE  0[xX][0-9a-fA-F_]*(\.[0-9a-fA-F_]*)?([pP][+-]?[0-9_]*)?i?

DECIMAL_CANDIDATE (([0-9][0-9_]*(\.[0-9_]*)?)|(\.[0-9][0-9_]*))([eEpP][+-]?[0-9_]*)?i?

/* ---------- Литералы с плавающей точкой ---------- */

DECIMAL_EXPONENT    [eE][+-]?{DECIMAL_DIGITS}
BINARY_EXPONENT     [pP][+-]?{DECIMAL_DIGITS}

DECIMAL_FLOAT       ({DECIMAL_DIGITS}"."{DECIMAL_DIGITS}?{DECIMAL_EXPONENT}?)|({DECIMAL_DIGITS}{DECIMAL_EXPONENT})|("."{DECIMAL_DIGITS}{DECIMAL_EXPONENT}?)

HEX_MANTISSA        ((_?{HEX_DIGITS}"."{HEX_DIGITS}?)|(_?{HEX_DIGITS})|("."{HEX_DIGITS}))
HEX_FLOAT           0[xX]{HEX_MANTISSA}{BINARY_EXPONENT}

/* ---------- Мнимые литералы ---------- */

IMAGINARY_LITERAL   ({DECIMAL_DIGITS}|{BINARY_LITERAL}|{OCTAL_LITERAL}|{HEX_LITERAL}|{DECIMAL_FLOAT}|{HEX_FLOAT})i

/* ---------- Символьные литералы  ---------- */

OCTAL_BYTE_ESCAPE   \\[0-3][0-7]{2}
HEX_BYTE_ESCAPE     \\x[0-9a-fA-F]{2}
UNICODE_4_ESCAPE    \\u[0-9a-fA-F]{4}
UNICODE_8_ESCAPE    \\U[0-9a-fA-F]{8}

RUNE_ESCAPE         (\\[abfnrtv\\']|{OCTAL_BYTE_ESCAPE}|{HEX_BYTE_ESCAPE}|{UNICODE_4_ESCAPE}|{UNICODE_8_ESCAPE})

ASCII_RUNE_CHAR     [^\\'\n\200-\377]
RUNE_CHAR           ({ASCII_RUNE_CHAR}|{UTF8_CHAR})

RUNE_LITERAL        \'({RUNE_CHAR}|{RUNE_ESCAPE})\'

/* ---------- Стороковые литералы  ---------- */

STRING_ESCAPE       (\\[abfnrtv\\"]|{OCTAL_BYTE_ESCAPE}|{HEX_BYTE_ESCAPE}|{UNICODE_4_ESCAPE}|{UNICODE_8_ESCAPE})
ASCII_STRING_CHAR   [^\\\"\n\200-\377]
STRING_CHAR         ({ASCII_STRING_CHAR}|{UTF8_CHAR})

ASCII_RAW_STRING_CHAR   [^`\r\n\200-\377]
RAW_STRING_CHAR         ({ASCII_RAW_STRING_CHAR}|{UTF8_CHAR})

%%

    /* Комментари внутри этого блока пишутся вот в этом синтаксесе и обязательно перед комментаривем табуляцию */

    /* ---------- Ключевые слова ---------- */

"break"       { RETURN_TOKEN(KW_BREAK, true); }
"default"     { RETURN_TOKEN(KW_DEFAULT, false); }
"func"        { RETURN_TOKEN(KW_FUNC, false); }
"interface"   { RETURN_TOKEN(KW_INTERFACE, false); }
"select"      { RETURN_TOKEN(KW_SELECT, false); }
"case"        { RETURN_TOKEN(KW_CASE, false); }
"defer"       { RETURN_TOKEN(KW_DEFER, false); }
"go"          { RETURN_TOKEN(KW_GO, false); }
"map"         { RETURN_TOKEN(KW_MAP, false); }
"struct"      { RETURN_TOKEN(KW_STRUCT, false); }
"chan"        { RETURN_TOKEN(KW_CHAN, false); }
"else"        { RETURN_TOKEN(KW_ELSE, false); }
"goto"        { RETURN_TOKEN(KW_GOTO, false); }
"package"     { RETURN_TOKEN(KW_PACKAGE, false); }
"switch"      { RETURN_TOKEN(KW_SWITCH, false); }
"const"       { RETURN_TOKEN(KW_CONST, false); }
"fallthrough" { RETURN_TOKEN(KW_FALLTHROUGH, true); }
"if"          { RETURN_TOKEN(KW_IF, false); }
"range"       { RETURN_TOKEN(KW_RANGE, false); }
"type"        { RETURN_TOKEN(KW_TYPE, false); }
"continue"    { RETURN_TOKEN(KW_CONTINUE, true); }
"for"         { RETURN_TOKEN(KW_FOR, false); }
"import"      { RETURN_TOKEN(KW_IMPORT, false); }
"return"      { RETURN_TOKEN(KW_RETURN, true); }
"var"         { RETURN_TOKEN(KW_VAR, false); }

    /* ---------- Мнимые литералы ---------- */

{IMAGINARY_LITERAL} {RETURN_FLOAT(IMAGINARY_LITERAL, Parser::Imaginary(yytext), true);}
    
    /* ---------- Литералы с плавающей точкой ---------- */

{HEX_FLOAT} { RETURN_FLOAT(HEX_FLOAT_LITERAL, Parser::Float(yytext), true); }

{DECIMAL_FLOAT} { RETURN_FLOAT(FLOAT_LITERAL, Parser::Float(yytext), true); }

    /* ---------- Целочисленные литералы ---------- */
    
{BINARY_LITERAL} { RETURN_INTEGER(BINARY_LITERAL, Parser::Integer(yytext), true); }

{OCTAL_LITERAL} {RETURN_INTEGER(OCTAL_LITERAL, Parser::Integer(yytext), true); }

{OLD_OCTAL_LITERAL} {RETURN_INTEGER(OCTAL_LITERAL, Parser::Integer(yytext), true); }

{HEX_LITERAL} {RETURN_INTEGER(HEX_LITERAL, Parser::Integer(yytext), true); }

{DECIMAL_LITERAL} { RETURN_INTEGER(DECIMAL_LITERAL, Parser::Integer(yytext), true); }
    
    /* ---------- ошибки ------------- */

{BINARY_CANDIDATE} {

    Logger::Error("Invalid binary literal '" + string(yytext) + "' at line " + std::to_string(yylineno));

    autoSemi = false;

    return LEXICAL_ERROR;
}

{OCTAL_CANDIDATE} {

    Logger::Error("Invalid octal literal '" + string(yytext) + "' at line " + std::to_string(yylineno));

    autoSemi = false;

    return LEXICAL_ERROR;
}

{HEX_CANDIDATE} {
   
   Logger::Error("Invalid hexadecimal literal '" + string(yytext) + "' at line " + std::to_string(yylineno));

    autoSemi = false;

    return LEXICAL_ERROR;
}

{DECIMAL_CANDIDATE} {
   
   Logger::Error("Invalid numeric literal '" + string(yytext) + "' at line " + std::to_string(yylineno));

    autoSemi = false;

    return LEXICAL_ERROR;
}

    /* ---------- Символьные литералы ---------- */

{RUNE_LITERAL} {
    long long value = Parser::Rune(yytext);

    if (!Parser::IsValidUnicodeCodePoint(value)) {
        
        Logger::Error("Invalid rune literal '" + string(yytext) + "' at line " + std::to_string(yylineno));

        autoSemi = false;
        return LEXICAL_ERROR;
    }

    RETURN_INTEGER(RUNE_LITERAL, value, true);
}

\'[^'\n]*\' {
   
   Logger::Error("Invalid rune literal '" + string(yytext) + "' at line " + std::to_string(yylineno));

    autoSemi = false;

    return LEXICAL_ERROR;
}

\'[^'\n]* {
    
    Logger::Error("Unclosed rune literal '" + string(yytext) + "' at line " + std::to_string(yylineno));

    autoSemi = false;

    return LEXICAL_ERROR;
}

    /* ---------- Стороковые литералы ---------- */

\" {
    buffer.Reset(yylineno);
    stringInvalid = false;
    BEGIN(STRING);
}

<STRING>{STRING_CHAR}+ {
    buffer.Append(yytext);
}

<STRING>{STRING_ESCAPE} {
    
    string escape = yytext;

    if (escape[1] == 'u' || escape[1] == 'U') {

        long long value =
            Parser::EscapeValue(escape);

        if (!Parser::IsValidUnicodeCodePoint(value)) {
            Logger::Error(
                "Invalid Unicode escape '" + escape +
                "' at line " + std::to_string(yylineno)
            );

            stringInvalid = true;
        }
        else {
            buffer.Append(
                Parser::EscapeToString(escape)
            );
        }
    }
    else {
        buffer.Append(
            Parser::EscapeToString(escape)
        );
    }
}

<STRING>\\. {
    Logger::Error(
        "Invalid escape sequence '" + string(yytext) +
        "' at line " + std::to_string(yylineno)
    );

    stringInvalid = true;
}

<STRING>\\ {
    /*
        при hello\\n, где \n не символ а enter.  
    */

}

<STRING>\" {

    BEGIN(INITIAL);

    if (stringInvalid) {
        autoSemi = false;
        return LEXICAL_ERROR;
    }

    RETURN_STRING(STRING_LITERAL, buffer.Get(), true);

}

<STRING>\n {
    
    Logger::Error("Unclosed string literal at line " + std::to_string(buffer.GetStartLine()));

    buffer.Reset(yylineno);

    stringInvalid = false;
    autoSemi = false;

    BEGIN(INITIAL);

    return LEXICAL_ERROR;
}

<STRING><<EOF>> {
    
    Logger::Error("Unclosed string literal at line " + std::to_string(buffer.GetStartLine()));

    stringInvalid = false;
    autoSemi = false;

    BEGIN(INITIAL);

    return LEXICAL_ERROR;
}

<STRING>[\200-\377] {
    
    Logger::Error("Invalid UTF-8 sequence at line " + std::to_string(yylineno));

    stringInvalid = true;
}

    /* ---------- Необработавыаемые строковые литералы ---------- */

` {
    buffer.Reset(yylineno);
    rawStringInvalid = false;
    BEGIN(RAW_STRING);
}

<RAW_STRING>{RAW_STRING_CHAR}+ {
    buffer.Append(yytext);
}

<RAW_STRING>\n {
    buffer.Append("\n");
}

<RAW_STRING>\r {
    /* удаляется из необратавыемых строк */
}

<RAW_STRING>` {
    
    BEGIN(INITIAL);

    if (rawStringInvalid) {
        autoSemi = false;
        return LEXICAL_ERROR;
    }

    RETURN_STRING(RAW_STRING_LITERAL, buffer.Get(), true);

}

<RAW_STRING><<EOF>> {
    
    Logger::Error("Unclosed raw string literal at line " + std::to_string(buffer.GetStartLine()));

    rawStringInvalid = false;
    autoSemi = false;

    BEGIN(INITIAL);

    return LEXICAL_ERROR;
}

<RAW_STRING>[\200-\377] {
    
    Logger::Error("Invalid UTF-8 sequence at line " + std::to_string(yylineno));

    rawStringInvalid = true;
}

    /* ---------- Арифметические операторы ---------- */

"+"   { RETURN_TOKEN(PLUS, false); }
"-"   { RETURN_TOKEN(MINUS, false); }
"*"   { RETURN_TOKEN(MULTIPLY, false); }
"/"   { RETURN_TOKEN(DIVIDE, false); }
"%"   { RETURN_TOKEN(MODULO, false); }

    /* ---------- Побитовые операторы ---------- */

"&"   { RETURN_TOKEN(BIT_AND, false); }
"|"   { RETURN_TOKEN(BIT_OR, false); }
"^"   { RETURN_TOKEN(BIT_XOR, false); }
"&^"  { RETURN_TOKEN(BIT_CLEAR, false); }

    /* ---------- Операторы сдвига ---------- */

"<<"  { RETURN_TOKEN(LEFT_SHIFT, false); }
">>"  { RETURN_TOKEN(RIGHT_SHIFT, false); }

    /* ---------- Логические операторы ---------- */

"&&"  { RETURN_TOKEN(LOGICAL_AND, false); }
"||"  { RETURN_TOKEN(LOGICAL_OR, false); }
"!"   { RETURN_TOKEN(LOGICAL_NOT, false); }

    /* ---------- Операторы сравнения ---------- */

"=="  { RETURN_TOKEN(EQUAL, false); }
"!="  { RETURN_TOKEN(NOT_EQUAL, false); }
"<"   { RETURN_TOKEN(LESS, false); }
"<="  { RETURN_TOKEN(LESS_EQUAL, false); }
">"   { RETURN_TOKEN(GREATER, false); }
">="  { RETURN_TOKEN(GREATER_EQUAL, false); }

    /* ---------- Идентификаторы ---------- */

{IDENTIFIER} { RETURN_STRING(IDENTIFIER, string(yytext), true); }

    /* ---------- пробелы ---------- */
[ \t\r]+ {

}

    /* ---------- Перевод строки ---------- */
\n {
    if (autoSemi) {
        RETURN_TOKEN(
            SEMICOLON,
            false
        );
    }
}

    /* ---------- Однострочные комментарии ---------- */

\/\/.* {
    //Logger::Value("COMMENT", string(yytext));
}

    /* ---------- Многострочные комментарии ---------- */
"/*" {
    BEGIN(COMMENT);
    //Logger::Value("COMMENT", "/*");
}

<COMMENT>"*/" {
    BEGIN(INITIAL);
    //Logger::Value("COMMENT", "*/");
}

<COMMENT>[^*\n]+ {
    //Logger::Value("COMMENT", string(yytext));
}

<COMMENT>"*" {
    //Logger::Value("COMMENT", string(yytext));
}

<COMMENT>\n {
    if (autoSemi) {
        RETURN_TOKEN(
            SEMICOLON,
            false
        );
    }
}

<COMMENT><<EOF>> {
    
    Logger::Error("Unclosed multi-line comment on line " + std::to_string(yylineno));

    autoSemi = false;

    BEGIN(INITIAL);

    return LEXICAL_ERROR;
}

    /* ---------- Операторы присваивания ---------- */

"="   { RETURN_TOKEN(ASSIGN, false); }

"+="  { RETURN_TOKEN(PLUS_ASSIGN, false); }
"-="  { RETURN_TOKEN(MINUS_ASSIGN, false); }
"*="  { RETURN_TOKEN(MULTIPLY_ASSIGN, false); }
"/="  { RETURN_TOKEN(DIVIDE_ASSIGN, false); }
"%="  { RETURN_TOKEN(MODULO_ASSIGN, false); }

"&="  { RETURN_TOKEN(BIT_AND_ASSIGN, false); }
"|="  { RETURN_TOKEN(BIT_OR_ASSIGN, false); }
"^="  { RETURN_TOKEN(BIT_XOR_ASSIGN, false); }

"<<=" { RETURN_TOKEN(LEFT_SHIFT_ASSIGN, false); }
">>=" { RETURN_TOKEN(RIGHT_SHIFT_ASSIGN, false); }

"&^=" { RETURN_TOKEN(BIT_CLEAR_ASSIGN, false); }

    /* ---------- Короткое объявление ---------- */

":="  { RETURN_TOKEN(DECLARE_ASSIGN, false); }

    /* ---------- Инкремент / декремент ---------- */

"++"  { RETURN_TOKEN(INCREMENT, true); }
"--"  { RETURN_TOKEN(DECREMENT, true); }

    /* ---------- Оператор канала ---------- */

"<-"  { RETURN_TOKEN(CHANNEL_ARROW, false); }

    /* ---------- Скобки ---------- */

"(" { RETURN_TOKEN(LEFT_PAREN, false); }
")" { RETURN_TOKEN(RIGHT_PAREN, true); }

"[" { RETURN_TOKEN(LEFT_BRACKET, false); }
"]" { RETURN_TOKEN(RIGHT_BRACKET, true); }

"{" { RETURN_TOKEN(LEFT_BRACE, false); }
"}" { RETURN_TOKEN(RIGHT_BRACE, true); }

    /* ---------- Пунктуация ---------- */

","   { RETURN_TOKEN(COMMA, false); }
":"   { RETURN_TOKEN(COLON, false); }
"..." { RETURN_TOKEN(ELLIPSIS, false); }
"."   { RETURN_TOKEN(DOT, false); }

    /* ---------- Тильда ---------- */

"~"   { RETURN_TOKEN(TILDE, false); }

    /* ---------- Точка с запятой ---------- */

";"   { RETURN_TOKEN(SEMICOLON, false); }

    /* если файл закончился после токена, а мы должны были вставить ;, то вставляем */
<INITIAL><<EOF>> {

    if (autoSemi) {
        RETURN_TOKEN(
            SEMICOLON,
            false
        );
    }

    return 0;
}

    /* ---------- Отлавливаем все остальное как ошибку ---------- */

. {
    
    Logger::Error("Unknown symbol '" + string(yytext) + "' at line " + std::to_string(yylineno));

    autoSemi = false;

    return LEXICAL_ERROR;
}

%%

int main(int argc, char* argv[])
{
#ifdef _WIN32
    SetConsoleCP(CP_UTF8);
    SetConsoleOutputCP(CP_UTF8);
#endif

    if (argc > 1) {

        yyin = fopen(
            argv[1],
            "rb"
        );

        if (yyin == nullptr) {

            std::cerr
                << "Cannot open file: "
                << argv[1]
                << std::endl;

            return 1;
        }
    }

    int result = yyparse();

    if (argc > 1) {
        fclose(yyin);
    }

    return result;
}