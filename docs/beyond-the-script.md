BEYOND THE SCRIPT: driver monitoring, car stats, the rest of the wish list
==========================================================================

kit.sh installs SmartTube. Three things from the original brief can't be
done by it, so here is what is actually known. Written 4 October 2026,
updated 31 October 2026.

  "Confirmed"  = an owner, a reviewer or BYD said it; the source is listed
                 at the bottom.
  "Unverified" = nobody has reported it on an Australian Sealion 7 yet.


1. DRIVER MONITORING ("keep eyes on road")
------------------------------------------

Update, October 2026: Nag Killer (github.com/jasoisjaso/byd-nag-killer)
keeps it off. It's a separate app that switches driver monitoring off at
every start, within a few seconds, and can do the same for lane assist,
the speed limit chime, child detection, AEB, cross traffic brake and
emergency lane keeping. Tested on an Australian Sealion 7. This kit itself
still doesn't touch any of it (docs/adr/0002).

The car's own behaviour: BYD told carsales that the driver-assist items can
be switched off but come back on with every start, and no update up to 3.3.0
changes that. Without Nag Killer, what you can do:

  a. The full menu path (confirmed, generic BYD):
     Settings > Vehicle > Cabin Perception > Driver Attention Warning >
     Off > OK. Lasts for the current drive only.

  b. Faster: the swipe-down control panel (confirmed, Australian owners).
     Swipe down from the top edge of the screen. The panel has a tile
     called DMS; if it isn't showing, the panel can be edited to add it.
     Owners who did this say it is 2-3 taps per drive: swipe, tap DMS,
     confirm. Lane keeping on the same panel is one tap.

  c. When the warning sounds anyway: press the scroll button on the
     steering wheel. That pauses the fatigue/distraction warnings for
     15 minutes (one Sealion 7 owner's report on r/BYD; not tried here).

  d. Touching the screen to change the heating or cooling is a known
     trigger for the warning (drive.com.au review). Use the steering-wheel
     buttons or voice for climate while moving.

What this kit will not do, and why:
  - Camera covers. Clip-on plastic covers are sold for the Sealion 7
    (drive.com.au reported on them). They blind the camera, not the
    system: owners report the child-presence alerts still fire, and
    nobody knows how an insurer treats a covered safety camera after a
    crash.

One good sign: update 3.0.0 made Child Presence Detection remember "off"
after a restart, so BYD does change these defaults sometimes. Read the
release notes of each update for Driver Attention Warning.


2. MORE CAR STATS
-----------------

Already in the car (confirmed, drive.com.au review):
  - The steering-wheel buttons change what the 10.25-inch cluster behind
    the wheel shows: which safety systems are active, energy use, tyre
    pressures.
  - Settings has an Energy page (battery icon in the left column). Check
    what it offers before buying anything.

Sealion 7 Pilot (sealion7pilot.bydlab.dev) is the closest thing to a Tesla
energy screen for this car. It is a third-party app that runs on the head
unit itself: live dashboard (state of charge, range, consumption, tyre
pressures, high-voltage volts and amps, motor temperature, battery
health), EV trip planning with charging stops, turn-by-turn navigation
that projects onto the cluster behind the wheel, trip and charging
history.
  Status (confirmed from their site, 4 Oct 2026): it is installed from
  a phone app that is not in Google Play yet, so there is no public
  install today. Creating an account gives a free 3-month licence, then
  it needs a paid licence with no price announced. Sign up on the site
  to hear when it opens. Unverified on Australian cars (their examples
  are Morocco and Turkey).

Backup: an OBD dongle plus the Car Scanner ELM OBD2 app (on your
phone). Car Scanner has a vehicle profile for "Sealion 7
EV (EU version)" and videos show battery health and cell voltages on a
Sealion 7 AWD. Needs a Bluetooth OBD2 dongle from Car Scanner's
compatibility list, plugged into the port under the dash. Unverified on
Australian cars.

Also seen on BYD head units, unverified on DiLink 5: Electro
(electro.app.br), BYDMate.


3. THE REST OF THE TESLA-LIKE LIST
----------------------------------

What happened on the AU Sealion 7 (October 2026). The car refuses every
install started from its own screen, so on-car app stores can't install
anything, and every app has to come from a Mac with adb.

Video             SmartTube (kit.sh): WORKS. A patched YouTube (ReVanced
                  Extended) installed but its feed errors out; RVX was
                  abandoned in Dec 2025 (MorpheApp is the live successor,
                  untested here). Plex: confirmed on 3.3.0 elsewhere.
                  Netflix says "device not supported", Disney+ gives audio
                  only, Prime Video won't install. Parked or charging only.
Dashcam           Overdrive (github.com/yash-srivastava/Overdrive-release,
                  braveheart build; no longer installed by kit.sh). Needs
                  Ingestion Mode set to DiLink 5. Continuous recording works;
                  parked sentry keeps the car awake. Slowed CarPlay on the
                  owner's car, which is why it was taken off.
Proximity lock    Overdrive has one, but it missed the walk-away on the
                  owner's car: the phone's Bluetooth drops at power-off and
                  reconnects too late.
Navigation        Waze installed but showed a blank map: it needs real Google
                  Play Services. Use CarPlay / Android Auto from the phone.
Browser           Brave: works. Not part of kit.sh; kit.sh leaves it alone.
Games             RetroArch: removed because it went unused.
Cluster mirroring DashCast (github.com/Kiroha/byd-dashcast). Unverified on
                  the Sealion 7.
Remote control    The official BYD app (pre-conditioning, lock, charge
                  status).
Music             Bluetooth or CarPlay from the phone.

Stay away from:
  - The DeBondor "BYD unlocking guide" and its firmware files. They are
    for DiLink 13.x / msm8953 cars (Han, Seal, Atto). Flashing them on a
    Sealion 7 could brick the head unit.
  - The wheregoes/byd-apps USB installer: incompatible with DiLink 5.
  - Dialer codes (*#...#*) with IMEI "password generators": other models,
    unverified here, and they hand the car's IMEI to a website.
  - Anything that needs root. Nothing above does.


4. UPDATES
----------

BYD has removed ADB access on other models in updates. Apps already
installed have survived so far, but without Wireless ADB they can't be
updated: there is no on-car route on this car. Before accepting a BYD
update, skim the Whirlpool Sealion 7 thread or r/BYD for what it changed.

If kit.sh can't connect but Wireless ADB is on, Buddy-Load
(github.com/charleschowsg/buddy-load, signed Apple Silicon DMG) is a
point-and-click Mac app that does the same adb install. A German
reviewer used it on 3.3.0.


SOURCES
-------
carsales.com.au, "Your questions answered: how can I permanently switch
  off annoying driver assist systems" (BYD's reply)
reddit.com/r/BYD/comments/1qmmrc3 (Sealion 7 shortcuts; scroll button)
reddit.com/r/BYD/comments/1jp7z47 (ADAS shortcuts, 2-3 taps)
reddit.com/r/BYD/comments/1mky4bd and r/AustralianEV 1tygg4a (covers)
reddit.com/r/BYD/comments/1nm0h7y (OTA 3.0.0 notes)
forums.whirlpool.net.au/thread/3vw46lj5 (AU owners, every-drive toggles)
drive.com.au, 2025 BYD Sealion 7 Premium review; "BYD, GWM owners using
  covers to silence annoying safety features"
youtube.com/watch?v=Q4m8j0TMONE (menu path)
smarthomeassistent.de, "Apps auf dem BYD Sealion 7 installieren" (app
  results on 3.3.0, Buddy-Load)
sealion7pilot.bydlab.dev; carscanner.info/profile-database-changelog
github.com/wheregoes/byd-apps issue 3; github.com/DeBondor/byd-unlocking-guide
