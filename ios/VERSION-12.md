# Pluki Build 12 — Video layout and easier Photos saving

## Included

- Taller portrait video sheet: 1010 px instead of 830 px, tighter side margins, a compact branded header and larger portrait stickers/beat spacing. Landscape also uses tighter margins. Output remains 720×1280 portrait and 1280×720 landscape.
- Footer reads “Made with Pluki” at 28.75 pt, with “Available in the App Store” below at 22 pt. Both formats preserve the logo, song title, scrolling playhead and audio timing. Photos may letterbox a 9:16 video on a taller phone screen; black bars are not encoded into the exported frames.
- A parent check appears only before the initial Photos permission request. Enter the number words as digits in their displayed order; no reverse-number puzzle. Once access is granted, saves go directly to Photos, including permission already granted in Build 11.
- Denied/restricted access shows guidance without repeating the challenge. Cancel, wrong answers and backgrounding do not approve the permission request. Resetting system authorization to not-determined requires a new check. Help and Privacy match this behavior.
- Settings displays **Build 12**. Marketing version is 0.9.1; local Apple build counter is 13. Codemagic overrides the Apple upload counter with PROJECT_BUILD_NUMBER while preserving the user-facing release label.

## Compile

In Codemagic select **main → Pluki Build 12 - TestFlight and iPad ZIP** (`pluki-ios-dual-export`). One signed archive produces the TestFlight IPA and iPad Ad Hoc ZIP with the existing signing identities. This is a manual build; preparation does not start Codemagic or submit to App Review.

## Validation

The included app changes passed unsigned iOS compilation, saved-song and parent-approval checks, orientation/resource/privacy validation and portrait/landscape video media checks in [GitHub run 40365310784](https://github.com/joseherrerias-maker/Plinka/actions/runs/40365310784). Actual exported frames were visually inspected: both footer lines fit and the enlarged sheet is visible in both orientations. Media checks cover audio/video tracks, duration, late notes and cancellation. Release metadata receives the normal compile checks again; no repeat simulator video run is needed for metadata-only changes.

On device, install over Build 11 without deleting the app; confirm Settings says Build 12 and saved songs/Continue survive. Export both formats and inspect the larger sheet, footer, scrolling and audio. With Photos already allowed, Save to Photos should save directly. With fresh permission, check the simpler challenge, Cancel, wrong input, swipe dismissal, background/return, grant and denial/retry. Check iPhone and iPad layouts.

## Release status and archives

Build 12 awaits signed compilation and device acceptance. Archive only after the user reports successful compilation, retaining the latest three compiled builds: 10, 11 and 12. Until then retain 9, 10 and 11.

See [App Store preparation](APP-STORE-RELEASE.md) for remaining launch work. The footer uses planned launch wording; the app has not been published. The final Kids-category choice and permission-only gate approach remain subject to App Review.
