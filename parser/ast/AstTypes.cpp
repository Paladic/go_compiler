#include "AstBuilder.h"
#include "LexerSupport.h"

#include <algorithm>
#include <utility>

namespace {
    using Ast::K;

    bool Error(const AstNode* node, const char* message) {
        LexerSupport::Error(node->range, message);
        return false;
    }

    bool IsExplicitType(const AstNode* node) {
        while (node->kind == K::Parenthesized) node = node->children.front();
        switch (node->kind) {
            case K::NamedType: case K::PointerType: case K::ArrayType: case K::SliceType:
            case K::MapType: case K::StructType: case K::InterfaceType:
            case K::FunctionType: case K::ChannelType:
                return true;
            default:
                return false;
        }
    }

    // A single bracket item can be an expression, a type, or both.
    bool CanBeExpression(const AstNode* node) {
        std::vector<const AstNode*> pending{node};
        while (!pending.empty()) {
            const AstNode* part = pending.back();
            pending.pop_back();
            switch (part->kind) {
                case K::BracketParameter: case K::Approximation: case K::TypeUnion:
                    return false;
                case K::Parenthesized: case K::Binary: case K::Unary: case K::Receive:
                    pending.insert(pending.end(), part->children.begin(), part->children.end());
                    break;
                default:
                    if (IsExplicitType(part)) return false;
                    break;
            }
        }
        return true;
    }

    bool IsQualifiedName(const AstNode* node) {
        return node->kind == K::Selector && node->children.front()->kind == K::Identifier;
    }

    AstNode* AsType(AstNode* node);

    AstNode* AsTypeArguments(AstNode* brackets) {
        AstNode* arguments = Ast::Node(K::TypeArguments, brackets->range);
        for (AstNode* item : brackets->children) {
            AstNode* type = AsType(item);
            if (!type) return nullptr;
            arguments->children.push_back(type);
        }
        return arguments;
    }

    AstNode* AsType(AstNode* node) {
        if (IsExplicitType(node)) return node;
        if (node->kind == K::Identifier || IsQualifiedName(node)) {
            return Ast::Node(K::NamedType, node->range, {node});
        }
        if (node->kind == K::Parenthesized || (node->kind == K::Unary && node->text == "*")) {
            AstNode* type = AsType(node->children.front());
            K kind = node->kind == K::Unary ? K::PointerType : K::Parenthesized;
            return type ? Ast::Node(kind, node->range, {type}) : nullptr;
        }
        if (node->kind != K::BracketExpression) return nullptr;

        AstNode* base = node->children.front();
        if (base->kind != K::Identifier && !IsQualifiedName(base)) return nullptr;
        AstNode* arguments = AsTypeArguments(node->children.back());
        return arguments ? Ast::Node(K::NamedType, node->range, {base, arguments}) : nullptr;
    }

    bool ResolveBracketExpression(AstNode* node) {
        AstNode*& suffix = node->children.back();
        AstNode* brackets = suffix;
        if (brackets->children.size() == 1 && CanBeExpression(brackets->children.front())) {
            suffix = brackets->children.front();
            node->kind = AsType(suffix) ? K::IndexOrInstantiation : K::Index;
            node->trailingComma = brackets->trailingComma;
            return true;
        }
        AstNode* arguments = AsTypeArguments(brackets);
        if (!arguments) return Error(brackets, "expected types in square brackets");
        suffix = arguments;
        node->kind = K::Instantiation;
        return true;
    }

    bool ResolveNamedType(AstNode* node) {
        AstNode*& suffix = node->children.back();
        if (suffix->kind != K::Brackets) return true;
        AstNode* brackets = suffix;
        AstNode* arguments = AsTypeArguments(brackets);
        if (!arguments) return Error(brackets, "expected types in type argument list");
        suffix = arguments;
        return true;
    }

    bool ResolveArray(AstNode* node) {
        AstNode* brackets = node->children.front();
        if (brackets->children.empty()) {
            node->kind = K::SliceType;
            node->children.erase(node->children.begin());
            return true;
        }
        if (brackets->children.size() != 1 || brackets->trailingComma
            || !CanBeExpression(brackets->children.front())) {
            return Error(brackets, "array length must be one expression without a trailing comma");
        }
        node->children.front() = brackets->children.front();
        return true;
    }

