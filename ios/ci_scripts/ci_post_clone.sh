#!/bin/bash
# Generate Pluki's approved app icon before Xcode Cloud builds.
# Codemagic continues to use its existing icon-preparation step.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$SCRIPT_DIR/../scripts/prepare-app-icon.sh"
