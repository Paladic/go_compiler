// Read a UTF-8 Go source file and report syntax errors.
#include "Parser.h"
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
    int Run(const std::vector<std::string>& arguments) {
        std::string filename;
        bool quiet = false;
        for (std::size_t index = 1; index < arguments.size(); ++index) {
            const std::string& argument = arguments[index];
            if (argument == "--help" || argument == "-h") {
                std::cout << "Usage: parser.exe [file.go|-] [--check] [--trace]\n";
                return 0;
            }
            if (argument == "--check") quiet = true;
            else if (argument == "--trace") yydebug = 1;
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
        if (!ParseSource(source, filename.empty() || filename == "-" ? "<stdin>" : filename)) return 1;
        if (!quiet) std::cout << "Syntax OK\n";
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
