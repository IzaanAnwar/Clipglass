#!/usr/bin/env bash
# Shared toolchain selection for Xcode and standalone Command Line Tools.
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"
export CLANG_MODULE_CACHE_PATH="$PROJECT_ROOT/.build/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PROJECT_ROOT/.build/module-cache"
SWIFT_ARGS=(--disable-sandbox --cache-path "$PROJECT_ROOT/.build/cache")
TEST_ARGS=()
DEVELOPER_ROOT="$(xcode-select -p)"
if [[ "$DEVELOPER_ROOT" == */CommandLineTools ]]; then
    SWIFT_ARGS+=(--build-system native)
    TEST_ARGS+=(-Xswiftc -F -Xswiftc "$DEVELOPER_ROOT/Library/Developer/Frameworks")
    TEST_ARGS+=(-Xswiftc -plugin-path -Xswiftc "$DEVELOPER_ROOT/usr/lib/swift/host/plugins/testing")
    TEST_ARGS+=(-Xlinker -rpath -Xlinker "$DEVELOPER_ROOT/Library/Developer/Frameworks")
fi