    bool ResolveComposite(AstNode* node) {
        AstNode*& prefix = node->children.front();
        switch (prefix->kind) {
            case K::ArrayType: case K::SliceType: case K::InferredArrayType:
            case K::MapType: case K::StructType:
                return true;
            default:
                break;
        }
        AstNode* type = AsType(prefix);
        if (!type || type->kind != K::NamedType) return Error(prefix, "expected a composite literal type");
        prefix = type;
        return true;
    }

    AstNode* AsConstraint(AstNode* node) {
        if (node->kind == K::Approximation || node->kind == K::TypeUnion) return node;
        return AsType(node);
    }

    AstNode* Parameter(AstNode* name, AstNode* constraint, SourceRange range) {
        if (name->kind != K::Identifier || !constraint) return nullptr;
        return Ast::Node(K::TypeParameter, range, {name, constraint});
    }

    // In P[N]T, the shared prefix may read P[N] as a postfix expression.
    // Each bracket belongs to the array type in this declaration.
    AstNode* ExplicitParameter(AstNode* item) {
        AstNode* name = item->children.front();
        AstNode* constraint = item->children.back();
        AstNode** head = &constraint;
        if (name->kind == K::BracketExpression && constraint->kind == K::TypeUnion) {
            AstNode* copy = Ast::Node(K::TypeUnion, constraint->range);
            copy->children = constraint->children;
            constraint = copy;
            head = &constraint->children.front();
        }
        while (name->kind == K::BracketExpression) {
            *head = Ast::Node(K::ArrayType, Ast::Span(name->children.back()->range, (*head)->range),
                              {name->children.back(), *head});
            name = name->children.front();
        }
        return Parameter(name, constraint, item->range);
    }

    AstNode* ExpressionParameter(AstNode* item) {
        if (item->kind == K::Binary && item->text == "*") {
            AstNode* type = AsType(item->children.back());
            if (!type) return nullptr;
            SourceRange range = Ast::Span(item->children.front()->range, type->range);
            range.begin = item->children.front()->range.end;
            range.first_line = item->children.front()->range.last_line;
            range.first_column = item->children.front()->range.last_column;
            return Parameter(item->children.front(), Ast::Node(K::PointerType, range, {type}), item->range);
        }
        if ((item->kind != K::Call && item->kind != K::Conversion)
            || item->children.front()->kind != K::Identifier) return nullptr;
        AstNode* arguments = item->children.back();
        if (arguments->children.size() != 1 || arguments->trailingComma) return nullptr;
        AstNode* type = AsType(arguments->children.front());
        if (!type) return nullptr;
        return Parameter(item->children.front(), Ast::Node(K::Parenthesized, arguments->range, {type}), item->range);
    }

    AstNode* AsTypeParameter(AstNode* item) {
        if (item->kind == K::Identifier) return Ast::Node(K::TypeParameter, item->range, {item});
        std::vector<AstNode*> terms;
        AstNode* first = item;
        while (first->kind == K::Binary && first->text == "|") {
            terms.push_back(first->children.back());
            first = first->children.front();
        }
        AstNode* parameter = first->kind == K::BracketParameter ? ExplicitParameter(first) : ExpressionParameter(first);
        if (!parameter) return nullptr;
        if (!terms.empty()) {
            AstNode*& constraint = parameter->children.back();
            AstNode* combined = Ast::Node(K::TypeUnion, item->range);
            auto append = [&](AstNode* term) {
                if (term->kind == K::TypeUnion) {
                    combined->children.insert(combined->children.end(), term->children.begin(), term->children.end());
                } else {
                    combined->children.push_back(term);
                }
            };
            append(constraint);
            for (auto term = terms.rbegin(); term != terms.rend(); ++term) {
                AstNode* type = AsConstraint(*term);
                if (!type) return nullptr;
                append(type);
            }
            constraint = combined;
        }
        parameter->range = item->range;
        return parameter;
    }

