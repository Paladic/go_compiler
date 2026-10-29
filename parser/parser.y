/* ---------- Общие объявления C++ ---------- */

%code requires {
    #include "SourceRange.h"
    #include <string>

    // Координаты допускают перемещение вместе со стеком LR.
    #define YYLTYPE_IS_TRIVIAL 1
    #define YYLLOC_DEFAULT(Current, Rhs, N) \
        MergeSourceRange(Current, YYRHSLOC(Rhs, (N) ? 1 : 0), \
                         YYRHSLOC(Rhs, N), YYRHSLOC(Rhs, 0), N)
}


/* ---------- Настройки парсера ---------- */

%define lr.type lalr
%expect 0
%locations
%define parse.trace
%define parse.error detailed
%define api.location.type {SourceRange}

%code top {
    #define YYMAXDEPTH 1000000
}

%code {
    #include "LexerSupport.h"

    int yylex();
    void yyerror(const char* message);
}


/* ---------- Семантические значения токенов ---------- */

%union {
    long long integerValue;
    const std::string* stringValue;
}


/* ---------- Литералы ---------- */

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


/* ---------- Ключевые слова ---------- */

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


/* ---------- Арифметические операторы ---------- */

%token PLUS "+"
%token MINUS "-"
%token MULTIPLY "*"
%token DIVIDE "/"
%token MODULO "%"


/* ---------- Побитовые операторы ---------- */

%token BIT_AND "&"
%token BIT_OR "|"
%token BIT_XOR "^"
%token BIT_CLEAR "&^"


/* ---------- Операторы сдвига ---------- */

%token LEFT_SHIFT "<<"
%token RIGHT_SHIFT ">>"


/* ---------- Логические операторы ---------- */

%token LOGICAL_AND "&&"
%token LOGICAL_OR "||"
%token LOGICAL_NOT "!"


/* ---------- Операторы сравнения ---------- */

%token EQUAL "=="
%token NOT_EQUAL "!="

%token LESS "<"
%token LESS_EQUAL "<="

%token GREATER ">"
%token GREATER_EQUAL ">="


/* ---------- Операторы присваивания ---------- */

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


/* ---------- Прочие операторы ---------- */

%token INCREMENT "++"
%token DECREMENT "--"

%token CHANNEL_ARROW "<-"

%token TILDE "~"


/* ---------- Скобки ---------- */

%token LEFT_PAREN "("
%token RIGHT_PAREN ")"

%token LEFT_BRACKET "["
%token RIGHT_BRACKET "]"

%token LEFT_BRACE "{"
%token RIGHT_BRACE "}"


/* ---------- Пунктуация ---------- */

%token COMMA ","
%token COLON ":"
%token DOT "."
%token ELLIPSIS "..."
%token SEMICOLON ";"


/* ---------- Служебный контекст лексера ---------- */

%token BODY_BRACE "body {"


/* ---------- Ошибки лексера ---------- */

%token LEXICAL_ERROR


/* ---------- Приоритеты операторов ---------- */

// Порядок всех объявлений приоритета сохраняется: он влияет на таблицу LR.

/* Границы имени типа, сигнатуры и направления канала. */
%precedence NAME_END EMPTY_SIGNATURE CHAN_BARE
%precedence LEFT_PAREN
%precedence ARRAY_CALL

/* Бинарные операторы: от меньшего приоритета к большему. */
%left LOGICAL_OR
%left LOGICAL_AND

%left EQUAL NOT_EQUAL LESS LESS_EQUAL GREATER GREATER_EQUAL

%left PLUS MINUS BIT_OR BIT_XOR

%left MULTIPLY DIVIDE MODULO LEFT_SHIFT RIGHT_SHIFT BIT_AND BIT_CLEAR

/* Продолжение типа или выражения. */
%precedence IDENTIFIER KW_FUNC KW_INTERFACE KW_MAP KW_STRUCT KW_CHAN LEFT_BRACKET DOT COMMA
%precedence CHANNEL_ARROW


/* ---------- Начальное правило ---------- */

%start start


%%

/* ============================================================
   PROGRAM
   ============================================================ */


