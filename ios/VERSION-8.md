# Pluki Build 8

## Changes
- Launch into a welcoming studio home screen with New song, Open song, Samples and Settings. Continue song appears when a draft exists, including after relaunch. Store remains deferred until content is ready.
- Centered in-song menu uses the same cream panel and colored tiles, adding Save song and Back to home. Menu pauses playback; Close returns to the current melody. Back to home retains the draft and composer position.
- New song starts an independent blank project and clears edit history. Unsaved changes prompt before New or opening a saved project. Samples open immediately without a save prompt, as requested.
- Six short editable samples: Twinkle, Old MacDonald, Pluki Pop, Frère Jacques, Ode to Joy and Animal Parade. Saving a sample creates a personal copy.
- Settings shows Build 8; approved Build 7 icon, sound assets, saved-song deletion and smooth playback following retained.

## Build
Select main and the single Codemagic workflow **Pluki Build 8 - TestFlight and iPad ZIP** (`pluki-ios-dual-export`). Signing identities and export paths are unchanged. One signed archive produces the TestFlight IPA and iPad Ad Hoc ZIP. The upload build counter stays managed by Codemagic; the app displays the separate release label Build 8.

## Validation and device checks
CI checks saved-song persistence, sample bounds/copies, fresh-install draft state, new-song save isolation, draft restoration, iOS compilation, orientation declarations, release label and sound resources. Device testing is still required: home/menu on iPhone and iPad in portrait/landscape; Continue after Back to home and relaunch; cancel/save/discard when starting New; saved-song Open/Delete; all six samples opening with one tap; sample playback; Save and Settings; close menu and resume playback. No paid Codemagic run is triggered automatically.

Archive after the user confirms successful signed compilation, retaining only the latest three compiled archives. Build 7 remains the tested baseline until then.
