/* Объявления, которые нужны и парсеру, и сгенерированному заголовку. */
%code requires {
    #include "SourceRange.h"
    #include <string>
    // Координаты хранятся в тривиальном типе SourceRange.
    #define YYLTYPE_IS_TRIVIAL 1
    #define YYLLOC_DEFAULT(Current, Rhs, N) \
        MergeSourceRange(Current, YYRHSLOC(Rhs, (N) ? 1 : 0), \
                         YYRHSLOC(Rhs, N), YYRHSLOC(Rhs, 0), N)
}

/* Настройки Bison */
%define lr.type lalr
%expect 0
%locations
%define parse.trace
%define parse.error detailed
%define api.location.type {SourceRange}

%code top {
    // Разрешаем глубокую вложенность при разборе.
    #define YYMAXDEPTH 1000000
}

%code {
    #include "LexerSupport.h"

    int yylex();
    void yyerror(const char* message);
}

/* Значения токенов */
%union {
    long long integerValue;
    const std::string* stringValue;
}

/* Литералы и идентификаторы */
%token <stringValue> DECIMAL_LITERAL
%token <stringValue> BINARY_LITERAL
%token <stringValue> OCTAL_LITERAL
%token <stringValue> HEX_LITERAL
%token <integerValue> RUNE_LITERAL

%token <stringValue> FLOAT_LITERAL
%token <stringValue> HEX_FLOAT_LITERAL
%token <stringValue> IMAGINARY_LITERAL

%token <stringValue> IDENTIFIER
%token <stringValue> STRING_LITERAL
%token <stringValue> RAW_STRING_LITERAL

/* Ключевые слова */
%token KW_BREAK
%token KW_DEFAULT
%token KW_FUNC
%token KW_INTERFACE
%token KW_SELECT

%token KW_CASE
%token KW_DEFER
%token KW_GO
%token KW_MAP
%token KW_STRUCT

%token KW_CHAN
%token KW_ELSE
%token KW_GOTO
%token KW_PACKAGE
%token KW_SWITCH

%token KW_CONST
%token KW_FALLTHROUGH
%token KW_IF
%token KW_RANGE
%token KW_TYPE

%token KW_CONTINUE
%token KW_FOR
%token KW_IMPORT
%token KW_RETURN
%token KW_VAR

/* Операторы */
%token PLUS "+"
%token MINUS "-"
%token MULTIPLY "*"
%token DIVIDE "/"
%token MODULO "%"

%token BIT_AND "&"
%token BIT_OR "|"
%token BIT_XOR "^"
%token BIT_CLEAR "&^"

%token LEFT_SHIFT "<<"
%token RIGHT_SHIFT ">>"

%token LOGICAL_AND "&&"
%token LOGICAL_OR "||"
%token LOGICAL_NOT "!"

%token EQUAL "=="
%token NOT_EQUAL "!="

%token LESS "<"
%token LESS_EQUAL "<="

%token GREATER ">"
%token GREATER_EQUAL ">="

%token ASSIGN "="

%token PLUS_ASSIGN "+="
%token MINUS_ASSIGN "-="
%token MULTIPLY_ASSIGN "*="
%token DIVIDE_ASSIGN "/="
%token MODULO_ASSIGN "%="

%token BIT_AND_ASSIGN "&="
%token BIT_OR_ASSIGN "|="
%token BIT_XOR_ASSIGN "^="
%token BIT_CLEAR_ASSIGN "&^="

%token LEFT_SHIFT_ASSIGN "<<="
%token RIGHT_SHIFT_ASSIGN ">>="

%token DECLARE_ASSIGN ":="

%token INCREMENT "++"
%token DECREMENT "--"

%token CHANNEL_ARROW "<-"

%token TILDE "~"

/* Скобки и разделители */
%token LEFT_PAREN "("
%token RIGHT_PAREN ")"

%token LEFT_BRACKET "["
%token RIGHT_BRACKET "]"

%token LEFT_BRACE "{"
%token RIGHT_BRACE "}"

%token COMMA ","
%token COLON ":"
%token DOT "."
%token ELLIPSIS "..."
%token SEMICOLON ";"

