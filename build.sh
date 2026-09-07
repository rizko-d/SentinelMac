#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BUILD_DIR="$DIR/.build"
mkdir -p "$BUILD_DIR"

echo "[+] Compiling SentinelCore module..."
swiftc -emit-library -emit-module \
    -module-name SentinelCore \
    "$DIR/Sources/SentinelCore/ProcessResolver.swift" \
    "$DIR/Sources/SentinelCore/TLSParser.swift" \
    "$DIR/Sources/SentinelCore/BlocklistEngine.swift" \
    "$DIR/Sources/SentinelCore/LocalProxyServer.swift" \
    "$DIR/Sources/SentinelCore/TCCReader.swift" \
    "$DIR/Sources/SentinelCore/HardwareSensorWatcher.swift" \
    "$DIR/Sources/SentinelCore/AppState.swift" \
    "$DIR/Sources/SentinelCore/UIComponents.swift" \
    "$DIR/Sources/SentinelCore/DashboardWindowView.swift" \
    "$DIR/Sources/SentinelCore/MenuBarView.swift" \
    -lsqlite3 \
    -o "$BUILD_DIR/libSentinelCore.dylib"

echo "[+] Compiling SentinelMac CLI..."
swiftc "$DIR/Sources/SentinelMac/main.swift" \
    -I"$BUILD_DIR" \
    -L"$BUILD_DIR" \
    -lSentinelCore \
    -Xlinker -rpath -Xlinker "$BUILD_DIR" \
    -o "$BUILD_DIR/SentinelMac"

echo "[+] Compiling & Running Unit Tests..."
swiftc "$DIR/Tests/SentinelCoreTests/ProcessResolverTests.swift" \
    -I"$BUILD_DIR" -L"$BUILD_DIR" -lSentinelCore \
    -Xlinker -rpath -Xlinker "$BUILD_DIR" \
    -o "$BUILD_DIR/TestProcessResolver"
"$BUILD_DIR/TestProcessResolver"

swiftc "$DIR/Tests/SentinelCoreTests/TLSParserTests.swift" \
    -I"$BUILD_DIR" -L"$BUILD_DIR" -lSentinelCore \
    -Xlinker -rpath -Xlinker "$BUILD_DIR" \
    -o "$BUILD_DIR/TestTLSParser"
"$BUILD_DIR/TestTLSParser"

swiftc "$DIR/Tests/SentinelCoreTests/TCCReaderTests.swift" \
    -I"$BUILD_DIR" -L"$BUILD_DIR" -lSentinelCore -lsqlite3 \
    -Xlinker -rpath -Xlinker "$BUILD_DIR" \
    -o "$BUILD_DIR/TestTCCReader"
"$BUILD_DIR/TestTCCReader"

echo "[✓] Build & all Phase 4 tests succeeded."
