# Pluki Build 16 — Release Candidate 4

Prepared October 27, 2026. Marketing version 1.0. Last owner-confirmed compiled build: 15. Signed compilation and physical-device acceptance are pending.

## Changes

- Replace keyboard text entry in every parent check with the shared on-screen keypad: digit buttons, read-only answer, Delete and Clear. Four digits are required for Continue; wrong answers reset the entry/challenge. Cancel, background invalidation and single-use approval remain in place. Used by video saving and contact/website actions on both iPhone and iPad.
- This avoids the text-input path implicated by the owner's first-digit iPad restart. No crash log establishes the underlying exception; the owner must verify the fix on the affected device.
- Replace puppy, cow and pig with CC0 source recordings, converted to mono 44.1 kHz 16-bit PCM, normalized to -3 dBFS with edge fades. Chicken/frog unchanged. Bundled credits and source evidence are updated (see SOUND-SOURCES-16.json).
- Display Build 16; fallback upload counter 17; Codemagic overrides the upload counter with PROJECT_BUILD_NUMBER. Marketing version remains 1.0.

## Build and validation

Use **main → Pluki Build 16 RC4 - TestFlight and iPad ZIP** in Codemagic (`pluki-ios-dual-export`). Manual signed workflow; one archive yields TestFlight and iPad Ad Hoc outputs. No App Review submission is made.

GitHub runs Debug/Release compilation, persistence, parent approval, orientation, privacy and resource checks. Targeted XCTest checks parent keypad entry/deletion/clearing/wrong answers/cancellation on iPhone SE and iPad Pro 11-inch in portrait and landscape. Media smoke checks exercise all five recorded sounds in vertical and landscape export. These automated checks do not replace listening or physical-device acceptance.

Before release: install over 15 and verify saved projects/draft; enter the first and remaining digits, approve and save a video on the affected iPad; test Photos grant/denial and authorized subsequent save; contact/website parent checks; audition puppy/cow/pig in playback and exported video, including low/high notes. Final listing/artwork/sample provenance review remains in APP-STORE-RELEASE.md.

## Archives

Keep compiled archives 13, 14 and 15. Archive Build 16 only after the owner confirms successful compilation, then retain 14, 15 and 16.
