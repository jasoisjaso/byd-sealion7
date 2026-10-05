BYD Sealion 7: sideload kit
===========================

Two scripts. Prep runs at home and needs no car. Install runs once the car's
Wireless ADB is on. Both only use built-in macOS tools (bash, curl, unzip).

Status (Australian Sealion 7, 2026-10-05): Wireless ADB works, install.sh
works, SmartTube works. Aurora Store installs nothing on this car. The
ReVanced YouTube build, Jellyfin, Waze and Brave install but are not yet
confirmed working in the car. Open an issue with your car's software
version if something differs on yours.

No root, no system changes: normal user apps only (docs/adr/0001). MIT
licence. Use at your own risk; this is not affiliated with BYD.

Folder layout
  scripts/prep.sh          downloads adb, the apps and the kids' games
  scripts/install.sh       connects to the car and installs everything
  scripts/build-youtube.sh optional: builds ad-free YouTube (ReVanced) on the Mac
  scripts/fetch-extra.sh   optional: fetches Waze and Brave (split bundles)
  scripts/install-extra.sh optional: installs Waze and Brave from the Mac
  docs/in-car-checklist.md turns on Wireless ADB in the car (do this first)
  docs/beyond-the-script.md driver monitoring, car stats, the rest of the wish list
  downloads/apks/          manager, store, tube, retroarch, jellyfin, gmscore, overdrive,
                           youtube (if built); extra/ for Waze and Brave
  downloads/ROMs/          libbet.gb, croom.nes, flappy_flappy.gb
  tools/platform-tools/    Google's adb for Mac
  tests/dry-run.sh         checks install.sh against a fake car (no car needed)


HOW TO RUN IT (first time on a Mac)
-----------------------------------

1. Open Terminal: press Cmd+Space, type Terminal, press Enter.
   Get the kit (once):

       git clone https://github.com/jasoisjaso/byd-sealion7 ~/Projects/byd-sealion7

   (If macOS offers to install "command line developer tools", say yes,
   then run the line again.)

2. Prep (at home, any time). Paste this line and press Enter:

       ~/Projects/byd-sealion7/scripts/prep.sh

   It downloads about 350 MB. Running it again skips files you already
   have. To fetch newer versions of everything:

       ~/Projects/byd-sealion7/scripts/prep.sh --refresh

3. In the car: follow PART A of docs/in-car-checklist.md to turn on
   Wireless ADB and write down the car's IP address. Car parked in P,
   on home Wi-Fi.

4. Install. On the Mac (home Wi-Fi), paste:

       ~/Projects/byd-sealion7/scripts/install.sh

   Type the car's IP when it asks. If macOS asks whether Terminal may find
   devices on your local network, click Allow. Watch the car screen for an
   "Allow USB debugging?" box: tick "Always allow" and tap OK. It then asks
   y/N about Overdrive (the dashcam app); n is fine for the first go.

   Options:
       install.sh --update           reinstall/update every app (keeps their data)
       install.sh --with-overdrive   install the dashcam app without asking

5. On the car: follow PART C of the checklist (Waze and Brave via
   install-extra.sh; RetroArch cores and game scan; SmartTube sign-in).

Optional extras (each needs Homebrew: /bin/bash -c "$(curl -fsSL
https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"):

   YouTube without ads (ReVanced). At home, once, 20-30 minutes:
       brew install openjdk apkeep
       ~/Projects/byd-sealion7/scripts/build-youtube.sh
   install.sh then installs it (with microG) next time it runs.

   Waze and Brave. At home:
       brew install apkeep
       ~/Projects/byd-sealion7/scripts/fetch-extra.sh
   then in the car, Wireless ADB on:
       ~/Projects/byd-sealion7/scripts/install-extra.sh

If macOS says "permission denied", run this once and try again:

       chmod +x ~/Projects/byd-sealion7/scripts/*.sh


AFTER A BYD SOFTWARE UPDATE
---------------------------
Redo Part A of the checklist first (an update may switch Wireless ADB off),
then re-run install.sh. Apps that are already there get skipped. If Wireless
ADB no longer turns on, Aurora Store and App Manager on the car are the only
route left, and on the AU car they are currently refused ("prohibited install
from unknown source"), so keep Wireless ADB working if you can.

WHAT THE SCRIPTS DON'T DO
-------------------------
Driver monitoring can't be made to stay off; the quickest per-drive ways,
plus car stats (Sealion 7 Pilot, OBD) and the rest of the Tesla-like list:
docs/beyond-the-script.md.

Background and decisions: CONTEXT.md and docs/adr/.
