/* Go 1.27, LALR(1). Действия вызывают конструкторы AST. */
%code requires {
    #include "SourceRange.h"
    struct AstNode;
    struct AstList;
    struct AstCases;
    #include <string>

    // Координаты допускают перемещение вместе со стеком LR.
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
    #include "ast/AstBuilder.h"

    using K = AstKind;

    int yylex();
    void yyerror(const char* message);
}

%union {
    long long integerValue;
    const std::string* stringValue;
    AstNode* node;
    AstList* list;
    AstCases* cases;
    const char* direction;
}

/* Литералы и имена: значения сохраняются лексером. */
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

/* Операторы и разделители */
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

/* Служебные приоритеты общих префиксов. */
%precedence NAME_END EMPTY_SIGNATURE CHAN_BARE
%precedence LEFT_PAREN
/* Пять уровней бинарных операторов Go: от меньшего к большему. */
%left LOGICAL_OR
%left LOGICAL_AND
%left EQUAL NOT_EQUAL LESS LESS_EQUAL GREATER GREATER_EQUAL
%left PLUS MINUS BIT_OR BIT_XOR
%left MULTIPLY DIVIDE MODULO LEFT_SHIFT RIGHT_SHIFT BIT_AND BIT_CLEAR
%precedence IDENTIFIER KW_FUNC KW_INTERFACE KW_MAP KW_STRUCT KW_CHAN
/* Цепочки a.b[i].c слева направо; nonassoc здесь не используется. */
%left LEFT_BRACKET DOT
%precedence CHANNEL_ARROW
/* Значения нетерминалов */
%type <node> import_declaration import_spec declaration variable_spec constant_spec
%type <node> initialized_constant_spec type_spec type type_name non_name_type non_expression_type
%type <node> array_type pointer_type map_type struct_type field_declaration embedded_field
%type <node> optional_struct_tag interface_type interface_element function_type channel_type
%type <node> type_parameters type_terms type_term type_terms_tail function_declaration method_declaration
%type <node> receiver receiver_type receiver_base_type receiver_name function_signature parameters
%type <node> parameter_item variadic_parameter result result_parameters expression unary_expression
%type <node> primary_expression literal string_literal arguments composite_literal composite_literal_type
%type <node> literal_value literal_element literal_element_value if_statement optional_else for_statement
%type <node> for_clause range_clause switch_statement expression_case_label type_case_label
%type <node> select_case_label type_switch_guard type_case_list select_statement communication_clause
%type <node> send_statement block loop_body statement simple_statement optional_simple_statement
%type <node> post_statement optional_post_statement assignment labeled_statement identifier
%type <node> identifier_list expression_list bracket_item bracket_group type_arguments optional_expression
%type <list> imports import_spec_list declarations variable_spec_list constant_spec_list
%type <list> constant_spec_list_tail type_spec_list field_declarations interface_elements
%type <list> type_parameter_after_name type_parameter_after_constraint parameter_list
%type <list> result_parameter_list argument_tail optional_literal_elements literal_elements
%type <list> expression_switch_header statement_list bracket_arguments
%type <cases> expression_cases expression_case_content type_cases type_case_content select_cases
%type <cases> select_case_content
%type <direction> chan_prefix
%start program

%%

/* Файл и объявления */
program: KW_PACKAGE identifier ";" imports declarations
         { Ast::SetRoot(Ast::File(@$, Ast::Node(K::Package, Ast::Span(@1, @2), {$2}), $4, $5)); };

imports: %empty { $$ = Ast::List(); }
       | imports import_declaration ";" { $$ = Ast::Append($1, $2); };

import_declaration: KW_IMPORT import_spec { $$ = Ast::Node(K::Import, @$, {$2}); }
                  | KW_IMPORT "(" import_spec_list ")" { $$ = Ast::Group(K::Import, @$, $3); };

import_spec_list: %empty { $$ = Ast::List(); }
                | import_spec ";" import_spec_list { $$ = Ast::Prepend($1, $3); }
                | import_spec { $$ = Ast::List($1); };

import_spec: string_literal { $$ = Ast::Node(K::ImportSpec, @$, {$1}); }
           | "." string_literal { $$ = Ast::Node(K::DotImport, @$, {$2}); }
           | identifier string_literal { $$ = Ast::Node(K::ImportSpec, @$, {$1, $2}); };

declarations: %empty { $$ = Ast::List(); }
            | declarations declaration ";" { $$ = Ast::Append($1, $2); }
            | declarations function_declaration ";" { $$ = Ast::Append($1, $2); }
            | declarations method_declaration ";" { $$ = Ast::Append($1, $2); };