/* Служебные токены лексера */
%token BODY_BRACE "body {"

%token LEXICAL_ERROR

/* Приоритеты операторов и разрешение неоднозначностей.
   Порядок объявлений важен для таблицы LALR. */
%precedence NAME_END EMPTY_SIGNATURE CHAN_BARE
%precedence LEFT_PAREN
%precedence ARRAY_CALL

%left LOGICAL_OR
%left LOGICAL_AND

%left EQUAL NOT_EQUAL LESS LESS_EQUAL GREATER GREATER_EQUAL

%left PLUS MINUS BIT_OR BIT_XOR

%left MULTIPLY DIVIDE MODULO LEFT_SHIFT RIGHT_SHIFT BIT_AND BIT_CLEAR

%precedence IDENTIFIER KW_FUNC KW_INTERFACE KW_MAP KW_STRUCT KW_CHAN LEFT_BRACKET DOT COMMA
%precedence CHANNEL_ARROW

/* Начальный символ */
%start start

%%

/* Структура файла */

start:
      program
    ;

program:
      package_clause ";" imports declarations
    ;

package_clause:
      KW_PACKAGE identifier
    ;

/* Импорты */

imports:
      %empty
    | imports import_declaration ";"
    ;

import_declaration:
      KW_IMPORT import_spec
    | KW_IMPORT "(" import_spec_list ")"
    ;

import_spec_list:
      %empty
    | import_spec ";" import_spec_list
    | import_spec
    ;

import_spec:
      import_path
    | "." import_path
    | identifier import_path
    ;

import_path:
      STRING_LITERAL {}
    | RAW_STRING_LITERAL {}
    ;

/* Объявления верхнего уровня */

declarations:
      %empty
    | declarations top_level_declaration ";"
    ;

top_level_declaration:
      declaration
    | function_declaration
    | method_declaration
    ;

declaration:
      variable_declaration
    | constant_declaration
    | type_declaration
    ;

/* Переменные и константы */

variable_declaration:
      KW_VAR variable_spec
    | KW_VAR "(" variable_spec_list ")"
    ;

variable_spec_list:
      %empty
    | variable_spec ";" variable_spec_list
    | variable_spec
    ;

variable_spec:
      identifier_list type
    | identifier_list type "=" expression_list
    | identifier_list "=" expression_list
    ;

constant_declaration:
      KW_CONST initialized_constant_spec
    | KW_CONST "(" constant_spec_list ")"
    ;

/* В группе const следующие строки могут наследовать тип и значение. */
constant_spec_list:
      %empty
    | initialized_constant_spec constant_spec_list_tail
    ;

constant_spec_list_tail:
      %empty
    | ";"
    | ";" constant_spec constant_spec_list_tail
    ;

constant_spec:
      initialized_constant_spec
    | identifier_list
    ;

initialized_constant_spec:
      identifier_list type "=" expression_list
    | identifier_list "=" expression_list
    ;

/* Объявления типов */

type_declaration:
      KW_TYPE type_spec
    | KW_TYPE "(" type_spec_list ")"
    ;

type_spec_list:
      %empty
    | type_spec ";" type_spec_list
    | type_spec
    ;

type_spec:
      identifier type
    | identifier "=" type
    | identifier type_parameters type
    | identifier type_parameters "=" type
    | identifier bracket_group "=" type
    ;

/* Типы */

type:
      type_name
    | pointer_type
    | array_type
    | map_type
    | struct_type
    | interface_type
    | function_type
    | channel_type
    | "(" type ")"
    ;

type_name:
      identifier %prec NAME_END
    | identifier "." identifier
    | identifier type_arguments
    | identifier "." identifier type_arguments
    ;

non_name_type:
      array_type
    | map_type
    | struct_type
    | interface_type
    | function_type
    | channel_type
    ;

/* Формы типов, которые не могут быть обычным выражением. */
non_expression_type:
      non_name_type
    | "*" non_expression_type
    | "(" non_expression_type ")"
    ;

/* Параметры типов и ограничения */

type_arguments:
      bracket_group
    ;

