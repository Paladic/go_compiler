%code requires {
    #include "SourceRange.h"
    #include <string>
	
    #define YYLTYPE_IS_TRIVIAL 1
    #define YYLLOC_DEFAULT(Current, Rhs, N) \
        MergeSourceRange(Current, YYRHSLOC(Rhs, (N) ? 1 : 0), \
                         YYRHSLOC(Rhs, N), YYRHSLOC(Rhs, 0), N)
}

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

%union {
    long long integerValue;
    const std::string* stringValue;
}

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
%token BODY_BRACE
%token LEXICAL_ERROR

%precedence NAME_END EMPTY_SIGNATURE CHAN_BARE
%precedence LEFT_PAREN

%left LOGICAL_OR
%left LOGICAL_AND
%left EQUAL NOT_EQUAL LESS LESS_EQUAL GREATER GREATER_EQUAL
%left PLUS MINUS BIT_OR BIT_XOR
%left MULTIPLY DIVIDE MODULO LEFT_SHIFT RIGHT_SHIFT BIT_AND BIT_CLEAR
%precedence IDENTIFIER KW_FUNC KW_INTERFACE KW_MAP KW_STRUCT KW_CHAN

%left LEFT_BRACKET DOT
%precedence CHANNEL_ARROW

%start program

%%

program: KW_PACKAGE identifier ";" imports declarations;

imports: %empty
       | imports import_declaration ";";

import_declaration: KW_IMPORT import_spec
                  | KW_IMPORT "(" import_spec_list ")";

import_spec_list: %empty
                | import_spec ";" import_spec_list
                | import_spec;

import_spec: string_literal
           | "." string_literal
           | identifier string_literal;

declarations: %empty
            | declarations declaration ";"
            | declarations function_declaration ";"
            | declarations method_declaration ";";

declaration: KW_VAR variable_spec
           | KW_VAR "(" variable_spec_list ")"
           | KW_CONST initialized_constant_spec
           | KW_CONST "(" constant_spec_list ")"
           | KW_TYPE type_spec
           | KW_TYPE "(" type_spec_list ")";

variable_spec_list: %empty
                  | variable_spec ";" variable_spec_list
                  | variable_spec;

variable_spec: identifier_list type
             | identifier_list type "=" expression_list
             | identifier_list "=" expression_list;

constant_spec_list: %empty
                  | initialized_constant_spec constant_spec_list_tail;

constant_spec_list_tail: %empty
                       | ";"
                       | ";" constant_spec constant_spec_list_tail;

constant_spec: initialized_constant_spec
             | identifier_list;

initialized_constant_spec: identifier_list type "=" expression_list
                         | identifier_list "=" expression_list;

type_spec_list: %empty
              | type_spec ";" type_spec_list
              | type_spec;

type_spec: identifier type
         | identifier "=" type
         | identifier type_arguments "=" type;

type: type_name
    | pointer_type
    | non_name_type
    | "(" type ")";

type_name: identifier %prec NAME_END
         | identifier "." identifier
         | identifier type_arguments
         | identifier "." identifier type_arguments;

non_name_type: array_type
             | map_type
             | struct_type
             | interface_type
             | function_type
             | channel_type;

non_expression_type: non_name_type
                   | "*" non_expression_type
                   | "(" non_expression_type ")";

array_type: bracket_group type;

pointer_type: "*" type;

map_type: KW_MAP "[" type "]" type;

struct_type: KW_STRUCT block_open field_declarations "}";

field_declarations: %empty
                  | field_declaration ";" field_declarations
                  | field_declaration;

field_declaration: identifier array_type optional_struct_tag
                 | identifier_list type optional_struct_tag
                 | embedded_field optional_struct_tag;

embedded_field: type_name
              | "*" type_name;

optional_struct_tag: %empty
                   | string_literal;

interface_type: KW_INTERFACE "{" interface_elements "}";

interface_elements: %empty
                  | interface_element ";" interface_elements
                  | interface_element;

interface_element: identifier function_signature
                 | type_terms;

function_type: KW_FUNC function_signature;

channel_type: chan_prefix type
            | "<-" KW_CHAN type;

chan_prefix: KW_CHAN %prec CHAN_BARE
           | KW_CHAN "<-";

type_parameters: "[" identifier type_parameter_after_name "]";

type_parameter_after_name: type_terms type_parameter_after_constraint
                         | "," identifier type_parameter_after_name;

