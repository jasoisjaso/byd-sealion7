BYD Sealion 7: SmartTube kit
============================

One command puts SmartTube (YouTube without ads, for when you're parked or
charging) on a BYD Sealion 7 (DiLink 5) head unit from a Mac, and keeps it up
to date.

The car refuses to install apps from its own screen, so everything goes in
from the Mac over Wi-Fi. That includes updates: SmartTube can't update itself
on this car. Re-run the same command whenever you want the newest version.

Want driver monitoring, lane assist, the speed limit chime and the other
nags to stay off? That's a separate app, Nag Killer:
https://github.com/jasoisjaso/byd-nag-killer

Status (Australian Sealion 7, October 2026): Wireless ADB and SmartTube work.
No root, no system changes, normal user apps only (docs/adr/0001). MIT
licence. Use at your own risk; this is not affiliated with BYD. If something
differs on your car, open an issue with your car's software version.


HOW TO RUN IT
-------------

1. On the Mac, open Terminal (Cmd+Space, type Terminal, Enter) and get the kit
   once:

       git clone https://github.com/jasoisjaso/byd-sealion7 ~/Projects/byd-sealion7

   If macOS offers to install "command line developer tools", say yes, then
   run the line again.

2. In the car (parked, on your home Wi-Fi): switch on Wireless ADB. Part A of
   docs/in-car-checklist.md walks through it. It takes a minute.

3. On the Mac (same Wi-Fi):

       ~/Projects/byd-sealion7/kit.sh

   Type the car's IP address the first time; after that, press Enter. Watch the
   car screen for "Allow USB debugging?": tick "Always allow" and tap OK.

That's it. The command:
  - downloads the newest SmartTube (stable), but only if it's newer than what
    you already have
  - installs it only if the car's copy is older (your settings are kept)
  - offers to remove apps left by older versions of this kit

To download at home without the car:   ~/Projects/byd-sealion7/kit.sh --download

The first time, sign in to SmartTube: open it, choose sign in, and enter the
code it shows at youtube.com/activate on your phone.


THINGS WORTH KNOWING
--------------------
- After a BYD software update: apps usually survive. Redo Part A and re-run
  kit.sh. If Wireless ADB is gone for good, there is no other way in: the apps
  stay at the version they're on.
- Overdrive: earlier versions of this kit also installed Overdrive (dashcam,
  proximity lock). It doesn't any more (docs/adr/0005). If you have it, kit.sh
  leaves it alone; get updates from Overdrive's own releases page.

Folder layout
  kit.sh                    the kit command
  docs/in-car-checklist.md  switching Wireless ADB on
  docs/beyond-the-script.md driver monitoring, car stats, other wishes
  CONTEXT.md, docs/adr/     terms used here, and why things are the way they are
  tests/dry-run.sh          checks kit.sh against a fake car (no car needed)
  downloads/, tools/        filled by kit.sh (not in git)

Earlier versions also installed App Manager, Aurora Store, a patched YouTube,
Waze, RetroArch and Jellyfin (and Brave, which works and is left alone). None
of them worked or got used on this car, so they were removed (docs/adr/0004).
kit.sh offers to uninstall them.
