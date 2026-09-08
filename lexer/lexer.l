%option noyywrap

%{

#include <stdio.h>

%}

%%

.   { printf("TEXT: %s\n", yytext); }

%%

int main(void)
{
    yylex();
    return 0;
}