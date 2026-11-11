# Pluki 1.1 — Build 32: privacy and help text

The bundled privacy policy still described the October 26 behavior. This build applies the prepared November 11 policy so the offline policy agrees with the updated website and the current app.

## Changes

- Use the exact `ios/Plinka/PrivacyPolicy.txt` from `Pluki_iOS_Privacy_Update_For_Next_Build(1).zip`.
- Describe recovered drafts, editable `.pluki` project transfer, local rating preferences, Photos permissions, temporary export files, and parent-checked external links.
- Correct “Try a sample” help to explain that meaningful unsaved melodies are preserved as Recovered drafts before switching.
- Set `CURRENT_PROJECT_VERSION` and `PLUKI_RELEASE_BUILD` to 32 in Debug and Release; marketing version remains 1.1.

No app behavior, saved data, sound, artwork, layout, permissions, privacy manifest, bundle ID, signing settings, or CI workflow changes are included.

## Validation and distribution

- Verify the policy matches the prepared package exactly, is included in the Resources build phase, and passes the existing privacy validation script.
- The existing GitHub compile workflow checks unsigned Debug/Release compilation, bundled policy and manifest, saved songs, draft recovery, project import, and parent approval.
- Use the existing manual Xcode Cloud `main` workflow for the signed build. Verify the next App Store Connect build number before starting and the processed number afterward; do not advance the source number for failed attempts.
- On iPhone and iPad, open Help & About → Privacy policy offline, scroll through the November 11 text, and check the updated sample help. Confirm external support/privacy links still require the parent check.
- Device acceptance is pending until the signed app is tested. Leave the current App Store review submission untouched.
