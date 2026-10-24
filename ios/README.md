# Plinka — Native iOS prototype (Build 1: simulator compile passed)

This is a **standalone SwiftUI iPhone + iPad app**. The web prototype remains at the repository root as GitHub Pages `index.html`. No web backend or subscription is needed.

## Open and compile

Open `ios/Plinka.xcodeproj` in Xcode 26 or newer. Select the shared **Plinka** scheme, a device or iOS simulator, and Build. The app targets iOS 17+ on iPhone and iPad.

**Provisioning:** For a signed device build, choose your Apple Developer Team in Signing & Capabilities. The bundle ID `com.joseherrerias.plinka` is a provisional identifier; verify its availability in App Store Connect before distribution.

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

- Final recorded instrument samples, final app icon, export to video/YouTube Shorts
- Parent gate/privacy policy/App Store product listing, in-app purchases or subscriptions
- Analytics, accounts, cloud storage
- Final Apple signing, TestFlight release or App Store submission

## Codemagic: compile and TestFlight workflows

The repository's root [`codemagic.yaml`](../codemagic.yaml) now has **two manually triggered workflows**:

1. **Plinka iOS - Compile Only** (`plinka-ios-compile`): unsigned iOS Simulator build, no Apple credentials, no TestFlight upload.
2. **Plinka iOS - TestFlight Upload** (`plinka-ios-testflight`): Apple distribution signing, signed Release IPA, and upload to App Store Connect for **internal TestFlight testing only**. It does **not** submit Plinka to App Store review.

Neither workflow starts automatically on a GitHub commit, and both are available under branch `main` when launching a Codemagic build.

### One-time Apple setup for TestFlight Upload

- A paid **Apple Developer Program** membership and permission to manage App Store Connect keys are required.
- Register **`com.joseherrerias.plinka`** as an App ID in Apple Developer and create a new app record named Plinka in App Store Connect using the exact same bundle identifier. It is still a provisional bundle ID until it is registered.
- In App Store Connect → Users and Access → Integrations → App Store Connect API, create an API key (App Manager access) for Codemagic. **Do not paste the private key into this chat or commit it to GitHub.**
- In Codemagic → Plinka → Environment variables, create a group named exactly **`appstore_credentials`** with these **Secret** variables:
  - `APP_STORE_CONNECT_PRIVATE_KEY`: full content of the downloaded .p8 API key
  - `APP_STORE_CONNECT_KEY_IDENTIFIER`: App Store Connect key ID
  - `APP_STORE_CONNECT_ISSUER_ID`: issuer ID
  - `CERTIFICATE_PRIVATE_KEY`: PEM-encoded signing key used to create/fetch the Apple distribution certificate; Codemagic's signing documentation explains how to generate/export this key
- From Codemagic select **Start new build → main → Plinka iOS - TestFlight Upload**. The workflow fetches/creates the appropriate Apple distribution files, configures signing, increases the build number using `PROJECT_BUILD_NUMBER`, archives the native Xcode project, and uploads the IPA.

### Important limitations / checks

- **Before the first TestFlight upload:** Finish adding a valid iOS app icon asset. The native Build 1 project was intentionally created without a final branded asset catalog, and Apple may reject uploads missing required icons. Also check the app record, bundle ID and any Apple compliance questions.
- The workflow requests **TestFlight Internal Testing Only** in its export options; add the relevant internal testers in App Store Connect after Apple finishes processing the uploaded build.
- Codemagic credentials, provisioning and the .p8 private key are not currently available to this ChatGPT session. Only you can complete those secure Codemagic / Apple steps.
- The signed TestFlight workflow **has not yet run**. The separate [GitHub Actions simulator build](https://github.com/joseherrerias-maker/Plinka/actions/runs/40045749850) was successful.
- The workflow is deliberately **manual** to conserve your Codemagic credits; it does not run visual or UI tests.

References: [Codemagic signing guide](https://docs.codemagic.io/yaml-code-signing/alternative-code-signing-methods/), [TestFlight publishing guide](https://docs.codemagic.io/yaml-publishing/app-store-connect/), and [native iOS guide](https://docs.codemagic.io/yaml-quick-start/building-a-native-ios-app/).

## Other cloud-build option

Apple Xcode Cloud also supports this repository with a shared scheme and App Store Connect integration, but Codemagic is now configured for manual compile-only builds.

Keep all iOS files under `ios/`. Do not move or replace the root `index.html`: GitHub Pages should keep working.