declaration: KW_VAR variable_spec { $$ = Ast::Node(K::VarDeclaration, @$, {$2}); }
           | KW_VAR "(" variable_spec_list ")" { $$ = Ast::Group(K::VarDeclaration, @$, $3); }
           | KW_CONST initialized_constant_spec { $$ = Ast::Node(K::ConstDeclaration, @$, {$2}); }
           | KW_CONST "(" constant_spec_list ")" { $$ = Ast::Group(K::ConstDeclaration, @$, $3); }
           | KW_TYPE type_spec { $$ = Ast::Node(K::TypeDeclaration, @$, {$2}); }
           | KW_TYPE "(" type_spec_list ")" { $$ = Ast::Group(K::TypeDeclaration, @$, $3); };

variable_spec_list: %empty { $$ = Ast::List(); }
                  | variable_spec ";" variable_spec_list { $$ = Ast::Prepend($1, $3); }
                  | variable_spec { $$ = Ast::List($1); };

variable_spec: identifier_list type { $$ = Ast::Node(K::VarSpec, @$, {$1, $2}); }
             | identifier_list type "=" expression_list { $$ = Ast::Node(K::VarSpec, @$, {$1, $2, $4}); }
             | identifier_list "=" expression_list { $$ = Ast::Node(K::VarSpec, @$, {$1, $3}); };

constant_spec_list: %empty { $$ = Ast::List(); }
                  | initialized_constant_spec constant_spec_list_tail { $$ = Ast::Prepend($1, $2); };

constant_spec_list_tail: %empty { $$ = Ast::List(); }
                       | ";" { $$ = Ast::List(); }
                       | ";" constant_spec constant_spec_list_tail { $$ = Ast::Prepend($2, $3); };

constant_spec: initialized_constant_spec
             | identifier_list { $$ = Ast::Node(K::ConstSpec, @$, {$1}); };

initialized_constant_spec: identifier_list type "=" expression_list { $$ = Ast::Node(K::ConstSpec, @$, {$1, $2, $4}); }
                         | identifier_list "=" expression_list { $$ = Ast::Node(K::ConstSpec, @$, {$1, $3}); };

type_spec_list: %empty { $$ = Ast::List(); }
              | type_spec ";" type_spec_list { $$ = Ast::Prepend($1, $3); }
              | type_spec { $$ = Ast::List($1); };

type_spec: identifier type { $$ = Ast::Node(K::TypeSpec, @$, {$1, $2}); }
         | identifier "=" type { $$ = Ast::Node(K::TypeAlias, @$, {$1, $3}); }
         | identifier type_arguments "=" type { $$ = Ast::Node(K::TypeAlias, @$, {$1, $2, $4}); };

/* Типы */
type: type_name
    | pointer_type
    | non_name_type
    | "(" type ")" { $$ = Ast::Node(K::Parenthesized, @$, {$2}); };

type_name: identifier %prec NAME_END { $$ = Ast::Node(K::NamedType, @$, {$1}); }
         | identifier "." identifier { $$ = Ast::Node(K::NamedType, @$, {Ast::Node(K::Selector, @$, {$1, $3})}); }
         | identifier type_arguments { $$ = Ast::Node(K::NamedType, @$, {$1, $2}); }
         | identifier "." identifier type_arguments { $$ = Ast::Node(K::NamedType, @$, {Ast::Node(K::Selector, Ast::Span(@1, @3), {$1, $3}), $4}); };

non_name_type: array_type
             | map_type
             | struct_type
             | interface_type
             | function_type
             | channel_type;

non_expression_type: non_name_type
                   | "*" non_expression_type { $$ = Ast::Node(K::PointerType, @$, {$2}); }
                   | "(" non_expression_type ")" { $$ = Ast::Node(K::Parenthesized, @$, {$2}); };

array_type: bracket_group type { $$ = Ast::Node(K::ArrayType, @$, {$1, $2}); };

pointer_type: "*" type { $$ = Ast::Node(K::PointerType, @$, {$2}); };

map_type: KW_MAP "[" type "]" type { $$ = Ast::Node(K::MapType, @$, {$3, $5}); };

struct_type: KW_STRUCT block_open field_declarations "}" { $$ = Ast::Group(K::StructType, @$, $3); };

field_declarations: %empty { $$ = Ast::List(); }
                  | field_declaration ";" field_declarations { $$ = Ast::Prepend($1, $3); }
                  | field_declaration { $$ = Ast::List($1); };

