# 0005 — The kit is SmartTube only

Date: 2026-10-31
Status: Accepted. Supersedes 0004.

The kit no longer installs or updates Overdrive. It installs SmartTube and nothing else.

## Why
- The owner took Overdrive off his car on 27 Oct 2026. On this head unit it slowed CarPlay, and the parts he used (proximity lock, parked sentry) never settled: proximity lock missed the walk-away, and parked keep-alive held the phone's Bluetooth audio from inside the house. A kit that installs an app nobody here runs can't be tested or supported.
- Overdrive's aftercare in kit.sh (switching it back on in BYD's background-apps list) had that screen's switch backwards: on the real car, ON means the app is blocked (found 18 Oct 2026). Fixing it for an app the kit no longer uses isn't worth it.
- Keeping car nags off (driver monitoring, lane assist, speed limit chime, AEB and the rest) is now its own app, Nag Killer (github.com/jasoisjaso/byd-nag-killer), with its own installer. The kit points to it rather than installing it.

## Consequences
- Overdrive is not on kit.sh's "old kit apps" list: people who use it keep it, and kit.sh leaves it alone, the same as Brave. They update it from Overdrive's own releases.
- The Overdrive setup notes (camera ingestion mode, recommended settings, proximity lock) are gone from the checklist; they stay in git history.
