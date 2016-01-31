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
        // Workaround for confirmed bug in VS2015.
        // See: https://social.msdn.microsoft.com/Forums/en-US/8f40dcd8-c67f-4eba-9134-a19b9178e481/vs-2015-rc-linker-stdcodecvt-error
        #if defined(_MSC_VER) && (_MSC_VER == 1900)
            auto s = std::wstring_convert<std::codecvt_utf8_utf16<int16_t>, int16_t>().from_bytes(in);
            auto p = reinterpret_cast<char16_t const*>(s.data());
            out.assign(p, p + s.size());
        #else
            out = std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t>().from_bytes(in);
        #endif
        return out;
    }

    inline std::string convert(nanodbc::string_type const& in)
    {
        std::string out;
        // See above for details about this workaround.
        #if defined(_MSC_VER) && (_MSC_VER == 1900)
            std::wstring_convert<std::codecvt_utf8_utf16<int16_t>, int16_t> convert;
            auto p = reinterpret_cast<const int16_t *>(in.data());
            out = convert.to_bytes(p, p + in.size());
        #else
            out = std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t>().to_bytes(in);
        #endif
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

template <typename T>
inline std::string any_to_string(T const& t)
{
    return std::to_string(t);
}

template <>
inline std::string any_to_string<nanodbc::string_type>(nanodbc::string_type const& t)
{
    return convert(t);
}

#endif // NANODBC_UNICODE_UTILS_H
