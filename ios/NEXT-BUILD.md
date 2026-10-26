# Changes after compiled Build 11

- Parent check appears only before an initial Photos permission request. Authorized saves go directly to Photos, including permission already granted in Build 11.
- Simplified the challenge to entering number words as digits in the displayed order; no reversing numbers.
- Denied/restricted access shows guidance instead of another puzzle. Resetting system authorization to not-determined requires a new check. Cancel/background never approves a permission request.
- Updated Help, Privacy and review notes to match. App label remains Build 11 until the next build is requested.

Validation: parent-approval tests and iOS compile. On device, check fresh permission, cancel/wrong answer, denial/retry, a second save, and upgrading from Build 11 with Photos already allowed. This permission-only gate approach remains subject to App Review for the final category.
