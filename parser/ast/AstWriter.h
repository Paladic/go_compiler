#pragma once

#include "Ast.h"
#include <iosfwd>

namespace AstWriter {
    void Html(std::ostream& out, const AstNode* root, std::string_view filename, std::string_view source,
              std::string_view error, SourceRange errorRange);
    void Dot(std::ostream& out, const AstNode& root);
}
