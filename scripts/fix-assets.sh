#!/bin/bash
# Copies fixed Contents.json files into Assets.xcassets (fixes actool "Operation timed out" / "couldn't be opened")
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ASSETS="$REPO_ROOT/WalkyTrails/WalkyTrails/Assets.xcassets"
FIX="$REPO_ROOT/docs/asset-fix"

cp "$FIX/Assets-Contents.json" "$ASSETS/Contents.json"
cp "$FIX/AppIcon-Contents.json" "$ASSETS/AppIcon.appiconset/Contents.json"
cp "$FIX/AccentColor-Contents.json" "$ASSETS/AccentColor.colorset/Contents.json"

echo "Done. Fixed 3 Contents.json files in Assets.xcassets. Try building in Xcode again."