type_parameters:
      "[" type_parameter_list "]"
    ;

type_parameter_list:
      identifier type_parameter_after_name
    ;

type_parameter_after_name:
      type_constraint type_parameter_after_constraint
    | "," type_parameter_list
    ;

type_parameter_after_constraint:
      %empty
    | ","
    | "," type_parameter_list
    ;

type_constraint:
      type_terms
    ;

type_terms:
      type_term
    | type_terms "|" type_term
    ;

type_term:
      type
    | "~" type
    ;

/* Составные типы */

array_type:
      bracket_group type
    ;

pointer_type:
      "*" type
    ;

map_type:
      KW_MAP "[" type "]" type
    ;

/* Структуры и интерфейсы */

struct_type:
      KW_STRUCT block_open field_declarations "}"
    ;

field_declarations:
      %empty
    | field_declaration ";" field_declarations
    | field_declaration
    ;

field_declaration:
      identifier array_type optional_struct_tag
    | identifier_list type optional_struct_tag
    | embedded_field optional_struct_tag
    ;

embedded_field:
      type_name
    | "*" type_name
    ;

optional_struct_tag:
      %empty
    | STRING_LITERAL {}
    | RAW_STRING_LITERAL {}
    ;

interface_type:
      KW_INTERFACE "{" interface_elements "}"
    ;

interface_elements:
      %empty
    | interface_element ";" interface_elements
    | interface_element
    ;

interface_element:
      identifier function_signature
    | type_terms
    ;

/* Функции, методы и каналы */

function_type:
      KW_FUNC function_signature
    ;

channel_type:
      chan_prefix type
    | "<-" KW_CHAN type
    ;

/* Направление канала влияет на разбор следующего типа. */
chan_prefix:
      KW_CHAN %prec CHAN_BARE
    | KW_CHAN "<-"
    ;

function_declaration:
      KW_FUNC identifier function_signature function_body
    | KW_FUNC identifier function_signature
    | KW_FUNC identifier type_parameters function_signature function_body
    | KW_FUNC identifier type_parameters function_signature
    ;

function_signature:
      parameters %prec EMPTY_SIGNATURE
    | parameters result
    ;

parameters:
      "(" ")"
    | "(" parameter_list ")"
    | "(" parameter_list "," ")"
    ;

parameter_list:
      parameter_item
    | parameter_list "," parameter_item
    ;

parameter_item:
      type_name
    | identifier type
    | identifier "..." type
    | "..." type
    | non_name_type
    | pointer_type
    | "(" type ")"
    ;

result:
      result_atomic_type
    | parameters
    ;

result_atomic_type:
      type_name
    | pointer_type
    | array_type
    | map_type
    | struct_type
    | interface_type
    | function_type
    | channel_type
    ;

function_body:
      block
    ;

method_declaration:
      KW_FUNC receiver identifier function_signature function_body
    | KW_FUNC receiver identifier function_signature
    | KW_FUNC receiver identifier type_parameters function_signature function_body
    | KW_FUNC receiver identifier type_parameters function_signature
    ;

receiver:
      "(" receiver_type optional_trailing_comma ")"
    | "(" identifier receiver_type optional_trailing_comma ")"
    ;

receiver_type:
      type_name
    | "*" receiver_type
    | "(" receiver_type ")"
    ;

/* Выражения */

expression:
      unary_expression
    | expression "||" expression
    | expression "&&" expression
    | expression "==" expression
    | expression "!=" expression
    | expression "<" expression
    | expression "<=" expression
    | expression ">" expression
    | expression ">=" expression
    | expression "+" expression
    | expression "-" expression
    | expression "|" expression
    | expression "^" expression
    | expression "*" expression
    | expression "/" expression
    | expression "%" expression
    | expression "<<" expression
    | expression ">>" expression
    | expression "&" expression
    | expression "&^" expression
    ;

unary_expression:
      primary_expression
    | "+" unary_expression
    | "-" unary_expression
    | "!" unary_expression
    | "^" unary_expression
    | "*" unary_expression
    | "&" unary_expression
    | "<-" unary_expression
    ;

