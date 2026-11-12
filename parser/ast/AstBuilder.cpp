#include "AstBuilder.h"
#include "LexerSupport.h"

#include <deque>

struct AstList {
    std::deque<AstNode*> items;
    bool trailingComma = false;
    bool spread = false;
};

struct AstCases {
    std::deque<AstNode*> clauses;
    std::deque<AstNode*> body;
};

const AstNode* astRoot = nullptr;

namespace {
    // Deques keep the addresses stored on the LR stack stable.
    std::deque<AstNode> nodes;
    std::deque<AstList> lists;
    std::deque<AstCases> caseLists;
    AstNode* parsedRoot = nullptr;
}

void Ast::Reset() {
    astRoot = nullptr;
    parsedRoot = nullptr;
    caseLists.clear();
    lists.clear();
    nodes.clear();
}

void Ast::SetRoot(AstNode* node) {
    parsedRoot = node;
}

bool Ast::Finish(const AstNode** rejectedTree) {
    if (!parsedRoot) return false;
    const bool accepted = ResolveTypes(parsedRoot) && Validate(parsedRoot);
    if (!accepted && !rejectedTree) return false;

    std::vector<AstNode*> pending{parsedRoot};
    std::size_t id = 0;
    while (!pending.empty()) {
        AstNode* node = pending.back();
        pending.pop_back();
        node->id = ++id;
        pending.insert(pending.end(), node->children.rbegin(), node->children.rend());
    }
    lists.clear();
    caseLists.clear();
    if (accepted) astRoot = parsedRoot;
    else *rejectedTree = parsedRoot;
    return accepted;
}

AstNode* Ast::Node(K kind, SourceRange range, std::initializer_list<AstNode*> children,
                   std::string_view text) {
    nodes.push_back({kind, range, std::string(text), {}, std::nullopt});
    AstNode& node = nodes.back();
    for (AstNode* child : children) {
        if (child) node.children.push_back(child);
    }
    return &node;
}

AstNode* Ast::Role(K kind, SourceRange range, AstNode* child) {
    return child ? Node(kind, range, {child}) : nullptr;
}

AstNode* Ast::Text(K kind, SourceRange range, const std::string* text) {
    return Node(kind, range, {}, *text);
}

AstNode* Ast::Rune(SourceRange range, long long value) {
    AstNode* node = Text(K::RuneLiteral, range, LexerSupport::Text(range));
    node->runeValue = value;
    return node;
}

SourceRange Ast::Span(SourceRange first, SourceRange last) {
    SourceRange range{};
    MergeSourceRange(range, first, last, first, 2);
    return range;
}

AstNode* Ast::AppendChild(AstNode* parent, AstNode* child, SourceRange range) {
    parent->children.push_back(child);
    parent->range = range;
    return parent;
}

AstList* Ast::List(AstNode* item) {
    lists.emplace_back();
    return Append(&lists.back(), item);
}

AstList* Ast::Append(AstList* list, AstNode* item) {
    if (item) list->items.push_back(item);
    return list;
}

AstList* Ast::Prepend(AstNode* item, AstList* list) {
    if (item) list->items.push_front(item);
    return list;
}

AstList* Ast::TrailingComma(AstList* list) {
    list->trailingComma = true;
    return list;
}

AstList* Ast::Spread(AstList* list) {
    list->spread = true;
    return list;
}

AstList* Ast::ParameterTail(AstNode* constraint, AstList* rest) {
    return Prepend(Node(K::TypeParameter, constraint ? constraint->range : SourceRange{}, {constraint}), rest);
}

AstList* Ast::NameParameter(AstNode* name, AstList* list) {
    AstNode* parameter = list->items.front();
    parameter->range = parameter->children.empty() ? name->range : Span(name->range, parameter->range);
    parameter->children.insert(parameter->children.begin(), name);
    return list;
}

AstNode* Ast::Group(K kind, SourceRange range, AstList* list) {
    AstNode* group = Node(kind, range);
    group->children.assign(list->items.begin(), list->items.end());
    group->trailingComma = list->trailingComma;
    if (list->spread) {
        AstNode*& last = group->children.back();
        last = Node(K::Spread, last->range, {last}, "...");
    }
    return group;
}

AstCases* Ast::Cases() {
    caseLists.emplace_back();
    return &caseLists.back();
}

AstCases* Ast::CaseStatement(AstNode* statement, AstCases* rest) {
    rest->body.push_front(statement);
    return rest;
}

