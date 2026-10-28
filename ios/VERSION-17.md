# Pluki Build 17 — Release Candidate 5

Prepared October 28, 2026. Version 1.0; display Build 17; fallback upload counter 18 (Codemagic uses PROJECT_BUILD_NUMBER).

## Changes

- Centered native Clear all notes? alert on iPhone/iPad, with explanatory message, Cancel and red Clear notes. Existing clear and undo behavior is preserved.
- Rename/Save open full-height editors on both platforms, with the name field near the top and native Form scrolling/keyboard avoidance. Explicit Cancel/Done/Save avoids accidental dismissal. This addresses the floating keyboard position shown in the owner's photos; a manually dragged floating keyboard can still cover arbitrary content. Verify on physical iPad with floating and docked keyboards in both orientations.
- VideoExport.swift, SupportViews.swift, audio files, parent approval and persistence logic are unchanged from Build 16. Owner confirmed working iPad video export.
- UI driver now checks screen geometry before tapping, and drags at the scroll-view edge outside the video player. The previous landscape failure snapshot had Save to Photos at y588 in a 375-point screen, while the app remained on Export video. isHittable alone was insufficient.
- New editor regression covers rename Cancel/Done, Save, keyboard visibility, centered clear alert, Cancel, Clear and Undo on iPhone SE and iPad in both orientations. Floating-keyboard dragging requires physical-device review.

## Build

Select **main → Pluki Build 17 RC5 - TestFlight and iPad ZIP** in Codemagic (`pluki-ios-dual-export`). One archive, existing signing and two exports. Signed compilation is pending. No App Review submission is triggered.

GitHub runs Debug/Release, persistence, approval, resources/privacy, media validation and targeted UI tests. Record actual outcomes rather than inferring success from compilation.

## Verification

- [Initial Build 17 run](https://github.com/joseherrerias-maker/Plinka/actions/runs/40609489512): Debug and Release builds, saved-song persistence, parent approval logic, orientation/resource checks and privacy checks passed.
- Portrait and landscape export checks passed: audio/video tracks, duration, late note and cancellation. Exported frames were visually reviewed; both retain the enlarged canvas, lowercase pluki! branding and two-line footer. Production export code is unchanged from Build 16.
- The early interaction runs exposed test-driver issues: waiting for an automatic keyboard before tapping the field, excluding visible bottom buttons with an 80-point inset, and dragging across the navigation area in landscape. The driver now taps the field, locates each sheet by its contents, and keeps gestures below its navigation bar. The timeout allows both fresh simulators to finish, and both devices are collected even if one reports a test failure.
- [Editor regression](https://github.com/joseherrerias-maker/Plinka/actions/runs/40611831923): Rename Cancel/Done, Save, keyboard visibility, centered Clear confirmation, Cancel, Clear and Undo passed on iPhone SE in both orientations. The separate keypad driver failed while scrolling; that run does not establish an iPad pass.
- [Updated two-device interaction run](https://github.com/joseherrerias-maker/Plinka/actions/runs/40613506224): pending. Do not infer a pass until the run completes and its results are reviewed. Physical floating-keyboard placement still requires owner acceptance.
- Signed compilation, physical-device acceptance and App Review submission remain pending.

## Release acceptance

Install over Build 16; verify saved songs survive, Rename/Save work with both keyboard modes in both orientations, clear dialog is centered, Cancel retains notes and Undo restores them. No new video feature or sound replacement is included.

## Archive

Retain 14, 15, 16. Archive 17 only after owner-confirmed successful compilation, then retain 15, 16, 17.
