#!/usr/bin/env bash

set -e  # exit on error

# === Displays a message in console as title
TITLE(){
    local MESSAGE="$1"

    printf '\n%s\n' "======================================"
    printf '%b\n' "$MESSAGE"
    printf '%s\n\n' "======================================"
}

# === Detect CMake's default generator ===
get_default_generator(){
    local DEFAULT_GENERATOR=$(cmake --help | awk '
        /^\*/ {                                     #Find line starting with "*" (which marks the default generator)
            generator = $0

            sub(/^[^[:alpha:]]*/, "", generator)    #From start, removes everything until the first letter (exclusive)
            sub(/[[:space:]]*=.*$/, "", generator)  #Find any amout of spaces followed by an "=", and remove from that point [inclusive] untill the end of the line

            print generator
            exit
        }
    ')

    printf '%s\n' "$DEFAULT_GENERATOR"
}

# === Ensures a valid target solution based on 1st argument or default value ===
get_validated_target(){
    local BUILD_TARGET="${1:-main}"     # Use "main" as default target solution

    # === Normalize target ===
    case "$BUILD_TARGET" in
        -m) BUILD_TARGET="main" ;;
        -t) BUILD_TARGET="test" ;;
        -a) BUILD_TARGET="all"  ;;
    esac

    # === Validate target ===
    case "$BUILD_TARGET" in 
        main|test|all)
            ;;
        *)
            echo "======================================"
            echo "Invalid target: $BUILD_TARGET"
            echo "Accepted: [main|-m|test|-t|all|-a]"
            echo "======================================"
            echo ""

            return 1
            ;;
    esac

    printf '%s\n' "$BUILD_TARGET"
}

# === If new generation params differs from previous one, we need to do a clean build ===
refresh_cmake_cache(){
    local SELECTED_GENERATOR="$1"
    local BUILD_PATH="$2"

    # Read existing CMake cache.
    if [[ -f "$BUILD_PATH/CMakeCache.txt" ]]; then
        local CURRENT_GENERATOR=$(sed -n \
            's/^CMAKE_GENERATOR:INTERNAL=//p' \
            "$BUILD_PATH/CMakeCache.txt")

        local CURRENT_PLATFORM=$(sed -n \
            's/^CMAKE_GENERATOR_PLATFORM:INTERNAL=//p' \
            "$BUILD_PATH/CMakeCache.txt")


         # Check whether the generator changed.
        if [[ "$CURRENT_GENERATOR" != "$SELECTED_GENERATOR" ]]; then
            printf '\n%s\n' "Generator changed!"
            printf '%s\n' "Previous: $CURRENT_GENERATOR"
            printf '%s\n' "New:      $SELECTED_GENERATOR"
            printf '%s\n' "Cleaning build directory..."

            rm -rf -- "$BUILD_PATH"     # Remove build directory (clean build)
        fi    
    fi
}


# === Set target architectiure for different compilers ===
set_architecture(){
    local ARCHITECTURE="$1"
    local GENERATOR="$2"

    # Select architecture for Visual Studio.
    if [[ "$GENERATOR" == "Visual Studio "* ]]; then
        # MSVC + visual (for MSVC + Ninja, ARCHITECTURE native tools must be manually initialized first)
        CMAKE_ARGS+=(-A x"$ARCHITECTURE")
    else
         # GCC / Clang
        CMAKE_ARGS+=(-DCMAKE_C_FLAGS=-m"$ARCHITECTURE")
        CMAKE_ARGS+=(-DCMAKE_CXX_FLAGS=-m"$ARCHITECTURE")
    fi
}


# === Configure build directory ===
configure_build() {
    local SELECTED_GENERATOR="$1"
    local BUILD_PATH="$2"
    local SOLUTION_NAME="$3"
    local TEST_OPTION="$4"

    TITLE "Configuring ${SOLUTION_NAME} solution"

    refresh_cmake_cache "$SELECTED_GENERATOR" "$BUILD_PATH"
    mkdir -p "$BUILD_PATH"

    # Build CMake arguments.
    CMAKE_ARGS=(
        -G "$SELECTED_GENERATOR"
        -DTEST="$TEST_OPTION"
        -B "$BUILD_PATH"
        -S "$SOURCE_DIR"
    )

    # Request x64 architecture 
    set_architecture "64" "$SELECTED_GENERATOR"

    # Display the exact command for debugging.
    printf '%s' "Executing: cmake "
    printf '%s' "${CMAKE_ARGS[@]}"
    printf '\n\n'

    # Configure and propagate errors.
    cmake "${CMAKE_ARGS[@]}" || return $?

    printf '\n%b\n' "${SOLUTION_NAME} solution generated successfully."
}


main() {
# === Compute paths ===
SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  #Get absolute path of this script
BUILD_DIR="$SOURCE_DIR/../Solutions/App"
BUILD_TEST_DIR="$SOURCE_DIR/../Solutions/Test"

# Normalize paths for Windows Git Bash / MSYS ===
case "$(uname -s)" in
    MINGW*|MSYS*)
        BUILD_DIR=$(cygpath -m "$BUILD_DIR")
        BUILD_TEST_DIR=$(cygpath -m "$BUILD_TEST_DIR")
        SOURCE_DIR=$(cygpath -m "$SOURCE_DIR")
        ;;
esac


# === Target selection  ===
BUILD_TARGET="$(get_validated_target "$1")" || return $?


# === Generator selection ===
# Can be supplied as the 2nd argument or through CMAKE_GENERATOR; otherwise, get CMake's default generator
GENERATOR="${2:-${CMAKE_GENERATOR:-"$(get_default_generator)"}}"


# === GENERATE MAIN SOLUTION ===
if [[ "$BUILD_TARGET" == "all" || "$BUILD_TARGET" == "main" ]]; then
    configure_build "$GENERATOR" "$BUILD_DIR" "MAIN" OFF || return $?
fi


# === GENERATE TEST SOLUTION ===
if [[ "$BUILD_TARGET" == "all" || "$BUILD_TARGET" == "test" ]]; then
    configure_build "$GENERATOR" "$BUILD_TEST_DIR" "TEST" ON || return $?

    # Ask whether to compile and run tests
    printf '\n'
    read -r -n1 -p "Do you want to build and run the tests? [Y/N]: " RUN_TESTS
    printf '\n'

    if [[ "$RUN_TESTS" =~ ^[Yy]$ ]]; then
        printf '%s\n' "Building tests..."
        cmake --build "$BUILD_TEST_DIR" || return $?

        printf '%s\n' "Running tests..."
        ctest --test-dir "$BUILD_TEST_DIR" --output-on-failure || return $?
    else
        printf '%s\n' "Skipping test execution."
    fi
fi
}



main "$@" || EXIT_CODE=$?
EXIT_CODE=${EXIT_CODE:-0}

if [[ $EXIT_CODE == 0 ]]; then
    STATUS_MESSAGE="Build generation succeed."
else
    STATUS_MESSAGE="Process failed! (exit code: $EXIT_CODE)."
fi

TITLE "$STATUS_MESSAGE"

printf '%s\n' "Press ENTER to close this window."
read -r

exit "$EXIT_CODE"
