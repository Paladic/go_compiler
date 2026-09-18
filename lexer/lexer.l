%option noyywrap yylineno

%{

// глобальные переменные, бибилотеки, функции и т.д.

#include <cstdio>
#include <iostream>
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

/* флаг проверки на корректность строковых литералов */
bool stringInvalid = false;

/* Флаг автоматической вставки точки с запятой */
bool autoSemi = false;

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
UTF8_3          [\340-\357]{UTF8_CONT}{UTF8_CONT}
UTF8_4          [\360-\364]{UTF8_CONT}{UTF8_CONT}{UTF8_CONT}

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

ASCII_RUNE_CHAR     [^\\'\n\r\200-\377]
RUNE_CHAR           ({ASCII_RUNE_CHAR}|{UTF8_CHAR})

RUNE_LITERAL        \'({RUNE_CHAR}|{RUNE_ESCAPE})\'


/* ---------- Стороковые литералы  ---------- */

STRING_ESCAPE       (\\[abfnrtv\\"]|{OCTAL_BYTE_ESCAPE}|{HEX_BYTE_ESCAPE}|{UNICODE_4_ESCAPE}|{UNICODE_8_ESCAPE})
STRING_CHAR         [^\\\"\n\r]

%%

    /* Комментари внутри этого блока пишутся вот в этом синтаксесе и обязательно перед комментаривем табуляцию */

    /* ---------- Ключевые слова ---------- */

"break" {
    Logger::Token("BREAK");
    autoSemi = true;
}

"default" {
    Logger::Token("DEFAULT");
    autoSemi = false;
}

"func" {
    Logger::Token("FUNC");
    autoSemi = false;
}

"interface" {
    Logger::Token("INTERFACE");
    autoSemi = false;
}

"select" {
    Logger::Token("SELECT");
    autoSemi = false;
}

"case" {
    Logger::Token("CASE");
    autoSemi = false;
}

"defer" {
    Logger::Token("DEFER");
    autoSemi = false;
}

"go" {
    Logger::Token("GO");
    autoSemi = false;
}

"map" {
    Logger::Token("MAP");
    autoSemi = false;
}

"struct" {
    Logger::Token("STRUCT");
    autoSemi = false;
}

"chan" {
    Logger::Token("CHAN");
    autoSemi = false;
}

"else" {
    Logger::Token("ELSE");
    autoSemi = false;
}

"goto" {
    Logger::Token("GOTO");
    autoSemi = false;
}

"package" {
    Logger::Token("PACKAGE");
    autoSemi = false;
}

"switch" {
    Logger::Token("SWITCH");
    autoSemi = false;
}

"const" {
    Logger::Token("CONST");
    autoSemi = false;
}

"fallthrough" {
    Logger::Token("FALLTHROUGH");
    autoSemi = true;
}

"if" {
    Logger::Token("IF");
    autoSemi = false;
}

"range" {
    Logger::Token("RANGE");
    autoSemi = false;
}

"type" {
    Logger::Token("TYPE");
    autoSemi = false;
}

"continue" {
    Logger::Token("CONTINUE");
    autoSemi = true;
}

"for" {
    Logger::Token("FOR");
    autoSemi = false;
}

"import" {
    Logger::Token("IMPORT");
    autoSemi = false;
}

"return" {
    Logger::Token("RETURN");
    autoSemi = true;
}

"var" {
    Logger::Token("VAR");
    autoSemi = false;
}

    /* ---------- Мнимые литералы ---------- */

{IMAGINARY_LITERAL} {
    Logger::Value(
        "IMAGINARY_LITERAL",
        Parser::Imaginary(yytext)
    );

    autoSemi = true;
}

    /* ---------- Литералы с плавающей точкой ---------- */

{HEX_FLOAT} {
    Logger::Value(
        "HEX_FLOAT_LITERAL",
        Parser::Float(yytext)
    );

    autoSemi = true;
}

{DECIMAL_FLOAT} {
    Logger::Value(
        "FLOAT_LITERAL",
        Parser::Float(yytext)
    );

    autoSemi = true;
}


    /* ---------- Целочисленные литералы ---------- */

{BINARY_LITERAL} {
    Logger::Value(
        "BINARY_LITERAL",
        Parser::Integer(yytext)
    );

    autoSemi = true;
}

{OCTAL_LITERAL} {
    Logger::Value(
        "OCTAL_LITERAL",
        Parser::Integer(yytext)
    );

    autoSemi = true;
}

{OLD_OCTAL_LITERAL} {
    Logger::Value(
        "OCTAL_LITERAL",
        Parser::Integer(yytext)
    );

    autoSemi = true;
}

{HEX_LITERAL} {
    Logger::Value(
        "HEX_LITERAL",
        Parser::Integer(yytext)
    );

    autoSemi = true;
}

{DECIMAL_LITERAL} {
    Logger::Value(
        "DECIMAL_LITERAL",
        Parser::Integer(yytext)
    );

    autoSemi = true;
}

    /* ---------- Символьные литералы ---------- */

{RUNE_LITERAL} {
    Logger::Value(
        "RUNE_LITERAL",
        Parser::Rune(yytext)
    );

    autoSemi = true;
}

\'[^'\n\r]*\' {
    Logger::Error(
        "Invalid rune literal '" + string(yytext) +
        "' at line " + std::to_string(yylineno)
    );

    autoSemi = false;
}

\'[^'\n\r]* {
    Logger::Error(
        "Unclosed rune literal '" + string(yytext) +
        "' at line " + std::to_string(yylineno)
    );

    autoSemi = false;
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

        autoSemi = true;
    }
    else {
        autoSemi = false;
    }

    BEGIN(INITIAL);
}

<STRING>\n {
    Logger::Error(
        "Unclosed string literal at line " +
        std::to_string(buffer.GetStartLine())
    );

    buffer.Reset(yylineno);
    autoSemi = false;

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

    autoSemi = true;

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
    autoSemi = false;
}

"-" {
    Logger::Token("MINUS");
    autoSemi = false;
}

"*" {
    Logger::Token("MULTIPLY");
    autoSemi = false;
}

"/" {
    Logger::Token("DIVIDE");
    autoSemi = false;
}

"%" {
    Logger::Token("MODULO");
    autoSemi = false;
}

    /* ---------- Побитовые операторы ---------- */

"&" {
    Logger::Token("BIT_AND");
    autoSemi = false;
}

"|" {
    Logger::Token("BIT_OR");
    autoSemi = false;
}

"^" {
    Logger::Token("BIT_XOR");
    autoSemi = false;
}

"&^" {
    Logger::Token("BIT_CLEAR");
    autoSemi = false;
}

    /* ---------- Операторы сдвига ---------- */

"<<" {
    Logger::Token("LEFT_SHIFT");
    autoSemi = false;
}

">>" {
    Logger::Token("RIGHT_SHIFT");
    autoSemi = false;
}

    /* ---------- Логические операторы ---------- */

"&&" {
    Logger::Token("LOGICAL_AND");
    autoSemi = false;
}

"||" {
    Logger::Token("LOGICAL_OR");
    autoSemi = false;
}

"!" {
    Logger::Token("LOGICAL_NOT");
    autoSemi = false;
}

    /* ---------- Операторы сравнения ---------- */

"==" {
    Logger::Token("EQUAL");
    autoSemi = false;
}

"!=" {
    Logger::Token("NOT_EQUAL");
    autoSemi = false;
}

"<" {
    Logger::Token("LESS");
    autoSemi = false;
}

"<=" {
    Logger::Token("LESS_EQUAL");
    autoSemi = false;
}

">" {
    Logger::Token("GREATER");
    autoSemi = false;
}

">=" {
    Logger::Token("GREATER_EQUAL");
    autoSemi = false;
}

    /* ---------- Идентификаторы ---------- */

{IDENTIFIER} {
    Logger::Value(
        "IDENTIFIER",
        string(yytext)
    );

    autoSemi = true;
}


    /* ---------- пробелы ---------- */
[ \t\r]+ {

}

    /* ---------- Перевод строки ---------- */
\n {
    if (autoSemi) {
        Logger::Value("PUNCTUATION", ";");
        autoSemi = false;
    }
}

    /* ---------- Однострочные комментарии ---------- */

\/\/.* {
    Logger::Value("COMMENT", string(yytext));
}

    /* ---------- Многострочные комментарии ---------- */
"/*" {
    BEGIN(COMMENT);
    Logger::Value("COMMENT", "/*");
}

<COMMENT>"*/" {
    BEGIN(INITIAL);
    Logger::Value("COMMENT", "*/");
}

<COMMENT>[^*\n]+ {
    Logger::Value("COMMENT", string(yytext));
}

<COMMENT>"*" {
    Logger::Value("COMMENT", string(yytext));
}

<COMMENT>\n {
}

<COMMENT><<EOF>> {
    Logger::Error(
        "Unclosed multi-line comment on line " +
        std::to_string(yylineno)
    );

    yyterminate();
}

    /* ---------- Операторы присваивания ---------- */

"=" {
    Logger::Value("OPERATOR", "=");
    autoSemi = false;
}

"+=" {
    Logger::Value("OPERATOR", "+=");
    autoSemi = false;
}

"-=" {
    Logger::Value("OPERATOR", "-=");
    autoSemi = false;
}

"*=" {
    Logger::Value("OPERATOR", "*=");
    autoSemi = false;
}

"/=" {
    Logger::Value("OPERATOR", "/=");
    autoSemi = false;
}

"%=" {
    Logger::Value("OPERATOR", "%=");
    autoSemi = false;
}

"&=" {
    Logger::Value("OPERATOR", "&=");
    autoSemi = false;
}

"|=" {
    Logger::Value("OPERATOR", "|=");
    autoSemi = false;
}

"^=" {
    Logger::Value("OPERATOR", "^=");
    autoSemi = false;
}

"<<=" {
    Logger::Value("OPERATOR", "<<=");
    autoSemi = false;
}

">>=" {
    Logger::Value("OPERATOR", ">>=");
    autoSemi = false;
}

"&^=" {
    Logger::Value("OPERATOR", "&^=");
    autoSemi = false;
}

    /* ---------- Короткое объявление ---------- */

":=" {
    Logger::Value("OPERATOR", ":=");
    autoSemi = false;
}


    /* ---------- Инкремент / декремент ---------- */

"++" {
    Logger::Value("OPERATOR", "++");
    autoSemi = true;
}

"--" {
    Logger::Value("OPERATOR", "--");
    autoSemi = true;
}

    /* ---------- Оператор канала ---------- */

"<-" {
    Logger::Value("OPERATOR", "<-");
    autoSemi = false;
}

    /* ---------- Скобки ---------- */

"(" {
    Logger::Value("PUNCTUATION", "(");
    autoSemi = false;
}

")" {
    Logger::Value("PUNCTUATION", ")");
    autoSemi = true;
}

"[" {
    Logger::Value("PUNCTUATION", "[");
    autoSemi = false;
}

"]" {
    Logger::Value("PUNCTUATION", "]");
    autoSemi = true;
}

"{" {
    Logger::Value("PUNCTUATION", "{");
    autoSemi = false;
}

"}" {
    Logger::Value("PUNCTUATION", "}");
    autoSemi = true;
}


    /* ---------- Пунктуация ---------- */

"," {
    Logger::Value("PUNCTUATION", ",");
    autoSemi = false;
}

":" {
    Logger::Value("PUNCTUATION", ":");
    autoSemi = false;
}

"." {
    Logger::Value("PUNCTUATION", ".");
    autoSemi = false;
}

"..." {
    Logger::Value("PUNCTUATION", "...");
    autoSemi = false;
}

    /* ---------- Тильда ---------- */

"~" {
    Logger::Value("OPERATOR", "~");
    autoSemi = false;
}

    /* ---------- Точка с запятой ---------- */
";" {
    Logger::Value("PUNCTUATION", ";");
    autoSemi = false;
}

    /* если файл закончился после токена, а мы должны были вставить ;, то вставляем */
<<EOF>> {
    if (autoSemi) {
        Logger::Value("PUNCTUATION", ";");
        autoSemi = false;
    }

    yyterminate();
}

    /* ---------- Отлавливаем все остальное как ошибку ---------- */
. {
    Logger::Error(
        "Unknown symbol '" + string(yytext) +
        "' at line " + std::to_string(yylineno)
    );
}

%%

int main(int argc, char* argv[])
{
#ifdef _WIN32
    SetConsoleCP(CP_UTF8);
    SetConsoleOutputCP(CP_UTF8);
#endif

    if (argc > 1) {
        yyin = fopen(argv[1], "rb");

        if (yyin == nullptr) {
            std::cerr
                << "Cannot open file: "
                << argv[1]
                << std::endl;

            return 1;
        }
    }

    yylex();

    if (argc > 1) {
        fclose(yyin);
    }

    return 0;
}