field_declaration: identifier array_type optional_struct_tag { $$ = Ast::Node(K::Field, @$, {Ast::Node(K::Names, @1, {$1}), $2, $3}); }
                 | identifier_list type optional_struct_tag { $$ = Ast::Node(K::Field, @$, {$1, $2, $3}); }
                 | embedded_field optional_struct_tag { $$ = Ast::Node(K::EmbeddedField, @$, {$1, $2}); };

embedded_field: type_name
              | "*" type_name { $$ = Ast::Node(K::PointerType, @$, {$2}); };

optional_struct_tag: %empty { $$ = nullptr; }
                   | string_literal { $$ = Ast::Node(K::StructTag, @$, {$1}); };

interface_type: KW_INTERFACE "{" interface_elements "}" { $$ = Ast::Group(K::InterfaceType, @$, $3); };

interface_elements: %empty { $$ = Ast::List(); }
                  | interface_element ";" interface_elements { $$ = Ast::Prepend($1, $3); }
                  | interface_element { $$ = Ast::List($1); };

interface_element: identifier function_signature { $$ = Ast::Node(K::InterfaceMethod, @$, {$1, $2}); }
                 | type_terms { $$ = $1; };

function_type: KW_FUNC function_signature { $$ = Ast::Node(K::FunctionType, @$, {$2}); };

channel_type: chan_prefix type { $$ = Ast::Node(K::ChannelType, @$, {$2}, $1); }
            | "<-" KW_CHAN type { $$ = Ast::Node(K::ChannelType, @$, {$3}, "<-chan"); };

chan_prefix: KW_CHAN %prec CHAN_BARE { $$ = "chan"; }
           | KW_CHAN "<-" { $$ = "chan<-"; };

/* Параметры типов */
type_parameters: "[" identifier type_parameter_after_name "]" { $$ = Ast::Group(K::TypeParameters, @$, Ast::NameParameter($2, $3)); };

type_parameter_after_name: type_terms type_parameter_after_constraint { $$ = Ast::ParameterTail($1, $2); }
                         | "," identifier type_parameter_after_name { $$ = Ast::ParameterTail(nullptr, Ast::NameParameter($2, $3)); };

type_parameter_after_constraint: %empty { $$ = Ast::List(); }
                               | "," { $$ = Ast::TrailingComma(Ast::List()); }
                               | "," identifier type_parameter_after_name { $$ = Ast::NameParameter($2, $3); };

type_terms: type_term
          | type_terms "|" type_term { $$ = Ast::Union(@$, $1, $3); };

type_term: type
         | "~" type { $$ = Ast::Node(K::Approximation, @$, {$2}, "~"); };

type_terms_tail: %empty { $$ = nullptr; }
               | "|" type_terms { $$ = $2; };

/* Функции и методы */
function_declaration: KW_FUNC identifier function_signature block { $$ = Ast::Node(K::Function, @$, {$2, $3, $4}); }
                    | KW_FUNC identifier function_signature { $$ = Ast::Node(K::Function, @$, {$2, $3}); }
                    | KW_FUNC identifier type_parameters function_signature block { $$ = Ast::Node(K::Function, @$, {$2, $3, $4, $5}); };

method_declaration: KW_FUNC receiver identifier function_signature block { $$ = Ast::Node(K::Method, @$, {$2, $3, $4, $5}); }
                  | KW_FUNC receiver identifier function_signature { $$ = Ast::Node(K::Method, @$, {$2, $3, $4}); }
                  | KW_FUNC receiver identifier type_parameters function_signature block { $$ = Ast::Node(K::Method, @$, {$2, $3, $4, $5, $6}); }
                  | KW_FUNC receiver identifier type_parameters function_signature { $$ = Ast::Node(K::Method, @$, {$2, $3, $4, $5}); };

receiver: "(" receiver_type optional_trailing_comma ")" { $$ = Ast::Node(K::Receiver, @$, {$2}); }
        | "(" identifier receiver_type optional_trailing_comma ")" { $$ = Ast::Node(K::Receiver, @$, {$2, $3}); };

receiver_type: receiver_name
             | "*" receiver_base_type { $$ = Ast::Node(K::PointerType, @$, {$2}); }
             | "(" receiver_type ")" { $$ = Ast::Node(K::Parenthesized, @$, {$2}); };

receiver_base_type: receiver_name
                  | "(" receiver_base_type ")" { $$ = Ast::Node(K::Parenthesized, @$, {$2}); };

receiver_name: identifier %prec NAME_END { $$ = Ast::Node(K::NamedType, @$, {$1}); }
             | identifier "[" identifier_list optional_trailing_comma "]"
               { $$ = Ast::Node(K::NamedType, @$, {$1, Ast::Node(K::TypeArguments, Ast::Span(@2, @5), {$3})}); };

