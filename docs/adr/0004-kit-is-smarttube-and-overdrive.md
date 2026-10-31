# 0004 — The kit is SmartTube and Overdrive

Date: 2026-10-17
Status: Superseded by 0005 (Overdrive dropped, 2026-10-31). The removals below still stand. Supersedes 0003; supersedes the "on-car installers first" part of 0001.

Two weeks of real-car testing showed most of the kit does nothing useful on the AU Sealion 7, so the kit now installs only the two apps that work and get used: SmartTube (YouTube without ads) and Overdrive (dashcam, proximity lock). Everything else is removed from the repo and uninstalled from the owner's car, and the kit gains a one-command update for those two apps, because neither can update itself from the car screen.

## Removed, and why
- App Manager, Aurora Store: meant as on-screen installers and the fallback if an OTA kills Wireless ADB, but the car refuses every install started on its own screen, so they can't install or update anything.
- Patched YouTube (RVX) and microG: RVX was abandoned in Dec 2025 and its home feed errors out; SmartTube covers the need.
- Waze: blank map without real Google Play Services; phone CarPlay does the job.
- RetroArch and the homebrew games: unused.
- Jellyfin: never tested and no media server at home; easy to add back if one appears.

Brave works on the car and the owner keeps it: the kit leaves it alone (no install, no removal).

## Consequences
- If an OTA removes Wireless ADB there is no on-car way to install or update. Installed apps usually survive OTAs; they just freeze at their last version. Accepted: the on-car installers never worked anyway.
- Removed items stay in git history. Bringing patched YouTube back would mean MorpheApp, not RVX (notes in the project memory).