/* ---------- Начальное правило ---------- */

start:
      program
;


/* ---------- Корень программы ---------- */

program:
      package_clause ";" imports declarations
;


/* ---------- Package ---------- */

package_clause:
      KW_PACKAGE identifier
;


/* ============================================================
   IMPORTS
   ============================================================ */


/* ---------- Список импортов ---------- */

imports:
      %empty
    | imports import_declaration ";"
;


/* ---------- Объявление import ---------- */

import_declaration:
      KW_IMPORT import_spec
    | KW_IMPORT "(" import_spec_list ")"
;


/* ---------- Содержимое группы import ---------- */

import_spec_list:
      %empty
    | import_spec ";" import_spec_list
    | import_spec
;


/* ---------- Один импорт ---------- */

import_spec:
      import_path
    | "." import_path
    | identifier import_path
;


/* ---------- Путь импорта ---------- */

import_path:
      STRING_LITERAL {}
    | RAW_STRING_LITERAL {}
;


/* ============================================================
   DECLARATIONS
   ============================================================ */


/* ---------- Список объявлений ---------- */

declarations:
      %empty
    | declarations top_level_declaration ";"
;


/* ---------- Объявление верхнего уровня ---------- */

top_level_declaration:
      declaration
    | function_declaration
    | method_declaration
;


/* ---------- Общее объявление ---------- */

declaration:
      variable_declaration
    | constant_declaration
    | type_declaration
;


/* ============================================================
   VARIABLES
   ============================================================ */


/* ---------- Объявление var ---------- */

variable_declaration:
      KW_VAR variable_spec
    | KW_VAR "(" variable_spec_list ")"
;


/* ---------- Содержимое группы var ---------- */

variable_spec_list:
      %empty
    | variable_spec ";" variable_spec_list
    | variable_spec
;


/* ---------- Одна спецификация var ---------- */

variable_spec:
      identifier_list type
    | identifier_list type "=" expression_list
    | identifier_list "=" expression_list
;


/* ============================================================
   CONSTANTS
   ============================================================ */


/* ---------- Объявление const ---------- */

constant_declaration:
      KW_CONST initialized_constant_spec
    | KW_CONST "(" constant_spec_list ")"
;


/* ---------- Содержимое группы const ---------- */

constant_spec_list:
      %empty
    | initialized_constant_spec constant_spec_list_tail
;


/* ---------- Продолжение группы const ---------- */

constant_spec_list_tail:
      %empty
    | ";"
    | ";" constant_spec constant_spec_list_tail
;


/* ---------- Спецификация const ---------- */

constant_spec:
      initialized_constant_spec
    | identifier_list
;


/* ---------- Спецификация const с инициализацией ---------- */

initialized_constant_spec:
      identifier_list type "=" expression_list
    | identifier_list "=" expression_list
;


/* ============================================================
   TYPE DECLARATION
   ============================================================ */


/* ---------- Объявление type ---------- */

type_declaration:
      KW_TYPE type_spec
    | KW_TYPE "(" type_spec_list ")"
;


/* ---------- Содержимое группы type ---------- */

type_spec_list:
      %empty
    | type_spec ";" type_spec_list
    | type_spec
;


/* ---------- Определение типа или alias ---------- */

type_spec:
      identifier type
    | identifier "=" type
    | identifier type_parameters type
    | identifier type_parameters "=" type
    | identifier bracket_group "=" type
;


/* ============================================================
   TYPES
   ============================================================ */


/* ---------- Общий тип ---------- */

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


/* ---------- Имя типа ---------- */

type_name:
      identifier %prec NAME_END
    | identifier "." identifier
    | identifier type_arguments
    | identifier "." identifier type_arguments
;


/* ---------- Тип без имени ---------- */

non_name_type:
      array_type
    | map_type
    | struct_type
    | interface_type
    | function_type
    | channel_type
;


/* ---------- Форма типа, не являющаяся выражением ---------- */

non_expression_type:
      non_name_type
    | "*" non_expression_type
    | "(" non_expression_type ")"
;


/* ============================================================
   TYPE PARAMETERS AND CONSTRAINTS
   ============================================================ */


