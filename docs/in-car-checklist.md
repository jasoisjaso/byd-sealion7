IN-CAR CHECKLIST: BYD Sealion 7 sideload
=========================================

Do this parked in the driveway, car in P, Mac on the same home Wi-Fi.
Takes about 15 minutes.

Tested elsewhere on software V3.1.0 (Morocco, BYD Lab) and 3.3.0 (Germany).
Australian menus should be the same in English. If a screen doesn't match,
STOP and write down what you see instead of guessing.


PART A: Turn on Wireless ADB (on the car screen)
-------------------------------------------------

1. Settings > System > Version.
   Write down the software version shown here: V__________

2. The bottom row says "Factory reset" (or "Reset to factory settings" /
   "Restore factory settings") in WHITE on the LEFT and has the word
   "Reset" in BLUE on the RIGHT.
   The row above it ("Restore settings") has a blue "Reset" too.

       !!! NEVER TOUCH EITHER BLUE "Reset". It really wipes the car. !!!

   Tap the WHITE WORDS "Factory reset" on the left 7 times, steady,
   about 2 taps per second. Nothing shows until the 7th tap.
   If nothing opens, wait a second and try again at an even rhythm.
   If a "Reset?" confirmation ever appears: tap CANCEL.

3. Rotate the screen to portrait (rotate button, bottom right).
   The hidden page only shows its controls properly in portrait
   (in landscape the long button labels run off the left edge).

4. The hidden page is in English. Tap the FIRST grey button, the long
   one that starts "CONNECT USB TO ENABLE DEBUGGING MODE/REVOKE USB
   DEBUGGING...". A message may say adb is on. If nothing appears,
   carry on anyway: install.sh checks within 30 seconds whether the car
   is listening and tells you plainly if it isn't. Rotate back to
   landscape if you want.

   Leave everything else on that page alone, especially
   "Factory Service Interface" and "Rollbench Mode".

   If step 2 does nothing after a few tries: stop. Some newer builds on
   other BYD models removed this, and it may happen here too. Note your
   version and don't try dialer codes off the internet.

5. Settings > Connection > Wi-Fi > make sure the car is on your home
   Wi-Fi > tap the network > write down the IP address: ____.____.____.____
   If no address is shown there, your router's app lists the car as a
   new device.


PART B: On the Mac
------------------

6. Open Terminal and run:
       ~/Projects/byd-sealion7/scripts/install.sh

7. Type the IP from step 5 when asked.

8. Watch the car screen. If "Allow USB debugging?" appears, tick
   "Always allow" and tap OK.

9. Answer y or n for Overdrive (dashcam). n is fine for the first go.

10. The script prints "Success" for each app, copies the games, and
    disconnects. If something fails it says why. Fix it and re-run;
    apps that are already done get skipped.


PART C: After the script (on the car screen)
---------------------------------------------

Waze and Brave: the car refuses installs started from Aurora Store or
App Manager on its own screen ("prohibited install from unknown source",
seen on the AU car 2026-10-04). Install them from the Mac instead,
while Wireless ADB is still on:
       ~/Projects/byd-sealion7/scripts/fetch-extra.sh     (at home, once)
       ~/Projects/byd-sealion7/scripts/install-extra.sh   (in the car)
  - Waze: sign in with email, not Google. If the map stays blank, see
    the note install-extra.sh prints at the end.
  - Claude: no APK outside Google Play; use claude.ai in Brave.

Aurora Store and App Manager stay on the car for browsing and for the
day BYD removes Wireless ADB, but on this car they can't install.

YouTube (ReVanced, app name "RVX"): only there if build-youtube.sh was
run at home. Open it; the first start asks to open microG for sign-in.
Sign in or skip. Settings > RVX > SponsorBlock to turn skipping on.

RetroArch setup, while still on home Wi-Fi:
  1. Main Menu > Online Updater > Core Downloader > install
     "Nintendo - Game Boy / Color (Gambatte)" and
     "Nintendo - NES / Famicom (FCEUmm)".
  2. Main Menu > Import Content > Manual Scan. Set:
       Content Directory: Download > ROMs > "<Scan This Directory>"
       System Name:       Nintendo - Game Boy
       File Extensions:   gb
       Default Core:      Gambatte
     then "Start Scan". Do it once more with System Name
     "Nintendo - Nintendo Entertainment System", extension "nes",
     core FCEUmm.
     Don't use the plain "Scan Directory": it only recognises games in
     RetroArch's database, and homebrew isn't in it, so it finds nothing.
     (Menu names as of RetroArch 1.22; not yet tried on the car.)
  3. The games now show under the Game Boy and NES icons. If anything
     above is missing: Main Menu > Load Content > Download > ROMs > tap
     a game and pick the core when asked.
  Touch controls appear on screen. A cheap Bluetooth controller is much
  easier for small hands if the car pairs with one.

SmartTube: open it and sign in to YouTube with the code it shows
(scan it with your phone). Confirmed working on the AU car 2026-10-04.

Jellyfin: open it and type your media server's address
(for example http://192.168.50.10:8096). Needs a Jellyfin server at
home; it's a player only.

Overdrive (if installed): open it once, then hold volume-down for
5 seconds to hard-reboot the screen. It's alpha software and the
developer has open bugs on DiLink 5 cameras, so it may not record.


SECURITY
--------
Wireless ADB stays on after the Mac disconnects (the script only closes
its own session). Nobody has yet tested whether it turns itself off when
the car restarts or sleeps overnight, so assume it stays on. Anyone on
the same Wi-Fi can ask to connect (the car still asks on screen). Fine
at home. Don't join the car to public Wi-Fi while it's on. Repeating
Part A is believed to switch it off again, but the button shows no on/off
state, so treat it as on until an install attempt is refused.

AFTER A BYD UPDATE
------------------
Apps usually survive. If any vanished, redo Part A and re-run install.sh.
If Part A no longer works, App Manager and Aurora on the car are the only
route left, and on the AU car they are currently refused ("prohibited
install from unknown source"). Write down the version and check the
project's GitHub issues for anyone who found a way.
