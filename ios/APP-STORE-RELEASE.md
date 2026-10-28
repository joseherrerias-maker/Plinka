# Pluki launch preparation

Build 17 is Release Candidate 5 (marketing version 1.0), prepared in source. Build 16 is owner-confirmed compiled, and video export now works on the affected iPad. Signed Build 17 compilation, acceptance of the editor changes and App Store submission remain separate milestones. Updated October 27, 2026.

## Prepared in the app

Offline Help and Privacy policy; sound attribution screen; initial Photos add-only permission preceded by a single-use parent check; no app login, tracking, ads or analytics. Local song storage uses UserDefaults, declared with CA92.1. No network client or third-party SDK was found in the native app source reviewed for this build. Recheck these claims if dependencies or data flows change.

## Decisions and account work still open

- Approved public contact: support@pebblesoftapps.com (Microsoft 365 alias). Receiving and outgoing Gmail delivery tested by owner. iCloud initially classified a reply as junk; authentication not fully audited.
- Domain pebblesoftapps.com is connected to the existing Netlify site. Owner confirmed the custom domain works. Final public routes: https://pebblesoftapps.com/pluki/support/ and https://pebblesoftapps.com/pluki/privacy/. Support contact is support@pebblesoftapps.com. Microsoft 365 DNS records are preserved.
- Shared website can introduce Pluki and Milo, but each requires its own reviewed policy. Do not reuse Pluki's offline/no-collection statements for Milo.
- Build 14 adds Contact & website under Help & About, with support email, support page, online policy and studio website. Each outgoing action requires a fresh local parent check. Offline Help and Privacy remain accessible without a check. The information sheet includes the approved Pebblesoft Apps logo.
- Confirm Kids-category selection and intended age band. The parent check prepares the Photos flow for a young audience, but does not select the category in App Store Connect. Age rating comes from the current questionnaire, not from a guessed value.
- Target price is $3.99 USD, paid download, with launch features included. Confirm availability, paid agreement, tax and banking details in App Store Connect. No in-app paywall, subscription or StoreKit purchase flow is needed for the intended paid-download model.
- Complete App Privacy answers from the actual released app and SDK inventory. Candidate answer is Data Not Collected by the developer; local songs and local Photos export do not imply server collection. Reassess any future support form or analytics.
- Supply review contact details, privacy/support URLs, copyright/developer name, current screenshots from iPhone and iPad, keywords and description. No screenshots or review submission have been uploaded by this task.
- Version 1.0 is prepared for RC5. Select the accepted signed build for the matching version in App Store Connect after testing.

## Listing copy draft

Name: Pluki
Subtitle: Make a little music

Turn playful sounds into your own little songs. Choose an instrument, animal or fun sound, then place colorful stickers on the music sheet. Move them up and down to change pitch, or sideways to change timing.

Explore 19 sounds, try six editable sample songs, save your creations on your device and watch the sheet follow along during playback. The sheet grows as you compose, up to 500 numbered beats. Create an animated music video in portrait or landscape and save it to Photos with a grown-up's help.

No account, ads or subscription. Music creation works offline. Songs are saved on the device; cloud project sync is not included.

Do not add “for kids” metadata until the Kids-category decision is finalized.

## Reviewer notes draft

No account or demo credentials are required. Start with New song or Samples. Select a sound and tap the sheet to place notes; use Play for playback. Open the song menu to rename, save, open, export or return Home. Help & About is available from Home and the song menu; it contains instructions, offline privacy, sound credits and contact links. Each outgoing contact link requires a fresh parent check. Saved songs and the draft are local.

For video export, create a song with notes, choose Export video, select a format and Create video. When Photos permission has not yet been requested, Save to Photos presents a parent challenge: tap the displayed number words as digits in the same order using the built-in number pad. Complete it to request add-only Photos access. Once permission is granted, later saves proceed directly. The challenge does not collect identity or persist an unlocked state. Declining Photos access leaves composition available. No microphone, camera, existing-photo reading or screen recording is used.

## Final device acceptance (record results before submission)

- iPhone and iPad, both orientations: Home/menu, Help/Privacy, sound tray, keyboard, parent challenge and video preview fit without clipping.
- Install RC5 over Build 16: saved projects, active draft, notes near the end and song names survive. New/Continue retain the visible grid.
- Parent challenge: incorrect input, Cancel, swipe-to-dismiss and background/return never save or request Photos access. Correct input authorizes the initial Photos permission request. A second export with Photos already authorized saves directly without a challenge. Denied or restricted permission shows guidance without repeating a puzzle; resetting permission to not-determined requires a fresh parent check.
- Photos: first grant, denial, later retry, low storage, background during generation, cancellation and both export formats.
- Longer songs: add/move near the end through the 500-beat cap, undo/redo, save/reopen, playback and export. Measure time/memory on real hardware; the audio engine renders the whole song into memory.
- Accessibility: larger text, VoiceOver labels, button touch sizes and reduced-motion playback.
- Listen to all sample arrangements and sounds; compare audio/video sync and final sound tails.

## Content and licensing review

Build 16 replaces the puppy, cow and pig recordings with sources listed as CC0 1.0 on their original Freesound pages, checked October 27, 2026. Chicken/frog remain the existing CC0 recordings. CREDITS.txt acknowledges the creators; SOUND-SOURCES-16.json records replacement source URLs, license URLs, downloaded preview hashes, processing and bundled hashes. The new sources remove the previous three recordings' attribution/share-alike requirements from newly rendered videos. Existing exported videos and old builds retain their original licensing situation. This is a source-license review, not blanket clearance of all app content or third-party rights.

SAMPLES.md records the six traditional/classical/original arrangements; no Baby Shark or modern commercial pop-song composition is bundled. Verify the exact arrangements and artwork provenance before commercial release; this preparation is not legal clearance.

## Apple references checked

- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/kids/
- https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
- https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons

## Build 16 scope and verification

- Shared on-screen parent keypad on all devices; no system keyboard/TextField in the parent check. Keep four-digit gating, wrong-answer refresh, Cancel/background invalidation and one-use approval.
- Replace puppy/cow/pig audio and credits only; retain song format, menus, samples, chicken/frog sounds and shipping behavior.
- Automated checks include Debug/Release, resource hashes/PCM validity, approval logic, first-digit UI regression on iPhone/iPad in both orientations, and portrait/landscape movie export using all five recorded sounds.
- Confirm the reported crash is resolved on the owner's iPad and test correct approval/Photos grant and denial on hardware. Audition replacements at low/middle/high pitches and in exported videos.
- Listing, privacy answers, Kids age band, paid agreement, tax/banking and review contact remain account work.
- Current Apple upload requirement checked October 27, 2026: Xcode 26 or later with iOS/iPadOS 26 SDK or later. Codemagic selects latest Xcode; confirm the actual SDK in the signed build log. Reference: https://developer.apple.com/news/upcoming-requirements/?id=04282026a

## Build 17 submission preparation

See APP-STORE-SUBMISSION-17.txt for copy-paste listing text and account steps. The approved marketing screenshot design is a draft using older captures and must be refreshed before submission. Choose manual release. No submission or account changes have been made.
