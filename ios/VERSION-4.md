# Pluki Build 4 — 0.3.1

Fixes prompted by the user-confirmed Build 3 TestFlight installation:
- Settings now reads the installed app version and Apple build number from
  Bundle.main. The previous literal "0.2.0" was misleading even in Build 3.
- Treble clef is rendered once using its actual glyph ink bounds, including
  overhang, then scaled to fit a padded gutter. Staff height can no longer
  enlarge the clef past the left edge.
- Visible Instruments, Animals and Fun selectors make Puppy, Kitten, Sparkle
  and Boing accessible without scrolling through eight instruments first.
- Staff stickers have larger size limits; tray stickers are larger and use
  increased saturation/contrast with a soft color shadow. The artwork remains
  the existing vector style, not a recreation of the glossy concept artwork.
- Restored Loop/Eraser/Clear All, audio engine, stored songs, and the
  audio-timed continuous scrolling implementation are preserved.
- One Codemagic workflow still creates TestFlight and iPad Ad Hoc ZIP exports
  using the confirmed profile reference names.

Validate portrait and landscape on iPhone/iPad: clef entirely inside cream
staff, three sound selectors visible, each sound previews/plays, controls fit,
and playback follows smoothly. Settings should show 0.3.1 and the actual Apple
build number. Local project build is 5; Codemagic overrides it with its counter.

The editing environment has no Xcode. Native compilation is checked on GitHub;
device appearance and sound acceptance remain separate. This is an unarchived
candidate until Jose confirms compilation. Build 3 remains the saved baseline.