/* Индексация, type arguments и составные литералы пересекаются по синтаксису. */
primary_expression:
      operand
    | primary_expression "." identifier
    | primary_expression arguments
    | primary_expression "[" optional_expression ":" optional_expression "]"
    | primary_expression "[" optional_expression ":" expression ":" expression "]"
    | primary_expression type_assertion
    | non_name_type "." identifier
    | "(" non_expression_type ")" arguments
    | "(" non_expression_type ")" "." identifier
    | primary_expression bracket_group
    | non_name_type "(" expression optional_trailing_comma ")"
    | primary_expression literal_value
    ;

operand:
      literal
    | identifier %prec ARRAY_CALL
    | "(" expression ")"
    ;

/* Литералы */

literal:
      integer_literal
    | float_literal
    | imaginary_literal
    | rune_literal
    | string_literal
    | composite_literal
    | function_literal
    ;

integer_literal:
      DECIMAL_LITERAL {}
    | BINARY_LITERAL {}
    | OCTAL_LITERAL {}
    | HEX_LITERAL {}
    ;

float_literal:
      FLOAT_LITERAL {}
    | HEX_FLOAT_LITERAL {}
    ;

imaginary_literal:
      IMAGINARY_LITERAL {}
    ;

rune_literal:
      RUNE_LITERAL {}
    ;

string_literal:
      STRING_LITERAL {}
    | RAW_STRING_LITERAL {}
    ;

/* Аргументы вызова */

arguments:
      "(" ")"
    | "(" expression argument_expression_tail ")"
    | "(" non_expression_type argument_type_tail ")"
    ;

/* Троеточие допускается только в конце списка аргументов. */
argument_expression_tail:
      %empty
    | ","
    | "..."
    | "..." ","
    | "," expression argument_expression_tail
    ;

argument_type_tail:
      %empty
    | ","
    | "..."
    | "..." ","
    | "," expression argument_expression_tail
    ;

/* Проверка типа */

type_assertion:
      "." "(" type ")"
    ;

/* Составные литералы */

composite_literal:
      composite_literal_type non_name_literal_value
    ;

composite_literal_type:
      array_type
    | map_type
    | struct_type
    | "[" "..." "]" type
    ;

literal_value:
      "{" "}"
    | "{" literal_elements "}"
    | "{" literal_elements "," "}"
    ;

non_name_literal_value:
      block_open "}"
    | block_open literal_elements "}"
    | block_open literal_elements "," "}"
    ;

literal_elements:
      literal_element
    | literal_elements "," literal_element
    ;

literal_element:
      literal_element_value
    | literal_key ":" literal_element_value
    ;

literal_element_value:
      expression
    | literal_value
    ;

literal_key:
      expression
    | literal_value
    ;

/* Анонимные функции */

function_literal:
      KW_FUNC function_signature function_body
    ;

/* Условия и циклы */

if_statement:
      KW_IF expression loop_body optional_else
    | KW_IF optional_simple_statement ";" expression loop_body optional_else
    ;

optional_else:
      %empty
    | KW_ELSE block
    | KW_ELSE if_statement
    ;

for_statement:
      KW_FOR loop_body
    | KW_FOR expression loop_body
    | KW_FOR for_clause loop_body
    | KW_FOR range_clause loop_body
    ;

for_clause:
      optional_simple_statement ";" optional_expression ";" optional_simple_statement
    ;

range_clause:
      KW_RANGE expression
    | expression_list "=" KW_RANGE expression
    | expression_list ":=" KW_RANGE expression
    ;

/* Switch */

switch_statement:
      expression_switch_statement
    | type_switch_statement
    ;

expression_switch_statement:
      KW_SWITCH expression_switch_header BODY_BRACE expression_cases "}"
    ;

expression_switch_header:
      %empty
    | expression
    | simple_statement ";" optional_expression
    | ";" optional_expression
    ;

expression_cases:
      %empty
    | expression_cases expression_case_clause
    ;

expression_case_clause:
      KW_CASE expression_list ":" statement_list
    | KW_DEFAULT ":" statement_list
    ;

