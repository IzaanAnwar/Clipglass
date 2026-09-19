#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
swift test "${SWIFT_ARGS[@]}" ${TEST_ARGS[@]+"${TEST_ARGS[@]}"} --enable-code-coverage "$@"