    bool ResolveTypeSpec(AstNode* node) {
        const bool alias = node->kind == K::TypeAlias;
        AstNode* type = node->children.back();
        AstNode* brackets = nullptr;
        if (alias && node->children.size() == 3) {
            brackets = node->children[1];
        } else if (!alias && type->kind == K::ArrayType) {
            brackets = type->children.front();
        }
        if (!brackets || brackets->children.empty()) return true;
        const AstNode* first = brackets->children.front();
        while (first->kind == K::Binary && first->text == "|") first = first->children.front();
        const bool explicitCallConstraint = first->kind == K::Call
            && first->children.back()->children.size() == 1
            && !CanBeExpression(first->children.back()->children.front());
        const bool ambiguous = brackets->children.size() == 1 && !brackets->trailingComma
            && !explicitCallConstraint && CanBeExpression(brackets->children.front());
        if (ambiguous) {
            if (alias) return Error(brackets, "a single ambiguous type parameter needs a trailing comma or an interface constraint");
            return true;
        }

        AstNode* parameters = Ast::Node(K::TypeParameters, brackets->range);
        for (AstNode* item : brackets->children) {
            AstNode* parameter = AsTypeParameter(item);
            if (!parameter) return Error(item, "expected a type parameter name and constraint");
            parameters->children.push_back(parameter);
        }
        if (!alias) type = type->children.back();
        node->children = {node->children.front(), parameters, type};
        return true;
    }

    AstNode* BareName(AstNode* parameter) {
        AstNode* type = parameter->children.front();
        if (type->kind != K::NamedType || type->children.size() != 1) return nullptr;
        AstNode* name = type->children.front();
        return name->kind == K::Identifier ? name : nullptr;
    }

    bool ResolveParameters(AstNode* list) {
        const auto isNamed = [](AstNode* parameter) { return parameter->children.size() == 2; };
        if (std::none_of(list->children.begin(), list->children.end(), isNamed)) return true;

        std::vector<AstNode*> names;
        std::vector<AstNode*> groups;
        for (AstNode* parameter : list->children) {
            if (!isNamed(parameter)) {
                AstNode* name = BareName(parameter);
                if (!name || parameter->kind == K::VariadicParameter) {
                    return Error(parameter, "cannot mix named and unnamed parameters or results");
                }
                names.push_back(name);
                continue;
            }
            if (!names.empty()) {
                if (parameter->kind == K::VariadicParameter) {
                    return Error(parameter, "a variadic parameter must have at most one name");
                }
                names.push_back(parameter->children.front()->children.front());
                AstNode* nameList = Ast::Node(K::Names, Ast::Span(names.front()->range, names.back()->range));
                nameList->children.swap(names);
                parameter = Ast::Node(K::Parameter, Ast::Span(nameList->range, parameter->range),
                                      {nameList, parameter->children.back()});
            }
            groups.push_back(parameter);
        }
        if (!names.empty()) return Error(names.front(), "parameter or result is missing its type");
        list->children.swap(groups);
        return true;
    }

    bool ResolveTypeParameters(AstNode* list) {
        std::vector<AstNode*> names;
        std::vector<AstNode*> groups;
        for (AstNode* parameter : list->children) {
            names.push_back(parameter->children.front());
            if (parameter->children.size() == 1) continue;
            AstNode* nameList = Ast::Node(K::Names, Ast::Span(names.front()->range, names.back()->range));
            nameList->children.swap(names);
            groups.push_back(Ast::Node(K::TypeParameter, Ast::Span(nameList->range, parameter->range),
                                       {nameList, parameter->children.back()}));
        }
        if (!names.empty()) return Error(names.front(), "missing type parameter constraint");
        list->children.swap(groups);
        return true;
    }

    bool ResolveCall(AstNode* node) {
        if (!IsExplicitType(node->children.front())) return true;
        AstNode* arguments = node->children.back();
        if (arguments->children.size() != 1 || arguments->children.front()->kind == K::Spread) {
            return Error(arguments, "a conversion requires one argument");
        }
        node->kind = K::Conversion;
        return true;
    }

    bool Resolve(AstNode* node) {
        switch (node->kind) {
            case K::BracketExpression: return ResolveBracketExpression(node);
            case K::NamedType: return ResolveNamedType(node);
            case K::ArrayType: return ResolveArray(node);
            case K::CompositeLiteral: return ResolveComposite(node);
            case K::TypeSpec: case K::TypeAlias: return ResolveTypeSpec(node);
            case K::Parameters: case K::Results: return ResolveParameters(node);
            case K::TypeParameters: return ResolveTypeParameters(node);
            case K::Call: return ResolveCall(node);
            case K::Brackets: case K::BracketParameter: return Error(node, "unexpected bracket syntax");
            default: return true;
        }
    }
}

bool Ast::ResolveTypes(AstNode* root) {
    std::vector<AstNode*> pending{root};
    while (!pending.empty()) {
        AstNode* node = pending.back();
        pending.pop_back();
        if (!Resolve(node)) return false;
        pending.insert(pending.end(), node->children.rbegin(), node->children.rend());
    }
    return true;
}