/* ---------- Аргументы типа ---------- */

type_arguments:
      bracket_group
;


/* ---------- Параметры типа ---------- */

type_parameters:
      "[" type_parameter_list "]"
;


/* ---------- Список параметров типа ---------- */

type_parameter_list:
      identifier type_parameter_after_name
;


/* ---------- Продолжение после имени параметра типа ---------- */

type_parameter_after_name:
      type_constraint type_parameter_after_constraint
    | "," type_parameter_list
;


/* ---------- Продолжение после ограничения ---------- */

type_parameter_after_constraint:
      %empty
    | ","
    | "," type_parameter_list
;


/* ---------- Ограничение типа ---------- */

type_constraint:
      type_terms
;


/* ---------- Объединение типов ---------- */

type_terms:
      type_term
    | type_terms "|" type_term
;


/* ---------- Один тип в ограничении ---------- */

type_term:
      type
    | "~" type
;


/* ============================================================
   ARRAY TYPE
   ============================================================ */


/* ---------- Массив или срез ---------- */

array_type:
      bracket_group type
;


/* ============================================================
   POINTER TYPE
   ============================================================ */


/* ---------- Указатель ---------- */

pointer_type:
      "*" type
;


/* ============================================================
   MAP TYPE
   ============================================================ */


/* ---------- Отображение map ---------- */

map_type:
      KW_MAP "[" type "]" type
;


/* ============================================================
   STRUCT TYPE
   ============================================================ */


/* ---------- Структура ---------- */

struct_type:
      KW_STRUCT block_open field_declarations "}"
;


/* ---------- Список полей ---------- */

field_declarations:
      %empty
    | field_declaration ";" field_declarations
    | field_declaration
;


/* ---------- Одно поле или группа полей ---------- */

field_declaration:
      identifier array_type optional_struct_tag
    | identifier_list type optional_struct_tag
    | embedded_field optional_struct_tag
;


/* ---------- Встроенное поле ---------- */

embedded_field:
      type_name
    | "*" type_name
;


/* ---------- Необязательный тег поля ---------- */

optional_struct_tag:
      %empty
    | STRING_LITERAL {}
    | RAW_STRING_LITERAL {}
;


/* ============================================================
   INTERFACE TYPE
   ============================================================ */


/* ---------- Интерфейс ---------- */

interface_type:
      KW_INTERFACE "{" interface_elements "}"
;


/* ---------- Список элементов интерфейса ---------- */

interface_elements:
      %empty
    | interface_element ";" interface_elements
    | interface_element
;


/* ---------- Метод или ограничение интерфейса ---------- */

interface_element:
      identifier function_signature
    | type_terms
;


/* ============================================================
   FUNCTION TYPE
   ============================================================ */


/* ---------- Тип функции ---------- */

function_type:
      KW_FUNC function_signature
;


/* ============================================================
   CHANNEL TYPE
   ============================================================ */


/* ---------- Тип канала ---------- */

channel_type:
      chan_prefix type
    | "<-" KW_CHAN type
;


/* ---------- Направление канала ---------- */

chan_prefix:
      KW_CHAN %prec CHAN_BARE
    | KW_CHAN "<-"
;


/* ============================================================
   FUNCTIONS
   ============================================================ */


/* ---------- Объявление функции ---------- */

function_declaration:
      KW_FUNC identifier function_signature function_body
    | KW_FUNC identifier function_signature
    | KW_FUNC identifier type_parameters function_signature function_body
    | KW_FUNC identifier type_parameters function_signature
;


/* ---------- Сигнатура функции ---------- */

function_signature:
      parameters %prec EMPTY_SIGNATURE
    | parameters result
;


/* ---------- Параметры функции ---------- */

parameters:
      "(" ")"
    | "(" parameter_list ")"
    | "(" parameter_list "," ")"
;


/* ---------- Список обычных параметров ---------- */

parameter_list:
      parameter_item
    | parameter_list "," parameter_item
;


/* ---------- Обычный параметр ---------- */

parameter_item:
      type_name
    | identifier type
    | identifier "..." type
    | "..." type
    | non_name_type
    | pointer_type
    | "(" type ")"
