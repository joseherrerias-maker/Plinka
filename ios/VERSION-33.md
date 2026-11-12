# Pluki 1.1 — Build 33: parent-area navigation

Contact & website previously appeared on the main Help & About screen, while the offline privacy page appeared both there and inside For parents. This update groups contact actions with the other parent features and removes the duplicate policy entry.

## Changes

- Move Contact & website to Help & About → For parents → Contact & support.
- Keep the existing parent check before entering For parents and a fresh parent check before every outgoing website or email action.
- Keep the November 11 offline Privacy policy directly available in Help & About; remove its duplicate from For parents.
- Set source and displayed build number to 33 in Debug and Release, keeping version 1.1.

The policy text, support address, URLs, parent challenge behavior, project import/export, saved songs, music, artwork, signing settings, and CI workflows are unchanged. No App Store review submission changes are included.

## Validation

- Run existing Debug and Release compilation plus bundled privacy, saved-song, draft-recovery, import, and parent-approval checks.
- Confirm the source exposes Contact & website only inside the gated parent route and keeps each outgoing action's separate check.
- On iPhone and iPad, verify the top-level menu has one offline policy entry and no Contact & website row. Cancel the parent check to confirm contact stays inaccessible, then complete it and open Contact & website. Cancel the email check to confirm no email app opens.
- Device acceptance remains pending until the signed build is tested.
