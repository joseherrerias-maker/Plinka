# Pluki Build 13 — Release Candidate 1

Prepared October 26, 2026. RC1 is a candidate for release, not a statement that App Review or final device testing has passed.

## Changes

- The 11-inch iPad portrait toolbar uses two rows, leaving room for the full pluki! wordmark. The wordmark cannot truncate to an ellipsis.
- Save song uses a native keyboard-aware sheet with its title, Cancel and Save in the navigation bar. The name and explanatory text scroll within the sheet on short landscape screens. Existing naming, overwrite/copy and local persistence rules remain unchanged.
- Exported video footer reads “Made with pluki!” with the existing smaller “Available in the App Store” line below.
- Settings displays Build 13. Marketing version is 1.0; the fallback Apple build counter is 14. Codemagic uses PROJECT_BUILD_NUMBER for the upload counter.

## Compile

Codemagic: **main → Pluki Build 13 RC1 - TestFlight and iPad ZIP** (`pluki-ios-dual-export`). Existing signing identities and the single-archive dual-export process are preserved. Preparation does not start Codemagic or submit to App Review.

## Validation

GitHub checks Debug and optimized Release compilation, release metadata, saved-song behavior and boundary growth, parent approval, bundled sounds, privacy and orientations. This candidate requests video media checks and a focused visual tour on iPhone SE (3rd generation) and iPad Pro 11-inch (M4), both orientations. The focused report contains 32 screenshots; the normal full matrix still captures 96. Record the actual run outcomes after completion; build preparation alone is not a pass.

## Final acceptance before release

Use the signed RC1 on an iPhone and iPad. Install over Build 12 without deleting it: verify saved songs, draft and Continue survive, and Settings says Build 13. Separately test a fresh installation on a spare device, without deleting the only copy of saved work.

1. Save, rename/save a copy, reopen and delete; test a long name and Cancel, with keyboard in portrait and landscape.
2. Listen to every sound and sample. Play, pause, loop, undo/redo, erase and rotate during use. Background/return and lock/unlock must recover cleanly.
3. Grow a dense song toward beat 500, save/reopen and play. Export both formats; check final notes, audio sync, time and memory on hardware. Cancel and background during generation. Include low free storage and Photos denial/retry.
4. Test initial Photos approval/cancel/wrong input and later saves with permission already granted.
5. Check larger text, VoiceOver, Reduce Motion and iPad resized windows, plus the oldest supported iOS version available for testing (deployment target iOS 17).

Record device, OS, result and any crash before calling the candidate approved. App Store listing, privacy/support URLs, category, price/account setup and content-license review remain in APP-STORE-RELEASE.md.

## Archives

Build 12 is the last user-confirmed compiled build. Keep compiled archives 10, 11 and 12 until the user confirms Build 13 compiled successfully; then archive 13 and retain 11, 12 and 13.

## Recorded checks

- [Debug/Release, persistence, parent approval and bundle checks](https://github.com/joseherrerias-maker/Plinka/actions/runs/40397115655) passed on commit `9f6c2d8`.
- [Video media checks](https://github.com/joseherrerias-maker/Plinka/actions/runs/40395138051) passed; portrait and landscape footer frames were visually inspected. The later change only adjusts Save-sheet focus timing.
- The 11-inch iPad portrait screenshot confirms the full wordmark fits.
- [Final focused capture run](https://github.com/joseherrerias-maker/Plinka/actions/runs/40397115682) verifies both orientations of iPhone SE and 11-inch iPad. Final keyboard screenshot approval is pending: the local review environment disconnected before those images were available. Do not interpret capture success alone as keyboard/layout approval.
- Signed Codemagic compilation and physical-device acceptance remain pending.
