# Pluki Build 10 — Keep composing

## Included
- Sheets grow automatically when a note is added or moved into the last four numbered beats. More space appears ahead without a manual Extend sheet command.
- Growth stops at 500 numbered beats (1,000 half-beat note positions). This limits timeline length, not the number of stickers. New songs start with the original compact sheet.
- Staff lines and dashed guides draw in a viewport-sized surface that refreshes on scrolling, layout and appearance, addressing the disappearing grid reported after New song and Continue song.
- Note edits and sheet growth undo/redo together. Drafts and saved projects retain their length; existing Build 9 projects remain compatible. Selecting and erasing do not expand the sheet, and deletion does not shrink it.
- Playback and video export still end after the final note's sound tail. Build 9's video-to-Photos feature, samples, sounds and saved-song tools are retained.
- Settings displays only **Build 10**. Marketing version is 0.8.0; Codemagic manages Apple's upload build counter separately.

## Build
Select **main** and **Pluki Build 10 - TestFlight and iPad ZIP** (`pluki-ios-dual-export`) in Codemagic. One signed archive produces the TestFlight IPA and iPad Ad Hoc ZIP. Signing identities and export paths are unchanged. No paid build starts automatically.

## Validation
The implementation passed unsigned iOS compilation, saved-song checks, built-app release/orientation/Photos-permission and sound-resource checks before release preparation. Saved-song checks cover automatic growth on add/move, undo/redo, persistence, the 500-beat boundary, and restoration of older long songs.

The grid renderer smoke check passed for 32, 256 and 1,000 positions at the start, middle and end, in portrait and landscape, including hide/show and resize. This checks drawing, not full New/Continue navigation on a device. Release preparation reruns normal CI to verify the Build 10 metadata and compiled app.

After installing, check New song and Continue song for visible staff/grid lines in both orientations. Add and move notes near the sheet's right edge, verify growth without a scroll jump, then undo/redo, save/reopen, play and export a longer song. Real-device performance at the full 500-beat limit and iPad testing remain to be verified.

Build 9 is the user-approved device baseline. Archive Build 10 only after successful signed compilation is confirmed; retain the latest three compiled archives.
