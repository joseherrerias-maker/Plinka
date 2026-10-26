# Pluki Build 11 — Release preparation

## Included

- Exported videos now show the green musical note and navy pluki! wordmark in a light rounded panel. The footer reads “Available in the App Store” at 28.75 points, exactly 25% larger than the original 23-point text, in both formats.
- Settings includes How to play & help, an offline Privacy policy, Build 11 and Sound credits. Help covers composing, automatic sheet growth, saved projects, samples, video export and troubleshooting.
- A fresh parent check precedes each Save to Photos action. Cancelling, an incorrect answer or backgrounding does not authorize a save. Approval is single-use and never persisted. Composition and video previews do not require a gate.
- Bundled PrivacyInfo.xcprivacy declares no tracking or developer-collected data and app-only UserDefaults access (CA92.1). Both signed exports are checked for the manifest and offline policy before upload.
- App label Build 11; marketing version 0.9.0. Apple's upload build counter is still managed separately by Codemagic.

## Compile

Select main → **Pluki Build 11 - TestFlight and iPad ZIP** (`pluki-ios-dual-export`). Signing identities and the two export destinations are preserved. No paid Codemagic build is started automatically.

## Checks

CI runs saved-song and parent-approval checks, unsigned iOS compilation and built-resource validation. The opt-in video check renders both formats and checks media/cancellation, providing frames to inspect the new branding. This does not replace physical-device testing of the parent sheet and Photos permission/import.

Device acceptance: install over Build 10 without deleting it; verify saved songs and Continue; test Help/Privacy in portrait and landscape on iPhone and iPad; check parent gate success, wrong answer, Cancel, swipe dismissal and background/return; deny Photos then allow and retry; save a video in each format and inspect branding/audio. Test a long song near 500 beats and foreground/background recovery. A parent check is a child interaction safeguard, not proof of age or identity.

## Still required before App Store submission

See APP-STORE-RELEASE.md. Public support contact and hosted policy/support URLs, final Kids-category choice, listing screenshots/metadata, final rights review and real-iPad testing remain open. No personal email has been published, and no placeholder Contact button has been added. The App Store footer is launch wording, not a claim that the app is already published.

Archive Build 11 only when the user reports successful signed compilation; retain builds 9, 10 and 11 at that point. Until then, compiled archives remain 8, 9 and 10. Build 10 is confirmed working on iPhone for automatic growth, grid appearance and video output.
