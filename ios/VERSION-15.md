# Pluki Build 15 — Release Candidate 3

Prepared October 27, 2026. Marketing version 1.0. Build 14 is the last owner-confirmed compiled baseline. This candidate is not yet a signed compilation or App Store submission.

## Changes

- Both the home and song menus show **Help & About**, with a blue information icon replacing the settings gear.
- The information sheet title is consistently **Help & About**, replacing Settings / Song settings.
- Existing help, contact, studio branding, build number, privacy and sound credits remain in place. Device Settings instructions for Photos permissions still refer to device Settings.
- The displayed release label is Build 15. The fallback Apple upload counter is 16; Codemagic overrides it with PROJECT_BUILD_NUMBER. Marketing version remains 1.0.

## Compile and upload

Codemagic: **main → Pluki Build 15 RC3 - TestFlight and iPad ZIP** (`pluki-ios-dual-export`). One archive produces the TestFlight IPA and iPad Ad Hoc ZIP using the existing signing setup. This remains a manually started workflow; source preparation does not start Codemagic or submit to App Review.

## Validation and acceptance

Run the existing GitHub Debug/Release, persistence, parent approval and resource checks. Capture the two focused devices (iPhone SE 3 and iPad Pro 11-inch M4), portrait and landscape, and review the new label and heading on Home, the song menu and the information sheet. No new behavior tests are needed for this label/icon change.

On the signed build, install over Build 14 and confirm saved songs and draft survive. Confirm both menu entry points, Done, Help, Contact, Privacy and credits work. Test Rename/Save and one Photos export as a final smoke check. Complete the remaining hardware, content licensing and listing work in APP-STORE-RELEASE.md before release approval.

## Archives

Retain compiled archives 12, 13 and 14 until the owner confirms Build 15 compiled successfully. Then archive 15 and retain 13, 14 and 15.
