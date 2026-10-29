#include "Parser.h"
#include "LexerSupport.h"
#include "parser.tab.hpp"
#include <limits>

struct yy_buffer_state;
using YY_BUFFER_STATE = yy_buffer_state*;
YY_BUFFER_STATE yy_scan_bytes(const char*, int);
void yy_delete_buffer(YY_BUFFER_STATE);
int yylex_destroy();
void ResetLexer();

namespace {
    struct ScannerGuard {
        YY_BUFFER_STATE buffer;

        ~ScannerGuard() {
            yy_delete_buffer(buffer);
            yylex_destroy();
        }
    };
}

bool ParseSource(const std::string& source, const std::string& filename) {
    LexerSupport::Reset(source, filename);
    if (source.size() > std::size_t(std::numeric_limits<int>::max()) - 2) {
        LexerSupport::Error({1, 1, 1, 1, 0, 0}, "input is too large");
        return false;
    }
    if (!LexerSupport::ValidateSource()) return false;

    std::size_t skip = source.compare(0, 3, "\xEF\xBB\xBF") == 0 ? 3 : 0;
    ScannerGuard scanner{yy_scan_bytes(source.data() + skip, static_cast<int>(source.size() - skip))};
    ResetLexer();
    return yyparse() == 0 && !LexerSupport::failed;
}
