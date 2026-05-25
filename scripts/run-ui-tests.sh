#!/usr/bin/env bash
# Runs FairyFlap UI tests on small and large iPhone simulators.
#
# Covers App Store review expectations across device sizes and iOS 17.6+.
#
# Usage:
#   ./scripts/run-ui-tests.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCHEME="FairyFlap"
DERIVED_DATA="${DERIVED_DATA:-/tmp/FairyFlapUITestResults}"

SIMULATORS=(
  "Small (SE-class)|platform=iOS Simulator,name=iPhone 16e"
  "Standard|platform=iOS Simulator,name=iPhone 16"
  "Large|platform=iOS Simulator,name=iPhone 17 Pro Max"
)

echo "Running FairyFlapUITests on ${#SIMULATORS[@]} simulators (iOS deployment target: 17.6)"

for entry in "${SIMULATORS[@]}"; do
  IFS='|' read -r label destination <<< "$entry"
  echo ""
  echo "========== $label =========="
  xcodebuild test \
    -scheme "$SCHEME" \
    -destination "$destination" \
    -derivedDataPath "$DERIVED_DATA" \
    -only-testing:FairyFlapUITests \
    CODE_SIGNING_ALLOWED=NO
done

echo ""
echo "All UI test runs completed."
