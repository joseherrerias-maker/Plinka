# Parent-check number entry — pending device verification

Build 15 was reported to close/restart on iPad after the first parent-check digit. No crash report is available; the underlying exception has not been identified.

The shared parent-check screen now uses on-screen digit buttons and a read-only answer display on every device. This removes the system keyboard/TextField update path from video saving and approved contact/website links. Four digits are required, with Delete and Clear controls. Continue, wrong-answer challenge renewal, cancellation, background invalidation, and one-use approval retain their existing behavior. No build-number or sound changes are included.

Before release, verify on a real iPad and iPhone:
- First digit and subsequent digits do not close the app; fifth digits are blocked.
- Delete/Clear work; Continue is disabled until four digits are entered.
- Wrong answers clear the entry and display a new challenge; correct answers continue once.
- Cancel/background never triggers Photos or an external link.
- First video save shows the native Photos permission only after approval; allowed saving succeeds, denial is handled, and later authorized saves skip the gate.
- Contact and website checks use the same keypad.
- Portrait/landscape and larger text remain scrollable, with VoiceOver labels for digits and editing controls.

The change is a workaround for the reported input path, not a confirmed crash-root-cause diagnosis. Physical-device verification is still required.