;


/* ---------- Результат функции ---------- */

result:
      result_atomic_type
    | parameters
;


/* ---------- Один тип результата ---------- */

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


/* ---------- Тело функции ---------- */

function_body:
      block
;


/* ============================================================
   METHODS
   ============================================================ */


/* ---------- Объявление метода ---------- */

method_declaration:
      KW_FUNC receiver identifier function_signature function_body
    | KW_FUNC receiver identifier function_signature
    | KW_FUNC receiver identifier type_parameters function_signature function_body
    | KW_FUNC receiver identifier type_parameters function_signature
;


/* ---------- Получатель метода ---------- */

receiver:
      "(" receiver_type optional_trailing_comma ")"
    | "(" identifier receiver_type optional_trailing_comma ")"
;


/* ---------- Тип получателя ---------- */

receiver_type:
      type_name
    | "*" receiver_type
    | "(" receiver_type ")"
;


/* ============================================================
   EXPRESSIONS
   ============================================================ */


/* ---------- Бинарные выражения ---------- */

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


/* ---------- Унарные выражения ---------- */

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


/* ---------- Первичные выражения ---------- */

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


/* ---------- Операнд ---------- */

operand:
      literal
    | identifier %prec ARRAY_CALL
    | "(" expression ")"
;


/* ============================================================
   LITERALS
   ============================================================ */


/* ---------- Виды литералов ---------- */

literal:
      integer_literal
    | float_literal
    | imaginary_literal
    | rune_literal
    | string_literal
    | composite_literal
    | function_literal
;


/* ---------- Целочисленные литералы ---------- */

integer_literal:
      DECIMAL_LITERAL {}
    | BINARY_LITERAL {}
    | OCTAL_LITERAL {}
    | HEX_LITERAL {}
;


/* ---------- Вещественные литералы ---------- */

float_literal:
      FLOAT_LITERAL {}
    | HEX_FLOAT_LITERAL {}
;


/* ---------- Мнимый литерал ---------- */

imaginary_literal:
      IMAGINARY_LITERAL {}
;


/* ---------- Rune-литерал ---------- */

rune_literal:
      RUNE_LITERAL {}
;


/* ---------- Строковые литералы ---------- */

string_literal:
      STRING_LITERAL {}
    | RAW_STRING_LITERAL {}
;


/* ============================================================
   CALL ARGUMENTS
   ============================================================ */


/* ---------- Аргументы вызова ---------- */

arguments:
      "(" ")"
    | "(" expression argument_expression_tail ")"
    | "(" non_expression_type argument_type_tail ")"
;


/* ---------- Продолжение после выражения ---------- */

argument_expression_tail:
      %empty
    | ","
    | "..."
    | "..." ","
    | "," expression argument_expression_tail
;


/* ---------- Продолжение после типа ---------- */

argument_type_tail:
      %empty
    | ","
    | "..."
    | "..." ","
    | "," expression argument_expression_tail
;


/* ============================================================
   TYPE ASSERTION
   ============================================================ */


/* ---------- Утверждение типа: value.(Type) ---------- */

type_assertion:
      "." "(" type ")"
;


/* ============================================================
   COMPOSITE LITERALS
   ============================================================ */


/* ---------- Составной литерал ---------- */

composite_literal:
      composite_literal_type non_name_literal_value
;


/* ---------- Тип составного литерала ---------- */

composite_literal_type:
      array_type
    | map_type
    | struct_type
    | "[" "..." "]" type
;


/* ---------- Содержимое литерала ---------- */

literal_value:
      "{" "}"
    | "{" literal_elements "}"
    | "{" literal_elements "," "}"
;


/* ---------- Содержимое литерала неименованного типа ---------- */

non_name_literal_value:
      block_open "}"
    | block_open literal_elements "}"
    | block_open literal_elements "," "}"
;


/* ---------- Список элементов ---------- */

literal_elements:
      literal_element
    | literal_elements "," literal_element
;


/* ---------- Один элемент ---------- */

literal_element:
      literal_element_value
    | literal_key ":" literal_element_value
;


/* ---------- Значение элемента ---------- */

