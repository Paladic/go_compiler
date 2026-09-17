%option noyywrap yylineno

%{

// глобальные переменные, бибилотеки, функции и т.д.

#include <string>
#include "extension/logger/logger.h"
#include "extension/buffer/Buffer.h"

using std::string;

Buffer buffer;

%}

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
    yylex();
    return 0;
}