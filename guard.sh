#!/bin/bash
# Guard: app must compile AND unit tests must pass
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST="generic/platform=iOS Simulator"

echo "▶ Guard: checking build..." >&2
xcodebuild build \
  -project "$PROJECT_DIR/ZedIPad.xcodeproj" \
  -scheme "ZedIPad" \
  -destination "$DEST" \
  -configuration Debug \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  -quiet 2>&1 | tail -3

echo "▶ Guard: running unit tests..." >&2
xcodebuild test \
  -project "$PROJECT_DIR/ZedIPad.xcodeproj" \
  -scheme "ZedIPadTests" \
  -destination "$DEST" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  -quiet 2>&1 | tail -3

echo "✓ Guard passed" >&2
