#include "AstBuilder.h"
#include "LexerSupport.h"

#include <algorithm>

namespace {
    using Ast::K;

    bool Error(const AstNode* node, const char* message) {
        LexerSupport::Error(node->range, message);
        return false;
    }

    const AstNode* Unparen(const AstNode* node) {
        while (node->kind == K::Parenthesized) node = node->children.front();
        return node;
    }

    bool CheckTargets(const AstNode* node, std::size_t limit = 0) {
        const AstNode* targets = node->children.front();
        if (targets->kind != K::Targets) return true;
        if (limit && targets->children.size() > limit) {
            return Error(targets, limit == 1 ? "type switch requires one name before :="
                                             : "at most two targets are allowed");
        }
        if (node->text == ":=") {
            for (const AstNode* target : targets->children) {
                if (target->kind != K::Identifier) {
                    return Error(target, "expected an identifier on the left of :=");
                }
            }
        }
        return true;
    }

    bool CheckCommunication(const AstNode* node) {
        if (node->kind == K::Send) return true;
        const AstNode* expression = node->children.back();
        if (node->kind == K::Assignment || node->kind == K::ShortDeclaration) {
            if (!CheckTargets(node, 2)) return false;
            expression = expression->children.front();
        }
        return Unparen(expression)->kind == K::Receive
            || Error(expression, "select case requires a send or a receive");
    }

    const AstNode* FinalFallthrough(const AstNode* clause) {
        const AstNode* body = clause->children.back();
        if (body->children.empty()) return nullptr;
        const AstNode* last = body->children.back();
        while (last->kind == K::Label && last->children.size() == 2) last = last->children.back();
        return last->kind == K::Fallthrough ? last : nullptr;
    }

    struct Context {
        bool canBreak = false;
        bool canContinue = false;
        const AstNode* fallthrough = nullptr;
    };

    struct Visit {
        const AstNode* node;
        Context context;
    };

    bool AddCases(std::vector<Visit>& pending, const AstNode* statement, Context context) {
        const auto& clauses = statement->children.back()->children;
        bool hasDefault = false;
        for (const AstNode* clause : clauses) {
            if (clause->kind == K::DefaultCase) {
                if (hasDefault) return Error(clause, "multiple default clauses");
                hasDefault = true;
            } else if (statement->kind == K::Select && !CheckCommunication(clause->children.front())) {
                return false;
            }
        }

        context.canBreak = true;
        for (auto clause = clauses.rbegin(); clause != clauses.rend(); ++clause) {
            context.fallthrough = statement->kind == K::Switch && clause != clauses.rbegin()
                ? FinalFallthrough(*clause) : nullptr;
            pending.push_back({*clause, context});
        }
        return true;
    }

    bool Check(const AstNode* node, Context context) {
        switch (node->kind) {
            case K::ShortDeclaration:
                return CheckTargets(node);
            case K::Range:
                return CheckTargets(node, 2);
            case K::TypeSwitchGuard:
                return CheckTargets(node, 1);
            case K::ExpressionStatement: {
                const AstNode* expression = Unparen(node->children.front());
                return expression->kind == K::Call || expression->kind == K::Receive
                    || Error(expression, "expression statement requires a call or a receive");
            }
            case K::Go: case K::Defer:
                return node->children.front()->kind == K::Call
                    || Error(node, "go or defer requires a function call");
            case K::Break:
                return context.canBreak || Error(node, "break outside for, switch or select");
            case K::Continue:
                return context.canContinue || Error(node, "continue outside for");
            case K::Fallthrough:
                return context.fallthrough == node
                    || Error(node, "fallthrough must end a non-final case of an expression switch");
            default:
                return true;
        }
    }
}

bool Ast::Validate(AstNode* root) {
    std::vector<Visit> pending{{root, {}}};
    while (!pending.empty()) {
        auto [node, context] = pending.back();
        pending.pop_back();
        if (!Check(node, context)) return false;

        auto child = node->children.rbegin();
        switch (node->kind) {
            case K::Function: case K::Method: case K::FunctionLiteral:
                context = {};
                break;
            case K::For:
                context.canBreak = true;
                context.canContinue = true;
                break;
            case K::Switch: case K::TypeSwitch: case K::Select:
                if (!AddCases(pending, node, context)) return false;
                ++child;
                break;
            default:
                break;
        }
        for (; child != node->children.rend(); ++child) pending.push_back({*child, context});
    }
    return true;
}
