# Pluki — Native iOS app

## Current release: Build 11

See [Build 11 release notes](VERSION-11.md) for video branding, Help/Privacy, a Photos parent check and packaged privacy declarations. Settings displays **Build 11**. Build 10 is the latest user-approved device baseline; Build 11 awaits signed compilation and device testing.

In Codemagic, choose **main → Pluki Build 11 - TestFlight and iPad ZIP** (`pluki-ios-dual-export`). This is the single manual workflow: one signed archive produces a TestFlight IPA and an iPad Ad Hoc ZIP. GitHub Actions separately checks unsigned compilation and saved-song behavior. Current signing configuration is in [`codemagic.yaml`](../codemagic.yaml); setup notes are in [VERSION-3.md](VERSION-3.md).

The app now includes 19 sounds across Instruments, Animals and Fun; continuous sound browsing; a home screen and song menu; save/open/delete; six editable samples; smooth playback following; and video export to Photos. The original web prototype remains separate at the repository root.

## Historical Build 1 notes

The initial setup and feature notes below describe Build 1 and are retained for context. Use the current release notes and workflow above for new builds.

This is a **standalone SwiftUI iPhone + iPad app**. The public-facing name is **Pluki**, while the GitHub repository, Xcode target and bundle identifier retain their original internal Plinka names. The web prototype remains at the repository root as GitHub Pages `index.html`. No web backend or subscription is needed.

## Open and compile

Open `ios/Plinka.xcodeproj` in Xcode 26 or newer. Select the shared **Plinka** scheme, a device or iOS simulator, and Build. The app targets iOS 17+ on iPhone and iPad.

**Provisioning:** For a signed device build, choose your Apple Developer Team in Signing & Capabilities. The registered bundle ID `com.joseherrerias.plinka` remains unchanged; the App Store Connect app is named **Pluki**. Keep the existing bundle ID and SKU `PLINKA-IOS-001`.

**Build 1 status:** GitHub Actions successfully compiled the native app for a generic iOS Simulator using Xcode on macOS 26. [Verified build](https://github.com/joseherrerias-maker/Plinka/actions/runs/40045749850). This does not establish real-device runtime testing, code signing, or TestFlight readiness.

## First playable native scope

- True SwiftUI music staff with five lines and nine pitch positions
- 32 half-beat steps / four measures, horizontal scroll
- Instrument stickers for piano, xylophone, guitar, trumpet, flute, bells, synth, drums
- Tap to add notes; drag to reposition; erase, undo, clear, demo melody
- Piano and guitar have clearly different synthesized timbres
- Audio is generated offline into a PCM buffer via AVAudioEngine/AVAudioPlayerNode
- Play, Pause, Stop, and Loop; playback ends after the final placed note
- Local song persistence through UserDefaults (web and native saves are separate)
- Responsive iPad landscape and iPhone portrait layouts

## Deliberately not added yet

- Final recorded instrument samples, a future polished mascot/icon redesign, export to video/YouTube Shorts
- Parent gate/privacy policy/App Store product listing, in-app purchases or subscriptions
- Analytics, accounts, cloud storage
- Final Apple signing, TestFlight release or App Store submission

## Codemagic: compile and TestFlight workflows

The repository's root [`codemagic.yaml`](../codemagic.yaml) now has **two manually triggered workflows**:

1. **Pluki iOS - Compile Only** (`plinka-ios-compile`): unsigned iOS Simulator build, no Apple credentials, no TestFlight upload.
2. **Pluki iOS - TestFlight Upload** (`plinka-ios-testflight`): Apple distribution signing, signed Release IPA, and upload to App Store Connect for **internal TestFlight testing only**. It does **not** submit Plinka to App Store review.

Neither workflow starts automatically on a GitHub commit, and both are available under branch `main` when launching a Codemagic build.

### One-time setup for TestFlight Upload — reuse Milo integration

Plinka now references the existing Codemagic Developer Portal integration **`Milo Codemagic 2`**, already used by Milo's working signed workflow. No duplicate App Store Connect API key or `appstore_credentials` group is required.

Before running the first signed Plinka build:

1. Apple Developer App ID **`com.joseherrerias.plinka`** has been registered and the **Pluki** iOS app record was accepted in App Store Connect.
2. In Codemagic **Team settings → codemagic.yaml settings → Code signing identities**, verify the existing Apple Distribution certificate is available (Milo uses the reference `Milo Distribution`). A distribution certificate may sign multiple apps belonging to the same Apple Developer team.
3. Create/fetch an **App Store provisioning profile for Plinka's bundle ID** and add it to Codemagic's iOS provisioning profiles. Milo's provisioning profile belongs to Milo's bundle ID and cannot be reused for Plinka. Codemagic selects the Plinka profile using `ios_signing.distribution_type: app_store` and `bundle_identifier: com.joseherrerias.plinka`.
4. The approved **temporary** Pluki music-note icon is now integrated through `Plinka/Assets.xcassets/AppIcon.appiconset` and generated before CI builds. The build script `ios/scripts/prepare-app-icon.sh` converts a compact, source-controlled rendering of the approved artwork into the required 1024px PNG. We can replace it with the original full-resolution PNG or a future mascot later.
5. In Codemagic → Plinka → **Start new build** → `main` → **Pluki iOS - TestFlight Upload**.

The workflow builds a signed Release IPA and uploads it to App Store Connect for **internal TestFlight testing only**, without submitting for external beta or public App Store review. Add internal testers in App Store Connect after Apple's processing finishes. It remains manual so it doesn't automatically consume Codemagic minutes.

**Status:** iOS unsigned simulator compilation passed in [GitHub Actions Build 1](https://github.com/joseherrerias-maker/Plinka/actions/runs/40045749850). The new Codemagic signed/TestFlight workflow has **not been run**; the latest GitHub Actions compile tests the new icon asset. A connected Developer Portal integration does not itself verify that Plinka's app record, distribution certificate, provisioning profile, or app icon is ready.

References: [Codemagic signing guide](https://docs.codemagic.io/yaml-code-signing/signing-ios/), [TestFlight publishing guide](https://docs.codemagic.io/yaml-publishing/app-store-connect/), [native iOS guide](https://docs.codemagic.io/yaml-quick-start/building-a-native-ios-app/).

## Other cloud-build option

Apple Xcode Cloud also supports this repository with a shared scheme and App Store Connect integration, but Codemagic is now configured for manual compile-only builds.

Keep all iOS files under `ios/`. Do not move or replace the root `index.html`: GitHub Pages should keep working.
