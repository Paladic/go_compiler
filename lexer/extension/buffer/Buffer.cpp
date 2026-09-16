#include "Buffer.h"

void Buffer::Reset(int line) {
    content.clear();
    startLine = line;
}

void Buffer::Append(const string& text) {
    content += text;
}

const string& Buffer::Get() const {
    return content;
}

int Buffer::GetStartLine() const {
    return startLine;
}