function_signature: parameters %prec EMPTY_SIGNATURE { $$ = Ast::Node(K::Signature, @$, {$1}); }
                  | parameters result { $$ = Ast::Node(K::Signature, @$, {$1, $2}); };

parameters: "(" ")" { $$ = Ast::Node(K::Parameters, @$); }
          | "(" parameter_list ")" { $$ = Ast::Group(K::Parameters, @$, $2); };

parameter_list: parameter_item optional_trailing_comma { $$ = Ast::List($1); }
              | parameter_item "," parameter_list { $$ = Ast::Prepend($1, $3); }
              | variadic_parameter optional_trailing_comma { $$ = Ast::List($1); };

parameter_item: type { $$ = Ast::Node(K::Parameter, @$, {$1}); }
              | identifier type { $$ = Ast::Node(K::Parameter, @$, {Ast::Node(K::Names, @1, {$1}), $2}); };

variadic_parameter: identifier "..." type { $$ = Ast::Node(K::VariadicParameter, @$, {Ast::Node(K::Names, @1, {$1}), $3}); }
                  | "..." type { $$ = Ast::Node(K::VariadicParameter, @$, {$2}); };

result: type_name { $$ = Ast::Node(K::Results, @$, {Ast::Node(K::Parameter, @1, {$1})}); }
      | pointer_type { $$ = Ast::Node(K::Results, @$, {Ast::Node(K::Parameter, @1, {$1})}); }
      | non_name_type { $$ = Ast::Node(K::Results, @$, {Ast::Node(K::Parameter, @1, {$1})}); }
      | result_parameters { $$ = $1; };

result_parameters: "(" ")" { $$ = Ast::Node(K::Results, @$); }
                 | "(" result_parameter_list optional_trailing_comma ")" { $$ = Ast::Group(K::Results, @$, $2); };

result_parameter_list: parameter_item { $$ = Ast::List($1); }
                     | result_parameter_list "," parameter_item { $$ = Ast::Append($1, $3); };

/* Выражения: приоритеты заданы через %left */
expression: unary_expression
          | expression "||" expression { $$ = Ast::Binary(@$, "||", $1, $3); }
          | expression "&&" expression { $$ = Ast::Binary(@$, "&&", $1, $3); }
          | expression "==" expression { $$ = Ast::Binary(@$, "==", $1, $3); }
          | expression "!=" expression { $$ = Ast::Binary(@$, "!=", $1, $3); }
          | expression "<" expression { $$ = Ast::Binary(@$, "<", $1, $3); }
          | expression "<=" expression { $$ = Ast::Binary(@$, "<=", $1, $3); }
          | expression ">" expression { $$ = Ast::Binary(@$, ">", $1, $3); }
          | expression ">=" expression { $$ = Ast::Binary(@$, ">=", $1, $3); }
          | expression "+" expression { $$ = Ast::Binary(@$, "+", $1, $3); }
          | expression "-" expression { $$ = Ast::Binary(@$, "-", $1, $3); }
          | expression "|" expression { $$ = Ast::Binary(@$, "|", $1, $3); }
          | expression "^" expression { $$ = Ast::Binary(@$, "^", $1, $3); }
          | expression "*" expression { $$ = Ast::Binary(@$, "*", $1, $3); }
          | expression "/" expression { $$ = Ast::Binary(@$, "/", $1, $3); }
          | expression "%" expression { $$ = Ast::Binary(@$, "%", $1, $3); }
          | expression "<<" expression { $$ = Ast::Binary(@$, "<<", $1, $3); }
          | expression ">>" expression { $$ = Ast::Binary(@$, ">>", $1, $3); }
          | expression "&" expression { $$ = Ast::Binary(@$, "&", $1, $3); }
          | expression "&^" expression { $$ = Ast::Binary(@$, "&^", $1, $3); };

unary_expression: primary_expression
                | "+" unary_expression { $$ = Ast::Unary(@$, "+", $2); }
                | "-" unary_expression { $$ = Ast::Unary(@$, "-", $2); }
                | "!" unary_expression { $$ = Ast::Unary(@$, "!", $2); }
                | "^" unary_expression { $$ = Ast::Unary(@$, "^", $2); }
                | "*" unary_expression { $$ = Ast::Unary(@$, "*", $2); }
                | "&" unary_expression { $$ = Ast::Unary(@$, "&", $2); }
                | "<-" unary_expression { $$ = Ast::Unary(@$, "<-", $2); };

