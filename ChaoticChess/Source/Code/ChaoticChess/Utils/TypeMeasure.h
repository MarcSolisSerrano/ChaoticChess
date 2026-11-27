#pragma once
#include <type_traits>

namespace Utils
{
	template <typename T>
	consteval size_t BitsSizeOf() noexcept
	{
		using type = std::remove_reference<T>;

		if constexpr (std::is_pointer<type>::value)
		{
			return sizeof(*type) * 8;	// 1 byte = 8 bits
		}
		else
		{
			return sizeof(type) * 8;	// 1 byte = 8 bits
		}
	};
}
