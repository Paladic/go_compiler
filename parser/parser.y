%code requires {
    #include <string>
    #include <vector>

    // Временные объявление типов узлов дерева для компилятора
    class ASTNode;
}

%define lr.type canonical-lr
%define parse.trace

%{
#include <string>
#include <vector>

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

    std::vector<std::string>* stringVector;
    ASTNode* astNode;
    std::vector<ASTNode*>* nodeVector;
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
/* ---------- Привязка типов к нетерминалам ---------- */

/* Для векторов строк */
%type <stringVector> identifier_list

/* Для векторов AST-узлов */
%type <nodeVector> expression_list
%type <nodeVector> statement_list
%type <nodeVector> declarations
%type <nodeVector> imports

/* Для одиночных AST-узлов */
%type <astNode> expression
%type <astNode> statement
%type <astNode> simple_statement
%type <astNode> block
%type <astNode> declaration
%type <astNode> variable_declaration
%type <astNode> constant_declaration
%type <astNode> type_declaration
%type <astNode> function_declaration
%type <astNode> method_declaration

%type <astNode> declaration_statement
%type <astNode> expression_statement
%type <astNode> increment_statement
%type <astNode> decrement_statement
%type <astNode> assignment
%type <astNode> short_variable_declaration
%type <astNode> return_statement
%type <astNode> break_statement
%type <astNode> continue_statement
%type <astNode> goto_statement
%type <astNode> fallthrough_statement
%type <astNode> labeled_statement
%type <astNode> defer_statement
%type <astNode> go_statement

/* очищаем строковые значения, если они удаляются */
%destructor {
    delete $$;
} <stringValue>

%destructor {
    delete $$;
} <stringVector>

/* корневой элемент дерева */
%start program

%%
/* ---------- Корень программы ---------- */

program:
    package_clause SEMICOLON imports declarations
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


imports:
    /* empty */
    {
        $$ = new std::vector<ASTNode*>();
    }
  | imports import_declaration SEMICOLON
    {
        $$ = $1;
    }
;



/* ---------- Import declaration ---------- */

import_declaration:
    KW_IMPORT import_spec
  | KW_IMPORT LEFT_PAREN import_spec_list RIGHT_PAREN
;


/* ---------- Один import ---------- */

import_spec_list:
    /* empty */
  | import_spec_list import_spec SEMICOLON
;

import_spec:
    STRING_LITERAL
    {
        ParserLogger::Value("import", *$1);
        delete $1;
    }
  | RAW_STRING_LITERAL
    {
        ParserLogger::Value("import", *$1);
        delete $1;
    }
  | DOT STRING_LITERAL
    {
        delete $2;
    }
  | IDENTIFIER STRING_LITERAL
    {
        delete $1;
        delete $2;
    }
;


/* ---------- Группа import ---------- */

/*
import_group:
    TODO
;
*/


/* ============================================================
   DECLARATIONS
   ============================================================ */


declarations:
    /* empty */
    {
        $$ = new std::vector<ASTNode*>();
    }
  | declarations declaration SEMICOLON
    {
        if ($2) $1->push_back($2);
        $$ = $1;
    }
  | declarations function_declaration SEMICOLON
    {
        if ($2) $1->push_back($2);
        $$ = $1;
    }
  | declarations method_declaration SEMICOLON
    {
        if ($2) $1->push_back($2);
        $$ = $1;
    }
  | declarations error SEMICOLON
    {
        yyerrok;
        $$ = $1;
    }
;



/* ---------- Общее declaration ---------- */


declaration:
    variable_declaration
  | constant_declaration
  | type_declaration
;



/* ============================================================
   VARIABLES
   ============================================================ */


variable_declaration:
    KW_VAR variable_spec
    {
        $$ = nullptr;
    }
  | KW_VAR LEFT_PAREN variable_spec_list RIGHT_PAREN
    {
        $$ = nullptr;
    }
;



/* ---------- Один var spec ---------- */

variable_spec_list:
    /* empty */
  | variable_spec_list variable_spec SEMICOLON
;

variable_spec:
    identifier_list type
    {
        delete $1;
    }
  | identifier_list type ASSIGN expression_list
    {
        delete $1;
        delete $4;
    }
  | identifier_list ASSIGN expression_list
    {
        delete $1;
        delete $3;
    }
;


/* ---------- Группа var ---------- */

/*
variable_group:
    TODO
;
*/


/* ============================================================
   CONSTANTS
   ============================================================ */

constant_declaration:
    KW_CONST constant_spec
    {
        $$ = nullptr;
    }
  | KW_CONST LEFT_PAREN constant_spec_list RIGHT_PAREN
    {
        $$ = nullptr;
    }
;


/* ---------- Один const spec ---------- */

constant_spec_list:
    /* empty */
  | constant_spec_list constant_spec SEMICOLON
;

constant_spec:
    identifier_list
    {
        delete $1;
    }
  | identifier_list type ASSIGN expression_list
    {
        delete $1;
        delete $4;
    }
  | identifier_list ASSIGN expression_list
    {
        delete $1;
        delete $3;
    }
;


/* ---------- Группа const ---------- */

/*
constant_group:
    TODO
;
*/


/* ============================================================
   TYPE DECLARATION
   ============================================================ */

type_declaration:
    KW_TYPE type_spec
    {
        $$ = nullptr;
    }
  | KW_TYPE LEFT_PAREN type_spec_list RIGHT_PAREN
    {
        $$ = nullptr;
    }
;


/* ---------- Один type spec ---------- */

type_spec_list:
    /* empty */
  | type_spec_list type_spec SEMICOLON
;

type_spec:
    IDENTIFIER type
    {
        delete $1;
    }
  | IDENTIFIER ASSIGN type
    {
        delete $1;
    }
;


/* ============================================================
   TYPES
   ============================================================ */


/* ---------- Общий тип ---------- */

type:
    type_name
  | pointer_type
  | array_type
  | slice_type
  | map_type
  | struct_type
  | interface_type
  | function_type
  | channel_type
;


/* ---------- Имя типа ---------- */

type_name:
    IDENTIFIER
    {
        delete $1;
    }
;


/* ============================================================
   ARRAY TYPE

   [10]int
   ============================================================ */

array_type:
    LEFT_BRACKET expression RIGHT_BRACKET type
;


/* ============================================================
   SLICE TYPE

   []int
   ============================================================ */

slice_type:
    LEFT_BRACKET RIGHT_BRACKET type
;


/* ============================================================
   POINTER TYPE

   *int
   ============================================================ */

pointer_type:
    MULTIPLY type
;


/* ============================================================
   MAP TYPE

   map[string]int
   ============================================================ */

map_type:
    KW_MAP LEFT_BRACKET type RIGHT_BRACKET type
;


/* ============================================================
   STRUCT TYPE
   ============================================================ */

struct_type:
    KW_STRUCT LEFT_BRACE field_declarations RIGHT_BRACE
;


/* ---------- Поля struct ---------- */

field_declarations:
    /* empty */
  | field_declarations field_declaration SEMICOLON
;


/* ---------- Одно поле ---------- */

field_declaration:
    identifier_list type
    {
        delete $1;
    }
  | type
;


/* ============================================================
   INTERFACE TYPE
   ============================================================ */

interface_type:
    KW_INTERFACE LEFT_BRACE interface_elements RIGHT_BRACE
;


/* ---------- Список элементов interface ---------- */

interface_elements:
    /* empty */
  | interface_elements interface_element SEMICOLON
;


/* ---------- Один элемент interface ---------- */

interface_element:
    IDENTIFIER function_signature
    {
        delete $1;
    }
  | type_name
;


/* ============================================================
   FUNCTION TYPE
   ============================================================ */

function_type:
    KW_FUNC function_signature
;


/* ============================================================
   CHANNEL TYPE

   chan int
   <-chan int
   chan<- int
   ============================================================ */

channel_type:
    KW_CHAN type
  | CHANNEL_ARROW KW_CHAN type
  | KW_CHAN CHANNEL_ARROW type
;


/* ============================================================
   FUNCTIONS
   ============================================================ */


/* ---------- Function declaration ---------- */

function_declaration:
    KW_FUNC IDENTIFIER function_signature function_body
    {
        ParserLogger::Value("func", *$2);
        delete $2;
        $$ = nullptr;
    }
  | KW_FUNC IDENTIFIER function_signature
    {
        ParserLogger::Value("func signature", *$2);
        delete $2;
        $$ = nullptr;
    }
;


/* ---------- Имя функции ---------- */

/*
function_name:
    TODO
;
*/


/* ---------- Сигнатура ---------- */

function_signature:
    parameters
  | parameters result
;


/* ---------- Параметры ---------- */

parameters:
    LEFT_PAREN RIGHT_PAREN
  | LEFT_PAREN parameter_list RIGHT_PAREN
  | LEFT_PAREN parameter_list COMMA RIGHT_PAREN
;


/* ---------- Список параметров ---------- */

parameter_list:
    parameter
  | parameter_list COMMA parameter
;


/* ---------- Один параметр ---------- */

parameter:
    identifier_list type
    {
        delete $1;
    }
  | identifier_list ELLIPSIS type
    {
        delete $1;
    }
  | type
;


/* ---------- Возвращаемое значение ---------- */

result:
    type
  | parameters
;


/* ---------- Тело функции ---------- */

function_body:
    block
;


/* ============================================================
   METHODS
   ============================================================ */

method_declaration:
    KW_FUNC receiver IDENTIFIER function_signature function_body
    {
        ParserLogger::Value("method", *$3);
        delete $3;
        $$ = nullptr;
    }
  | KW_FUNC receiver IDENTIFIER function_signature
    {
        ParserLogger::Value("method signature", *$3);
        delete $3;
        $$ = nullptr;
    }
;


/* ---------- Receiver ---------- */

receiver:
    parameters
;


/* ============================================================
   BLOCK

   {
       ...
   }
   ============================================================ */

block:
    LEFT_BRACE statement_list RIGHT_BRACE
    {
        delete $2;
        $$ = nullptr;
    }
;


/* ============================================================
   STATEMENT LIST

   Набор инструкций внутри block.
   ============================================================ */

statement_list:
    /* empty */
    {
        $$ = new std::vector<ASTNode*>();
    }
  | statement_list statement SEMICOLON
    {
        if ($2) $1->push_back($2);
        $$ = $1;
    }
  | statement_list error SEMICOLON
    {
        yyerrok;
        $$ = $1;
    }
;

/* ============================================================
   ОБЩИЙ STATEMENT

   Главная точка входа для любой инструкции.
   ============================================================ */

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
  | empty_statement
;


/* ============================================================
   DECLARATION STATEMENT

   var / const / type внутри блока
   ============================================================ */

declaration_statement:
    declaration
;


/* ============================================================
   SIMPLE STATEMENT

   assignment
   :=
   ++
   --
   expression statement
   send
   ============================================================ */

simple_statement:
    expression_statement
  | increment_statement
  | decrement_statement
  | assignment
  | short_variable_declaration
;


/* ============================================================
   EXPRESSION STATEMENT
   ============================================================ */

expression_statement:
    expression
;


/* ============================================================
   ASSIGNMENT

   x = y
   x += y
   x <<= y
   ============================================================ */

assignment:
    expression_list assignment_operator expression_list
    {
        delete $1;
        delete $3;
        $$ = nullptr;
    }
;

/* ---------- Оператор присваивания ---------- */

assignment_operator:
    ASSIGN
  | PLUS_ASSIGN
  | MINUS_ASSIGN
  | MULTIPLY_ASSIGN
  | DIVIDE_ASSIGN
  | MODULO_ASSIGN
  | BIT_AND_ASSIGN
  | BIT_OR_ASSIGN
  | BIT_XOR_ASSIGN
  | LEFT_SHIFT_ASSIGN
  | RIGHT_SHIFT_ASSIGN
  | BIT_CLEAR_ASSIGN
;


/* ============================================================
   SHORT VARIABLE DECLARATION

   x := 10
   x, y := 10, 20
   ============================================================ */

short_variable_declaration:
    identifier_list DECLARE_ASSIGN expression_list
    {
        delete $1;
        delete $3;
        $$ = nullptr;
    }
;


/* ============================================================
   INCREMENT

   x++
   ============================================================ */

increment_statement:
    expression INCREMENT
    {
        $$ = nullptr;
    }
;


/* ============================================================
   DECREMENT

   x--
   ============================================================ */

decrement_statement:
    expression DECREMENT
    {
        $$ = nullptr;
    }
;


/* ============================================================
   RETURN
   ============================================================ */

return_statement:
    KW_RETURN
    {
        $$ = nullptr;
    }
  | KW_RETURN expression_list
    {
        delete $2;
        $$ = nullptr;
    }
;


/* ============================================================
   BREAK
   ============================================================ */

break_statement:
    KW_BREAK
    {
        $$ = nullptr;
    }
  | KW_BREAK IDENTIFIER
    {
        delete $2;
        $$ = nullptr;
    }
;


/* ============================================================
   CONTINUE
   ============================================================ */

continue_statement:
    KW_CONTINUE
    {
        $$ = nullptr;
    }
  | KW_CONTINUE IDENTIFIER
    {
        delete $2;
        $$ = nullptr;
    }
;


/* ============================================================
   GOTO
   ============================================================ */

goto_statement:
    KW_GOTO IDENTIFIER
    {
        delete $2;
        $$ = nullptr;
    }
;


/* ============================================================
   FALLTHROUGH
   ============================================================ */

fallthrough_statement:
    KW_FALLTHROUGH
    {
        $$ = nullptr;
    }
;


/* ============================================================
   LABEL

   start:
   ============================================================ */

labeled_statement:
    IDENTIFIER COLON statement
    {
        delete $1;
        $$ = nullptr;
    }
;


/* ============================================================
   DEFER

   defer foo()
   ============================================================ */

defer_statement:
    KW_DEFER expression
    {
        $$ = nullptr;
    }
;

/* ============================================================
   GO

   go foo()
   ============================================================ */

go_statement:
    KW_GO expression
    {
        $$ = nullptr;
    }
;


/* ============================================================
   IDENTIFIER LIST

   x
   x, y
   x, y, z
   ============================================================ */

identifier_list:
    IDENTIFIER
    {
        $$ = new std::vector<std::string>();
        $$->push_back(*$1);
        delete $1;
    }
  | identifier_list COMMA IDENTIFIER
    {
        $1->push_back(*$3);
        delete $3;
        $$ = $1;
    }
;


/* ============================================================
   EXPRESSION LIST

   x
   x, y
   x + 10, foo()
   ============================================================ */

expression_list:
    expression
    {
        $$ = new std::vector<ASTNode*>();
        if ($1) $$->push_back($1);
    }
  | expression_list COMMA expression
    {
        if ($3) $1->push_back($3);
        $$ = $1;
    }
;


/* ============================================================
   EMPTY STATEMENT
   ============================================================ */

empty_statement:
    /* empty */
;


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