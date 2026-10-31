IN-CAR CHECKLIST: BYD Sealion 7 kit
===================================

Car parked in P on your home Wi-Fi, Mac on the same Wi-Fi.
Part A every time you run kit.sh; Part C only the first time.

Tested on the Australian Sealion 7; the same menus are reported on V3.1.0
(Morocco) and 3.3.0 (Germany). If a screen doesn't match, STOP and write down
what you see instead of guessing.


PART A: Switch on Wireless ADB (car screen, about a minute)
-----------------------------------------------------------

1. Settings > System > Version.

2. The bottom row says "Factory reset" in WHITE on the LEFT and "Reset" in
   BLUE on the RIGHT. The row above it has a blue "Reset" too.

       !!! NEVER TOUCH EITHER BLUE "Reset". It really wipes the car. !!!

   Tap the WHITE WORDS "Factory reset" 7 times, steady, about 2 taps per
   second. Nothing shows until the 7th tap. If a "Reset?" box ever appears,
   tap CANCEL.

3. Rotate the screen to portrait (rotate button, bottom right). The hidden
   page only shows its buttons properly in portrait.

4. Tap the FIRST long grey button, "CONNECT USB TO ENABLE DEBUGGING
   MODE/REVOKE USB DEBUGGING...". Leave everything else on that page alone,
   especially "Factory Service Interface" and "Rollbench Mode". Rotate back.

5. First time only: Settings > Connection > Wi-Fi > tap your network > note
   the IP address (192.168.x.x). kit.sh remembers it after that. If the car
   gets a new address one day, kit.sh says it can't find the car: look the
   address up here again.

The car switches Wireless ADB off by itself after it has been parked off,
so this is needed every session.


PART B: On the Mac
------------------

6. Run   ~/Projects/byd-sealion7/kit.sh
   Type the IP (first time) or press Enter. If the car shows "Allow USB
   debugging?", tick "Always allow" and tap OK.

7. It tells you what it updated, and what it couldn't do and why. Fix the
   problem and re-run: anything already up to date is skipped.


PART C: First-time app setup (car screen)
-----------------------------------------

SmartTube
  Open it, choose sign in, and enter the code it shows at youtube.com/activate
  on your phone.

Keeping driver monitoring and the other nags off is a separate app, Nag
Killer (github.com/jasoisjaso/byd-nag-killer). It has its own install steps.


SECURITY
--------
While Wireless ADB is on, anyone on the same Wi-Fi can ask to connect (the
car still asks on screen). Fine at home; don't join the car to public Wi-Fi
in that state. The car switches it off once it has been parked off.

AFTER A BYD UPDATE
------------------
Apps usually survive. Redo Part A and re-run kit.sh. If Part A no longer
works, write down the software version and check the project's GitHub issues;
the apps on the car keep working, but they can't be updated.
