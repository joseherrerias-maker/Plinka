# Pluki launch preparation

Build 11 is a TestFlight candidate, not an App Store submission. Updated October 26, 2026.

## Prepared in the app

Offline Help and Privacy policy; sound attribution screen; Photos add-only permission preceded by a single-use parent check; no app login, tracking, ads or analytics. Local song storage uses UserDefaults, declared with CA92.1. No network client or third-party SDK was found in the native app source reviewed for this build. Recheck these claims if dependencies or data flows change.

## Decisions and account work still open

- Owner supplies the public support contact. Publish a support page and the policy at stable HTTPS URLs, add the approved contact to the policy, and wire any app contact/link actions behind a parent gate. Do not use an unapproved personal email or a nonfunctional placeholder.
- Confirm Kids-category selection and intended age band. The parent check prepares the Photos flow for a young audience, but does not select the category in App Store Connect. Age rating comes from the current questionnaire, not from a guessed value.
- Target price is $3.99 USD, paid download, with launch features included. Confirm availability, paid agreement, tax and banking details in App Store Connect. No in-app paywall, subscription or StoreKit purchase flow is needed for the intended paid-download model.
- Complete App Privacy answers from the actual released app and SDK inventory. Candidate answer is Data Not Collected by the developer; local songs and local Photos export do not imply server collection. Reassess any future support form or analytics.
- Supply review contact details, privacy/support URLs, copyright/developer name, current screenshots from iPhone and iPad, keywords and description. No screenshots or review submission have been uploaded by this task.
- Decide whether 0.9.0 will remain the beta version or bump to 1.0 for the final App Store build.

## Listing copy draft

Name: Pluki
Subtitle: Make a little music

Turn playful sounds into your own little songs. Choose an instrument, animal or fun sound, then place colorful stickers on the music sheet. Move them up and down to change pitch, or sideways to change timing.

Explore 19 sounds, try six editable sample songs, save your creations on your device and watch the sheet follow along during playback. The sheet grows as you compose, up to 500 numbered beats. Create an animated music video in portrait or landscape and save it to Photos with a grown-up's help.

No account, ads or subscription. Music creation works offline. Songs are saved on the device; cloud project sync is not included.

Do not add “for kids” metadata until the Kids-category decision is finalized.

## Reviewer notes draft

No account or demo credentials are required. Start with New song or Samples. Select a sound and tap the sheet to place notes; use Play for playback. Open the song menu to save, open, export or return Home. Saved songs and the draft are local.

For video export, create a song with notes, choose Export video, select a format and Create video. Save to Photos presents a parent challenge: enter the four displayed number words in reverse order using digits. Complete it to request add-only Photos access. The challenge is new for each save; it does not collect identity or persist an unlocked state. Declining Photos access leaves composition available. No microphone, camera, existing-photo reading or screen recording is used.

## Final device acceptance (record results before submission)

- iPhone and iPad, both orientations: Home/menu, Help/Privacy, sound tray, keyboard, parent challenge and video preview fit without clipping.
- Install over Build 10: saved projects, active draft, notes near the end and song names survive. New/Continue retain the visible grid.
- Parent challenge: incorrect input, Cancel, swipe-to-dismiss and background/return never save or request Photos access. Correct input grants only the pending save, including on a second export with Photos already authorized.
- Photos: first grant, denial, later retry, low storage, background during generation, cancellation and both export formats.
- Longer songs: add/move near the end through the 500-beat cap, undo/redo, save/reopen, playback and export. Measure time/memory on real hardware; the audio engine renders the whole song into memory.
- Accessibility: larger text, VoiceOver labels, button touch sizes and reduced-motion playback.
- Listen to all sample arrangements and sounds; compare audio/video sync and final sound tails.

## Content and licensing review

The app bundles credited recordings in Plinka/Sounds/CREDITS.txt. Puppy and cow use CC BY-SA 3.0 adaptations; pig uses CC BY 3.0; chicken/frog use CC0. Attribution and downloadable adaptations are already provided. Before release, verify source records and attribution/share-alike obligations for videos users export, not just for files inside the app. Do not describe every bundled sound as royalty-free or claim all exported content has unrestricted rights.

SAMPLES.md records the six traditional/classical/original arrangements; no Baby Shark or modern commercial pop-song composition is bundled. Verify the exact arrangements and artwork provenance before commercial release; this preparation is not legal clearance.

## Apple references checked

- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/kids/
- https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
- https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons
