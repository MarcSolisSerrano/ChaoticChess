#pragma once
#include <cstdint>
#include <limits>

#include "ChaoticChess/Utils/TypeOperations.h"


namespace Board
{
	struct Coordinate 
	{
		uint8_t x{ std::numeric_limits<uint8_t>::max() };
		uint8_t y{ std::numeric_limits<uint8_t>::max() };

		static const Coordinate Invalid;

		friend constexpr bool operator==(const Coordinate& lhs, const Coordinate& rhs) noexcept;
		friend constexpr bool operator!=(const Coordinate& lhs, const Coordinate& rhs) noexcept;
		friend constexpr bool operator<(const Coordinate& lhs, const Coordinate& rhs);
	};

	constexpr bool operator==(const Coordinate& lhs, const Coordinate& rhs) noexcept
	{
		return lhs.x == rhs.x && lhs.y == rhs.y;
	}

	constexpr bool operator!=(const Coordinate& lhs, const Coordinate& rhs) noexcept
	{
		return !(lhs == rhs);
	}

	constexpr bool operator<(const Coordinate& lhs, const Coordinate& rhs)
	{
		using type = Utils::RawType<sizeof(lhs.x) + sizeof(rhs.y)>::type;

		return (static_cast<type>(lhs.x) << Utils::BitsSizeOf<decltype(lhs.y)>() | static_cast<type>(lhs.y)) <
			(static_cast<type>(rhs.x) << Utils::BitsSizeOf<decltype(rhs.y)>() | static_cast<type>(rhs.y));
	}

}

namespace std
{
	inline void HashCombine(std::size_t& seed, std::size_t value) noexcept
	{
		seed ^= value + 0x9e3779b9 + (seed << 6) + (seed >> 2);
	}

	template<>
	struct hash<Board::Coordinate>
	{
		constexpr size_t operator()(const Board::Coordinate& coordinate) noexcept
		{
			size_t seed{ 0 };
			HashCombine(seed, std::hash<decltype(coordinate.x)>{}(coordinate.x));
			HashCombine(seed, std::hash<decltype(coordinate.y)>{}(coordinate.y));
			return seed;
		}
	};
}