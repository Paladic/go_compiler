%code requires {
    #include <string>
}

%define lr.type canonical-lr

%{
#include <string>

#include "extension/logger/ParserLogger.h"

extern int yylex();
extern int yylineno;

void yyerror(const char* message);
%}


/* ---------- Семантические значения ---------- */

%union {
    long long integerValue;
    double floatValue;
    std::string* stringValue;
}


/* ---------- литералы ---------- */

%token <integerValue> DECIMAL_LITERAL
%token <integerValue> BINARY_LITERAL
%token <integerValue> OCTAL_LITERAL
%token <integerValue> HEX_LITERAL
%token <integerValue> RUNE_LITERAL

%token <floatValue> FLOAT_LITERAL
%token <floatValue> HEX_FLOAT_LITERAL
%token <floatValue> IMAGINARY_LITERAL

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

%token PLUS
%token MINUS
%token MULTIPLY
%token DIVIDE
%token MODULO


/* ---------- Побитовые операторы ---------- */

%token BIT_AND
%token BIT_OR
%token BIT_XOR
%token BIT_CLEAR


/* ---------- Операторы сдвига ---------- */

%token LEFT_SHIFT
%token RIGHT_SHIFT


/* ---------- Логические операторы ---------- */

%token LOGICAL_AND
%token LOGICAL_OR
%token LOGICAL_NOT


/* ---------- Операторы сравнения ---------- */

%token EQUAL
%token NOT_EQUAL

%token LESS
%token LESS_EQUAL

%token GREATER
%token GREATER_EQUAL


/* ---------- Операторы присваивания ---------- */

%token ASSIGN

%token PLUS_ASSIGN
%token MINUS_ASSIGN
%token MULTIPLY_ASSIGN
%token DIVIDE_ASSIGN
%token MODULO_ASSIGN

%token BIT_AND_ASSIGN
%token BIT_OR_ASSIGN
%token BIT_XOR_ASSIGN

%token LEFT_SHIFT_ASSIGN
%token RIGHT_SHIFT_ASSIGN

%token BIT_CLEAR_ASSIGN

%token DECLARE_ASSIGN


/* ---------- Прочие операторы ---------- */

%token INCREMENT
%token DECREMENT

%token CHANNEL_ARROW

%token TILDE


/* ---------- Скобки ---------- */

%token LEFT_PAREN
%token RIGHT_PAREN

%token LEFT_BRACKET
%token RIGHT_BRACKET

%token LEFT_BRACE
%token RIGHT_BRACE


/* ---------- Пунктуация---------- */

%token COMMA
%token COLON
%token DOT
%token ELLIPSIS
%token SEMICOLON

/* ---------- Ошибки лексера ---------- */

%token LEXICAL_ERROR


/* очищаем строковые значения, если они удаляются */
%destructor {
    delete $$;
} <stringValue>


/* корневой элемент дерева */
%start program

%%

/* ---------- Корень программы ---------- */

program:
    package_clause SEMICOLON
    {
        ParserLogger::Message(
            "program parsed successfully"
        );
    }
;

/* ---------- Package ---------- */

package_clause:
    KW_PACKAGE IDENTIFIER
    {
        ParserLogger::Value(
            "package",
            *$2
        );

        delete $2;
    }
;

/* ============================================================
   EXPRESSIONS
   ============================================================ */


/* ---------- Общее выражение ---------- */

/*
expression:
    TODO
;
*/


/* ---------- || ---------- */

/*
logical_or_expression:
    TODO
;
*/


/* ---------- && ---------- */

/*
logical_and_expression:
    TODO
;
*/


/* ---------- == != < <= > >= ---------- */

/*
comparison_expression:
    TODO
;
*/


/* ---------- + - | ^ ---------- */

/*
additive_expression:
    TODO
;
*/


/* ---------- * / % << >> & &^ ---------- */

/*
multiplicative_expression:
    TODO
;
*/


/* ---------- Унарные выражения ---------- */

/*
unary_expression:
    TODO
;
*/


/* ---------- Primary expression ---------- */

/*
primary_expression:
    TODO
;
*/


/* ---------- Operand ---------- */

/*
operand:
    TODO
;
*/


/* ============================================================
   LITERALS
   ============================================================ */

/*
literal:
    TODO
;
*/


/* ---------- Integer literals ---------- */

/*
integer_literal:
    TODO
;
*/


/* ---------- Float literals ---------- */

/*
float_literal:
    TODO
;
*/


/* ---------- Imaginary literal ---------- */

/*
imaginary_literal:
    TODO
;
*/


/* ---------- Rune literal ---------- */

/*
rune_literal:
    TODO
;
*/


/* ---------- String literal ---------- */

/*
string_literal:
    TODO
;
*/


/* ============================================================
   FUNCTION CALL
   ============================================================ */

/*
function_call:
    TODO
;
*/


/* ---------- Аргументы вызова ---------- */

/*
arguments:
    TODO
;
*/


/* ============================================================
   SELECTOR

   obj.field
   ============================================================ */