type_parameter_after_constraint: %empty
                               | ","
                               | "," identifier type_parameter_after_name;

type_terms: type_term
          | type_terms "|" type_term;

type_term: type
         | "~" type;

type_terms_tail: %empty
               | "|" type_terms;

function_declaration: KW_FUNC identifier function_signature block
                    | KW_FUNC identifier function_signature
                    | KW_FUNC identifier type_parameters function_signature block;

method_declaration: KW_FUNC receiver identifier function_signature block
                  | KW_FUNC receiver identifier function_signature
                  | KW_FUNC receiver identifier type_parameters function_signature block
                  | KW_FUNC receiver identifier type_parameters function_signature;

receiver: "(" receiver_type optional_trailing_comma ")"
        | "(" identifier receiver_type optional_trailing_comma ")";

receiver_type: receiver_name
             | "*" receiver_base_type
             | "(" receiver_type ")";

receiver_base_type: receiver_name
                  | "(" receiver_base_type ")";

receiver_name: identifier %prec NAME_END
             | identifier "[" identifier_list optional_trailing_comma "]";

function_signature: parameters %prec EMPTY_SIGNATURE
                  | parameters result;

parameters: "(" ")"
          | "(" parameter_list ")";

parameter_list: parameter_item optional_trailing_comma
              | parameter_item "," parameter_list
              | variadic_parameter optional_trailing_comma;

parameter_item: type
              | identifier type;

variadic_parameter: identifier "..." type
                  | "..." type;

result: type_name
      | pointer_type
      | non_name_type
      | result_parameters;

result_parameters: "(" ")"
                 | "(" result_parameter_list optional_trailing_comma ")";

result_parameter_list: parameter_item
                     | result_parameter_list "," parameter_item;

expression: unary_expression
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
          | expression "&^" expression;

unary_expression: primary_expression
                | "+" unary_expression
                | "-" unary_expression
                | "!" unary_expression
                | "^" unary_expression
                | "*" unary_expression
                | "&" unary_expression
                | "<-" unary_expression;

primary_expression: literal
                  | identifier
                  | "(" expression ")"
                  | primary_expression "." identifier
                  | primary_expression arguments
                  | primary_expression "[" optional_expression ":" optional_expression "]"
                  | primary_expression "[" optional_expression ":" expression ":" expression "]"
                  | primary_expression "." "(" type ")"
                  | non_name_type "." identifier
                  | "(" non_expression_type ")" arguments
                  | "(" non_expression_type ")" "." identifier
                  | primary_expression type_arguments
                  | non_name_type "(" expression optional_trailing_comma ")"
                  | primary_expression literal_value;

literal: DECIMAL_LITERAL {}
       | BINARY_LITERAL {}
       | OCTAL_LITERAL {}
       | HEX_LITERAL {}
       | FLOAT_LITERAL {}
       | HEX_FLOAT_LITERAL {}
       | IMAGINARY_LITERAL {}
       | RUNE_LITERAL {}
       | string_literal
       | composite_literal
       | KW_FUNC function_signature block;

string_literal: STRING_LITERAL {}
              | RAW_STRING_LITERAL {};

arguments: "(" ")"
         | "(" expression argument_tail ")"
         | "(" non_expression_type argument_tail ")";

argument_tail: %empty
             | ","
             | "..."
             | "..." ","
             | "," expression argument_tail;

composite_literal: composite_literal_type block_open optional_literal_elements "}";

composite_literal_type: array_type
                      | map_type
                      | struct_type
                      | "[" "..." "]" type;

literal_value: "{" optional_literal_elements "}";

optional_literal_elements: %empty
                         | literal_elements optional_trailing_comma;

literal_elements: literal_element
                | literal_elements "," literal_element;

literal_element: literal_element_value
               | literal_element_value ":" literal_element_value;

literal_element_value: expression
                     | literal_value;

if_statement: KW_IF expression loop_body optional_else
            | KW_IF optional_simple_statement ";" expression loop_body optional_else;

optional_else: %empty
             | KW_ELSE block
             | KW_ELSE if_statement;

for_statement: KW_FOR loop_body
             | KW_FOR expression loop_body
             | KW_FOR for_clause loop_body
             | KW_FOR range_clause loop_body;

for_clause: optional_simple_statement ";" optional_expression ";" optional_post_statement;

range_clause: KW_RANGE expression
            | expression_list "=" KW_RANGE expression
            | expression_list ":=" KW_RANGE expression;

