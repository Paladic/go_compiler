#pragma once
#include <cstddef>
#include <type_traits>

struct SourceRange {
    int first_line;
    int first_column;
    int last_line;
    int last_column;
    std::size_t begin = 0;
    std::size_t end = 0;
};

static_assert(std::is_trivially_copyable<SourceRange>::value, "LR locations must support stack relocation");

inline void MergeSourceRange(SourceRange& result, SourceRange first, SourceRange last,
                  SourceRange previous, int count) {
    result = count ? first : previous;
    if (count) {
        result.last_line = last.last_line;
        result.last_column = last.last_column;
        result.end = last.end;
    } else {
        result.first_line = result.last_line;
        result.first_column = result.last_column;
        result.begin = result.end;
    }
}
