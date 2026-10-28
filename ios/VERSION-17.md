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
- The UI driver taps fields before testing keyboard visibility, locates sheets by their contents, and keeps scrolling gestures below the navigation bar. It resolves simulator identifiers from Xcode's device list and collects both devices even when one test fails.
- [iPhone SE interaction run](https://github.com/joseherrerias-maker/Plinka/actions/runs/40613506224): both EditorTests and ParentKeypadTests passed, covering portrait and landscape. Rename Cancel/Done, Save, keyboard visibility, centered Clear confirmation, Cancel, Clear and Undo passed. The job subsequently stopped on an invalid iPad simulator identifier; that identifier lookup was corrected before the focused iPad run.
- [Focused iPad interaction run](https://github.com/joseherrerias-maker/Plinka/actions/runs/40615453671): EditorTests passed in portrait and landscape. The parent-keypad test completed its portrait checks, then failed during landscape video-preview setup before reaching the keypad: XCTest reported that the app's main thread was busy for 30 seconds while waiting for Save to Photos. The cause is unresolved; this run is not fully green and does not establish an iPad landscape keypad pass. Owner-confirmed physical-iPad export remains the existing acceptance evidence, and production export code was not changed. Recheck that path on the signed candidate before submission.
- Simulator keyboard geometry and interactions passed; manually positioned floating-keyboard placement still requires physical-device acceptance. Landscape XCTest screenshot attachments were cropped and are not suitable for marketing captures.
- Signed compilation, physical-device acceptance and App Review submission remain pending.

## Release acceptance

Install over Build 16; verify saved songs survive, Rename/Save work with both keyboard modes in both orientations, clear dialog is centered, Cancel retains notes and Undo restores them. No new video feature or sound replacement is included.

## Archive

Retain 14, 15, 16. Archive 17 only after owner-confirmed successful compilation, then retain 15, 16, 17.

## App Store export correction

Owner confirmed successful Build 17 compilation and both iPad editor fixes. App Store Connect shows upload 1.0 (20) as Valid but Internal Only. The export script had explicitly enabled testFlightInternalTestingOnly; this is now false. Rebuild main in the same Codemagic workflow to create a new signed upload with the next available upload counter. Display Build 17 and app behavior are unchanged. Verify the replacement is eligible for App Store selection before submitting; upload 20 cannot be used for customer distribution. The compiled source archive remains the original compiled revision and is not silently replaced with an uncompiled export correction.
