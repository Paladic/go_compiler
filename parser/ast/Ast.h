#pragma once

#include "SourceRange.h"
#include <optional>
#include <string>
#include <string_view>
#include <vector>

enum class AstKind {
    File, Package, Import, ImportSpec, DotImport,
    VarDeclaration, ConstDeclaration, TypeDeclaration, VarSpec, ConstSpec, TypeSpec, TypeAlias,
    Function, Method, FunctionLiteral, Signature, Receiver, Parameters, Results, Parameter,
    VariadicParameter, TypeParameters, TypeParameter, TypeUnion, Approximation,
    NamedType, PointerType, Parenthesized, ArrayType, SliceType, InferredArrayType,
    MapType, StructType, Field, EmbeddedField, StructTag, InterfaceType, InterfaceMethod,
    FunctionType, ChannelType, TypeArguments,
    Identifier, DecimalLiteral, BinaryLiteral, OctalLiteral, HexLiteral, FloatLiteral,
    HexFloatLiteral, ImaginaryLiteral, RuneLiteral, StringLiteral, RawStringLiteral,
    Binary, Unary, Receive, Selector, Index, Instantiation, IndexOrInstantiation,
    Slice, FullSlice, LowerBound, UpperBound, Capacity, TypeAssertion,
    Call, Conversion, Arguments, Spread, CompositeLiteral, LiteralValue, KeyValue,
    Block, If, Else, For, ForClause, Range, Initializer, Condition, Post,
    Switch, TypeSwitch, TypeSwitchGuard, Select, Cases, Case, DefaultCase, CaseBody, CaseTypes,
    ExpressionStatement, Assignment, ShortDeclaration, Increment, Decrement, Send,
    Return, Break, Continue, Goto, Fallthrough, Label, Go, Defer,
    Names, Targets, Values,

    // Parser intermediates resolved before publishing astRoot.
    Brackets, BracketExpression, BracketParameter
};

struct AstNode {
    AstKind kind;
    SourceRange range;
    std::string text;
    std::vector<AstNode*> children;
    std::optional<long long> runeValue;
    std::size_t id = 0;
    bool trailingComma = false;
};

// Owns no memory. The parser keeps the tree alive until the next ParseSource call.
extern const AstNode* astRoot;
std::string_view AstKindName(AstKind kind);
