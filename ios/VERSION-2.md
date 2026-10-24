# Pluki Version 2 — 0.2.0

Prepared from repository commit c50f413b6fdbcb2141fe9343c85c7d7ca4f0dcb9.
This is a new testing candidate; do not archive as a user-confirmed compiled build yet.

## Changes
- Height-aware composition layout: compact toolbar, full staff, and an always-visible horizontal sound tray. iPhone landscape no longer inherits fixed tablet staff heights or requires vertical page scrolling.
- Warm illustrated studio, cream staff with five lines and treble clef, blue playhead, green play button, eight custom illustrated instrument stickers. Editable artwork lives in design/. This is an adaptation of the approved concept, not a pixel-identical reproduction; animal/nature sound categories are not added in this release.
- Smooth native follow scrolling uses CADisplayLink and actual AVAudioPlayerNode sample time. Removed four-step scrollTo jumps. Pause freezes the playhead, Stop resets the viewport, and loops return directly to the first beat without sweeping backward through the song.
- Song title, eraser, loop, and clear are in Song settings. Added redo alongside undo. Existing saved songs and bundle identifier remain compatible.
- Version is 0.2.0. Local build number is 3 because App Store Connect already shows build 2; Codemagic continues supplying PROJECT_BUILD_NUMBER for signed archives.

## Validation and device acceptance
The editing environment has no Xcode/iOS Simulator. Native compilation is checked by the repository's existing GitHub Actions workflow after upload. Confirm the exact workflow result before treating the candidate as compiled.

On iPhone and iPad, test portrait and both landscape directions:
1. The complete five-line staff, transport controls, and sound tray must fit without vertical page scrolling; tray scrolls sideways on small displays.
2. Place notes at all nine pitches, including first and last steps. Drag, erase, undo, redo, and reload the saved song.
3. Use a melody spanning all 32 steps at 65, 110, and 160 BPM. The viewport follows continuously after the playhead passes 38% of the visible width, without beat-sized jumps. Check visible notes against heard notes.
4. Pause while scrolling and resume; position must freeze and continue. Stop must return to the start. Loop several times and rotate mid-playback.
5. Background the app during playback: it pauses. Return and resume without losing the song.
6. Verify the new artwork against the supplied concept on actual screens. The source assets were visually inspected, but full native screenshots still require a simulator/device.

## Archive policy
Archive when Jose confirms successful compilation; retain only the latest three successfully compiled Pluki builds in Music game/Pluki App Builds. Record the exact commit and Apple version/build number. Keep this candidate out of compiled archives until that confirmation.
