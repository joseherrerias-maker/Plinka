#!/bin/bash
set -euo pipefail
app_path="$1"
xcodegen generate --spec ios/VisualDriver/project.yml
mkdir -p "$RUNNER_TEMP/PlukiParentCheck"
defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool NO
checks_failed=0
device_names=('iPhone SE (3rd generation)' 'iPad Pro 11-inch (M4)')
if [[ -n "${PLUKI_UI_DEVICE:-}" ]]; then device_names=("$PLUKI_UI_DEVICE"); fi
for device_name in "${device_names[@]}"; do
    device_type=$(xcrun simctl list devicetypes --json | python3 -c 'import json,sys; devices=json.load(sys.stdin)["devicetypes"]; matches=[d["identifier"] for d in devices if d["name"]==sys.argv[1]]; assert len(matches)==1, "Simulator unavailable: "+sys.argv[1]; print(matches[0])' "$device_name")
    keypad_device=$(xcrun simctl create 'Pluki Parent Check' "$device_type")
    trap 'xcrun simctl shutdown "$keypad_device" >/dev/null 2>&1 || true; xcrun simctl delete "$keypad_device" >/dev/null 2>&1 || true' EXIT
    xcrun simctl boot "$keypad_device"
    xcrun simctl bootstatus "$keypad_device" -b
    xcrun simctl install "$keypad_device" "$app_path"
    xcodebuild test -project ios/VisualDriver/VisualDriver.xcodeproj -scheme VisualDriver \
      -destination "id=$keypad_device" -parallel-testing-enabled NO \
      -only-testing:VisualDriver/ParentKeypadTests -only-testing:VisualDriver/EditorTests \
      -resultBundlePath "$RUNNER_TEMP/PlukiParentCheck/$device_type.xcresult" \
      CODE_SIGNING_ALLOWED=NO > "$RUNNER_TEMP/PlukiParentCheck/$device_type.log" 2>&1 || {
        tail -100 "$RUNNER_TEMP/PlukiParentCheck/$device_type.log"
        checks_failed=1
      }
    xcrun xcresulttool export attachments --path "$RUNNER_TEMP/PlukiParentCheck/$device_type.xcresult" --output-path "$RUNNER_TEMP/PlukiParentCheck/$device_type-attachments" || checks_failed=1
    xcrun simctl shutdown "$keypad_device"
    xcrun simctl delete "$keypad_device"
    trap - EXIT
done
exit "$checks_failed"
