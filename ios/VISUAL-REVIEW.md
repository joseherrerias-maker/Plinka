# Pluki visual review

GitHub → Actions → **Pluki Visual Review** → Run workflow → main.

This manual workflow builds one unsigned Debug app and captures six actual simulators in portrait and landscape: iPhone SE (3rd generation), iPhone 16, iPhone 16 Pro Max, iPad mini (A17 Pro), iPad Pro 11-inch (M4), iPad Pro 13-inch (M4). A marked workflow-file commit can bootstrap a run; ordinary app pushes do not run this matrix. Codemagic is not involved.

Download **Pluki-Visual-Report**, extract it, and open `index.html`. There are 96 full-resolution PNGs and six labeled contact sheets. Each device captures Home, a busy sample, song menu, saved songs with a long title, Save with keyboard, Samples, Settings and an actual short video preview. The native layout and native sheets are used, not mockups. The Debug-only tour seeds disposable simulator data and exchanges capture acknowledgements with the host; no screenshot hooks run in signed Release builds. Required device names fail explicitly if unavailable; no silent substitute is used.

A green Action means capture completed, not that every layout looks good. Review all images for overlaps, cut-off text, reachable controls, safe areas, sticker scale and keyboard placement. Record approval per device/orientation against the commit shown on the run. Keep approved report images as a baseline before making layout changes.

This first matrix covers full-screen, standard-text layouts on the runner's newest installed iOS runtime. It does not automate taps, VoiceOver, larger accessibility text, iPad multitasking, old OS versions, physical-device rotation or Photos permissions. Those require separate targeted checks. Video preview uses a short excerpt to avoid rendering a whole song six times; audio/export correctness has its own media check.