primary_expression: literal
                  | identifier
                  | "(" expression ")" { $$ = Ast::Node(K::Parenthesized, @$, {$2}); }
                  | primary_expression "." identifier { $$ = Ast::Postfix(K::Selector, @$, $1, {$3}); }
                  | primary_expression arguments { $$ = Ast::Call(@$, $1, $2); }
                  | primary_expression "[" optional_expression ":" optional_expression "]" { $$ = Ast::Slice(@$, $1, $3, $5, nullptr); }
                  | primary_expression "[" optional_expression ":" expression ":" expression "]" { $$ = Ast::Slice(@$, $1, $3, $5, $7); }
                  | primary_expression "." "(" type ")" { $$ = Ast::Postfix(K::TypeAssertion, @$, $1, {$4}); }
                  | non_name_type "." identifier { $$ = Ast::Node(K::Selector, @$, {$1, $3}); }
                  | "(" non_expression_type ")" arguments { $$ = Ast::Call(@$, Ast::Node(K::Parenthesized, Ast::Span(@1, @3), {$2}), $4); }
                  | "(" non_expression_type ")" "." identifier
                    { $$ = Ast::Node(K::Selector, @$, {Ast::Node(K::Parenthesized, Ast::Span(@1, @3), {$2}), $5}); }
                  | primary_expression type_arguments { $$ = Ast::Postfix(K::BracketExpression, @$, $1, {$2}); }
                  | non_name_type "(" expression optional_trailing_comma ")" { $$ = Ast::Conversion(@$, $1, $3); }
                  | primary_expression literal_value { $$ = Ast::Node(K::CompositeLiteral, @$, {$1, $2}); };

/* Литералы и аргументы вызова */
literal: DECIMAL_LITERAL { $$ = Ast::Text(K::DecimalLiteral, @$, $1); }
       | BINARY_LITERAL { $$ = Ast::Text(K::BinaryLiteral, @$, $1); }
       | OCTAL_LITERAL { $$ = Ast::Text(K::OctalLiteral, @$, $1); }
       | HEX_LITERAL { $$ = Ast::Text(K::HexLiteral, @$, $1); }
       | FLOAT_LITERAL { $$ = Ast::Text(K::FloatLiteral, @$, $1); }
       | HEX_FLOAT_LITERAL { $$ = Ast::Text(K::HexFloatLiteral, @$, $1); }
       | IMAGINARY_LITERAL { $$ = Ast::Text(K::ImaginaryLiteral, @$, $1); }
       | RUNE_LITERAL { $$ = Ast::Rune(@$, $1); }
       | string_literal
       | composite_literal
       | KW_FUNC function_signature block { $$ = Ast::Node(K::FunctionLiteral, @$, {$2, $3}); };

string_literal: STRING_LITERAL { $$ = Ast::Text(K::StringLiteral, @$, $1); }
              | RAW_STRING_LITERAL { $$ = Ast::Text(K::RawStringLiteral, @$, $1); };

arguments: "(" ")" { $$ = Ast::Node(K::Arguments, @$); }
         | "(" expression argument_tail ")" { $$ = Ast::Group(K::Arguments, @$, Ast::Prepend($2, $3)); }
         | "(" non_expression_type argument_tail ")" { $$ = Ast::Group(K::Arguments, @$, Ast::Prepend($2, $3)); };

argument_tail: %empty { $$ = Ast::List(); }
             | "," { $$ = Ast::TrailingComma(Ast::List()); }
             | "..." { $$ = Ast::Spread(Ast::List()); }
             | "..." "," { $$ = Ast::TrailingComma(Ast::Spread(Ast::List())); }
             | "," expression argument_tail { $$ = Ast::Prepend($2, $3); };

composite_literal: composite_literal_type block_open optional_literal_elements "}"
                   { $$ = Ast::Node(K::CompositeLiteral, @$, {$1, Ast::Group(K::LiteralValue, Ast::Span(@2, @4), $3)}); };

composite_literal_type: array_type
                      | map_type
                      | struct_type
                      | "[" "..." "]" type { $$ = Ast::Node(K::InferredArrayType, @$, {$4}); };

literal_value: "{" optional_literal_elements "}" { $$ = Ast::Group(K::LiteralValue, @$, $2); };

optional_literal_elements: %empty { $$ = Ast::List(); }
                         | literal_elements optional_trailing_comma { $$ = $1; };

literal_elements: literal_element { $$ = Ast::List($1); }
                | literal_elements "," literal_element { $$ = Ast::Append($1, $3); };

literal_element: literal_element_value
               | literal_element_value ":" literal_element_value { $$ = Ast::Node(K::KeyValue, @$, {$1, $3}); };

literal_element_value: expression
                     | literal_value;

