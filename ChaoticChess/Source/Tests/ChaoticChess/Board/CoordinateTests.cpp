
#include <gtest/gtest.h>
#include <gmock/gmock.h>

#include "ChaoticChess/Board/Coordinate.h"


using namespace ::testing;

namespace Board {

    namespace Tests {

        class ACoordinateTest : public Test
        {
        protected:

        };


        TEST_F(ACoordinateTest, WhenCoordinateDefaultInstantiated_ThenValueIsInvalid)
        {
			Coordinate defaultCoordinate;

            EXPECT_TRUE(defaultCoordinate == Coordinate::Invalid);
        }

	}
}