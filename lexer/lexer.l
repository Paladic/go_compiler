%option noyywrap yylineno

%{

// глобальные переменные, бибилотеки, функции и т.д.

#include <string>
#include "extension/logger/logger.h"
#include "extension/Parser/Parser.h"
#include "extension/buffer/Buffer.h"
#ifdef _WIN32
#include <windows.h>
#endif

using std::string;

/* буфер где будем хранить текст для строковых литералов */
Buffer buffer;

%}

/* состояние для строк */
%x STRING

/* состояние для строк которые не обрабатываются */
%x RAW_STRING

/* ---------- Идентификаторы ---------- */

LETTER          [A-Za-z_]
DIGIT           [0-9]
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

/* ---------- Литералы с плавающей точкой ---------- */

DECIMAL_EXPONENT    [eE][+-]?{DECIMAL_DIGITS}
BINARY_EXPONENT     [pP][+-]?{DECIMAL_DIGITS}

DECIMAL_FLOAT       ({DECIMAL_DIGITS}"."{DECIMAL_DIGITS}?{DECIMAL_EXPONENT}?)|({DECIMAL_DIGITS}{DECIMAL_EXPONENT})|("."{DECIMAL_DIGITS}{DECIMAL_EXPONENT}?)

HEX_MANTISSA        (({HEX_DIGITS}"."{HEX_DIGITS}?)|({HEX_DIGITS})|("."{HEX_DIGITS}))
HEX_FLOAT           0[xX]_?{HEX_MANTISSA}{BINARY_EXPONENT}

/* ---------- Мнимые литералы ---------- */

IMAGINARY_LITERAL   ({DECIMAL_LITERAL}|{BINARY_LITERAL}|{OCTAL_LITERAL}|{OLD_OCTAL_LITERAL}|{HEX_LITERAL}|{DECIMAL_FLOAT}|{HEX_FLOAT})i

/* ---------- Символьные литералы  ---------- */

OCTAL_BYTE_ESCAPE   \\[0-7]{3}
HEX_BYTE_ESCAPE     \\x[0-9a-fA-F]{2}
UNICODE_4_ESCAPE    \\u[0-9a-fA-F]{4}
UNICODE_8_ESCAPE    \\U[0-9a-fA-F]{8}