/* Условия и циклы */
if_statement: KW_IF expression loop_body optional_else { $$ = Ast::Node(K::If, @$, {Ast::Role(K::Condition, @2, $2), $3, $4}); }
            | KW_IF optional_simple_statement ";" expression loop_body optional_else
              { $$ = Ast::Node(K::If, @$, {Ast::Role(K::Initializer, @2, $2), Ast::Role(K::Condition, @4, $4), $5, $6}); };

optional_else: %empty { $$ = nullptr; }
             | KW_ELSE block { $$ = Ast::Node(K::Else, @$, {$2}); }
             | KW_ELSE if_statement { $$ = Ast::Node(K::Else, @$, {$2}); };

for_statement: KW_FOR loop_body { $$ = Ast::Node(K::For, @$, {$2}); }
             | KW_FOR expression loop_body { $$ = Ast::Node(K::For, @$, {Ast::Role(K::Condition, @2, $2), $3}); }
             | KW_FOR for_clause loop_body { $$ = Ast::Node(K::For, @$, {$2, $3}); }
             | KW_FOR range_clause loop_body { $$ = Ast::Node(K::For, @$, {$2, $3}); };

for_clause: optional_simple_statement ";" optional_expression ";" optional_post_statement
            { $$ = Ast::Node(K::ForClause, @$, {Ast::Role(K::Initializer, @1, $1), Ast::Role(K::Condition, @3, $3), Ast::Role(K::Post, @5, $5)}); };

range_clause: KW_RANGE expression { $$ = Ast::Binding(K::Range, @$, nullptr, $2, ""); }
            | expression_list "=" KW_RANGE expression { $$ = Ast::Binding(K::Range, @$, $1, $4, "="); }
            | expression_list ":=" KW_RANGE expression { $$ = Ast::Binding(K::Range, @$, $1, $4, ":="); };

/* Switch и select */
switch_statement: KW_SWITCH expression_switch_header BODY_BRACE expression_cases "}" { $$ = Ast::Switch(@$, $2, Ast::CaseList(@4, $4)); }
                | KW_SWITCH type_switch_guard BODY_BRACE type_cases "}" { $$ = Ast::Node(K::TypeSwitch, @$, {$2, Ast::CaseList(@4, $4)}); }
                | KW_SWITCH ";" type_switch_guard BODY_BRACE type_cases "}"
                  { $$ = Ast::Node(K::TypeSwitch, @$, {$3, Ast::CaseList(@5, $5)}); }
                | KW_SWITCH simple_statement ";" type_switch_guard BODY_BRACE type_cases "}"
                  { $$ = Ast::Node(K::TypeSwitch, @$, {Ast::Role(K::Initializer, @2, $2), $4, Ast::CaseList(@6, $6)}); };

expression_switch_header: %empty { $$ = Ast::List(); }
                        | expression { $$ = Ast::List(Ast::Role(K::Condition, @1, $1)); }
                        | simple_statement ";" optional_expression
                          { $$ = Ast::Prepend(Ast::Role(K::Initializer, @1, $1), Ast::List(Ast::Role(K::Condition, @3, $3))); }
                        | ";" optional_expression { $$ = Ast::List(Ast::Role(K::Condition, @2, $2)); };

expression_cases: %empty { $$ = Ast::Cases(); }
                | expression_case_label expression_case_content { $$ = Ast::AddCase($1, $2); };

expression_case_label: KW_CASE expression_list ":" { $$ = Ast::Node(K::Case, @$, {$2}); }
                     | KW_DEFAULT ":" { $$ = Ast::Node(K::DefaultCase, @$); };

expression_case_content: %empty { $$ = Ast::Cases(); }
                       | ";" expression_case_content { $$ = $2; }
                       | statement ";" expression_case_content { $$ = Ast::CaseStatement($1, $3); }
                       | statement { $$ = Ast::CaseStatement($1, Ast::Cases()); }
                       | expression_case_label expression_case_content { $$ = Ast::AddCase($1, $2); };

type_switch_guard: primary_expression "." "(" KW_TYPE ")" { $$ = Ast::Binding(K::TypeSwitchGuard, @$, nullptr, $1, ""); }
                 | expression_list ":=" primary_expression "." "(" KW_TYPE ")" { $$ = Ast::Binding(K::TypeSwitchGuard, @$, $1, $3, ":="); };

type_cases: %empty { $$ = Ast::Cases(); }
          | type_case_label type_case_content { $$ = Ast::AddCase($1, $2); };

type_case_label: KW_CASE type_case_list ":" { $$ = Ast::Node(K::Case, @$, {$2}); }
               | KW_DEFAULT ":" { $$ = Ast::Node(K::DefaultCase, @$); };

