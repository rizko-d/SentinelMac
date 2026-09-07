#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BUILD_DIR="$DIR/.build"
mkdir -p "$BUILD_DIR"

echo "[+] Compiling SentinelCore module..."
swiftc -emit-library -emit-module \
    -module-name SentinelCore \
    "$DIR/Sources/SentinelCore/ProcessResolver.swift" \
    -o "$BUILD_DIR/libSentinelCore.dylib"

echo "[+] Compiling SentinelMac CLI..."
swiftc "$DIR/Sources/SentinelMac/main.swift" \
    -I"$BUILD_DIR" \
    -L"$BUILD_DIR" \
    -lSentinelCore \
    -Xlinker -rpath -Xlinker "$BUILD_DIR" \
    -o "$BUILD_DIR/SentinelMac"

echo "[+] Running SentinelMac test binary..."
"$BUILD_DIR/SentinelMac"
