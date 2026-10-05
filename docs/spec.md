# Spec: BYD Sealion 7 sideload kit (project at ~/Projects/byd-sealion7)

This is the originating spec for the project. Section A is the owner's original brief, verbatim.
Section B lists the decisions agreed with the owner during a design interview afterwards; where B
contradicts A, B wins (it is an agreed change, not scope creep). Section C lists the deliverables.

## A. Original brief (verbatim)

Act as an expert Android systems engineer and Apple scripting specialist. Create a completely automated
Bash script for macOS that lets me sideload a curated set of apps and retro games over Wi-Fi onto my BYD
Sealion 7 EV (which runs on an Android DiLink 5 backend).

I am not sitting inside the car right now but I will be a little bit later. My Mac and my car will
connected to my home wifi as I'm home.

Please generate a single script that runs the following steps sequentially:

1. WORK DIRECTORY: Create a temporary working folder called "BYD_Sideload" on my macOS Desktop and change
   the terminal directory into it. Inside it, create a nested subfolder called "ROMs".
2. TOOLS ARCHIVE: Check if Android Platform-Tools for Mac is present. If not, automatically curl/download
   the official Google macOS zip ("https://google.com"), unzip it, and move 'adb' into the working
   directory root.
3. APP & GAME DOWNLOADING: Use 'curl -L' to scrape/download the latest official release APK versions of
   these specific apps directly into the folder:
   - SmartTube (Android TV client for YouTube without Google Services framework) from its stable release
     link on GitHub.
   - Aurora Store (An open-source, anonymous Google Play Store mirror to easily install/update future apps
     natively on the car dashboard).
   - Brave Browser for Android (The official Brave ARM64 build to enjoy ad-free browsing on the dashboard).
   - App Manager (The essential open-source package installer by MuntashirAkon—once installed via adb,
     this lets me install apps directly on my car screen later without needing my laptop).
   - RetroArch (The all-in-one classic gaming console emulator).
   Rename the downloaded app files to simple names: 'tube.apk', 'store.apk', 'brave.apk', 'manager.apk',
   and 'retroarch.apk'.
4. ROM ACQUISITION: Have the script download a few lightweight that will work well on this system retro
   game ROMs (such as classic NES or Game Boy homebrew titles like '2048.nes' or open-source platformers)
   and save them directly into the "ROMs" subfolder.
5. USER PROMPT: Print a clear instruction in the terminal asking me to look at my Sealion 7 Wi-Fi
   settings, read the car's IP address, and type it into the terminal prompt.
6. WIRELESS CONNECTION: Run './adb connect <IP>' to pair with the car. Remind me that a popup window will
   immediately appear on the car's 15.6-inch screen, and I must check "Always Allow" and tap "OK".
7. DEPLOYMENT & PUSH:
   - Wait 5 seconds for authorization to complete, then sequentially execute standard adb install commands
     using the '-g' flag (e.g., './adb install -g tube.apk') for all 5 apps.
   - Use the './adb push' command to copy the entire "ROMs" folder from the Mac directly onto the car's
     internal storage (e.g., to '/storage/emulated/0/Download/ROMs') so RetroArch can easily scan and load
     the games for kids.
8. CLEANUP: Once all apps print "Success" and files are pushed, disconnect the adb link.

Provide clear, step-by-step terminal instructions for a Mac beginner on how to execute your script. Do not
use complex dependencies; keep it to native macOS tools (curl, unzip, bash). thats what i got so far for my
byd sealion 7 i know i can get into developer mode but not sure if theres something i missied maybe get me
waze too and some other stuff i wanna be able to have a good mix of stuff and maybe a way to disable some
of the pesky driver monitoring things that contantly turn on after ive turned them off like the driver
monitoring thing like keep eyes on road its too intrusive i want it fully turned off and iwanna be able to
see some more car stats not sure how we achive this im looking for a more tesla like experiance with this
car not sure if thers other thing we could achive

## B. Decisions agreed in the design interview (these override A)

Facts established by research first (as of 2026-10-04):
- Head unit: BYD DiLink 5, Android 11 (API 30), arm64-v8a, no Google Play Services, no Play Store.
- Wireless ADB is classic adb over TCP port 5555, switched on through a hidden page behind the
  "Factory reset" row (Settings > System > Version; tap the words "Factory reset" 7 times; rotate to
  portrait; tap the first button). Confirmed on a Moroccan car (V3.1.0) and a German car (3.3.0); not yet
  on an Australian car. The blue Reset button on that row really wipes the car.
- Single APKs only: XAPK/APKM bundles fail over adb. Waze and Brave ship as bundles.
- BYD has removed ADB access in OTA updates on other models; already-installed apps usually survive.
- Driver monitoring ("keep eyes on road") cannot be made to stay off through any setting or firmware.

