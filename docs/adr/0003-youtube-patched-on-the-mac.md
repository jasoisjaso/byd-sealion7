# 0003 — YouTube is patched on the Mac, not with ReVanced Manager on the car

Date: 2026-10-05
Status: Superseded by 0004

## Context
The owner wants real YouTube (not the TV-style SmartTube) without ads, running on a head unit that has no Google Play Services. The usual way is ReVanced Manager: an app that downloads patches and rebuilds YouTube on the device itself.

Two things found on the real car (2026-10-04) rule that out:
- The Sealion 7 refuses every install started from an app on its own screen ("prohibited install from unknown source"). Aurora Store, App Manager and therefore ReVanced Manager cannot install anything. Only `adb install` from the Mac works.
- ReVanced's own patch bundles have been unreachable since a DMCA notice took the GitHub repository down in March 2026 (github.com/ReVanced/where-is-revanced-patches). The GitLab mirror publishes source only; api.revanced.app still points at the dead GitHub asset.

## Decision
- A separate, optional build step on the Mac (`scripts/build-youtube.sh`) fetches YouTube 19.47.53 from APKPure with apkeep, merges the split bundle with APKEditor, and patches it with ReVanced Extended (inotia00's RVX fork: cli 5.0.2 + patches 5.14.1, both still published on GitHub). The result is `downloads/apks/youtube.apk`, package `app.rvx.android.youtube`, app name "RVX".
- `install.sh` installs ReVanced's GmsCore (microG, `app.revanced.android.gms`) first, then the patched YouTube, and skips both if youtube.apk was never built. Nothing else in the kit depends on the build step.
- The signing key lives in `downloads/keys/youtube.keystore` and is kept out of git. Losing it means the copy on the car has to be uninstalled before a rebuilt one can go on.
- This is the only step that needs Homebrew (openjdk, apkeep). prep.sh and install.sh stay curl/unzip/bash only.
- YouTube Kids is dropped: the owner found it not worth having, and it needs Google sign-in that microG handles badly.

## Alternatives rejected
- ReVanced Manager on the car: cannot install on this firmware; no patches to download anyway.
- Official ReVanced patches via revanced-cli: not obtainable right now. Switch back when the GitHub repo is reinstated; the script's version pins are at the top of build-youtube.sh.
- Shipping a prebuilt youtube.apk in the repo: Google's code, 320 MB, and signed with one person's key. Everyone builds their own.
