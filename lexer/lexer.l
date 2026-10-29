%option noyywrap nodefault nounput noinput

%{

/* Flex records token spellings and source ranges. Rune tokens carry Unicode values. */

#include <string>
#include "LexerSupport.h"
#include "parser.tab.hpp"

using std::string;

/* флаг проверки на корректность строковых литералов */
bool stringInvalid = false;

bool rawStringInvalid = false;

/* Флаг автоматической вставки точки с запятой */
bool autoSemi = false;

static int InvalidToken() {
    autoSemi = false;
    return LEXICAL_ERROR;
}

#define YY_USER_ACTION LexerSupport::Advance(yytext, yyleng, yylloc);

#define RETURN_TOKEN(token, semi) \
    do { \
        autoSemi = (semi); \
        return LexerSupport::ClassifyToken(token); \
    } while (0)

// Text tokens preserve exact spelling, including large Go constants and escapes.
#define RETURN_TEXT(token) \
    do { \
        yylval.stringValue = LexerSupport::Text(yylloc); \
        autoSemi = true; \
        return token; \
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

/* ---------- Строковые литералы  ---------- */

STRING_ESCAPE       (\\[abfnrtv\\"]|{OCTAL_BYTE_ESCAPE}|{HEX_BYTE_ESCAPE}|{UNICODE_4_ESCAPE}|{UNICODE_8_ESCAPE})
ASCII_STRING_CHAR   [^\\\"\n\200-\377]
STRING_CHAR         ({ASCII_STRING_CHAR}|{UTF8_CHAR})

ASCII_RAW_STRING_CHAR   [^`\r\n\200-\377]
RAW_STRING_CHAR         ({ASCII_RAW_STRING_CHAR}|{UTF8_CHAR})

%%

    /* Flex rule-section comments must be indented. */

\xEF\xBB\xBF {
    if (yylloc.begin != 0) {
        LexerSupport::Error(yylloc, "BOM is only allowed at the start of a file");
        return LEXICAL_ERROR;
    }
}

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

{IMAGINARY_LITERAL} {RETURN_TEXT(IMAGINARY_LITERAL);}

    /* ---------- Литералы с плавающей точкой ---------- */

{HEX_FLOAT} { RETURN_TEXT(HEX_FLOAT_LITERAL); }

{DECIMAL_FLOAT} { RETURN_TEXT(FLOAT_LITERAL); }

    /* ---------- Целочисленные литералы ---------- */

{BINARY_LITERAL} { RETURN_TEXT(BINARY_LITERAL); }

{OCTAL_LITERAL} {RETURN_TEXT(OCTAL_LITERAL); }

{OLD_OCTAL_LITERAL} {RETURN_TEXT(OCTAL_LITERAL); }

{HEX_LITERAL} {RETURN_TEXT(HEX_LITERAL); }

{DECIMAL_LITERAL} { RETURN_TEXT(DECIMAL_LITERAL); }

    /* ---------- ошибки ------------- */

{BINARY_CANDIDATE} {

    LexerSupport::Error(yylloc, "Invalid binary literal '" + string(yytext) + "'");

    return InvalidToken();
}

{OCTAL_CANDIDATE} {

    LexerSupport::Error(yylloc, "Invalid octal literal '" + string(yytext) + "'");

    return InvalidToken();
}

{HEX_CANDIDATE} {

   LexerSupport::Error(yylloc, "Invalid hexadecimal literal '" + string(yytext) + "'");

    return InvalidToken();
}

{DECIMAL_CANDIDATE} {

   LexerSupport::Error(yylloc, "Invalid numeric literal '" + string(yytext) + "'");

    return InvalidToken();
}

    /* ---------- Символьные литералы ---------- */

{RUNE_LITERAL} {
    if (!LexerSupport::ValidRune(yytext)) {

        LexerSupport::Error(yylloc, "Invalid rune literal '" + string(yytext) + "'");

        return InvalidToken();
    }

    yylval.integerValue = LexerSupport::RuneValue(yytext);
    autoSemi = true;
    return RUNE_LITERAL;
}

\'[^'\n]*\' {

   LexerSupport::Error(yylloc, "Invalid rune literal '" + string(yytext) + "'");

    return InvalidToken();
}

\'[^'\n]* {

    LexerSupport::Error(yylloc, "Unclosed rune literal '" + string(yytext) + "'");

    return InvalidToken();
}

    /* ---------- Строковые литералы ---------- */

\" {
    LexerSupport::BeginLiteral(yylloc);
    stringInvalid = false;
    BEGIN(STRING);
}

<STRING>{STRING_CHAR}+ { /* Source spelling is retained. */ }

<STRING>{STRING_ESCAPE} {
    if (!LexerSupport::ValidUnicodeEscape(yytext)) {
        LexerSupport::Error(yylloc, "Invalid Unicode escape '" + string(yytext) + "'");
        stringInvalid = true;
    }
}

<STRING>\\. {
    LexerSupport::Error(yylloc, 
        "Invalid escape sequence '" + string(yytext) +
        "'"
    );

    stringInvalid = true;
}

<STRING>\\ {
    stringInvalid = true;

}

<STRING>\" {

    BEGIN(INITIAL);

    if (stringInvalid) {
        return InvalidToken();
    }

    LexerSupport::FinishLiteral(yylloc);
    RETURN_TEXT(STRING_LITERAL);

}

<STRING>\n {

    LexerSupport::FinishLiteral(yylloc);
    LexerSupport::Error(yylloc, "Unclosed string literal");

    stringInvalid = false;
    autoSemi = false;

    BEGIN(INITIAL);

    return LEXICAL_ERROR;
}

<STRING><<EOF>> {

    LexerSupport::FinishLiteral(yylloc);
    LexerSupport::Error(yylloc, "Unclosed string literal");

    stringInvalid = false;
    autoSemi = false;

    BEGIN(INITIAL);

    return LEXICAL_ERROR;
}

<STRING>[\200-\377] {

    LexerSupport::Error(yylloc, "Invalid UTF-8 sequence");

    stringInvalid = true;
}

    /* ---------- Необрабатываемые строковые литералы ---------- */

` {
    LexerSupport::BeginLiteral(yylloc);
    rawStringInvalid = false;
    BEGIN(RAW_STRING);
}

<RAW_STRING>{RAW_STRING_CHAR}+ { /* Source spelling is retained. */ }

<RAW_STRING>\n { /* Source spelling is retained. */ }

<RAW_STRING>\r {
    /* The token keeps the original source, including CR bytes. */
}

<RAW_STRING>` {

    BEGIN(INITIAL);

    if (rawStringInvalid) {
        return InvalidToken();
    }

    LexerSupport::FinishLiteral(yylloc);
    RETURN_TEXT(RAW_STRING_LITERAL);

}

<RAW_STRING><<EOF>> {

    LexerSupport::FinishLiteral(yylloc);
    LexerSupport::Error(yylloc, "Unclosed raw string literal");

    rawStringInvalid = false;
    autoSemi = false;

    BEGIN(INITIAL);

    return LEXICAL_ERROR;
}

<RAW_STRING>[\200-\377] {

    LexerSupport::Error(yylloc, "Invalid UTF-8 sequence");

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

{IDENTIFIER} {
    if (!LexerSupport::Identifier(yylloc)) return LEXICAL_ERROR;
    RETURN_TEXT(IDENTIFIER);
}

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

    LexerSupport::Error(yylloc, "Unclosed multi-line comment");

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
    LexerSupport::End(yylloc);

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

    LexerSupport::Error(yylloc, "Unknown symbol '" + string(yytext) + "'");

    return InvalidToken();
}

%%

void ResetLexer() {
    BEGIN(INITIAL);
    autoSemi = false;
    stringInvalid = rawStringInvalid = false;
}
