#!/usr/bin/env bash

set -e  # exit on error


# === Detect CMake's default generator ===
get_default_generator() {
    local DEFAULT_GENERATOR

    DEFAULT_GENERATOR=$(cmake --help | awk '
        /^[[:space:]]*\*/ {
            generator = $0

            sub(/^[[:space:]]*\*[[:space:]]*/, "", generator)
            sub(/[[:space:]]*=.*/, "", generator)

            print generator
            exit
        }
    ')

    if [[ -z "$DEFAULT_GENERATOR" ]]; then
        echo "ERROR: Could not detect CMake's default generator." >&2
        return 1
    fi

    printf '%s\n' "$DEFAULT_GENERATOR"
}


# === Configure build directory ===
configure_build() {
    local BUILD_PATH="$1"
    local TEST_OPTION="$2"

    local CURRENT_GENERATOR=""
    local CURRENT_PLATFORM=""
    local SELECTED_GENERATOR="$GENERATOR"

    # Read existing CMake cache.
    if [[ -f "$BUILD_PATH/CMakeCache.txt" ]]; then
        CURRENT_GENERATOR=$(sed -n \
            's/^CMAKE_GENERATOR:INTERNAL=//p' \
            "$BUILD_PATH/CMakeCache.txt")

        CURRENT_PLATFORM=$(sed -n \
            's/^CMAKE_GENERATOR_PLATFORM:INTERNAL=//p' \
            "$BUILD_PATH/CMakeCache.txt")
    fi

    # Select generator.
    if [[ -z "$SELECTED_GENERATOR" ]]; then
        if [[ -n "$CURRENT_GENERATOR" ]]; then
            SELECTED_GENERATOR="$CURRENT_GENERATOR"
        else
            SELECTED_GENERATOR="$DEFAULT_GENERATOR"
        fi
    fi

    # Check whether the generator changed.
    if [[ -n "$CURRENT_GENERATOR" && "$CURRENT_GENERATOR" != "$SELECTED_GENERATOR" ]]; then
        echo "Generator changed!"
        echo "Previous: $CURRENT_GENERATOR"
        echo "New:      $SELECTED_GENERATOR"
        echo "Cleaning build directory..."

        rm -rf -- "$BUILD_PATH"
        CURRENT_GENERATOR=""
        CURRENT_PLATFORM=""
    fi

    # Ensure Visual Studio uses x64.
    if [[ "$SELECTED_GENERATOR" == "Visual Studio "* && "$CURRENT_PLATFORM" != "x64" ]]; then
        echo "Visual Studio architecture is not x64."
        echo "Cleaning build directory..."

        rm -rf -- "$BUILD_PATH"
    fi

    mkdir -p "$BUILD_PATH"

    # Build CMake arguments.
    local CMAKE_ARGS=(
        -G "$SELECTED_GENERATOR"
    )

    # Select x64 for Visual Studio.
    if [[ "$SELECTED_GENERATOR" == "Visual Studio "* ]]; then
        CMAKE_ARGS+=(-A x64)
    fi

    # Add project configuration arguments.
    CMAKE_ARGS+=(
        -DTEST="$TEST_OPTION"
        -B "$BUILD_PATH"
        -S "$SOURCE_DIR"
    )

    echo "Generator: $SELECTED_GENERATOR"

    # Display the exact command for debugging.
    printf 'Executing:'
    printf ' %q' cmake "${CMAKE_ARGS[@]}"
    printf '\n'

    # Configure and propagate errors.
    cmake "${CMAKE_ARGS[@]}" || return $?
}


main() {

# === Compute paths ===
SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR="$SOURCE_DIR/../Solutions/App"
BUILD_TEST_DIR="$SOURCE_DIR/../Solutions/Test"

#  === Default target  ===
BUILD_TARGET="${1:-main}"


# === Generator selection ===
# Can be supplied as the second argument or through CMAKE_GENERATOR.
GENERATOR="${2:-${CMAKE_GENERATOR:-}}"

# Detect CMake's default generator.
DEFAULT_GENERATOR="$(get_default_generator)"


# === Normalize target ===
case "$BUILD_TARGET" in
    -m) BUILD_TARGET="main" ;;
    -t) BUILD_TARGET="test" ;;
    -a) BUILD_TARGET="all" ;;
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


# === Normalize paths for Windows Git Bash / MSYS ===
case "$(uname -s)" in
    MINGW*|MSYS*)
        BUILD_DIR=$(cygpath -m "$BUILD_DIR")
        BUILD_TEST_DIR=$(cygpath -m "$BUILD_TEST_DIR")
        SOURCE_DIR=$(cygpath -m "$SOURCE_DIR")
        ;;
esac


# === GENERATE MAIN SOLUTION ===
if [[ "$BUILD_TARGET" == "all" || "$BUILD_TARGET" == "main" ]]; then
    echo "======================================"
    echo " Configuring MAIN solution"
    echo "======================================"
    echo ""

    configure_build "$BUILD_DIR" OFF || return $?

    echo ""
    echo "Main solution generated successfully."
    echo ""
fi


# === GENERATE TEST SOLUTION ===
if [[ "$BUILD_TARGET" == "all" || "$BUILD_TARGET" == "test" ]]; then
    echo "======================================"
    echo " Configuring TEST solution"
    echo "======================================"
    echo ""

    configure_build "$BUILD_TEST_DIR" ON || return $?

    echo ""
    echo "Test solution generated successfully."
    echo ""


 # === Ask whether to compile and run tests ===
    echo ""
    read -r -p "Do you want to build and run the tests? [Y/N]: " RUN_TESTS

    if [[ "$RUN_TESTS" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Building tests..."

        cmake --build "$BUILD_TEST_DIR" || return $?

        echo ""
        echo "Running tests..."

        ctest --test-dir "$BUILD_TEST_DIR" --output-on-failure || return $?
    else
        echo ""
        echo "Skipping test execution."
    fi
fi


echo ""
echo "======================================"
echo "Build generation completed."
echo "======================================"
echo ""

}


main "$@" || EXIT_CODE=$?
EXIT_CODE=${EXIT_CODE:-0}

echo ""
echo "======================================"
echo "Process finished (exit code: $EXIT_CODE)."
echo "Press ENTER to close this window."
echo "======================================"

read -r

exit "$EXIT_CODE"
