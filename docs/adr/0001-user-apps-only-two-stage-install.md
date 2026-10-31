# 0001 — User apps only, two-stage install, on-car installers first

Date: 2026-10-04
Status: Accepted (the on-car installers part is superseded by 0004)

## Context
The Sealion 7 head unit runs Android 11 with no Google Play Services. Wireless ADB is reachable through a hidden menu, but BYD has removed easy ADB access on other models (Seal, Atto 3) in OTA updates. Installed apps usually survive OTAs. The owner wants a Tesla-like mix of apps without risking the warranty.

## Decision
- Install normal user apps only. No root, no replacing or disabling system packages, no changing system settings over ADB.
- Per-app grants are fine: `adb install -g` (runtime permissions for the app being installed) and `appops set <pkg> REQUEST_INSTALL_PACKAGES allow` for App Manager and Aurora Store only. They touch nothing outside the apps we install and are what Android's own "Install unknown apps" page would do if the head unit exposed it.
- Split the script into a Prep stage (Mac only, at home) and a repeatable Install stage (in the car) that skips anything already installed.
- Install App Manager and Aurora Store first in the Install stage, so that if a later OTA removes Wireless ADB, apps can still be installed and updated from the car screen.

## Alternatives rejected
- Rooting or system-level tweaks: more control, but risks warranty, safety systems and bricking.
- One-shot script: simpler, but has to re-download everything and fails partway through if the car isn't reachable.
