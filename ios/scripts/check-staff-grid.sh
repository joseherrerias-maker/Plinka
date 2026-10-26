#!/bin/bash
# A small media-render check using the already compiled app, not UI automation.
set -euo pipefail
app_path="$1"
video_device=$(xcrun simctl create 'Pluki Grid Check' 'com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro')
trap 'xcrun simctl shutdown "$video_device" >/dev/null 2>&1 || true; xcrun simctl delete "$video_device" >/dev/null 2>&1 || true' EXIT
xcrun simctl boot "$video_device"
xcrun simctl bootstatus "$video_device" -b
xcrun simctl install "$video_device" "$app_path"
xcrun simctl launch "$video_device" com.joseherrerias.plinka --check-staff-grid
video_data=$(xcrun simctl get_app_container "$video_device" com.joseherrerias.plinka data)
for attempt in {1..90}; do
    if [ -f "$video_data/Documents/grid-check.txt" ]; then
        mkdir -p "$RUNNER_TEMP/PlukiGridCheck"
        cp "$video_data/Documents/"*.png "$video_data/Documents/grid-check.txt" "$RUNNER_TEMP/PlukiGridCheck/" 2>/dev/null || true
        cat "$video_data/Documents/grid-check.txt"
        grep -q '^PASS:' "$video_data/Documents/grid-check.txt"
        exit $?
    fi
    sleep 2
done
printf 'Staff grid check timed out\n' >&2
exit 1
