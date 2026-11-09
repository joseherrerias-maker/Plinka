# Pluki Build 27 — joyful continuous theme refinement

The original 1.1 (26) theme was too slow, interrupted and melancholy. Build 27 changes only the Pluki Theme arrangement and its seamless home-screen looping; the existing App Review submission is untouched. Use the single manual Xcode Cloud workflow `main` and existing internal Pluki Testing group.

- Recompose **Pluki Theme** as an upbeat, original C-major melody with a happier tonic ending.
- Increase tempo from 112 to 132 BPM, use 30 close-spaced piano melody notes across exactly 48 half-beat steps (approximately 10.9 seconds) with 6 soft xylophone accompaniment notes. No animals, voices, drums or distracting effects.
- Rhythms are 1- or 2-step intervals throughout, with variation across three phrases and no dead air or long rests.
- Home playback uses a precisely measured 48-step looping buffer and a 15 ms seam taper. The editable Samples entry uses the identical 36-note arrangement; ordinary editor and export audio timing is unchanged.
- Preserve soft ambient playback, the start-screen mute preference, 20%-larger staff stickers, playback bounce, save and import, parent review gate, and iPhone Duo UI.

## Validation

Check `ios/scripts/PlukiThemeChecks.swift`, existing GitHub Actions Debug/Release builds, persistence/import/privacy/orientation tests. Preview WAV is a listening aid and is **not** an extra app asset. Launch the next internal TestFlight build only after code checks and verifying Xcode Cloud's build number is greater than 26. No automatic public App Store submission.