switch_statement: KW_SWITCH expression_switch_header BODY_BRACE expression_cases "}"
                | KW_SWITCH type_switch_guard BODY_BRACE type_cases "}"
                | KW_SWITCH simple_statement ";" type_switch_guard BODY_BRACE type_cases "}";

expression_switch_header: %empty
                        | expression
                        | simple_statement ";" optional_expression
                        | ";" optional_expression;

expression_cases: %empty
                | expression_case_label expression_case_content;

expression_case_label: KW_CASE expression_list ":"
                     | KW_DEFAULT ":";

expression_case_content: %empty
                       | ";" expression_case_content
                       | statement ";" expression_case_content
                       | statement
                       | expression_case_label expression_case_content;

type_switch_guard: primary_expression "." "(" KW_TYPE ")"
                 | expression_list ":=" primary_expression "." "(" KW_TYPE ")";

type_cases: %empty
          | type_case_label type_case_content;

type_case_label: KW_CASE type_case_list ":"
               | KW_DEFAULT ":";

type_case_content: %empty
                 | ";" type_case_content
                 | statement ";" type_case_content
                 | statement
                 | type_case_label type_case_content;

type_case_list: type
              | type_case_list "," type;

select_statement: KW_SELECT BODY_BRACE select_cases "}";

select_cases: %empty
            | select_case_label select_case_content;

select_case_label: KW_CASE communication_clause ":"
                 | KW_DEFAULT ":";

select_case_content: %empty
                   | ";" select_case_content
                   | statement ";" select_case_content
                   | statement
                   | select_case_label select_case_content;

communication_clause: send_statement
                    | expression
                    | expression_list "=" expression
                    | expression_list ":=" expression;

send_statement: expression "<-" expression;

block: block_open statement_list "}";

block_open: "{"
          | BODY_BRACE { LexerSupport::ResumeHeader(); };

loop_body: BODY_BRACE statement_list "}";

statement_list: %empty
              | ";" statement_list
              | statement ";" statement_list
              | statement;

statement: declaration
         | simple_statement
         | KW_RETURN
         | KW_RETURN expression_list
         | KW_BREAK
         | KW_BREAK identifier
         | KW_CONTINUE
         | KW_CONTINUE identifier
         | KW_GOTO identifier
         | KW_FALLTHROUGH
         | labeled_statement
         | KW_DEFER primary_expression arguments
         | KW_GO primary_expression arguments
         | block
         | if_statement
         | for_statement
         | switch_statement
         | select_statement;

simple_statement: post_statement
                | expression_list ":=" expression_list;

optional_simple_statement: %empty
                         | simple_statement;

post_statement: expression
              | send_statement
              | expression "++"
              | expression "--"
              | assignment;

optional_post_statement: %empty
                       | post_statement;

assignment: expression_list "=" expression_list
          | expression "+=" expression
          | expression "-=" expression
          | expression "*=" expression
          | expression "/=" expression
          | expression "%=" expression
          | expression "&=" expression
          | expression "|=" expression
          | expression "^=" expression
          | expression "&^=" expression
          | expression "<<=" expression
          | expression ">>=" expression;

labeled_statement: identifier ":" statement
                 | identifier ":";

identifier: IDENTIFIER {};

identifier_list: identifier %prec NAME_END
               | identifier_list "," identifier;

expression_list: expression
               | expression_list "," expression;

bracket_arguments: bracket_item
                 | bracket_arguments "," bracket_item;

bracket_item: expression
            | non_expression_type
            | primary_expression type_name type_terms_tail
            | primary_expression "[" "]" type type_terms_tail
            | primary_expression map_type type_terms_tail
            | primary_expression struct_type type_terms_tail
            | primary_expression interface_type type_terms_tail
            | primary_expression function_type type_terms_tail
            | primary_expression channel_type type_terms_tail
            | identifier "~" type type_terms_tail
            | expression "*" non_expression_type type_terms_tail
            | expression "|" "~" type type_terms_tail
            | expression "|" non_expression_type type_terms_tail;

bracket_group: "[" "]"
             | type_arguments %prec NAME_END;

type_arguments: "[" bracket_arguments "]"
              | "[" bracket_arguments "," "]";

optional_expression: %empty
                   | expression;

optional_trailing_comma: %empty
                       | ",";

%%

void yyerror(const char* message) {
    if (!LexerSupport::failed) LexerSupport::Error(yylloc, message);
}