type_switch_statement:
      KW_SWITCH type_switch_guard BODY_BRACE type_cases "}"
    | KW_SWITCH simple_statement ";" type_switch_guard BODY_BRACE type_cases "}"
    ;

type_switch_guard:
      primary_expression "." "(" KW_TYPE ")"
    | expression_list ":=" primary_expression "." "(" KW_TYPE ")"
    ;

type_cases:
      %empty
    | type_cases type_case_clause
    ;

type_case_clause:
      KW_CASE type_case_list ":" statement_list
    | KW_DEFAULT ":" statement_list
    ;

type_case_list:
      type
    | type_case_list "," type
    ;

/* Select и каналы */

select_statement:
      KW_SELECT BODY_BRACE select_cases "}"
    ;

select_cases:
      %empty
    | select_cases select_case
    ;

select_case:
      KW_CASE communication_clause ":" statement_list
    | KW_DEFAULT ":" statement_list
    ;

communication_clause:
      send_statement
    | expression
    | expression_list "=" expression
    | expression_list ":=" expression
    ;

send_statement:
      expression "<-" expression
    ;

/* Блоки и инструкции */

block:
      block_open statement_list "}"
    ;

/* BODY_BRACE отличает тело управляющей конструкции от составного литерала.
   Здесь синхронизируем состояние лексера после открытия блока. */
block_open:
      "{"
    | BODY_BRACE { LexerSupport::ResumeHeader(); }
    ;

loop_body:
      BODY_BRACE statement_list "}"
    ;

statement_list:
      %empty
    | ";" statement_list
    | statement ";" statement_list
    | statement
    ;

statement:
      declaration_statement
    | simple_statement
    | return_statement
    | break_statement
    | continue_statement
    | goto_statement
    | fallthrough_statement
    | labeled_statement
    | defer_statement
    | go_statement
    | block
    | if_statement
    | for_statement
    | switch_statement
    | select_statement
    ;

declaration_statement:
      declaration
    ;

simple_statement:
      expression_statement
    | send_statement
    | increment_statement
    | decrement_statement
    | assignment
    | short_variable_declaration
    ;

expression_statement:
      expression
    ;

optional_simple_statement:
      %empty
    | simple_statement
    ;

/* Присваивания */

assignment:
      expression_list assignment_operator expression_list
    ;

assignment_operator:
      "="
    | "+="
    | "-="
    | "*="
    | "/="
    | "%="
    | "&="
    | "|="
    | "^="
    | "&^="
    | "<<="
    | ">>="
    ;

short_variable_declaration:
      expression_list ":=" expression_list
    ;

/* Остальные инструкции */

increment_statement:
      expression "++"
    ;

decrement_statement:
      expression "--"
    ;

return_statement:
      KW_RETURN
    | KW_RETURN expression_list
    ;

break_statement:
      KW_BREAK
    | KW_BREAK identifier
    ;

continue_statement:
      KW_CONTINUE
    | KW_CONTINUE identifier
    ;

goto_statement:
      KW_GOTO identifier
    ;

fallthrough_statement:
      KW_FALLTHROUGH
    ;

labeled_statement:
      identifier ":" statement
    | identifier ":"
    ;

defer_statement:
      KW_DEFER expression
    ;

go_statement:
      KW_GO expression
    ;

/* Вспомогательные правила */

identifier:
      IDENTIFIER {}
    ;

identifier_list:
      identifier %prec NAME_END
    | identifier_list "," identifier
    ;

expression_list:
      expression
    | expression_list "," expression
    ;

bracket_arguments:
      expression
    | non_expression_type
    | bracket_arguments "," expression
    | bracket_arguments "," non_expression_type
    ;

/* Общий разбор квадратных скобок для типов и выражений. */
bracket_group:
      "[" "]"
    | "[" bracket_arguments "]"
    | "[" bracket_arguments "," "]"
    ;

optional_expression:
      %empty
    | expression
    ;

optional_trailing_comma:
      %empty
    | ","
    ;

%%

void yyerror(const char* message) {
    // Сообщение о лексической ошибке уже вывел лексер.
    if (!LexerSupport::failed) LexerSupport::Error(yylloc, message);
}