/*
selector:
    TODO
;
*/


/* ============================================================
   INDEX

   array[index]
   ============================================================ */

/*
index_expression:
    TODO
;
*/


/* ============================================================
   SLICE EXPRESSION

   array[1:5]
   array[:5]
   array[1:]
   array[:]
   ============================================================ */

/*
slice_expression:
    TODO
;
*/


/* ============================================================
   TYPE ASSERTION

   value.(Type)
   ============================================================ */

/*
type_assertion:
    TODO
;
*/


/* ============================================================
   COMPOSITE LITERAL

   Point{x: 10}
   []int{1, 2, 3}
   ============================================================ */

/*
composite_literal:
    TODO
;
*/


/* ---------- Элементы composite literal ---------- */

/*
literal_elements:
    TODO
;
*/


/* ---------- Один элемент ---------- */

/*
literal_element:
    TODO
;
*/


/* ============================================================
   FUNCTION LITERAL

   func(x int) int {
       return x
   }
   ============================================================ */

/*
function_literal:
    TODO
;
*/


/* ============================================================
   IF
   ============================================================ */

/*
if_statement:
    TODO
;
*/


/* ============================================================
   FOR
   ============================================================ */

/*
for_statement:
    TODO
;
*/


/* ---------- Классический for ---------- */

/*
for_clause:
    TODO
;
*/


/* ---------- Range ---------- */

/*
range_clause:
    TODO
;
*/


/* ============================================================
   SWITCH
   ============================================================ */

/*
switch_statement:
    TODO
;
*/


/* ---------- Список case ---------- */

/*
switch_cases:
    TODO
;
*/


/* ---------- Один элемент switch ---------- */

/*
switch_case:
    TODO
;
*/


/* ---------- case ---------- */

/*
case_clause:
    TODO
;
*/


/* ---------- default ---------- */

/*
default_clause:
    TODO
;
*/


/* ============================================================
   TYPE SWITCH
   ============================================================ */

/*
type_switch_statement:
    TODO
;
*/


/* ============================================================
   SELECT
   ============================================================ */

/*
select_statement:
    TODO
;
*/


/* ---------- Cases внутри select ---------- */

/*
select_cases:
    TODO
;
*/


/* ---------- Один case внутри select ---------- */

/*
select_case:
    TODO
;
*/


/* ============================================================
   CHANNEL SEND

   channel <- value
   ============================================================ */

/*
send_statement:
    TODO
;
*/


/* ============================================================
   CHANNEL RECEIVE

   <-channel
   ============================================================ */

/*
receive_expression:
    TODO
;
*/


/* ============================================================
   IMPORTS
   ============================================================ */

/*
imports:
    TODO
;
*/


/* ---------- Import declaration ---------- */

/*
import_declaration:
    TODO
;
*/


/* ---------- Один import ---------- */

/*
import_spec:
    TODO
;
*/


/* ---------- Группа import ---------- */

/*
import_group:
    TODO
;
*/


/* ============================================================
   DECLARATIONS
   ============================================================ */

/*
declarations:
    TODO
;
*/


/* ---------- Общее declaration ---------- */

/*
declaration:
    TODO
;
*/


/* ============================================================
   VARIABLES
   ============================================================ */

/*
variable_declaration:
    TODO
;
*/


/* ---------- Один var spec ---------- */

/*
variable_spec:
    TODO
;
*/


/* ---------- Группа var ---------- */

/*
variable_group:
    TODO
;
*/


/* ============================================================
   CONSTANTS
   ============================================================ */

/*
constant_declaration:
    TODO
;
*/


/* ---------- Один const spec ---------- */

/*
constant_spec:
    TODO
;
*/


/* ---------- Группа const ---------- */

/*
constant_group:
    TODO
;
*/


/* ============================================================
   TYPE DECLARATION
   ============================================================ */

/*
type_declaration:
    TODO
;
*/


/* ---------- Один type spec ---------- */

/*
type_spec:
    TODO
;
*/


/* ============================================================
   TYPES
   ============================================================ */


/* ---------- Общий тип ---------- */

/*
type:
    TODO
;
*/


/* ---------- Имя типа ---------- */

/*
type_name:
    TODO
;
*/


/* ============================================================
   ARRAY TYPE

   [10]int
   ============================================================ */

/*
array_type:
    TODO
;
*/


/* ============================================================
   SLICE TYPE

   []int
   ============================================================ */

/*
slice_type:
    TODO
;
*/


/* ============================================================
   POINTER TYPE

   *int
   ============================================================ */

/*
pointer_type:
    TODO
;
*/


/* ============================================================
   MAP TYPE

   map[string]int
   ============================================================ */

/*
map_type:
    TODO
;
*/


/* ============================================================
   STRUCT TYPE
   ============================================================ */

/*
struct_type:
    TODO
;
*/


/* ---------- Поля struct ---------- */

/*
field_declarations:
    TODO
;
*/


/* ---------- Одно поле ---------- */

/*
field_declaration:
    TODO
;
*/


