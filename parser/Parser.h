#pragma once
#include "ast/Ast.h"
#include <string>

// A successful parse publishes astRoot. A failed parse leaves it null.
// rejectedTree optionally receives the debug tree after a failed AST check.
// Both trees live until the next call.
// Flex and Bison use shared state; call this function sequentially.
bool ParseSource(const std::string& source, const std::string& filename = "<input>",
                 const AstNode** rejectedTree = nullptr);