type_case_content: %empty { $$ = Ast::Cases(); }
                 | ";" type_case_content { $$ = $2; }
                 | statement ";" type_case_content { $$ = Ast::CaseStatement($1, $3); }
                 | statement { $$ = Ast::CaseStatement($1, Ast::Cases()); }
                 | type_case_label type_case_content { $$ = Ast::AddCase($1, $2); };

type_case_list: type { $$ = Ast::Node(K::CaseTypes, @$, {$1}); }
              | type_case_list "," type { $$ = Ast::AppendChild($1, $3, @$); };

select_statement: KW_SELECT BODY_BRACE select_cases "}" { $$ = Ast::Node(K::Select, @$, {Ast::CaseList(@3, $3)}); };

select_cases: %empty { $$ = Ast::Cases(); }
            | select_case_label select_case_content { $$ = Ast::AddCase($1, $2); };

select_case_label: KW_CASE communication_clause ":" { $$ = Ast::Node(K::Case, @$, {$2}); }
                 | KW_DEFAULT ":" { $$ = Ast::Node(K::DefaultCase, @$); };

select_case_content: %empty { $$ = Ast::Cases(); }
                   | ";" select_case_content { $$ = $2; }
                   | statement ";" select_case_content { $$ = Ast::CaseStatement($1, $3); }
                   | statement { $$ = Ast::CaseStatement($1, Ast::Cases()); }
                   | select_case_label select_case_content { $$ = Ast::AddCase($1, $2); };

communication_clause: send_statement
                    | expression { $$ = Ast::Node(K::ExpressionStatement, @$, {$1}); }
                    | expression_list "=" expression { $$ = Ast::Binding(K::Assignment, @$, $1, Ast::Node(K::Values, @3, {$3}), "="); }
                    | expression_list ":=" expression { $$ = Ast::Binding(K::ShortDeclaration, @$, $1, Ast::Node(K::Values, @3, {$3}), ":="); };

send_statement: expression "<-" expression { $$ = Ast::Node(K::Send, @$, {$1, $3}, "<-"); };

/* Блоки и инструкции */
block: block_open statement_list "}" { $$ = Ast::Group(K::Block, @$, $2); };

block_open: "{"
          | BODY_BRACE { LexerSupport::ResumeHeader(); };

loop_body: BODY_BRACE statement_list "}" { $$ = Ast::Group(K::Block, @$, $2); };

statement_list: %empty { $$ = Ast::List(); }
              | ";" statement_list { $$ = $2; }
              | statement ";" statement_list { $$ = Ast::Prepend($1, $3); }
              | statement { $$ = Ast::List($1); };

statement: declaration
         | simple_statement
         | KW_RETURN { $$ = Ast::Node(K::Return, @$); }
         | KW_RETURN expression_list { $$ = Ast::Node(K::Return, @$, {$2}); }
         | KW_BREAK { $$ = Ast::Node(K::Break, @$); }
         | KW_BREAK identifier { $$ = Ast::Node(K::Break, @$, {$2}); }
         | KW_CONTINUE { $$ = Ast::Node(K::Continue, @$); }
         | KW_CONTINUE identifier { $$ = Ast::Node(K::Continue, @$, {$2}); }
         | KW_GOTO identifier { $$ = Ast::Node(K::Goto, @$, {$2}); }
         | KW_FALLTHROUGH { $$ = Ast::Node(K::Fallthrough, @$); }
         | labeled_statement
         | KW_DEFER primary_expression arguments { $$ = Ast::Node(K::Defer, @$, {Ast::Call(Ast::Span(@2, @3), $2, $3)}); }
         | KW_GO primary_expression arguments { $$ = Ast::Node(K::Go, @$, {Ast::Call(Ast::Span(@2, @3), $2, $3)}); }
         | block
         | if_statement
         | for_statement
         | switch_statement
         | select_statement;

simple_statement: post_statement
                | expression_list ":=" expression_list { $$ = Ast::Binding(K::ShortDeclaration, @$, $1, $3, ":="); };

optional_simple_statement: %empty { $$ = nullptr; }
                         | simple_statement { $$ = $1; };

post_statement: expression { $$ = Ast::Node(K::ExpressionStatement, @$, {$1}); }
              | send_statement
              | expression "++" { $$ = Ast::Node(K::Increment, @$, {$1}, "++"); }
              | expression "--" { $$ = Ast::Node(K::Decrement, @$, {$1}, "--"); }
              | assignment;

optional_post_statement: %empty { $$ = nullptr; }
                       | post_statement { $$ = $1; };

