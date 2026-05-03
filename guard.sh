#!/bin/bash
# Guard: app must compile AND all unit tests must pass
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SIM_UDID="471E6102-3ECB-4DF3-A55B-A6E71773A9DA"
DEST="platform=iOS Simulator,id=$SIM_UDID"

if ! xcodebuild -version >/dev/null 2>&1 && [ -d /Applications/Xcode.app/Contents/Developer ]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
elif xcode-select -p 2>/dev/null | grep -q "/CommandLineTools$" && [ -d /Applications/Xcode.app/Contents/Developer ]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

XCODEBUILD=(xcodebuild -sdk iphonesimulator)

echo "▶ Guard: build check..." >&2
BUILD_OUTPUT=$("${XCODEBUILD[@]}" build \
  -project "$PROJECT_DIR/ZedIPad.xcodeproj" \
  -scheme "ZedIPad" \
  -destination "$DEST" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  -quiet 2>&1)
echo "$BUILD_OUTPUT" | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" | tail -3 || true

echo "▶ Guard: unit tests..." >&2
set +e
RESULT=$("${XCODEBUILD[@]}" test \
  -project "$PROJECT_DIR/ZedIPad.xcodeproj" \
  -scheme "ZedIPadTests" \
  -destination "$DEST" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  2>&1)
TEST_STATUS=$?
set -e

FAILED=$(echo "$RESULT" | grep -c "Test Case.*failed" || true)
if [ "$TEST_STATUS" -ne 0 ] || [ "$FAILED" -gt 0 ]; then
  echo "$RESULT" | grep -E "error: -\\[|Test Suite '.*' failed|Executed .* failures|TEST FAILED" | tail -20 >&2 || true
  echo "✗ Guard FAILED: $FAILED unit test(s) failing" >&2
  exit 1
fi

echo "✓ Guard passed" >&2
