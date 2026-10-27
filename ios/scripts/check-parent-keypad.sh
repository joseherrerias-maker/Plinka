#!/bin/bash
set -euo pipefail
app_path="$1"
xcodegen generate --spec ios/VisualDriver/project.yml
mkdir -p "$RUNNER_TEMP/PlukiParentCheck"
for device_type in 'com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation' 'com.apple.CoreSimulator.SimDeviceType.iPad-Pro-11-inch-M4'; do
    keypad_device=$(xcrun simctl create 'Pluki Parent Check' "$device_type")
    trap 'xcrun simctl shutdown "$keypad_device" >/dev/null 2>&1 || true; xcrun simctl delete "$keypad_device" >/dev/null 2>&1 || true' EXIT
    xcrun simctl boot "$keypad_device"
    xcrun simctl bootstatus "$keypad_device" -b
    xcrun simctl install "$keypad_device" "$app_path"
    xcodebuild test -project ios/VisualDriver/VisualDriver.xcodeproj -scheme VisualDriver \
      -destination "id=$keypad_device" -parallel-testing-enabled NO \
      -only-testing:VisualDriver/ParentKeypadTests \
      -resultBundlePath "$RUNNER_TEMP/PlukiParentCheck/$device_type.xcresult" \
      CODE_SIGNING_ALLOWED=NO > "$RUNNER_TEMP/PlukiParentCheck/$device_type.log" 2>&1 || {
        tail -100 "$RUNNER_TEMP/PlukiParentCheck/$device_type.log"; exit 1;
      }
    xcrun simctl shutdown "$keypad_device"
    xcrun simctl delete "$keypad_device"
    trap - EXIT
done
