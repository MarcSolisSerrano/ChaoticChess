#pragma once

#include <cstdint>
#include <type_traits>

namespace Utils
{
    template <typename T>
    concept is_primitive_type = std::is_arithmetic_v<T> || std::is_enum_v<T>;

    static constexpr uint8_t MaxDataTypeByteSize{8};    // Max type size (bytes) for RawType
}