# Pluki Build 7

- New approved cream P-note icon on Pluki green.
- Cream song menu with colored icon tiles, rounded navy labels, Open song, Save song, Samples, and separated Settings. Tap outside to dismiss; menu scrolls on short screens and supports Reduce Motion and VoiceOver escape.
- Three editable starter samples: Twinkle, Twinkle, Little Star (opening), Old MacDonald (opening with animal replies), and original Pluki Pop loop. Saving creates a personal copy. Unsaved work prompts before replacement.
- Delete individual saved projects with confirmation; the current working melody remains available.
- Settings displays Build 7. Internal upload counter remains managed by Codemagic.

Use main and the single workflow `pluki-ios-dual-export` (Pluki Build 7 - TestFlight and iPad ZIP). Signing and dual-export configuration are unchanged. Baby Shark is not included pending source verification.

Device checks: icon after update, menu in both orientations on iPhone/iPad, dismissal by tapping outside, Open/Save/Samples/Settings actions, sample playback and save-as-copy, saved-song deletion, and Build 7 label. Automated compile checks do not replace these device checks.

Archive only after successful signed compilation is confirmed; retain the latest three compiled builds.
