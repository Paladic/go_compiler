%option noyywrap yylineno

%{

// глобальные переменные, бибилотеки, функции и т.д.

#include <string>
#include "extension/logger/logger.h"
#include "extension/buffer/Buffer.h"

using std::string;

Buffer buffer;

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
    Logger::Value("PUNCTUATION", ";");

}

    /* ---------- Операторы присваивания ---------- */
"="|"+="|"-="|"*="|"/="|"%="|"\&="|"\^="|"<<="|">>="|"\&^=" { 
    Logger::Value("OPERATOR", string(yytext));  
}

    /* ---------- Короткое объявление ---------- */
":=" { 
    Logger::Value("OPERATOR", ":="); 
}

    /* ---------- Инкремент/декремент ---------- */
"++"|"--" { 
    Logger::Value("PUNCTUATION", string(yytext)); 
}

    /* ---------- Оператор канала ---------- */
"<-" { 
    Logger::Value("OPERATOR", "<-"); 
}

    /* ---------- Скобки ---------- */
"(" { Logger::Value("PUNCTUATION", "("); }
")" { Logger::Value("PUNCTUATION", ")"); }
"[" { Logger::Value("PUNCTUATION", "["); }
"]" { Logger::Value("PUNCTUATION", "]"); }
"{" { Logger::Value("PUNCTUATION", "{"); }
"}" { Logger::Value("PUNCTUATION", "}"); }

    /* ---------- Пунктуация ---------- */
","|":"|"."|"..." { 
    Logger::Value("PUNCTUATION", string(yytext)); 
}

    /* ---------- Тильда ---------- */
"~" { 
    Logger::Value("OPERATOR", "~"); 
}

    /* ---------- Точка с запятой ---------- */
";" {
    Logger::Value("PUNCTUATION", ";");
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