Decisions:
- D1 Driver monitoring: the project will NOT disable, automate, or script anything about driver
  monitoring (no ADB, no Tasker, no killing services). The owner only gets the quickest legitimate
  methods as information: the tile in the swipe-down quick-control panel, and pressing the steering-wheel
  scroll button when the warning sounds (one owner reports this pauses it 15 minutes; unverified here).
- D2 Video/games are for stationary use (parked, charging, track, private land). No driving lock-out is
  to be added.
- D3 "Tesla-like" wish list: everything (car stats, nav, media, kids' games, dashcam/sentry, remote
  control). Remote control is left to the official BYD app. Car stats: Sealion 7 Pilot (third-party
  head-unit app) is the recommended option but is not yet publicly installable; OBD dongle + Car Scanner
  app is the backup. Both are information only, nothing in the scripts.
- D4 Waze: installed from Aurora Store on the car screen, not by the script (bundle APK; sign in with a
  non-Google account). SUPERSEDED 2026-10-04: the AU car refuses all on-screen installs, so Waze and
  Brave come via scripts/fetch-extra.sh (apkeep) + scripts/install-extra.sh (adb install-multiple).
  Waze installs but its map didn't load on the first try; not yet diagnosed.
- D5 Risk level (a): normal user apps only. No root, no system packages, no system settings over ADB.
  Per-app grants are allowed: adb install -g, and appops REQUEST_INSTALL_PACKAGES for the two on-car
  installers only (docs/adr/0001).
- D6 Two-stage script: prep.sh (at home, Mac only, downloads everything, re-runnable, skips existing
  files, --refresh to refetch) and install.sh (in the car, re-runnable, skips apps already installed,
  --update to reinstall everything, --with-overdrive to skip the prompt).
- D7 Project lives at ~/Projects/byd-sealion7/ (not Desktop/BYD_Sideload). Folders: tools/ (adb),
  downloads/apks/, downloads/ROMs/, docs/, scripts/.
- D8 Car software version unknown until the owner is in the car. Checklist is written for the
  V3.1.0/3.3.0 procedure and tells the owner to stop if screens differ.
- D9 Car stats: Sealion 7 Pilot first, OBD dongle later. Information only.
- D10 Overdrive (dashcam/sentry, alpha) is downloaded by prep.sh and offered as an optional step in
  install.sh, off by default (y/N prompt; --with-overdrive flag).
- D11 SmartTube for the owner (installed by the script). YouTube Kids was dropped on 2026-10-05
  (owner: "unnecessary"). Added the same day: Jellyfin (script), microG + ReVanced-patched YouTube
  (optional build stage, docs/adr/0003).
- D12 Games: exactly three free homebrew titles, picture-only: Libbet and the Magic Floor (GB),
  Concentration Room (NES), Flappy flappy (GB). No commercial ROMs, no ROM sites.
- D13 Brave: via Aurora on the car (owner's choice), with Chrome via Aurora as fallback. So the script
  no longer downloads brave.apk. SUPERSEDED 2026-10-04: Brave comes via fetch-extra.sh + install-extra.sh.
- D14 Claude app: via Aurora, sign in with "Continue with email"; fallback claude.ai in Brave.
  SUPERSEDED 2026-10-04: no Claude APK exists outside Google Play and Aurora can't install here, so
  claude.ai in Brave is the only route.
- D15 Apps the script installs, in this order: App Manager, Aurora Store, SmartTube, RetroArch,
  then Overdrive (optional). On-car installers first so they are present if a later OTA removes ADB
  (recorded in docs/adr/0001).
- D16 Platform-tools URL is https://dl.google.com/android/repository/platform-tools-latest-darwin.zip.
- D17 Steps 5-8 of the brief are kept: prompt for the car IP, adb connect, remind about the
  Always-allow popup, wait for authorisation (polling instead of a blind 5 s), adb install -g for each
  scripted app, adb push the ROMs folder to /storage/emulated/0/Download/ROMs, disconnect at the end.
- D18 Beginner instructions in README.md; the in-car procedure in docs/in-car-checklist.md, which must
  make it impossible to confuse the "Factory reset" label with the blue Reset button.
- D19 Native macOS tools only (bash, curl, unzip) plus Google's adb. macOS /bin/bash is 3.2.

## C. Deliverables
- scripts/prep.sh, scripts/install.sh (executable), README.md, docs/in-car-checklist.md,
  CONTEXT.md (glossary), docs/adr/0001-user-apps-only-two-stage-install.md,
  docs/adr/0002-driver-monitoring-out-of-scope.md, docs/beyond-the-script.md (D1, D3, D9 information),
  tests/dry-run.sh and tests/mock-adb (the only way install.sh is exercised without a car).
- Added 2026-10-05: scripts/build-youtube.sh, scripts/fetch-extra.sh, scripts/install-extra.sh,
  docs/adr/0003-youtube-patched-on-the-mac.md.
- install.sh ran on the owner's AU car on 2026-10-04: SmartTube works; Aurora Store installs nothing.
