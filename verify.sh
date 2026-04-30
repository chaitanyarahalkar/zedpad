#!/bin/bash
# Autoresearch verify script — outputs composite score (higher = better)
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEME="ZedIPad"
DEST="generic/platform=iOS Simulator"
SCREENSHOTS_DIR="$PROJECT_DIR/autoresearch-screenshots"

mkdir -p "$SCREENSHOTS_DIR"

# 1. Build errors (lower is better, penalises score)
echo "▶ Building..." >&2
BUILD_OUTPUT=$(xcodebuild build \
  -project "$PROJECT_DIR/ZedIPad.xcodeproj" \
  -scheme "$SCHEME" \
  -destination "$DEST" \
  -configuration Debug \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  2>&1)
ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "^.*error:" || true)
echo "  Compile errors: $ERRORS" >&2

# 2. Unit tests passed
echo "▶ Running unit tests..." >&2
TEST_OUTPUT=$(xcodebuild test \
  -project "$PROJECT_DIR/ZedIPad.xcodeproj" \
  -scheme "ZedIPadTests" \
  -destination "$DEST" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  2>&1) || true
TESTS_PASSED=$(echo "$TEST_OUTPUT" | grep -c "Test Case.*passed" || true)
echo "  Tests passed: $TESTS_PASSED" >&2

# 3. Lines of Swift code (higher = more features implemented)
LOC=$(find "$PROJECT_DIR/ZedIPad" -name "*.swift" -exec wc -l {} \; 2>/dev/null | \
  awk '{sum += $1} END {print sum}')
echo "  Lines of Swift: $LOC" >&2

# 4. Screenshots taken by UI tests
SCREENSHOTS=$(ls "$SCREENSHOTS_DIR"/*.png 2>/dev/null | wc -l | tr -d ' ')
echo "  Screenshots: $SCREENSHOTS" >&2

# Composite score
SCORE=$(echo "$TESTS_PASSED * 20 + $LOC / 10 + $SCREENSHOTS * 5 - $ERRORS * 50" | bc)
echo "  Composite score: $SCORE" >&2
echo "$SCORE"
