# Build 18 — Song import

Separate creator-development branch: feature/song-import. Submitted App Store version 1.0 (21) remains unchanged. Internal build label is 18; the signed upload number is assigned by Codemagic.

## Using it
Save a .pluki file to Files. In Pluki, choose Import song from Home or the song menu, select the file, and confirm Import and open. The import creates a new saved song. Unsaved current changes are preserved as a separate saved copy; existing saved songs are not overwritten. Same-name imports remain independent entries. Cancel and rejected imports leave songs unchanged. Playback and video export are unchanged.

Example: ios/marketing/First-Little-Groove.pluki, an original 16-note test tune. Audition before publishing.

## File contract
UTF-8 JSON envelope: format "pluki-song", version 1, song object. Song fields: title (1–80 characters, no control characters), tempo (65–160 BPM), loop (Boolean), sheetSteps (32–1000), notes (nonempty array). Each note has UUID id, step (0..<sheetSteps), row (0–8), instrument (an existing Instrument raw value). Rows map to MIDI pitches [77,76,74,72,71,69,67,65,64]; steps are half-beats. Duplicate IDs and occupied cells are rejected. Imported note IDs are regenerated for independent editing. Maximum file size: 1 MiB.

The Files picker accepts .pluki and .json. There is no file upload, network fetch, or automatic opening from external links. Imports read only the selected file using security-scoped access.

## Validation
SongImportChecks covers valid decoding, invalid versions/types/size/ranges, duplicate notes, preservation of unsaved edits, same-title independence, persisted reload and corrupt-library protection. Existing persistence checks and Debug/Release simulator builds run on this branch.

Device acceptance after compilation: import from local Files and iCloud on iPhone/iPad; cancel picker and confirmation; invalid file; existing saved and unsaved songs; play/edit/save imported tune; export portrait and landscape to Photos.

## Compile
In Codemagic select feature/song-import and workflow "Pluki Build 18 Song Import - TestFlight and iPad ZIP". Do not replace the App Store build currently under review. This source change is not itself a signed IPA.
