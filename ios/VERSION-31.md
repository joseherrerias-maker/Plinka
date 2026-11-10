# Pluki 1.1 — Build 31: restore playfulness, accessible Clear, and Duo responsiveness

## Scope

This is a targeted polish update based on feedback from native TestFlight Build 30. It preserves Build 29 draft recovery, the one-obvious-action Home hierarchy, the Pluki Theme/Samples, sticker scale and bounce, save/import/export, parent gates, audio and signatures.

### 1. Home feels like a children's music app again
- Keep the prominent green **Make music / Continue song** primary action.
- Restore soft colorful rounded tiles on secondary actions: green **New song** (when a melody exists), orange **Open song**, purple **Samples**, blue **Help & About**. Make icons warm, larger and accessible instead of thin uniform blue.
- Change the repetitive tagline to **Your little music studio**.
- Keep the studio-room artwork, warm paper panels, rounded typography and strong primary-action hierarchy.

### 2. Restore easy access to Clear notes
- Restore the toolbar trash button (44pt minimum touch target) in regular-size toolbars, including normal iPhone portrait and iPad.
- Keep **Clear all notes** in Song menu everywhere; compact iPhone landscape uses menu-only to avoid crowding the one-row toolbar.
- Retain confirmation and Undo/Redo after clearing; do not alter the underlying song persistence or undo logic.
- Add a dedicated UI check for toolbar visibility vs menu fallback in portrait/landscape. Keep existing clear/menu regression checks.

### 3. Optimize closed iPhone Duo and resizable displays
- Use the **actual SwiftUI safe-area viewport** on Home, with compact spacing and a shorter brand panel when it is narrow and short. Leave ample touch targets; do not simply shrink everything.
- Use the icon-only brand in narrow editor toolbars up to 540pt so the restored Clear button and the editor controls fit beside one another.
- Let studio-room background artwork extend behind system-owned safe areas, while foreground actions remain within the SwiftUI safe area. Never hardcode a camera/status-bar inset or device model.
- **Important SDK requirement**: Apple's official guidance explains why the native screenshot shows a white strip to the right of the outer display. iOS 27 SDK apps are positioned to the left of the camera/status rail. iOS **27.1 SDK or later** lets apps use the full iPhone Duo display with system bars automatically adapting. Use **Xcode 27.1 or later in the existing manual Xcode Cloud workflow**, then validate both closed and open postures on a real Duo. Changing SwiftUI padding alone cannot remove the SDK-limited OS rail.
- Full-bleed background applies across safe-area transitions; layout adapts to window size rather than explicit screen dimensions.
- Apple developer references: https://developer.apple.com/iphone-duo/prepare/ and https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo

## Validation / release constraints

- Intentionally advance source build from 29 to **31** (Build 30 was already distributed by Xcode Cloud); do not increment on failed CI attempts. Version remains 1.1.
- GitHub Actions runs existing source, audio/resources/privacy/undo/recovery and unsigned Debug/Release compilation. The editor UI regression includes checking toolbar Clear in standard layouts and menu fallback in compact landscape; video/parent gates stay unchanged.
- Request normal iPhone + iPad simulator screenshots with the existing visual-review workflow when feasible; **no Duo simulator/Device Hub results are claimed** unless a real Duo pose is actually tested using Xcode 27.1.
- On physical closed and open Duo: inspect Home layout, system status rail, full-bleed background, primary/secondary buttons, keyboard parent check and editor toolbar, safe area and rotation. Check iPad portrait/landscape and iPhone landscape; verify Clear, confirmation, Undo, audio and saved-song recovery.
- Keep signing and the single Xcode Cloud `main` workflow unchanged; no NoMac, website preview, signed upload or public App Store submission in this change. The user triggers distribution.

## Results

Source implementation is ready for GitHub CI and device QA; do not mark full Duo optimization verified from source inspection alone.
