# Plinka — Native iOS prototype (0.1 / pre-build)

This is a **standalone SwiftUI iPhone + iPad app**. The web prototype remains at the repository root as GitHub Pages \`index.html\`. No web backend or subscription is needed.

## Open and compile

Open \`ios/Plinka.xcodeproj\` in Xcode 26 or newer. Select the shared **Plinka** scheme, a device or iOS simulator, and Build. The app targets iOS 17+ on iPhone and iPad.

**Provisioning:** For a signed device build, choose your Apple Developer Team in Signing & Capabilities. The bundle ID \`com.joseherrerias.plinka\` is a provisional identifier; verify its availability in App Store Connect before distribution.

**First-build status:** Source files and Xcode project scaffolding are committed, but this environment has no macOS/Xcode SDK. Swift syntax-only checks cannot substitute for a device/simulator build. Do not label this as successfully compiled until an actual Xcode build has passed.

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

## Cloud build

Apple Xcode Cloud supports this repository and requires a shared archivable scheme (included here), an App Store Connect app record, development signing and initial configuration. For your current older Mac, a cloud Mac/Xcode service or Codemagic compile-only workflow may be the practical first-build route.

Keep all iOS files under \`ios/\`. Do not move or replace the root \`index.html\`: GitHub Pages should keep working.