assignment: expression_list "=" expression_list { $$ = Ast::Binding(K::Assignment, @$, $1, $3, "="); }
          | expression "+=" expression { $$ = Ast::CompoundAssignment(@$, "+=", $1, $3); }
          | expression "-=" expression { $$ = Ast::CompoundAssignment(@$, "-=", $1, $3); }
          | expression "*=" expression { $$ = Ast::CompoundAssignment(@$, "*=", $1, $3); }
          | expression "/=" expression { $$ = Ast::CompoundAssignment(@$, "/=", $1, $3); }
          | expression "%=" expression { $$ = Ast::CompoundAssignment(@$, "%=", $1, $3); }
          | expression "&=" expression { $$ = Ast::CompoundAssignment(@$, "&=", $1, $3); }
          | expression "|=" expression { $$ = Ast::CompoundAssignment(@$, "|=", $1, $3); }
          | expression "^=" expression { $$ = Ast::CompoundAssignment(@$, "^=", $1, $3); }
          | expression "&^=" expression { $$ = Ast::CompoundAssignment(@$, "&^=", $1, $3); }
          | expression "<<=" expression { $$ = Ast::CompoundAssignment(@$, "<<=", $1, $3); }
          | expression ">>=" expression { $$ = Ast::CompoundAssignment(@$, ">>=", $1, $3); };

labeled_statement: identifier ":" statement { $$ = Ast::Node(K::Label, @$, {$1, $3}); }
                 | identifier ":" { $$ = Ast::Node(K::Label, @$, {$1}); };

/* Списки и общий префикс квадратных скобок */
identifier: IDENTIFIER { $$ = Ast::Text(K::Identifier, @$, $1); };

identifier_list: identifier %prec NAME_END { $$ = Ast::Node(K::Names, @$, {$1}); }
               | identifier_list "," identifier { $$ = Ast::AppendChild($1, $3, @$); };

expression_list: expression { $$ = Ast::Node(K::Values, @$, {$1}); }
               | expression_list "," expression { $$ = Ast::AppendChild($1, $3, @$); };

bracket_arguments: bracket_item { $$ = Ast::List($1); }
                 | bracket_arguments "," bracket_item { $$ = Ast::Append($1, $3); };

bracket_item: expression
            | non_expression_type
            | primary_expression type_name type_terms_tail { $$ = Ast::BracketParameter(@$, $1, $2, $3); }
            | primary_expression "[" "]" type type_terms_tail
              { $$ = Ast::BracketParameter(@$, $1, Ast::Node(K::SliceType, Ast::Span(@2, @4), {$4}), $5); }
            | primary_expression map_type type_terms_tail { $$ = Ast::BracketParameter(@$, $1, $2, $3); }
            | primary_expression struct_type type_terms_tail { $$ = Ast::BracketParameter(@$, $1, $2, $3); }
            | primary_expression interface_type type_terms_tail { $$ = Ast::BracketParameter(@$, $1, $2, $3); }
            | primary_expression function_type type_terms_tail { $$ = Ast::BracketParameter(@$, $1, $2, $3); }
            | primary_expression channel_type type_terms_tail { $$ = Ast::BracketParameter(@$, $1, $2, $3); }
            | identifier "~" type type_terms_tail { $$ = Ast::BracketParameter(@$, $1, Ast::Node(K::Approximation, Ast::Span(@2, @3), {$3}, "~"), $4); }
            | expression "*" non_expression_type type_terms_tail
              { $$ = Ast::BracketParameter(@$, $1, Ast::Node(K::PointerType, Ast::Span(@2, @3), {$3}), $4); }
            | expression "|" "~" type type_terms_tail
              { $$ = Ast::Binary(@$, "|", $1, Ast::Union(@$, Ast::Node(K::Approximation, Ast::Span(@3, @4), {$4}, "~"), $5)); }
            | expression "|" non_expression_type type_terms_tail { $$ = Ast::Binary(@$, "|", $1, Ast::Union(@$, $3, $4)); };

bracket_group: "[" "]" { $$ = Ast::Node(K::Brackets, @$); }
             | type_arguments %prec NAME_END { $$ = $1; };

type_arguments: "[" bracket_arguments "]" { $$ = Ast::Group(K::Brackets, @$, $2); }
              | "[" bracket_arguments "," "]" { $$ = Ast::Group(K::Brackets, @$, Ast::TrailingComma($2)); };

optional_expression: %empty { $$ = nullptr; }
                   | expression { $$ = $1; };

optional_trailing_comma: %empty
                       | ",";

%%
void yyerror(const char* message) {
    // A lexical error already has a specific diagnostic.
    if (!LexerSupport::failed) LexerSupport::Error(yylloc, message);
}


