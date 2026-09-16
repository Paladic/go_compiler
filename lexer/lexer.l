%option noyywrap yylineno

%{

// глобальные переменные, бибилотеки, функции и т.д.

#include <string>
#include "extension/logger/logger.h"
#include "extension/buffer/Buffer.h"

using std::string;

Buffer buffer;

%}

%%

    /* Комментари внутри этого блока пишутся вот в этом синтаксесе и обязательно перед комментаривем табуляцию */



    /* пробелы */
[ \t\r]+ {

}

    /* Перевод строки */
\n {

}

    /* Отлавливаем все остальное как ошибку */
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