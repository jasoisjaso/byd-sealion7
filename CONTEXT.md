# BYD Sealion 7 — head unit customisation

Glossary for the sideload project. Terms only; no implementation detail.

**Head unit**
The car's centre-screen computer (BYD DiLink 5, Android 11, no Google Play Services). Everything we install lands here.
_Avoid_: dashboard, infotainment, tablet

**Wireless ADB**
The head unit's hidden setting (the first button on the engineering page behind the "Factory reset" row) that lets the Mac install apps over Wi-Fi. Turned on by hand in the car, never by the script.
_Avoid_: developer mode, debug mode

**OTA**
A BYD over-the-air firmware update. May remove Wireless ADB; usually keeps already-installed apps, which then stay at their last version.

**Driver monitoring**
The cabin-camera "keep eyes on road" attention warning (BYD: Driver Attention Warning; the quick-panel tile says DMS). This kit doesn't touch it; keeping it off is the separate Nag Killer app (docs/adr/0002).
_Avoid_: DMS hack, eye tracker

**Quick panel**
The swipe-down control panel on the head unit where toggles such as DMS can be pinned.
_Avoid_: notification shade, drop-down

**Stationary use**
Video on the head unit while parked or charging.

**Kit command**
The single command (./kit.sh) that installs or updates SmartTube on the head unit, fetching only what is newer. Same command for a first install and every update; Wireless ADB must be switched on in the car first.
_Avoid_: prep, install, update script
