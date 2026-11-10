# Pluki 1.1 / Build 28 — editable project backup and transfer

Build 28 completes parent-protected **Save & Transfer Projects** while leaving the existing App Review submission untouched. Run manually using Xcode Cloud workflow `main`; only distribute to Pluki Testing.

- Keep Import Pluki Project under Help & About → For parents, behind the existing parent check.
- Add Export Pluki Project beside it, producing an editable `.pluki` file through the native Files save dialog. Parents can save to Files/iCloud Drive, share via AirDrop, or transfer between devices.
- Export the **currently open** song; open a previously saved composition first to export it. Disable Export when there are no notes.
- Preserve the exact version-1 `PlukiSongFile` JSON format (`format=pluki-song`, `version=1`) and existing import validation. Normalize automatic sheet lengths in a *copy* without changing the song or saved library.
- Enforce 1 MB file-size limit, valid notes and musical staff coordinates, title, tempo, and no duplicate notes.
- Keep the existing import flow that creates a separate saved copy and preserves unsaved work.
- Use the FileDocument Files picker after dismissing the For Parents sheet. Handle failures without modifying songs. Rename the help section to **Save & Transfer Projects** and update the offline Help text.
- Mark the `com.pebblesoftapps.pluki.song` UTI as exported in the app's Info.plist while continuing to import the same extension.
- Preserve Editor → Export Video and the current Pluki Theme, play animations, and iPhone Duo layout. No backend, login, subscriptions, or new public release.

## Validation

GitHub Actions compiles Debug/Release for iOS and tests import/export round-trip and automatic sheet length compatibility using `SongImportChecks.swift`, alongside existing resource/privacy/orientation checks. Manually test an iPhone and iPad: open saved song → parent gate → export to Files → import on another device; confirm notes, pitch, tempo, saved-library independence and no extra file extensions. Confirm cancellations and a blank current song. Start next Xcode Cloud `main` build only after CI checks pass and ensure TestFlight build numbering is greater than 27. No change to current public App Store review.
