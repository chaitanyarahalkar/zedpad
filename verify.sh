#!/bin/bash
# Autoresearch verify script — outputs composite score (higher = better)
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEME="ZedIPad"
SIM_UDID="471E6102-3ECB-4DF3-A55B-A6E71773A9DA"
DEST="platform=iOS Simulator,id=$SIM_UDID"
SCREENSHOTS_DIR="$PROJECT_DIR/autoresearch-screenshots"

if ! xcodebuild -version >/dev/null 2>&1 && [ -d /Applications/Xcode.app/Contents/Developer ]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
elif xcode-select -p 2>/dev/null | grep -q "/CommandLineTools$" && [ -d /Applications/Xcode.app/Contents/Developer ]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

XCODEBUILD=(xcodebuild -sdk iphonesimulator)

mkdir -p "$SCREENSHOTS_DIR"

# 1. Build errors (penalises score)
echo "▶ Building..." >&2
BUILD_OUTPUT=$("${XCODEBUILD[@]}" build \
  -project "$PROJECT_DIR/ZedIPad.xcodeproj" \
  -scheme "$SCHEME" \
  -destination "$DEST" \
  -configuration Debug \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  2>&1) || true
ERRORS=$(echo "$BUILD_OUTPUT" | grep -E "^.* error:" | grep -v "^note:" | wc -l | tr -d ' ') || ERRORS=0
echo "  Compile errors: $ERRORS" >&2

# 2. Unit tests
echo "▶ Running unit tests..." >&2
UNIT_OUTPUT=$("${XCODEBUILD[@]}" test \
  -project "$PROJECT_DIR/ZedIPad.xcodeproj" \
  -scheme "ZedIPadTests" \
  -destination "$DEST" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  2>&1) || true
UNIT_PASSED=$(echo "$UNIT_OUTPUT" | grep -c "Test Case.*passed" 2>/dev/null) || UNIT_PASSED=0
echo "  Unit tests passed: $UNIT_PASSED" >&2

# 3. UI tests (with screenshots)
echo "▶ Running UI tests..." >&2
UI_OUTPUT=$("${XCODEBUILD[@]}" test \
  -project "$PROJECT_DIR/ZedIPad.xcodeproj" \
  -scheme "ZedIPadUITests" \
  -destination "$DEST" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  2>&1) || true
UI_PASSED=$(echo "$UI_OUTPUT" | grep -c "Test Case.*passed" 2>/dev/null) || UI_PASSED=0
echo "  UI tests passed: $UI_PASSED" >&2

TESTS_PASSED=$((UNIT_PASSED + UI_PASSED))

# 4. Lines of Swift code
LOC=$(find "$PROJECT_DIR/ZedIPad" -name "*.swift" -exec wc -l {} \; 2>/dev/null | \
  awk '{sum += $1} END {print sum+0}')
echo "  Lines of Swift: $LOC" >&2

# 5. Screenshots saved to disk
SCREENSHOTS=$(find "$SCREENSHOTS_DIR" -name "*.png" 2>/dev/null | wc -l | tr -d ' ') || SCREENSHOTS=0
echo "  Screenshots on disk: $SCREENSHOTS" >&2

# Composite score
SCORE=$(echo "$TESTS_PASSED * 20 + $LOC / 10 + $SCREENSHOTS * 5 - $ERRORS * 50" | bc)
echo "  Composite score: $SCORE" >&2
echo "$SCORE"
