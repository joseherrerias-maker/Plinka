# Changes after the compiled Build 9 baseline

- Fixed disappearing staff/grid lines by drawing them in a viewport-sized UIKit surface, refreshed on scroll, layout and appearance. The note canvas no longer allocates one full-song drawing surface.
- Removed the Extend sheet command. Adding or moving a note into the last four numbered beats automatically adds room ahead, without changing the current scroll position.
- Automatic growth stops at 500 numbered beats (1,000 half-beat note positions). This is a timeline length limit, not a limit on the number of stickers.
- Existing Build 9 projects remain intact and editable. New projects start with the original compact sheet. Erasing and selecting do not expand the sheet; deletion does not shrink it.
- Note edits and automatic growth undo/redo together. Drafts and saved projects retain the expanded length. Playback and video export still end after the last note's sound tail.

Validation: saved-song checks cover automatic add/move growth, undo/redo, limit handling, restoration, erasing and older long songs. Run iOS compile. On device, add notes near the right edge and confirm more space appears without a jump, then save/reopen and export the longer song.

Release label remains Build 9 until the next build is prepared. The archived, device-approved Build 9 source is unchanged.
