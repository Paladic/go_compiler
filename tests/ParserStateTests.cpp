#include "Parser.h"
#include "LexerSupport.h"
#include "parser.tab.hpp"
#include <iostream>
#include <stdexcept>

struct yy_buffer_state;
yy_buffer_state* yy_scan_bytes(const char*, int);
void yy_delete_buffer(yy_buffer_state*);
int yylex_destroy();
int yylex();
void ResetLexer();

namespace {
    void Require(bool condition, const char* message) {
        if (!condition) throw std::runtime_error(message);
    }

    void CheckRepeatedParsing() {
        Require(ParseSource("package p;var x=1"), "initial parse failed");
        Require(!ParseSource("package p;var x=`unclosed"), "unclosed raw string accepted");
        Require(ParseSource("package q\nfunc f(){return}\n"), "scanner state was not reset");
        Require(!ParseSource("package p;var x=@"), "illegal character accepted");
        Require(ParseSource("package p;var x=2"), "parse after lexical error failed");
        Require(!ParseSource("package p;var x="), "missing initializer accepted");
        Require(ParseSource("package p;type G[P(C),]int"), "parse after a missing initializer failed");
        Require(!ParseSource("package p;func f("), "unfinished parameters accepted");
        Require(ParseSource("package p;func f(a,b int){}"), "parse after unfinished parameters failed");
    }

    void CheckExpressions() {
        const char* binary[] = {"||", "&&", "==", "!=", "<", "<=", ">", ">=", "+", "-", "|", "^", "*", "/", "%", "<<", ">>", "&", "&^"};
        const char* unary[] = {"+", "-", "!", "^", "*", "&", "<-"};
        auto check = [](const std::string& expression) {
            if (!ParseSource("package p;var x=" + expression)) {
                throw std::runtime_error("expression rejected: " + expression);
            }
        };
        for (const char* first : binary) {
            for (const char* second : binary) {
                check(std::string("a ") + first + " b " + second + " c");
                check(std::string("(a ") + first + " b) " + second + " c");
                check(std::string("a ") + first + " (b " + second + " c)");
            }
            for (const char* prefix : unary) {
                check(std::string(prefix) + " a " + first + " b");
                check(std::string("a ") + first + " " + prefix + " b");
            }
        }
        for (const char* outer : unary) {
            for (const char* inner : unary) check(std::string(outer) + " " + inner + " a");
        }
    }

    void CheckEncodingAndLiterals() {
        std::string invalid = "package p;var x=\"";
        invalid.push_back(static_cast<char>(0xff));
        invalid += '"';
        Require(!ParseSource(invalid), "invalid UTF-8 accepted");
        invalid = "package p;var x=\"";
        invalid.push_back('\0');
        invalid += '"';
        Require(!ParseSource(invalid), "NUL in source accepted");
        Require(ParseSource(R"(package p;var x="\u0041\377";var r='\U0010FFFF')"), "valid escapes rejected");
        Require(!ParseSource(R"(package p;var x="\uD800")"), "surrogate escape accepted");
        Require(!ParseSource(R"(package p;var r='\U00110000')"), "out-of-range rune accepted");
        Require(ParseSource("package p;var x=1267650600228229401496703205376"), "large constant rejected");
    }

    void CheckTokenValues() {
        const std::string source = R"('A' '\n' '\u0410' '\U0001F600' '\377' '\xFF' 1267650600228229401496703205376 0x1.fp2 12i "raw\n" name)";
        LexerSupport::Reset(source, "<token-test>");
        Require(LexerSupport::ValidateSource(), "token source is invalid");
        yy_buffer_state* buffer = yy_scan_bytes(source.data(), static_cast<int>(source.size()));
        ResetLexer();
        for (long long expected : {65, 10, 1040, 128512, 255, 255}) {
            Require(yylex() == RUNE_LITERAL && yylval.integerValue == expected, "rune token value is wrong");
        }
        Require(yylex() == DECIMAL_LITERAL && *yylval.stringValue == "1267650600228229401496703205376", "integer token was truncated");
        Require(yylex() == HEX_FLOAT_LITERAL && *yylval.stringValue == "0x1.fp2", "float token lost its spelling");
        Require(yylex() == IMAGINARY_LITERAL && *yylval.stringValue == "12i", "imaginary token lost its spelling");
        Require(yylex() == STRING_LITERAL && *yylval.stringValue == R"("raw\n")", "string token lost its spelling");
        Require(yylex() == IDENTIFIER && *yylval.stringValue == "name", "identifier token value is wrong");
        Require(yylex() == SEMICOLON && yylex() == 0, "token stream did not end correctly");
        yy_delete_buffer(buffer);
        yylex_destroy();
    }

    void CheckLrStackGrowth() {
        std::string source = "package p;func f(){";
        for (int index = 0; index < 1000; ++index) source += "x++;";
        source += '}';
        Require(ParseSource(source), "LR stack did not grow for a long statement list");
        Require(ParseSource("package p;var x chan<-chan int"), "nested channel type rejected");
    }
}

int main() {
    try {
        CheckRepeatedParsing();
        CheckExpressions();
        CheckEncodingAndLiterals();
        CheckTokenValues();
        CheckLrStackGrowth();
        std::cout << "Parser state, token values and expression syntax: PASS\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
