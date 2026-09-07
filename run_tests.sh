#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BUILD_DIR="$DIR/.build"

echo "[+] Compiling Test Suite..."
swiftc "$DIR/Tests/SentinelCoreTests/ProcessResolverTests.swift" \
    -I"$BUILD_DIR" \
    -L"$BUILD_DIR" \
    -lSentinelCore \
    -Xlinker -rpath -Xlinker "$BUILD_DIR" \
    -o "$BUILD_DIR/SentinelTests"

echo "[+] Running Unit Tests..."
"$BUILD_DIR/SentinelTests"
echo "[✓] All Phase 1 tests passed."
