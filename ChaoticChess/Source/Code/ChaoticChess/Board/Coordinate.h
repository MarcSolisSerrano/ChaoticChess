#pragma once
#include <cstdint>
#include <limits>

#include "ChaoticChess/Utils/TypeMeasure.h"


namespace Board
{
	struct Coordinate 
	{
		uint8_t x{ std::numeric_limits<uint8_t>::max() };
		uint8_t y{ std::numeric_limits<uint8_t>::max() };

		static const Coordinate Invalid;

		friend constexpr bool operator==(const Coordinate& lhs, const Coordinate& rhs);
		friend constexpr bool operator!=(const Coordinate& lhs, const Coordinate& rhs);
		friend constexpr bool operator<(const Coordinate& lhs, const Coordinate& rhs);
	};


	constexpr bool operator==(const Board::Coordinate& lhs, const Board::Coordinate& rhs)
	{
		return lhs.x == rhs.x && lhs.y == rhs.y;
	}

	constexpr bool operator!=(const Board::Coordinate& lhs, const Board::Coordinate& rhs)
	{
		return !(lhs == rhs);
	}

	constexpr bool operator<(const Board::Coordinate& lhs, const Board::Coordinate& rhs)
	{
		return (static_cast<uint16_t>(lhs.x) << Utils::BitsSizeOf<decltype(Coordinate().y)>() | static_cast<uint16_t>(lhs.y)) < (static_cast<uint16_t>(rhs.x) << 8 | static_cast<uint16_t>(rhs.y));
	}

}

