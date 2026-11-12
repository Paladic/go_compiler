// Read a UTF-8 Go source file, then optionally export its AST.
#include "Parser.h"
#include "LexerSupport.h"
#include "ast/AstWriter.h"
#include <filesystem>
#include <fstream>
#include <iostream>
#include <iterator>
#include <stdexcept>
#include <vector>
#ifdef _WIN32
#include <windows.h>
#include <shellapi.h>
#endif

extern int yydebug;

namespace {
    bool SameFile(const std::string& first, const std::string& second) {
        if (first.empty() || second.empty() || first == "-") return false;
        auto a = std::filesystem::u8path(first);
        auto b = std::filesystem::u8path(second);
        std::error_code error;
        if (std::filesystem::equivalent(a, b, error)) return true;
        a = std::filesystem::weakly_canonical(a);
        b = std::filesystem::weakly_canonical(b);
#ifdef _WIN32
        return CompareStringOrdinal(a.c_str(), -1, b.c_str(), -1, TRUE) == CSTR_EQUAL;
#else
        return a == b;
#endif
    }

    template<typename Writer>
    void Write(const std::string& filename, Writer writer) {
        if (filename.empty()) return;
        std::ofstream output(std::filesystem::u8path(filename), std::ios::binary);
        if (!output) throw std::runtime_error("cannot open output: " + filename);
        writer(output);
        output.close();
        if (!output) throw std::runtime_error("cannot write output: " + filename);
    }

    int Run(const std::vector<std::string>& arguments) {
        std::string filename;
        std::string html;
        std::string dot;
        bool quiet = false;
        for (std::size_t index = 1; index < arguments.size(); ++index) {
            const std::string& argument = arguments[index];
            if (argument == "--help" || argument == "-h") {
                std::cout << "Usage: parser.exe [file.go|-] [--check] [--trace]\n"
                             "                  [--html tree.html] [--dot tree.dot]\n";
                return 0;
            }
            if (argument == "--check") quiet = true;
            else if (argument == "--trace") yydebug = 1;
            else if (argument == "--html" || argument == "--dot") {
                if (++index == arguments.size() || arguments[index].empty()
                    || arguments[index].compare(0, 2, "--") == 0) {
                    throw std::runtime_error("missing output filename after " + argument);
                }
                (argument == "--html" ? html : dot) = arguments[index];
            }
            else if (argument == "-" || (!argument.empty() && argument.front() != '-')) {
                if (!filename.empty()) throw std::runtime_error("only one input file is supported");
                filename = argument;
            } else throw std::runtime_error("unknown option: " + argument);
        }
        std::string source;
        if (filename.empty() || filename == "-") {
            source.assign(std::istreambuf_iterator<char>(std::cin), {});
        } else {
            std::ifstream input(std::filesystem::u8path(filename), std::ios::binary);
            if (!input) throw std::runtime_error("cannot open input: " + filename);
            source.assign(std::istreambuf_iterator<char>(input), {});
            if (input.bad()) throw std::runtime_error("cannot read input: " + filename);
        }
        const std::string label = filename.empty() || filename == "-" ? "<stdin>" : filename;
        if (SameFile(filename, html) || SameFile(filename, dot) || SameFile(html, dot)) {
            throw std::runtime_error("input, HTML and DOT paths must be different");
        }
        const AstNode* rejectedTree = nullptr;
        const bool accepted = ParseSource(source, label, html.empty() ? nullptr : &rejectedTree);
        Write(html, [&](std::ostream& out) {
            const auto& diagnostic = LexerSupport::LastError();
            AstWriter::Html(out, accepted ? astRoot : rejectedTree, label, source,
                            diagnostic.message, diagnostic.range);
        });
        if (!accepted) return 1;
        Write(dot, [&](std::ostream& out) { AstWriter::Dot(out, *astRoot); });
        if (!quiet) std::cout << "AST OK\n";
        return 0;
    }

    std::vector<std::string> ReadArguments(int count, char* values[]) {
        std::vector<std::string> arguments;
#ifdef _WIN32
        (void)count;
        (void)values;
        int wideCount = 0;
        LPWSTR* wide = CommandLineToArgvW(GetCommandLineW(), &wideCount);
        if (!wide) throw std::runtime_error("cannot read command line");
        for (int index = 0; index < wideCount; ++index) {
            int length = WideCharToMultiByte(CP_UTF8, 0, wide[index], -1, nullptr, 0, nullptr, nullptr);
            std::string argument(length, '\0');
            WideCharToMultiByte(CP_UTF8, 0, wide[index], -1, argument.data(), length, nullptr, nullptr);
            argument.pop_back();
            arguments.push_back(std::move(argument));
        }
        LocalFree(wide);
#else
        for (int index = 0; index < count; ++index) arguments.emplace_back(values[index]);
#endif
        return arguments;
    }
}

int main(int count, char* values[]) {
#ifdef _WIN32
    SetConsoleOutputCP(CP_UTF8);
#endif
    try { return Run(ReadArguments(count, values)); }
    catch (const std::exception& error) {
        std::cerr << "parser: " << error.what() << '\n';
        return 2;
    }
}
