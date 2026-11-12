#pragma once

#include "Ast.h"
#include <initializer_list>

struct AstList;
struct AstCases;

namespace Ast {
    using K = AstKind;

    void Reset();
    bool Finish(const AstNode** rejectedTree);
    void SetRoot(AstNode* node);
    bool ResolveTypes(AstNode* root);
    bool Validate(AstNode* root);

    AstNode* Node(K kind, SourceRange range, std::initializer_list<AstNode*> children = {},
                  std::string_view text = {});
    AstNode* Role(K kind, SourceRange range, AstNode* child);
    AstNode* Text(K kind, SourceRange range, const std::string* text);
    AstNode* Rune(SourceRange range, long long value);
    SourceRange Span(SourceRange first, SourceRange last);
    AstNode* AppendChild(AstNode* parent, AstNode* child, SourceRange range);

    AstList* List(AstNode* item = nullptr);
    AstList* Append(AstList* list, AstNode* item);
    AstList* Prepend(AstNode* item, AstList* list);
    AstList* TrailingComma(AstList* list);
    AstList* Spread(AstList* list);
    AstList* ParameterTail(AstNode* constraint, AstList* rest);
    AstList* NameParameter(AstNode* name, AstList* list);
    AstNode* Group(K kind, SourceRange range, AstList* list);

    AstCases* Cases();
    AstCases* CaseStatement(AstNode* statement, AstCases* rest);
    AstCases* AddCase(AstNode* label, AstCases* rest);
    AstNode* CaseList(SourceRange range, AstCases* cases);

    AstNode* File(SourceRange range, AstNode* package, AstList* imports, AstList* declarations);
    AstNode* Binary(SourceRange range, std::string_view op, AstNode* left, AstNode* right);
    AstNode* Unary(SourceRange range, std::string_view op, AstNode* operand);
    AstNode* Call(SourceRange range, AstNode* callee, AstNode* arguments);
    AstNode* Postfix(K kind, SourceRange range, AstNode* base, std::initializer_list<AstNode*> rest);
    AstNode* Conversion(SourceRange range, AstNode* type, AstNode* value);
    AstNode* Switch(SourceRange range, AstList* header, AstNode* cases);
    AstNode* Binding(K kind, SourceRange range, AstNode* targets, AstNode* value, std::string_view op);
    AstNode* CompoundAssignment(SourceRange range, std::string_view op, AstNode* target, AstNode* value);
    AstNode* Union(SourceRange range, AstNode* first, AstNode* rest);
    AstNode* BracketParameter(SourceRange range, AstNode* name, AstNode* constraint, AstNode* tail);
    AstNode* Slice(SourceRange range, AstNode* base, AstNode* low, AstNode* high, AstNode* capacity);
}