/* ============================================================
   INTERFACE TYPE
   ============================================================ */

/*
interface_type:
    TODO
;
*/


/* ---------- Список элементов interface ---------- */

/*
interface_elements:
    TODO
;
*/


/* ---------- Один элемент interface ---------- */

/*
interface_element:
    TODO
;
*/


/* ============================================================
   FUNCTION TYPE
   ============================================================ */

/*
function_type:
    TODO
;
*/


/* ============================================================
   CHANNEL TYPE

   chan int
   <-chan int
   chan<- int
   ============================================================ */

/*
channel_type:
    TODO
;
*/


/* ============================================================
   FUNCTIONS
   ============================================================ */


/* ---------- Function declaration ---------- */

/*
function_declaration:
    TODO
;
*/


/* ---------- Имя функции ---------- */

/*
function_name:
    TODO
;
*/


/* ---------- Сигнатура ---------- */

/*
function_signature:
    TODO
;
*/


/* ---------- Параметры ---------- */

/*
parameters:
    TODO
;
*/


/* ---------- Список параметров ---------- */

/*
parameter_list:
    TODO
;
*/


/* ---------- Один параметр ---------- */

/*
parameter:
    TODO
;
*/


/* ---------- Возвращаемое значение ---------- */

/*
result:
    TODO
;
*/


/* ---------- Тело функции ---------- */

/*
function_body:
    TODO
;
*/


/* ============================================================
   METHODS
   ============================================================ */

/*
method_declaration:
    TODO
;
*/


/* ---------- Receiver ---------- */

/*
receiver:
    TODO
;
*/


/* ============================================================
   BLOCK

   {
       ...
   }
   ============================================================ */

/*
block:
    TODO
;
*/


/* ============================================================
   STATEMENT LIST

   Набор инструкций внутри block.
   ============================================================ */

/*
statement_list:
    TODO
;
*/


/* ============================================================
   ОБЩИЙ STATEMENT

   Главная точка входа для любой инструкции.
   ============================================================ */

/*
statement:
    TODO
;
*/


/* ============================================================
   DECLARATION STATEMENT

   var / const / type внутри блока
   ============================================================ */

/*
declaration_statement:
    TODO
;
*/


/* ============================================================
   SIMPLE STATEMENT

   assignment
   :=
   ++
   --
   expression statement
   send
   ============================================================ */

/*
simple_statement:
    TODO
;
*/


/* ============================================================
   EXPRESSION STATEMENT
   ============================================================ */

/*
expression_statement:
    TODO
;
*/


/* ============================================================
   ASSIGNMENT

   x = y
   x += y
   x <<= y
   ============================================================ */

/*
assignment:
    TODO
;
*/


/* ---------- Оператор присваивания ---------- */

/*
assignment_operator:
    TODO
;
*/


/* ============================================================
   SHORT VARIABLE DECLARATION

   x := 10
   x, y := 10, 20
   ============================================================ */

/*
short_variable_declaration:
    TODO
;
*/


/* ============================================================
   INCREMENT

   x++
   ============================================================ */

/*
increment_statement:
    TODO
;
*/


/* ============================================================
   DECREMENT

   x--
   ============================================================ */

/*
decrement_statement:
    TODO
;
*/


/* ============================================================
   RETURN
   ============================================================ */

/*
return_statement:
    TODO
;
*/


/* ============================================================
   BREAK
   ============================================================ */

/*
break_statement:
    TODO
;
*/


/* ============================================================
   CONTINUE
   ============================================================ */

/*
continue_statement:
    TODO
;
*/


/* ============================================================
   GOTO
   ============================================================ */

/*
goto_statement:
    TODO
;
*/


/* ============================================================
   FALLTHROUGH
   ============================================================ */

/*
fallthrough_statement:
    TODO
;
*/


/* ============================================================
   LABEL

   start:
   ============================================================ */

/*
labeled_statement:
    TODO
;
*/


/* ============================================================
   DEFER

   defer foo()
   ============================================================ */

/*
defer_statement:
    TODO
;
*/


/* ============================================================
   GO

   go foo()
   ============================================================ */

/*
go_statement:
    TODO
;
*/


/* ============================================================
   IDENTIFIER LIST

   x
   x, y
   x, y, z
   ============================================================ */

/*
identifier_list:
    TODO
;
*/


/* ============================================================
   EXPRESSION LIST

   x
   x, y
   x + 10, foo()
   ============================================================ */

/*
expression_list:
    TODO
;
*/


/* ============================================================
   EMPTY STATEMENT
   ============================================================ */

/*
empty_statement:
    TODO
;
*/


/* ============================================================
   ERROR RECOVERY

   Позже здесь можно добавить правила с системным
   символом Bison:

       error

   Например синхронизацию по SEMICOLON.
   ============================================================ */

/*
error_statement:
    TODO
;
*/

%%


/* ---------- Ошибки ---------- */

void yyerror(const char* message)
{
    ParserLogger::Error(
        yylineno,
        message
    );
}