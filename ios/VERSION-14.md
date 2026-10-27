# Pluki Build 14 — Release Candidate 2

Prepared October 27, 2026. Marketing version remains 1.0. Build 13 is the last owner-confirmed signed compilation; this file does not claim Build 14 has compiled or passed device acceptance.

## Changes

- Rename the current song from its title and pencil at the top of the song menu. Settings no longer contains the song name. The toolbar remains unchanged. Cancel keeps the original title; Done trims whitespace, limits the title to 80 characters and uses Untitled Song for an empty name.
- Settings → About Pluki displays the approved Pebblesoft Apps logo.
- Settings → Contact & website includes support@pebblesoftapps.com and the live studio, support and privacy URLs. Each outgoing link requires a fresh parent check. Offline Help and Privacy remain available without leaving the app.
- Help explains song naming. The bundled privacy policy explains optional website and email links.
- Settings displays Build 14. The fallback Apple upload counter is 15; Codemagic continues to use PROJECT_BUILD_NUMBER for the actual upload counter.

## Compile and upload

Codemagic: **main → Pluki Build 14 RC2 - TestFlight and iPad ZIP** (`pluki-ios-dual-export`). One signed archive is exported for TestFlight and iPad Ad Hoc using the existing profiles. Build preparation alone does not start Codemagic or submit to App Review.

## Validation

Run GitHub Debug and Release compilation, persistence, parent approval, sound, orientation and privacy checks. The focused visual tour covers iPhone SE (3rd generation) and iPad Pro 11-inch (M4), portrait and landscape: 40 screenshots including song menu, Rename keyboard, Save keyboard, Settings and Contact. The full six-device tour now captures 120 screenshots. Capture success requires a separate human visual review.

On the signed candidate: install over Build 13 and confirm saved projects and the active draft survive. Test Rename Cancel/Done, long and blank names, Save and reopen, and both keyboard orientations. Confirm each outgoing support action opens the intended destination only after approval; Cancel, wrong input and backgrounding must not open a link. Confirm Photos export still uses its original permission behavior.

Complete the remaining hardware acceptance and store listing steps in APP-STORE-RELEASE.md before submitting. No App Review submission is part of this build.

## Archives

Keep compiled archives 11, 12 and 13 until the owner confirms Build 14 compiled successfully. Then archive 14 and retain 12, 13 and 14.