RUNE_ESCAPE         (\\[abfnrtv\\']|{OCTAL_BYTE_ESCAPE}|{HEX_BYTE_ESCAPE}|{UNICODE_4_ESCAPE}|{UNICODE_8_ESCAPE})
RUNE_CHAR           [^\\'\n\r]

RUNE_LITERAL        \'({RUNE_CHAR}|{RUNE_ESCAPE})\'

/* ---------- Стороковые литералы  ---------- */

STRING_ESCAPE       (\\[abfnrtv\\"]|{OCTAL_BYTE_ESCAPE}|{HEX_BYTE_ESCAPE}|{UNICODE_4_ESCAPE}|{UNICODE_8_ESCAPE})
STRING_CHAR         [^\\\"\n\r]

%%

    /* Комментари внутри этого блока пишутся вот в этом синтаксесе и обязательно перед комментаривем табуляцию */

    /* ---------- Ключевые слова ---------- */

"break" {
    Logger::Token("BREAK");
}

"default" {
    Logger::Token("DEFAULT");
}

"func" {
    Logger::Token("FUNC");
}

"interface" {
    Logger::Token("INTERFACE");
}

"select" {
    Logger::Token("SELECT");
}

"case" {
    Logger::Token("CASE");
}

"defer" {
    Logger::Token("DEFER");
}

"go" {
    Logger::Token("GO");
}

"map" {
    Logger::Token("MAP");
}

"struct" {
    Logger::Token("STRUCT");
}

"chan" {
    Logger::Token("CHAN");
}

"else" {
    Logger::Token("ELSE");
}

"goto" {
    Logger::Token("GOTO");
}

"package" {
    Logger::Token("PACKAGE");
}

"switch" {
    Logger::Token("SWITCH");
}

"const" {
    Logger::Token("CONST");
}

"fallthrough" {
    Logger::Token("FALLTHROUGH");
}

"if" {
    Logger::Token("IF");
}

"range" {
    Logger::Token("RANGE");
}

"type" {
    Logger::Token("TYPE");
}

"continue" {
    Logger::Token("CONTINUE");
}

"for" {
    Logger::Token("FOR");
}

"import" {
    Logger::Token("IMPORT");
}

"return" {
    Logger::Token("RETURN");
}

"var" {
    Logger::Token("VAR");
}

    /* ---------- Мнимые литералы ---------- */

{IMAGINARY_LITERAL} {
    Logger::Value(
        "IMAGINARY_LITERAL",
        Parser::Imaginary(yytext)
    );
}

    /* ---------- Литералы с плавающей точкой ---------- */

{HEX_FLOAT} {
    Logger::Value(
        "HEX_FLOAT_LITERAL",
        Parser::Float(yytext)
    );
}

{DECIMAL_FLOAT} {
    Logger::Value(
        "FLOAT_LITERAL",
        Parser::Float(yytext)
    );
}


    /* ---------- Целочисленные литералы ---------- */

{BINARY_LITERAL} {
    Logger::Value(
        "BINARY_LITERAL",
        Parser::Integer(yytext)
    );
}

{OCTAL_LITERAL} {
    Logger::Value(
        "OCTAL_LITERAL",
        Parser::Integer(yytext)
    );
}

{OLD_OCTAL_LITERAL} {
    Logger::Value(
        "OCTAL_LITERAL",
        Parser::Integer(yytext)
    );
}

{HEX_LITERAL} {
    Logger::Value(
        "HEX_LITERAL",
        Parser::Integer(yytext)
    );
}

{DECIMAL_LITERAL} {
    Logger::Value(
        "DECIMAL_LITERAL",
        Parser::Integer(yytext)
    );
    /* ---------- Символьные литералы ---------- */

{RUNE_LITERAL} {
    Logger::Value(
        "RUNE_LITERAL",
        Parser::Rune(yytext)
    );

}

\'[^'\n\r]*\' {
    Logger::Error(
        "Invalid rune literal '" + string(yytext) +
        "' at line " + std::to_string(yylineno)
    );

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
    buffer.Append(Parser::EscapeToString(yytext));
}

<STRING>\\. {
    Logger::Error(
        "Invalid escape sequence '" + string(yytext) +
        "' at line " + std::to_string(yylineno)
    );

    stringInvalid = true;
}

<STRING>\" {
   
   if (!stringInvalid) {
        Logger::Value(
            "STRING_LITERAL",
            buffer.Get()
        );

    }
    else {
    }

    BEGIN(INITIAL);
}

<STRING>\n {
    Logger::Error(
        "Unclosed string literal at line " +
        std::to_string(buffer.GetStartLine())
    );

    buffer.Reset(yylineno);

    BEGIN(INITIAL);
}

<STRING><<EOF>> {
    Logger::Error(
        "Unclosed string literal at line " +
        std::to_string(buffer.GetStartLine())
    );

    yyterminate();
}

    /* ---------- Необработавыаемые строковые литералы ---------- */

` {
    buffer.Reset(yylineno);
    BEGIN(RAW_STRING);
}

<RAW_STRING>[^`\r\n]+ {
    buffer.Append(yytext);
}

<RAW_STRING>\n {
    buffer.Append("\n");
}

<RAW_STRING>\r {
    /* удаляется из необратавыемых строк */
}

<RAW_STRING>` {
    Logger::Value(
        "RAW_STRING_LITERAL",
        buffer.Get()
    );


    BEGIN(INITIAL);
}


<RAW_STRING><<EOF>> {
    Logger::Error(
        "Unclosed raw string literal at line " +
        std::to_string(buffer.GetStartLine())
    );

    yyterminate();
}

    /* ---------- Арифметические операторы ---------- */

"+" {
    Logger::Token("PLUS");
}

"-" {
    Logger::Token("MINUS");
}

"*" {
    Logger::Token("MULTIPLY");
}

"/" {
    Logger::Token("DIVIDE");
}

"%" {
    Logger::Token("MODULO");
}

    /* ---------- Побитовые операторы ---------- */

"&" {
    Logger::Token("BIT_AND");
}

"|" {
    Logger::Token("BIT_OR");
}

"^" {
    Logger::Token("BIT_XOR");
}

"&^" {
    Logger::Token("BIT_CLEAR");
}

    /* ---------- Операторы сдвига ---------- */

"<<" {
    Logger::Token("LEFT_SHIFT");
}

">>" {
    Logger::Token("RIGHT_SHIFT");
}

    /* ---------- Логические операторы ---------- */

"&&" {
    Logger::Token("LOGICAL_AND");
}

"||" {
    Logger::Token("LOGICAL_OR");
}

"!" {
    Logger::Token("LOGICAL_NOT");
}

    /* ---------- Операторы сравнения ---------- */

"==" {
    Logger::Token("EQUAL");
}

"!=" {
    Logger::Token("NOT_EQUAL");
}

"<" {
    Logger::Token("LESS");
}

"<=" {
    Logger::Token("LESS_EQUAL");
}

">" {
    Logger::Token("GREATER");
}

">=" {
    Logger::Token("GREATER_EQUAL");
}



    /* ---------- Идентификаторы ---------- */

{IDENTIFIER} {
    Logger::Value("IDENTIFIER", string(yytext));
}


    /* ---------- пробелы ---------- */
[ \t\r]+ {

}

    /* ---------- Перевод строки ---------- */
\n {

}

    /* ---------- Отлавливаем все остальное как ошибку ---------- */
. {
    Logger::Error(
        "Unknown symbol '" + string(yytext) +
        "' at line " + std::to_string(yylineno)
    );
}

%%

int main(void)
{

#ifdef _WIN32
    SetConsoleOutputCP(CP_UTF8);
#endif

    yylex();
    return 0;
}