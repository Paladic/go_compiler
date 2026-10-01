%code requires {
    #include <string>
}

%define lr.type canonical-lr
%define parse.trace

%{
#include <string>

#include "extension/logger/ParserLogger.h"

extern int yylex();
extern int yylineno;
extern int yydebug;

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

/* ---------- Приоритеты операторов ---------- */

%left LOGICAL_OR
%left LOGICAL_AND

%left EQUAL NOT_EQUAL LESS LESS_EQUAL GREATER GREATER_EQUAL

%left PLUS MINUS BIT_OR BIT_XOR

%left MULTIPLY DIVIDE MODULO LEFT_SHIFT RIGHT_SHIFT BIT_AND BIT_CLEAR

%precedence UNARY

/* очищаем строковые значения, если они удаляются */
%destructor {
    delete $$;
} <stringValue>


/* корневой элемент дерева */
%start program

%%
/* ---------- Корень программы ---------- */

program:
    package_clause SEMICOLON declarations
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

/* ---------- Список объявлений ---------- */

declarations:
      %empty
    | declarations declaration SEMICOLON
;

/* ---------- Объявление ---------- */

declaration:
    variable_declaration
;

/* ---------- Переменная ---------- */

variable_declaration:
    KW_VAR IDENTIFIER ASSIGN expression
    {
        ParserLogger::Value(
            "variable declaration",
            *$2
        );

        delete $2;
    }
;

/* ============================================================
   EXPRESSIONS
   ============================================================ */

expression:
      primary_expression

    /* ---------- Бинарные логические ---------- */

    | expression LOGICAL_OR expression
    | expression LOGICAL_AND expression


    /* ---------- Сравнение ---------- */

    | expression EQUAL expression
    | expression NOT_EQUAL expression

    | expression LESS expression
    | expression LESS_EQUAL expression
    | expression GREATER expression
    | expression GREATER_EQUAL expression


    /* ---------- Арифметика / побитовые ---------- */

    | expression PLUS expression
    | expression MINUS expression

    | expression BIT_OR expression
    | expression BIT_XOR expression

    | expression MULTIPLY expression
    | expression DIVIDE expression
    | expression MODULO expression

    | expression LEFT_SHIFT expression
    | expression RIGHT_SHIFT expression

    | expression BIT_AND expression
    | expression BIT_CLEAR expression


    /* ---------- Унарные ---------- */

    | PLUS expression %prec UNARY
    | MINUS expression %prec UNARY

    | LOGICAL_NOT expression %prec UNARY
    | BIT_XOR expression %prec UNARY

    | MULTIPLY expression %prec UNARY
    | BIT_AND expression %prec UNARY

    | CHANNEL_ARROW expression %prec UNARY
;

/* ---------- Primary expression ---------- */

primary_expression:
      operand

    /* obj.field */
    | primary_expression DOT IDENTIFIER
    {
        delete $3;
    }

    /* foo(...) / obj.method(...) */
    | primary_expression arguments

    /* array[index] */
    | primary_expression LEFT_BRACKET expression RIGHT_BRACKET

    /* array[low:high] */
    | primary_expression LEFT_BRACKET optional_expression
      COLON optional_expression RIGHT_BRACKET

    /* array[low:high:max] */
    | primary_expression LEFT_BRACKET optional_expression
      COLON expression
      COLON expression RIGHT_BRACKET

    /* x.(T) */
    | primary_expression type_assertion
;


/* ---------- Operand ---------- */

operand:
      literal

    | IDENTIFIER
    {
        delete $1;
    }

    | LEFT_PAREN expression RIGHT_PAREN
;

/* ---------- Operand ---------- */



/* ============================================================
   LITERALS
   ============================================================ */

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
      DECIMAL_LITERAL
    | BINARY_LITERAL
    | OCTAL_LITERAL
    | HEX_LITERAL
;


float_literal:
      FLOAT_LITERAL
    | HEX_FLOAT_LITERAL
;


imaginary_literal:
    IMAGINARY_LITERAL
;


rune_literal:
    RUNE_LITERAL
;


string_literal:
      STRING_LITERAL
    {
        delete $1;
    }

    | RAW_STRING_LITERAL
    {
        delete $1;
    }
;



/* ---------- Аргументы вызова ---------- */

arguments:
      LEFT_PAREN RIGHT_PAREN

    | LEFT_PAREN argument_list RIGHT_PAREN

    | LEFT_PAREN argument_list COMMA RIGHT_PAREN

    /* foo(args...) */
    | LEFT_PAREN argument_list ELLIPSIS RIGHT_PAREN

    | LEFT_PAREN argument_list ELLIPSIS COMMA RIGHT_PAREN
;

/* ---------- Argument list ---------- */

argument_list:
      expression
    | argument_list COMMA expression
;

/* ---------- Optional expression ---------- */

optional_expression:
      %empty
    | expression
;


/* ============================================================
   TYPE ASSERTION

   value.(Type)
   ============================================================ */

type_assertion:
    DOT LEFT_PAREN type RIGHT_PAREN
;


/* ============================================================
   COMPOSITE LITERAL

   Point{x: 10}
   []int{1, 2, 3}
   map[string]int{"a": 1}
   ============================================================ */

composite_literal:
    composite_literal_type literal_value
;

composite_literal_type:
      type_name
    | array_type
    | slice_type
    | map_type
    | struct_type

    /* [...]int{1, 2, 3} */
    | LEFT_BRACKET ELLIPSIS RIGHT_BRACKET type
;

literal_value:
      LEFT_BRACE RIGHT_BRACE
    | LEFT_BRACE literal_elements RIGHT_BRACE
    | LEFT_BRACE literal_elements COMMA RIGHT_BRACE
;

literal_elements:
      literal_element
    | literal_elements COMMA literal_element
;

literal_element:
      expression

    /* key: value / field: value */
    | expression COLON expression

    /* вложенный литерал без повторения типа:
       [][]int{{1, 2}, {3, 4}}
    */
    | literal_value

    | expression COLON literal_value
;


/* ============================================================
   FUNCTION LITERAL

   func(x int) int {
       return x
   }
   ============================================================ */

function_literal:
    KW_FUNC function_signature function_body
;


/* ============================================================
   IF
   ============================================================ */

if_statement:
      KW_IF expression block

    | KW_IF expression block KW_ELSE block

    | KW_IF expression block KW_ELSE if_statement

    | KW_IF simple_statement SEMICOLON expression block

    | KW_IF simple_statement SEMICOLON expression block KW_ELSE block

    | KW_IF simple_statement SEMICOLON expression block KW_ELSE if_statement
;


/* ============================================================
   FOR
   ============================================================ */

for_statement:
      KW_FOR block

    | KW_FOR expression block

    | KW_FOR for_clause block

    | KW_FOR range_clause block
;

/* ---------- Optional simple statement ---------- */

optional_simple_statement:
      %empty
    | simple_statement
;

/* ---------- Классический for ---------- */

for_clause:
    optional_simple_statement
    SEMICOLON
    optional_expression
    SEMICOLON
    optional_simple_statement
;


/* ---------- Range ---------- */

range_clause:
      KW_RANGE expression

    | expression_list ASSIGN KW_RANGE expression

    | identifier_list DECLARE_ASSIGN KW_RANGE expression
;


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