#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
ICONSET="$PROJECT_ROOT/.build/Clipglass.iconset"
mkdir -p "$ICONSET"
swift scripts/draw-icon.swift "$PROJECT_ROOT/.build/icon-1024.png"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" .build/icon-1024.png --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z "$double" "$double" .build/icon-1024.png --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$PROJECT_ROOT/.build/Clipglass.icns"
