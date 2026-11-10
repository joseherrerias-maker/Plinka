# Pluki 1.1 — Build 29: Design Critic's first three improvements

Base: native Build 28, commit a8099b5215fb2b1f2775adc4165bc2ee9466e092. Preserve existing Pluki visual identity and capabilities. Do not change the current App Store submission. Distribute the next internal build manually through the existing Xcode Cloud `main` workflow only after verifying source tests, screenshots and build number.

## 1. Protect unfinished music everywhere
- All replacement paths (New song, Samples, Open saved song) now auto-preserve a **separate recovery copy** of meaningful unsaved work before replacing the editor. Existing version-1 library keys and Song IDs remain compatible.
- Each copy stores the exact original song, including title, tempo, notes, IDs, loop and sheet length, and is marked **Recovered draft** in Open song. The label does not alter the underlying song.
- Untouched samples, empty drafts, unchanged saved songs and duplicate transitions do not generate unnecessary recovery entries. A sample baseline is retained across app relaunches.
- Failed/corrupt library writes block the transition and display an error; the current composition remains open. Imports retain their existing preservation-and-validation behavior.
- No additional child-facing save dialogs.

## 2. One unmistakable Home action
- First launch/empty song: a prominent green **Make music** action starts a fresh composition.
- Meaningful working song: **Continue song** is the prominent primary action; secondary **New song** remains available with automatic draft protection.
- Open song, Samples and Help & About remain accessible as quieter secondary actions.
- Preserve the studio background, Pluki type, colors, rounded panels and music theme, with touch targets of at least 44 pt and a horizontal Home layout on compact landscape screens where feasible.

## 3. Compact iPhone staff and toolbar
- In short iPhone landscape (height < 500, width ≥ 540), the old 108-pt double toolbar becomes one 52-pt row. Essential Play/Pause, Stop, Loop, Undo, Redo, Eraser, menu and tempo remain available.
- Restart playback stays accessible from the song menu in compact landscape. Clear all notes moves to the song menu on all devices, with its existing destructive confirmation and Undo logic.
- Compact iPhone portrait reduces only the otherwise unused treble-clef gutter from 90 to 64 pt, leaving time-cell spacing, all nine pitches and approved note artwork sizes unchanged.
- Staff-grid Debug geometry checks verify that all nine sticker centers and images fit within a representative compact landscape, compact portrait and spacious layout, in addition to the existing pixel-grid checks.
- Layout behavior outside compact phones, including spacious iPad, is retained except for the moved Clear control.

## Compact interaction regression follow-up
- First focused UI run exposed two iPhone SE landscape issues (its iPad 11-inch tests passed): tapping Clear in the menu closed the overlay without presenting confirmation, and the parent keypad required excessive scrolling to reach its answer area.
- Clear now waits for the menu dismiss animation to finish before presenting the existing confirmation alert. Parent check uses a compact two-column challenge/keypad layout only on short wide screens, retaining the same number challenge, cancel, approval state and no-keyboard safety model.
- First iPhone SE visual capture produced portrait and most landscape screenshots but its XCTest driver failed confirming the orientation change; preserve partial evidence and rerun the small device on the corrected source.

## Focused verification
- `DraftProtectionChecks.swift`: unsaved sample replacement and Home→New, relaunch/recovery exactness, sample baseline persistence, edited saved song, empty drafts, duplication, corrupt-library and serialization failures, legacy saved library decoding.
- `SongStoreChecks.swift`: original persistence, undo/redo and sample checks updated for unchanged-sample semantics.
- `EditorTests.swift`: clear action now uses the menu; confirmation + Undo must still work.
- Existing GitHub Actions Debug/Release compile and project import/export, resources, privacy, audio, orientation regression checks.
- Manual iPhone/iPad checks still required for touching, dragging, erasing, rotation, dense melodies, continued playback, safe areas, large Dynamic Type and Reduce Motion. Simulator screenshots are **visual evidence, not hands-on usability validation**.

No NoMac, website preview maintenance, signed distribution, TestFlight upload or public review change.
