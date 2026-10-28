# Pluki Build 17 — Release Candidate 5

Prepared October 27, 2026. Version 1.0; display Build 17; fallback upload counter 18 (Codemagic uses PROJECT_BUILD_NUMBER).

## Changes

- Centered native Clear all notes? alert on iPhone/iPad, with explanatory message, Cancel and red Clear notes. Existing clear and undo behavior is preserved.
- Rename/Save open full-height editors on both platforms, with the name field near the top and native Form scrolling/keyboard avoidance. Explicit Cancel/Done/Save avoids accidental dismissal. This addresses the floating keyboard position shown in the owner's photos; a manually dragged floating keyboard can still cover arbitrary content. Verify on physical iPad with floating and docked keyboards in both orientations.
- VideoExport.swift, SupportViews.swift, audio files, parent approval and persistence logic are unchanged from Build 16. Owner confirmed working iPad video export.
- UI driver now checks screen geometry before tapping, and drags at the scroll-view edge outside the video player. The previous landscape failure snapshot had Save to Photos at y588 in a 375-point screen, while the app remained on Export video. isHittable alone was insufficient.
- New editor regression covers rename Cancel/Done, Save, keyboard visibility, centered clear alert, Cancel, Clear and Undo on iPhone SE and iPad in both orientations. Floating-keyboard dragging requires physical-device review.

## Build

Select **main → Pluki Build 17 RC5 - TestFlight and iPad ZIP** in Codemagic (`pluki-ios-dual-export`). One archive, existing signing and two exports. Signed compilation is pending. No App Review submission is triggered.

GitHub runs Debug/Release, persistence, approval, resources/privacy, media validation and targeted UI tests. Record actual outcomes rather than inferring success from compilation.

## Release acceptance

Install over Build 16; verify saved songs survive, Rename/Save work with both keyboard modes in both orientations, clear dialog is centered, Cancel retains notes and Undo restores them. No new video feature or sound replacement is included.

## Archive

Retain 14, 15, 16. Archive 17 only after owner-confirmed successful compilation, then retain 15, 16, 17.
