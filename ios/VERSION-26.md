# Pluki 1.1 — next development build (source label 26)

The current Apple App Review submission remains untouched. This change is for internal TestFlight verification through the single manual Xcode Cloud workflow `main`.

- Original **Pluki Theme**: a soft, roughly 10-second piano-and-bells melody, heard only on the home screen when home music is enabled. Uses the existing local synthesis engine and loops softly. Home audio uses the ambient category to respect the device's silent mode and a small accessible mute/unmute button.
- The same **Pluki Theme** is the first editable item in Samples; no animal, voice, or special-effect notes.
- Composer note stickers grow by approximately 20%; the bottom instrument tray stays unchanged. The selectable hit region stays within each beat cell to reduce accidental taps.
- Each playing note performs a single subtle 10% scale bounce, about 0.2 seconds, with no glow or particles. Animation is disabled with Reduce Motion and pauses with playback.
- Existing parent-gated StoreKit review request, iPhone Duo adaptive layout, save/import/export, and privacy settings are preserved. Confirm them on real iPhone Duo and iPad before approving the build.

## Build numbering and cloud workflow

Source fallback build label: **1.1 (26)**, independent of failed CI runs. Xcode Cloud assigns its own build number (first cloud build may default to 1); before the first TestFlight distribution set its **Next Build Number** to 26 in App Store Connect > Pluki > Xcode Cloud > Settings > Build Number if source and distributed build labels must match. Do not run Codemagic and Xcode Cloud upload concurrently for the same version/build number.

## Validation

Run existing GitHub Actions iPhone/iPad debug/release compilation, resource/privacy/orientation checks, song store/import checks, and the new original-theme invariant. Then manually launch Xcode Cloud `main` on GitHub `main` and inspect archived TestFlight version and internal group. No new App Store submission.
