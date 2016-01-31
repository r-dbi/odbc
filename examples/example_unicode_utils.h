#ifndef NANODBC_UNICODE_UTILS_H
#define NANODBC_UNICODE_UTILS_H

#include "nanodbc.h"

#include <codecvt>
#include <locale>
#include <string>

#ifdef NANODBC_USE_UNICODE
    #undef NANODBC_TEXT
    #define NANODBC_TEXT(s) u ## s

    inline nanodbc::string_type convert(std::string const& in)
    {
        std::u16string out;
        out = std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t>().from_bytes(in);
        return out;
    }

    inline std::string convert(nanodbc::string_type const& in)
    {
        std::string out;
        out = std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t>().to_bytes(in);
        return out;
    }
#else
    #undef NANODBC_TEXT
    #define NANODBC_TEXT(s) s

    inline nanodbc::string_type convert(std::string const& in)
    {
        return in;
    }
#endif

#endif // NANODBC_UNICODE_UTILS_H
