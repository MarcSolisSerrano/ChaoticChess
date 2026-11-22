#pragma once

#include "ChaoticChess/Utils/TypeDefinitions.h"

namespace Utils
{
	template <typename T>
	consteval std::size_t BitsSizeOf() noexcept
	{
		using type = std::remove_reference_t<T>;

		if constexpr (std::is_pointer_v<type>)
		{
			return sizeof(std::remove_pointer_t<type>) * 8;	// 1 byte = 8 bits
		}
		else
		{
			return sizeof(type) * 8;	// 1 byte = 8 bits
		}
	};

	//Defines a valid type to operate with raw data of size N
	template <uint8_t N>
	struct RawType
	{
		RawType() = delete;
	};

	template <>
	struct RawType<1>
	{
		using type = uint8_t;
	};

	template <>
	struct RawType<2>
	{
		using type = uint16_t;
	};

	template <>
	struct RawType<4>
	{
		using type = uint32_t;
	};

	template <>
	struct RawType<8>
	{
		using type = uint64_t;
	};
}