literal_element_value:
      expression
    | literal_value
;


/* ---------- Ключ или имя поля ---------- */

literal_key:
      expression
    | literal_value
;


/* ============================================================
   FUNCTION LITERAL
   ============================================================ */


/* ---------- Анонимная функция ---------- */

function_literal:
      KW_FUNC function_signature function_body
;


/* ============================================================
   IF
   ============================================================ */


/* ---------- Условный оператор ---------- */

if_statement:
      KW_IF expression loop_body optional_else
    | KW_IF optional_simple_statement ";" expression loop_body optional_else
;


/* ---------- Необязательная ветвь else ---------- */

optional_else:
      %empty
    | KW_ELSE block
    | KW_ELSE if_statement
;


/* ============================================================
   FOR
   ============================================================ */


/* ---------- Варианты цикла for ---------- */

for_statement:
      KW_FOR loop_body
    | KW_FOR expression loop_body
    | KW_FOR for_clause loop_body
    | KW_FOR range_clause loop_body
;


/* ---------- Классический for ---------- */

for_clause:
      optional_simple_statement ";" optional_expression ";" optional_simple_statement
;


/* ---------- Цикл range ---------- */

range_clause:
      KW_RANGE expression
    | expression_list "=" KW_RANGE expression
    | expression_list ":=" KW_RANGE expression
;


/* ============================================================
   SWITCH
   ============================================================ */


/* ---------- Виды switch ---------- */

switch_statement:
      expression_switch_statement
    | type_switch_statement
;


/* ---------- Switch по выражению ---------- */

expression_switch_statement:
      KW_SWITCH expression_switch_header BODY_BRACE expression_cases "}"
;


/* ---------- Заголовок switch ---------- */

expression_switch_header:
      %empty
    | expression
    | simple_statement ";" optional_expression
    | ";" optional_expression
;


/* ---------- Ветви switch ---------- */

expression_cases:
      %empty
    | expression_cases expression_case_clause
;


/* ---------- Заголовок case или default ---------- */

expression_case_clause:
      KW_CASE expression_list ":" statement_list
    | KW_DEFAULT ":" statement_list
;


/* ============================================================
   TYPE SWITCH
   ============================================================ */


/* ---------- Switch по типу ---------- */

type_switch_statement:
      KW_SWITCH type_switch_guard BODY_BRACE type_cases "}"
    | KW_SWITCH simple_statement ";" type_switch_guard BODY_BRACE type_cases "}"
;


/* ---------- Проверка типа в заголовке ---------- */

type_switch_guard:
      primary_expression "." "(" KW_TYPE ")"
    | expression_list ":=" primary_expression "." "(" KW_TYPE ")"
;


/* ---------- Ветви type switch ---------- */

type_cases:
      %empty
    | type_cases type_case_clause
;


/* ---------- Заголовок case или default ---------- */

type_case_clause:
      KW_CASE type_case_list ":" statement_list
    | KW_DEFAULT ":" statement_list
;


/* ---------- Список типов в case ---------- */

type_case_list:
      type
    | type_case_list "," type
;


/* ============================================================
   SELECT
   ============================================================ */


/* ---------- Оператор select ---------- */

select_statement:
      KW_SELECT BODY_BRACE select_cases "}"
;


/* ---------- Ветви select ---------- */

select_cases:
      %empty
    | select_cases select_case
;


/* ---------- Заголовок case или default ---------- */

select_case:
      KW_CASE communication_clause ":" statement_list
    | KW_DEFAULT ":" statement_list
;


/* ---------- Операция в ветви select ---------- */

communication_clause:
      send_statement
    | expression
    | expression_list "=" expression
    | expression_list ":=" expression
;


/* ============================================================
   CHANNEL SEND
   ============================================================ */


/* ---------- Отправка в канал: channel <- value ---------- */

send_statement:
      expression "<-" expression
;


/* ============================================================
   BLOCKS
   ============================================================ */


/* ---------- Блок ---------- */

block:
      block_open statement_list "}"
;


/* ---------- Начало блока и контекст лексера ---------- */

block_open:
      "{"
    | BODY_BRACE { LexerSupport::ResumeHeader(); }
