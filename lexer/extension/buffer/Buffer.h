#ifndef COMPILER_BUFFER_H
#define COMPILER_BUFFER_H

#include <string>

using std::string;

class Buffer {
private:
    string content;
    int startLine = 0;

public:
    void Reset(int line);
    void Append(const string& text);

    const string& Get() const;
    int GetStartLine() const;
};

#endif