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

## Codemagic - compile only (manual)

The repository root [`codemagic.yaml`](../codemagic.yaml) defines the workflow **Plinka iOS - Compile Only**, ID `plinka-ios-compile`.

1. In [Codemagic](https://codemagic.io/apps), select **Add application**, connect GitHub, and select `joseherrerias-maker/Plinka` (not Milo-Native).
2. Use the **codemagic.yaml** configuration; select branch `main` and **Check for configuration file** if prompted.
3. Select **Start new build**, branch `main`, workflow **Plinka iOS - Compile Only**.
4. Review the build logs and resulting unsigned iOS Simulator `Plinka.app` artifact.

The workflow uses the M2 Mac mini with `xcode: latest`, executes `xcodebuild` on `ios/Plinka.xcodeproj` with scheme `Plinka`, and does not sign, run UI tests, publish, or trigger builds automatically. **No Apple certificates or API credentials are required** for this compile check. This is not a signed installable iPhone/iPad `.ipa`; Apple signing and provisioning must be configured separately for real-device testing or TestFlight.

The **GitHub Actions iOS simulator compile passed** independently on [Build 1](https://github.com/joseherrerias-maker/Plinka/actions/runs/40045749850). A Codemagic build has not been run or verified yet.

## Other cloud-build option

Apple Xcode Cloud also supports this repository with a shared scheme and App Store Connect integration, but Codemagic is now configured for manual compile-only builds.

Keep all iOS files under `ios/`. Do not move or replace the root `index.html`: GitHub Pages should keep working.
