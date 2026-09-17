%option noyywrap yylineno

%{

// глобальные переменные, бибилотеки, функции и т.д.

#include <string>
#include "extension/logger/logger.h"
#include "extension/buffer/Buffer.h"

using std::string;

Buffer buffer;

/* Флаг автоматической вставки точки с запятой */
bool auto_semi = false;

%}

/* Состояние для многострочных комментариев */
%x COMMENT

/* ---------- Идентификаторы ---------- */

LETTER          [A-Za-z_]
DIGIT           [0-9]
IDENTIFIER      {LETTER}({LETTER}|{DIGIT})*


%%

    /* Комментари внутри этого блока пишутся вот в этом синтаксесе и обязательно перед комментаривем табуляцию */

    /* ---------- Ключевые слова ---------- */

"break" {
    Logger::Token("BREAK"); auto_semi = true;
}

"default" {
    Logger::Token("DEFAULT"); auto_semi = false;
}

"func" {
    Logger::Token("FUNC"); auto_semi = false;
}

"interface" {
    Logger::Token("INTERFACE"); auto_semi = false;
}

"select" {
    Logger::Token("SELECT"); auto_semi = false;
}

"case" {
    Logger::Token("CASE"); auto_semi = false;
}

"defer" {
    Logger::Token("DEFER"); auto_semi = false;
}

"go" {
    Logger::Token("GO"); auto_semi = false;
}

"map" {
    Logger::Token("MAP"); auto_semi = false;
}

"struct" {
    Logger::Token("STRUCT"); auto_semi = false;
}

"chan" {
    Logger::Token("CHAN"); auto_semi = false;
}

"else" {
    Logger::Token("ELSE"); auto_semi = false;
}

"goto" {
    Logger::Token("GOTO"); auto_semi = false;
}

"package" {
    Logger::Token("PACKAGE"); auto_semi = false;
}

"switch" {
    Logger::Token("SWITCH"); auto_semi = false;
}

"const" {
    Logger::Token("CONST"); auto_semi = false;
}

"fallthrough" {
    Logger::Token("FALLTHROUGH"); auto_semi = true;
}

"if" {
    Logger::Token("IF"); auto_semi = false;
}

"range" {
    Logger::Token("RANGE"); auto_semi = false;
}

"type" {
    Logger::Token("TYPE"); auto_semi = false;
}

"continue" {
    Logger::Token("CONTINUE"); auto_semi = true;
}

"for" {
    Logger::Token("FOR"); auto_semi = false;
}

"import" {
    Logger::Token("IMPORT"); auto_semi = false;
}

"return" {
    Logger::Token("RETURN"); auto_semi = true;
}

"var" {
    Logger::Token("VAR"); auto_semi = false;
}

    /* ---------- Идентификаторы ---------- */

{IDENTIFIER} {
    Logger::Value("IDENTIFIER", string(yytext)); auto_semi = true;
}



    /* ---------- пробелы ---------- */
[ \t\r]+ {

}

    /* ---------- Перевод строки ---------- */
\n {
    if (auto_semi) {
        Logger::Value("PUNCTUATION", ";");
        auto_semi = false;
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
    if (auto_semi){
    Logger::Value("PUNCTUATION", ";");
    auto_semi = false;
    }
}

<COMMENT><<EOF>> {
    Logger::Error(
        "Незакрытый многострочный комментарий на строке " + std::to_string(yylineno)
    );
    return 0;
}

    /* ---------- Операторы присваивания ---------- */
"=" { 
    Logger::Value("OPERATOR", "="); auto_semi = false;
}

"+=" { 
    Logger::Value("OPERATOR", "+="); auto_semi = false;
}

"-=" { 
    Logger::Value("OPERATOR", "-="); auto_semi = false;
}

"*=" { 
    Logger::Value("OPERATOR", "*="); auto_semi = false;
}

"/=" { 
    Logger::Value("OPERATOR", "/="); auto_semi = false;
}

"%=" { 
    Logger::Value("OPERATOR", "%="); auto_semi = false;
}

"&=" { 
    Logger::Value("OPERATOR", "&="); auto_semi = false;
}

"^=" { 
    Logger::Value("OPERATOR", "^="); auto_semi = false;
}

"<<=" { 
    Logger::Value("OPERATOR", "<<="); auto_semi = false;
}

">>=" { 
    Logger::Value("OPERATOR", ">>="); auto_semi = false;
}

"&^=" { 
    Logger::Value("OPERATOR", "&^="); auto_semi = false;
}

    /* ---------- Короткое объявление ---------- */
":=" { 
    Logger::Value("OPERATOR", ":="); auto_semi = false;
}

    /* ---------- Инкремент/декремент ---------- */
"++" { 
    Logger::Value("OPERATOR", "++"); auto_semi = true;
}

"--" { 
    Logger::Value("OPERATOR", "--"); auto_semi = true;
}

    /* ---------- Оператор канала ---------- */
"<-" { 
    Logger::Value("OPERATOR", "<-"); auto_semi = false;
}

    /* ---------- Скобки ---------- */
"(" { Logger::Value("PUNCTUATION", "("); auto_semi = false; }
")" { Logger::Value("PUNCTUATION", ")"); auto_semi = true; }
"[" { Logger::Value("PUNCTUATION", "["); auto_semi = false; }
"]" { Logger::Value("PUNCTUATION", "]"); auto_semi = true; }
"{" { Logger::Value("PUNCTUATION", "{"); auto_semi = false; }
"}" { Logger::Value("PUNCTUATION", "}"); auto_semi = true; }

    /* ---------- Пунктуация ---------- */
"," { 
    Logger::Value("PUNCTUATION", ","); auto_semi = false; 
}

":" { 
    Logger::Value("PUNCTUATION", ":"); auto_semi = false; 
}

"." { 
    Logger::Value("PUNCTUATION", "."); auto_semi = false; 
}

"..." { 
    Logger::Value("PUNCTUATION", "..."); auto_semi = false; 
}

    /* ---------- Тильда ---------- */
"~" { 
    Logger::Value("OPERATOR", "~"); auto_semi = false;
}

    /* ---------- Точка с запятой ---------- */
";" {
    Logger::Value("PUNCTUATION", ";"); auto_semi = false;
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