AstCases* Ast::AddCase(AstNode* label, AstCases* rest) {
    SourceRange bodyRange{};
    const bool hasBody = !rest->body.empty();
    MergeSourceRange(bodyRange,
                     hasBody ? rest->body.front()->range : label->range,
                     hasBody ? rest->body.back()->range : label->range,
                     label->range, hasBody);
    AstNode* body = Node(K::CaseBody, bodyRange);
    body->children.assign(rest->body.begin(), rest->body.end());
    rest->body.clear();
    label->children.push_back(body);
    MergeSourceRange(label->range, label->range, bodyRange, label->range, 2);
    rest->clauses.push_front(label);
    return rest;
}

AstNode* Ast::CaseList(SourceRange range, AstCases* cases) {
    AstNode* node = Node(K::Cases, range);
    node->children.assign(cases->clauses.begin(), cases->clauses.end());
    return node;
}

AstNode* Ast::File(SourceRange range, AstNode* package, AstList* imports, AstList* declarations) {
    AstNode* file = Node(K::File, range, {package});
    file->children.insert(file->children.end(), imports->items.begin(), imports->items.end());
    file->children.insert(file->children.end(), declarations->items.begin(), declarations->items.end());
    return file;
}

AstNode* Ast::Binary(SourceRange range, std::string_view op, AstNode* left, AstNode* right) {
    return Node(K::Binary, range, {left, right}, op);
}

AstNode* Ast::Unary(SourceRange range, std::string_view op, AstNode* operand) {
    return Node(op == "<-" ? K::Receive : K::Unary, range, {operand}, op);
}

AstNode* Ast::Call(SourceRange range, AstNode* callee, AstNode* arguments) {
    return Postfix(K::Call, range, callee, {arguments});
}

AstNode* Ast::Postfix(K kind, SourceRange range, AstNode* base, std::initializer_list<AstNode*> rest) {
    // The shared channel-type prefix can reduce <-chan T(x) inside primary_expression.
    // Its postfix operations still belong to the operand of the receive.
    AstNode* operand = base->kind == K::Receive ? base->children.front() : base;
    AstNode* result = Node(kind, Span(operand->range, range), {operand});
    for (AstNode* child : rest) {
        if (child) result->children.push_back(child);
    }
    if (operand == base) return result;
    base->children.front() = result;
    base->range = range;
    return base;
}

AstNode* Ast::Conversion(SourceRange range, AstNode* type, AstNode* value) {
    AstNode* arguments = Node(K::Arguments, value->range, {value});
    if (type->kind != K::ChannelType || type->text != "<-chan") {
        return Node(K::Conversion, range, {type, arguments});
    }
    type->text = "chan";
    type->range.begin += 2;
    type->range.first_column += 2;
    AstNode* conversion = Node(K::Conversion, Span(type->range, range), {type, arguments});
    return Unary(range, "<-", conversion);
}

AstNode* Ast::Switch(SourceRange range, AstList* header, AstNode* cases) {
    return Group(K::Switch, range, Append(header, cases));
}

AstNode* Ast::Binding(K kind, SourceRange range, AstNode* targets, AstNode* value, std::string_view op) {
    if (targets) targets->kind = K::Targets;
    return Node(kind, range, {targets, value}, op);
}

AstNode* Ast::CompoundAssignment(SourceRange range, std::string_view op, AstNode* target, AstNode* value) {
    return Node(K::Assignment, range, {
        Node(K::Targets, target->range, {target}),
        Node(K::Values, value->range, {value})
    }, op);
}

AstNode* Ast::Union(SourceRange range, AstNode* first, AstNode* rest) {
    if (!rest) return first;
    if (first->kind == K::TypeUnion) {
        first->children.push_back(rest);
        first->range = range;
        return first;
    }
    if (rest->kind == K::TypeUnion) {
        AstNode* node = Node(K::TypeUnion, range, {first});
        node->children.insert(node->children.end(), rest->children.begin(), rest->children.end());
        return node;
    }
    return Node(K::TypeUnion, range, {first, rest});
}

AstNode* Ast::BracketParameter(SourceRange range, AstNode* name, AstNode* constraint, AstNode* tail) {
    return Node(K::BracketParameter, range, {name, Union(range, constraint, tail)});
}

AstNode* Ast::Slice(SourceRange range, AstNode* base, AstNode* low, AstNode* high, AstNode* capacity) {
    return Postfix(capacity ? K::FullSlice : K::Slice, range, base, {
        Role(K::LowerBound, low ? low->range : range, low),
        Role(K::UpperBound, high ? high->range : range, high),
        Role(K::Capacity, capacity ? capacity->range : range, capacity)
    });
}
