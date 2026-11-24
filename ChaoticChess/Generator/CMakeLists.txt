
cmake_minimum_required (VERSION 3.20)

include("Utilities.cmake")
include(FetchContent) # Include FetchContent module

#Set paths
cmake_path(GET CMAKE_CURRENT_SOURCE_DIR PARENT_PATH ROOT_DIR)

cmake_path(GET ROOT_DIR FILENAME ProjectId)
string(REPLACE " " "_" ProjectId ${ProjectId})

set(SOURCE_DIR ${ROOT_DIR}/Source)
set(CODE_DIR ${SOURCE_DIR}/Code)
set(TEST_DIR ${SOURCE_DIR}/Test)
set(BUILDING_PROJECT_NAME ${ProjectId})


#Optional params
option(TEST "Generate test project" OFF)

if(TEST)
	set(BUILDING_PROJECT_NAME "${BUILDING_PROJECT_NAME}_Test")
	message(Building " ${BUILDING_PROJECT_NAME}")

	GetProjectExternalPath("${ROOT_DIR}" EXTERNAL_DIR)
	#Set WHERE FetchContent downloads dependencies
	set(FETCHCONTENT_BASE_DIR "${EXTERNAL_DIR}")

	#Declare GoogleTest dependency
	FetchContent_Declare(
		googletest
		GIT_REPOSITORY https://github.com/google/googletest.git
		GIT_TAG        52eb8108c5bdec04579160ae17225d66034bd723 # release-1.17.0
	)

	#Generate GoogleTest Project
	project(${BUILDING_PROJECT_NAME})

	if (MSVC)
		# Use MultiThreadedDebugDLL for Debug config
		set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")  # /MD
		set(gtest_force_shared_crt ON CACHE BOOL "Use shared CRT for GoogleTest" FORCE)
	endif()

	set(gtest_force_shared_crt on)
	FetchContent_MakeAvailable(googletest)	#Adds googletests to the build
	AddLibraryToCurrentTestProject(${ROOT_DIR} "${SOURCE_DIR}")
	SetLibraryCppStandard(${BUILDING_PROJECT_NAME} 20)
else()
	message(Building " ${BUILDING_PROJECT_NAME}")
	#Generate Main Project
	project(${BUILDING_PROJECT_NAME})
	AddLibraryToCurrentProject(${ROOT_DIR} "${CODE_DIR}")
	SetLibraryCppStandard(${BUILDING_PROJECT_NAME} 20)
endif()


#Set options
if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
	SetCompileOptionsMSVC(${BUILDING_PROJECT_NAME})
elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
	SetCompileOptionsGNU(${BUILDING_PROJECT_NAME})
endif()
