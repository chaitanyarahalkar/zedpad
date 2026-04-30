#!/bin/bash
# Guard: app must compile AND all unit tests must pass
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SIM_UDID="471E6102-3ECB-4DF3-A55B-A6E71773A9DA"
DEST="platform=iOS Simulator,id=$SIM_UDID"

echo "▶ Guard: build check..." >&2
xcodebuild build \
  -project "$PROJECT_DIR/ZedIPad.xcodeproj" \
  -scheme "ZedIPad" \
  -destination "$DEST" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  -quiet 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" | tail -3

echo "▶ Guard: unit tests..." >&2
RESULT=$(xcodebuild test \
  -project "$PROJECT_DIR/ZedIPad.xcodeproj" \
  -scheme "ZedIPadTests" \
  -destination "$DEST" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  2>&1)

FAILED=$(echo "$RESULT" | grep -c "Test Case.*failed" || echo 0)
if [ "$FAILED" -gt 0 ]; then
  echo "✗ Guard FAILED: $FAILED unit test(s) failing" >&2
  exit 1
fi

echo "✓ Guard passed" >&2
