#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ $# -lt 1 ]]; then
  echo 'Usage: scripts/verify.sh <dedicated-simulator-UDID>'
  exit 2
fi
DEVICE_ID="$1"
BUILD_DIR="${TMPDIR:-/tmp}/turnscene-verification"
mkdir -p output/validation
xcodebuild -project Crailglitun.xcodeproj -scheme Crailglitun -configuration Debug -sdk iphonesimulator -destination "platform=iOS Simulator,id=$DEVICE_ID" -derivedDataPath "$BUILD_DIR" CODE_SIGNING_ALLOWED=NO build > output/validation/build.log 2>&1
xcrun simctl install "$DEVICE_ID" "$BUILD_DIR/Build/Products/Debug-iphonesimulator/Crailglitun.app"
xcrun simctl terminate "$DEVICE_ID" com.tumo.Crailglitun 2>/dev/null || true
APP_DATA="$(xcrun simctl get_app_container "$DEVICE_ID" com.tumo.Crailglitun data)"
RESULT="$APP_DATA/Library/Application Support/TurnScene/self-tests.txt"
rm -f "$RESULT"
xcrun simctl launch "$DEVICE_ID" com.tumo.Crailglitun --self-test
for attempt in {1..30}; do
  if [[ -f "$RESULT" ]] && rg -q 'missing media produces export error' "$RESULT"; then
    cp "$RESULT" output/validation/self-tests.txt
    cp "$APP_DATA/Library/Application Support/TurnScene/qa-export.jpg" output/validation/qa-export.jpg
    if rg '^FAIL' output/validation/self-tests.txt; then exit 1; fi
    echo "$(rg -c '^PASS' output/validation/self-tests.txt) assertions passed."
    exit 0
  fi
  sleep 1
done
echo 'Self-tests did not finish within 30 seconds.'
exit 1
