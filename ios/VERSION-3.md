# Pluki Build 3 — 0.3.0

Candidate includes the restored main-screen Loop, Eraser and Clear All controls,
plus Puppy, Kitten, Sparkle and Boing sounds and stickers. Smooth audio-linked
scrolling is preserved. Existing instrument artwork enlargement and treble-clef
clipping polish remain pending; this workflow update does not claim those fixes.

## Codemagic: TestFlight and iPad ZIP

Select main and **Pluki Build 3 - TestFlight and iPad ZIP**.
It creates one archive and exports:
- TestFlight: build/testflight/Plinka.ipa (only this file is uploaded to Apple).
- Direct device installation: build/ipad/Pluki-iPad-AdHoc.ipa.
- Download bundle: build/Pluki-iPad-AdHoc.zip, containing the Ad Hoc IPA.
- Archive: build/Pluki.xcarchive.

One-time signing setup in Apple Developer and Codemagic:
1. Create an Ad Hoc distribution profile for com.joseherrerias.plinka.
   Include the target iPad's registered UDID and the same Apple Distribution
   certificate used by the Codemagic "Milo Distribution" identity.
2. Import/fetch it into Codemagic Code signing identities with reference
   pluki_adhoc_ipad.
3. Import/reference Pluki's existing App Store profile as pluki_app_store.
   Both must use that distribution certificate. The script reads actual profile
   UUIDs and team IDs; Apple profile display names do not need to match.
4. Both references must exist before selecting the dual-export workflow.
   The existing TestFlight-only workflow remains available without these references.

Milo's Ad Hoc profile cannot sign Pluki: its app identifier is different.
The ZIP is a transport container; extract the IPA and use the same Ad Hoc install
method as Milo. Only devices included in the Pluki profile can install it.
Alternatively install the TestFlight build on an authorized iPad tester account.

The export verifier checks app ID, distribution profile, expiration, registered
device list and orientations. It cannot confirm the intended iPad is registered
without its UDID. No signing credentials or device IDs are stored in Git.

## Version and checks

App version 0.3.0; local build number 4. Codemagic uses PROJECT_BUILD_NUMBER
for Apple's build number, independently of our project label "Build 3".
GitHub compiles the unsigned app. Actual signed dual export must be verified
on Codemagic after provisioning setup. Check the new sounds and both orientations
on devices. Archive only after Jose confirms compilation; retain the latest
three confirmed Pluki builds.
