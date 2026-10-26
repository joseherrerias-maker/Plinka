# Changes after compiled Build 11

- Parent check appears only before an initial Photos permission request. Authorized saves go directly to Photos, including permission already granted in Build 11.
- Simplified the challenge to entering number words as digits in the displayed order; no reversing numbers.
- Denied/restricted access shows guidance instead of another puzzle. Resetting system authorization to not-determined requires a new check. Cancel/background never approves a permission request.
- Updated Help, Privacy and review notes to match. App label remains Build 11 until the next build is requested.

Validation: parent-approval tests and iOS compile. On device, check fresh permission, cancel/wrong answer, denial/retry, a second save, and upgrading from Build 11 with Photos already allowed. This permission-only gate approach remains subject to App Review for the final category.

- Enlarged the exported video sheet: portrait paper is 1010 px tall (previously 830), with tighter outer margins and a compact branded header. Slightly larger portrait stickers and beat spacing. Landscape retains room for both footer lines.
- Footer now reads “Made with Pluki” at the existing 28.75 pt size, with “Available in the App Store” below at 22 pt. Export dimensions remain 720×1280 / 1280×720; Photos may letterbox on taller screens.
- Validate both export orientations with the existing video smoke check, then review on device.
