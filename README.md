# Pluki 🎵

**Pluki** is an experimental, colorful music composer inspired by the intuitive note-placement of classic creative games. Designed iPad-first for ages approximately 3–8, with room for older creators.

## Playable prototype (v0.4)

- Five-line musical staff with nine pitch positions (pitch goes **up/down**, time goes **left/right**)
- 8 selectable instrument sounds and editable note stickers
- Four horizontally scrolling measures, playback and tempo controls
- Undo, eraser, clear, sample melody, automatic local saving
- Responsive iPad landscape and iPhone portrait layout
- Uses built-in browser Web Audio synthesis: **these sounds are placeholders**, not the final recorded instrument pack
- Guitar has a custom plucked-string sound, audibly distinct from the piano's oscillator timbre
- Playback automatically ends after the last note, rather than playing the entire four-measure canvas
- Loop control repeats the current phrase until switched off or Stop is pressed; loop preference is saved locally

All prototype code is in `index.html`. No dependencies, analytics, accounts, external assets, audio API keys, or backend.

## Publish to GitHub Pages

1. Create a new GitHub repository named `Plinka` (public for GitHub Pages on GitHub Free). Keep it **separate** from Milo.
2. Put `index.html`, this `README.md`, and `.nojekyll` in the repository root on `main`.
3. Go to **Settings → Pages → Build and deployment → Source: Deploy from a branch**.
4. Select **Branch: `main`**, **Folder: `/ (root)`**, then **Save**.
5. After publication, open `https://<username>.github.io/Plinka/` in Safari on iPhone or iPad.

For the intended account, this should be `https://joseherrerias-maker.github.io/Plinka/` **after** GitHub Pages publishes successfully. This is not a live link until deployment finishes.

**Note:** GitHub Pages publishes a public site. Do not add secrets, identifying child information, private recordings, or API credentials to this repository.

## How to use

1. Tap a sound in the bottom tray.
2. Tap or drag on the musical staff to place notes; higher positions play higher pitches.
3. Tap **Play** to hear your song. Use **Stop**, **Undo**, **Erase**, or **Clear** to revise it.
4. Scroll sideways to reach later beats, and use **Try a little tune** to hear the demo.

Music is saved in the browser’s local storage on the device, not uploaded to GitHub. Browser audio starts only after a user gesture. The iOS file preview may block JavaScript; for actual gameplay use a normal HTTPS webpage in Safari.

## Prototype status

This is a mechanics-first proof of concept, **not** a finished app or App Store build. Sound quality, touch UX, note layering, accessibility, and iOS device testing remain to be refined.

No software license is granted by including this README. This is an unpublished prototype owned by its creator.

**Branding note (October 2026):** The app's public name is **Pluki**, accepted in App Store Connect. The GitHub repository URL, Xcode project/scheme, SKU `PLINKA-IOS-001`, and registered bundle identifier `com.joseherrerias.plinka` remain unchanged to preserve existing development and Apple signing configuration.

## Native iOS app (Build 11)

The native SwiftUI source and Xcode project are under [`ios/`](ios/). Build 11 adds video branding, Help/Privacy screens, a parent check for Photos saves and packaged privacy declarations. Build 10 was compiled and tested on iPhone; Build 11 awaits signed compilation and device testing. See [Build 11 release notes](ios/VERSION-11.md) and [iOS build notes](ios/README.md).

## Build iOS with Codemagic

The root [`codemagic.yaml`](codemagic.yaml) provides one manual workflow: **Pluki Build 11 - TestFlight and iPad ZIP** (`pluki-ios-dual-export`). Select branch **main**. One signed archive produces the TestFlight IPA and iPad Ad Hoc ZIP using the existing Apple signing setup. GitHub Actions separately checks unsigned compilation; Codemagic builds do not start automatically.
