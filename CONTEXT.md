# BYD Sealion 7 — head unit customisation

Glossary for the sideload project. Terms only; no implementation detail.

**Head unit**
The car's centre-screen computer (BYD DiLink 5, Android 11, no Google Play Services). Everything we install lands here.
_Avoid_: dashboard, infotainment, tablet

**Prep stage**
Work done on the Mac at home with no car involved: fetching apps and games into the project folder.
_Avoid_: download step, setup

**Install stage**
Work done while the Mac and the head unit are on the same Wi-Fi with Wireless ADB on: pushing apps and games to the head unit. Safe to repeat; anything already installed is skipped.
_Avoid_: deploy, push step

**Wireless ADB**
The head unit's hidden setting (the first button on the engineering page behind the "Factory reset" row) that lets the Mac install apps over Wi-Fi. Turned on by hand in the car, never by the script.
_Avoid_: developer mode, debug mode

**On-car installers**
App Manager and Aurora Store. Once on the head unit, they let new apps be installed and updated from the car screen with no Mac. They are the fallback if an OTA removes Wireless ADB.

**Extra apps**
Waze and Brave: apps that ship as split bundles, so plain curl can't fetch them and plain `adb install` can't install them. Fetched by fetch-extra.sh (apkeep) and installed by install-extra.sh. They were meant to come from Aurora Store on the car screen, but the AU Sealion 7 refuses every on-screen install.

**Build stage**
Optional work on the Mac that patches the real YouTube app with ReVanced Extended (RVX) so it runs without Google services and without ads (scripts/build-youtube.sh). Needs Homebrew's openjdk and apkeep. The result installs as "RVX" alongside microG.

**microG**
ReVanced's build of GmsCore: a small open-source stand-in for Google Play Services that the patched YouTube uses to sign in. User app only, no system changes.

**OTA**
A BYD over-the-air firmware update. May remove Wireless ADB; usually keeps already-installed apps.

**Driver monitoring**
The cabin-camera "keep eyes on road" attention warning (BYD: Driver Attention Warning; the quick-panel tile says DMS). Only ever switched off through the car's own controls; this project never alters it (docs/adr/0002).
_Avoid_: DMS hack, eye tracker

**Quick panel**
The swipe-down control panel on the head unit where toggles such as DMS can be pinned.
_Avoid_: notification shade, drop-down

**Stationary use**
Video and games on the head unit while parked or charging.