;


/* ---------- Тело управляющей конструкции ---------- */

loop_body:
      BODY_BRACE statement_list "}"
;


/* ---------- Список инструкций ---------- */

statement_list:
      %empty
    | ";" statement_list
    | statement ";" statement_list
    | statement
;


/* ============================================================
   STATEMENTS
   ============================================================ */


/* ---------- Виды инструкций ---------- */

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


/* ---------- Объявление внутри блока ---------- */

declaration_statement:
      declaration
;


/* ---------- Простая инструкция ---------- */

simple_statement:
      expression_statement
    | send_statement
    | increment_statement
    | decrement_statement
    | assignment
    | short_variable_declaration
;


/* ---------- Инструкция-выражение ---------- */

expression_statement:
      expression
;


/* ---------- Необязательная простая инструкция ---------- */

optional_simple_statement:
      %empty
    | simple_statement
;


/* ============================================================
   ASSIGNMENT
   ============================================================ */


/* ---------- Присваивание ---------- */

assignment:
      expression_list assignment_operator expression_list
;


/* ---------- Операторы присваивания ---------- */

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


/* ---------- Короткое объявление через := ---------- */

short_variable_declaration:
      expression_list ":=" expression_list
;


/* ============================================================
   INCREMENT AND DECREMENT
   ============================================================ */


/* ---------- Инкремент ---------- */

increment_statement:
      expression "++"
;


/* ---------- Декремент ---------- */

decrement_statement:
      expression "--"
;


/* ============================================================
   RETURN
   ============================================================ */


/* ---------- Возврат из функции ---------- */

return_statement:
      KW_RETURN
    | KW_RETURN expression_list
;


/* ============================================================
   BREAK
   ============================================================ */


/* ---------- Выход из цикла или ветви ---------- */

break_statement:
      KW_BREAK
    | KW_BREAK identifier
;


/* ============================================================
   CONTINUE
   ============================================================ */


/* ---------- Следующая итерация цикла ---------- */

continue_statement:
      KW_CONTINUE
    | KW_CONTINUE identifier
;


/* ============================================================
   GOTO
   ============================================================ */


/* ---------- Переход к метке ---------- */

goto_statement:
      KW_GOTO identifier
;


/* ============================================================
   FALLTHROUGH
   ============================================================ */


/* ---------- Переход в следующую ветвь switch ---------- */

fallthrough_statement:
      KW_FALLTHROUGH
;


/* ============================================================
   LABEL
   ============================================================ */


/* ---------- Метка ---------- */

labeled_statement:
      identifier ":" statement
    | identifier ":"
;


/* ============================================================
   DEFER
   ============================================================ */


/* ---------- Отложенный вызов ---------- */

defer_statement:
      KW_DEFER expression
;


/* ============================================================
   GO
   ============================================================ */


/* ---------- Запуск вызова в goroutine ---------- */

go_statement:
      KW_GO expression
;


/* ============================================================
   LISTS AND OPTIONAL ELEMENTS
   ============================================================ */


/* ---------- Идентификатор ---------- */

identifier:
      IDENTIFIER {}
;


/* ---------- Список идентификаторов ---------- */

identifier_list:
      identifier %prec NAME_END
    | identifier_list "," identifier
;


/* ---------- Список выражений ---------- */

expression_list:
      expression
    | expression_list "," expression
;


/* ---------- Содержимое квадратных скобок ---------- */

bracket_arguments:
      expression
    | non_expression_type
    | bracket_arguments "," expression
    | bracket_arguments "," non_expression_type
;


/* ---------- Общая запись квадратных скобок ---------- */

bracket_group:
      "[" "]"
    | "[" bracket_arguments "]"
    | "[" bracket_arguments "," "]"
;


/* ---------- Необязательное выражение ---------- */

optional_expression:
      %empty
    | expression
;


/* ---------- Необязательная завершающая запятая ---------- */

optional_trailing_comma:
      %empty
    | ","
;

%%

void yyerror(const char* message) {
    // A lexical error already has a specific diagnostic.
    if (!LexerSupport::failed) LexerSupport::Error(yylloc, message);
}
