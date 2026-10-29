#pragma once
#include <string>

// Flex and Bison use shared state; call this function sequentially.
bool ParseSource(const std::string& source, const std::string& filename = "<input>");
