# BYD Sealion 7 (AU, DiLink 5): sideloading research, as of 2026-10-04

Legend: **CONFIRMED** means a source says it (URL given), or I checked it live with curl/GitHub API on 2026-10-04. **UNCERTAIN** means it is inferred, comes from a different model or region, or rests on a single unverified post.

## 1. Developer mode / ADB / Android version
- **CONFIRMED**: The Sealion 7 runs DiLink 5.0 on a Snapdragon 8155 (SA8155P) with **Android 11**, according to developer bug reports. https://github.com/yash-srivastava/Overdrive-release/issues/307 and /issues/304
- **CONFIRMED**: A German reviewer sideloaded over **wireless ADB** on a Sealion 7 running **SW 3.3.0** (Sept 2026), from a MacBook. The car and the Mac were on the same Wi-Fi (an iPhone hotspot), and the car's IP came from its Wi-Fi details. ADB was enabled through a hidden menu reached from the factory-reset screen; the article says do NOT confirm the reset. They installed with the Buddy-Load app; no ADB authorisation prompt appeared for them. Single APKs only: XAPK/APKM bundles did not install. https://www.smarthomeassistent.de/apps-auf-dem-byd-sealion-7-installieren-so-gehts/ (the exact menu steps are only in screenshots/video, which I could not read.)
- **CONFIRMED**: Buddy-Load (charleschowsg) is a GUI that installs APKs over wireless ADB. It "never enables ADB on the car", so ADB must already be on. Latest release is v0.1.0 (2026-09-12), with a signed and notarised Apple Silicon DMG. https://github.com/charleschowsg/buddy-load, https://github.com/charleschowsg/buddy-load/releases/download/v0.1.0/Buddy-Load_0.1.0_aarch64.dmg. Video guides: https://www.youtube.com/@bydbuddy
- **CONFIRMED**: German Sealion 7 forum (April 2025, firmware 1.2.x): `adb connect <ip>` worked. The first `adb install` failed with "adb install be disabled"; turning the debugging toggle off and on again fixed it. Waze, Netflix and TuneIn were installed, with XAPKs going through App Manager. https://www.byd-sealion7-forum.de/forum/thread/121-sideloads/
- **CONFIRMED** (other BYD models): wireless ADB uses the legacy **tcpip port 5555** (`adb connect IP:5555`). Two routes are reported for enabling it: the Bluetooth phone dialer code `*#91532547#*` followed by an IMEI-derived password, which opens Test Tools with a "Wireless adb debug switch". https://www.reddit.com/r/BYD/comments/1tqilaz/ (Seal 06, Ireland, May 2026) and https://github.com/wheregoes/byd-dolphin-hacking/blob/master/docs/sideloading-guide.md (DiLink 3, where the car hotspot head unit is 192.168.10.10:5555)
- **UNCERTAIN**: Whether Android 11 "Wireless debugging" with `adb pair` is used. Nobody reports it. Plan for `adb connect IP:5555` plus accepting the RSA prompt if it appears.
- **UNCERTAIN**: Whether the dialer-code / IMEI route works on the **AU** Sealion 7. The guides are for other models. https://github.com/DeBondor/byd-unlocking-guide/blob/main/README_EN.md is for DiLink 13.1.33 / msm8953 cars (Han, Atto 2, Seal…), **NOT the Sealion 7**. Do not flash its firmware on a Sealion 7.
- **CONFIRMED**: The USB-stick install path for AU/EU/JP units uses a folder named `Application Installation <countryCode>` with cloud verification and no password. On DiLink 3 that route is effectively locked down. https://github.com/wheregoes/byd-apps
- USB-only ADB through a micro-USB port behind the passenger console box applies to older units (XDA, 2023). **UNCERTAIN** for the Sealion 7. https://xdaforums.com/t/byd-multimedia-install-apk.4541247/

## 2. OTA lock-downs
- **CONFIRMED** (other models): BYD has repeatedly removed easy ADB. Reports include "killed easy ADB after ~2310; on 2507 it's dead" (Seal, Feb 2026: https://www.reddit.com/r/BYD/comments/1r7edaa/), "Sideload via USB … and wireless ADB has been REMOVED" (Atto 3: https://onefiniteplanet.org/webpapers/byd-atto-3-software-and-tips/), and "disabled for a number of releases" (https://www.reddit.com/r/BYD/comments/1hdp4w1/side_loading/).
- **CONFIRMED** (other models): An unauthorised APK can get the error "This app has not passed safety checks… install from the app market". https://www.reddit.com/r/BYD/comments/1tqilaz/
- **CONFIRMED**: Owner workarounds include downgrading firmware, enabling ADB, then upgrading again, with apps reported to survive (DeBondor guide, Seal, https://www.reddit.com/r/BYD/comments/1tqilaz/). Owners also install a "PackageInstallerUnlocked" APK (https://effendy.com.au/blocking-ota-update-on-your-byd-atto3/) and block OTA. Several owners say updates have not removed their sideloaded apps (https://www.reddit.com/r/BYD/comments/1dog6cv/).
- **CONFIRMED** for the Sealion 7 specifically: sideloading still worked on SW **3.3.0** (smarthomeassistent, Sept 2026).
- **UNCERTAIN**: Whether a future AU OTA after 3.3.0 will block it. The history on other models suggests it is a real risk. Recommendation: install App Manager early as a fallback installer.

## 3. GMS / Waze / app compatibility
- **CONFIRMED**: There is no Google Play Services on BYD head units. Owners use microG or GBox (https://www.reddit.com/r/BYD/comments/1dryifw/). Waze installs without GMS but needs a non-Google login (https://www.reddit.com/r/BYD/comments/1kawg04/).
- Results on the Sealion 7 at SW 3.3.0 (**CONFIRMED**, smarthomeassistent):

  | App | Result on SW 3.3.0 |
  | --- | --- |
  | Chrome | works |
  | Waze | works; sometimes rotates the screen |
  | YouTube, YouTube Kids, YouTube Music | work |
  | Plex | works |
  | OverDrive | works (camera streams) |
  | UGREEN NAS | works |
  | Netflix | "device not supported" |
  | Disney+ | audio only, black screen |
  | Prime Video | install failed |

- **CONFIRMED** (other BYD models): App Manager, Aurora Store, Mixplorer and ReVanced+microG work. https://www.reddit.com/r/BYD/comments/19997ir/
- APK requirements (DiLink 3 notes): arm64-v8a only and single APKs, with minSdk at or below the unit's Android version. https://github.com/wheregoes/byd-dolphin-hacking/blob/master/docs/sideloading-guide.md. **UNCERTAIN** for DiLink 5 (Android 11, so minSdk ≤ 30).
- **UNCERTAIN / not verified for the Sealion 7**: SmartTube, Brave, RetroArch, Spotify, ABRP and Car Scanner on the head unit. No Sealion 7 owner reports were found. DRM video apps (Netflix, Disney+) tend to fail.
- **UNCERTAIN**: Whether third-party apps are blocked while driving. The reasons given for BYD's lock-downs centre on video and games while driving (r/BYD 1hdp4w1), but I found no Sealion 7 report of a speed lock-out for sideloaded apps.

## 4. Driver monitoring (DMS), facts only
- **CONFIRMED**: An AU owner on Whirlpool turns off ELKA, LKA, AEB, driver monitoring and child monitoring **every drive** ("5 toggles across 3 menus"). That means DMS does not stay off. https://forums.whirlpool.net.au/archive/3vw46lj5-4
- **CONFIRMED**: AU owners put the toggles on a shortcut. LKA takes one tap; driver monitoring takes 2–3. https://www.reddit.com/r/BYD/comments/1jp7z47/
- **CONFIRMED**: OTA 3.0.0 made **child presence detection** stay off after a restart. That applies to CPD, not DMS. https://forums.whirlpool.net.au/thread/3vw46lj5?p=141, https://www.reddit.com/r/BYD/comments/1nm0h7y/ota_300_news/
- **CONFIRMED**: The UK-market setting sits under "Cabin perception". https://www.carwow.co.uk/byd/sealion-7
- **CONFIRMED**: Some owners physically cover the DMS camera, for example with 3D-printed covers (r/BYD 1mky4bd). Owners report that this does not stop child-presence alerts (https://www.reddit.com/r/AustralianEV/comments/1tygg4a/).
- **UNCERTAIN / not found**: Any OTA (3.1.0 started rolling out in AU on 23 June 2026, per https://sealion7.wordpress.com/; 3.2.0 and 3.3.0 also exist) that remembers DMS-off. No source confirmed this. The persistent resetting is generally attributed to ANCAP/Euro NCAP rules that require these systems to default on. That attribution is **UNCERTAIN**; I fetched no primary ANCAP document.
- Risks: these are safety systems. Disabling or obstructing them may affect insurance, warranty or liability after a crash. **UNCERTAIN**: there are no specific legal sources. The official manual is https://bydautomotive.com.au/brochures/BYD-SEALION-7-Owners-Handbook-2025.pdf

## 5. Extra car stats
- **CONFIRMED**: Car Scanner ELM OBD2 has a BYD profile that includes the "Sealion 7 EV (EU version)". https://www.carscanner.info/profile-database-changelog/. Videos show Sealion 7 AWD SoH and cell voltages: https://www.youtube.com/watch?v=a4fTn_g1VCY, https://www.youtube.com/watch?v=11D3oWyEXAo. Whether it works on AU cars is **UNCERTAIN**.
- **CONFIRMED**: Sealion 7 Pilot is a sideloaded head-unit app showing SoC, range, consumption, tyre pressures, HV voltage/current, motor temperature and battery health, plus EV route planning and cluster navigation. It gives a free 3-month licence, then needs a paid licence (no price announced). https://sealion7pilot.bydlab.dev/
- **CONFIRMED**: Overdrive is a dashcam/sentry/camera app that people run on the Sealion 7, with open DiLink 5 bugs. https://github.com/yash-srivastava/Overdrive-release/issues/304
- **CONFIRMED**: Overdrive's README, "Initial Configuration": "CRITICAL: Hard Reboot Required. After the first installation and initial run, you must hard reboot the device: Press and hold the Volume Down button for 5 seconds. Wait for the system to fully restart." (Repeated in the v20.0 release note.) https://github.com/yash-srivastava/Overdrive-release#quick-start-use-pre-built-apk. The README says the app is built for "DiLink v3"; DiLink 5 support rests on the issue tracker above.
- **CONFIRMED**: Electro (https://electro.app.br/) gives telemetry and battery stats on BYD units. It is popular in Brazil; DiLink 5 support is **UNCERTAIN**. BYDMate: https://nevpedia.com/en/byd/all-models/bydmate-what-it-is-and-how-to-install. BladeWatch is a sentry/dashcam app: https://loable.tech/bladewatch-byd-dashcam-sentry/. DashCast mirrors an app to the instrument cluster: https://github.com/Kiroha/byd-dashcast
- **CONFIRMED**: wheregoes/byd-apps is **incompatible with DiLink 5** (issue #3).

## 6. Download URLs (checked live 2026-10-04, all HTTP 200)

| Item | Current version | Stable "latest" URL |
| --- | --- | --- |
| platform-tools (mac) | rolling | `https://dl.google.com/android/repository/platform-tools-latest-darwin.zip` |
| SmartTube | 32.56s (2026-09-23) | `https://github.com/yuliskov/SmartTube/releases/download/32.56s/SmartTube_stable_32.56_arm64-v8a.apk` |
| Brave Android | v1.96.61 (2026-10-02) | `https://github.com/brave/brave-browser/releases/latest/download/BraveMonoarm64.apk` |
| App Manager | v4.1.1 (2026-09-04) | `https://github.com/MuntashirAkon/AppManager/releases/download/v4.1.1/AppManager_v4.1.1.apk` |
| Aurora Store (F-Droid) | 4.8.4 (versionCode 76) | `https://f-droid.org/repo/com.aurora.store_76.apk` |
| RetroArch | 1.22.2 | `https://buildbot.libretro.com/stable/1.22.2/android/RetroArch_aarch64.apk` |

Notes on the "latest" patterns:
- **SmartTube**: the filename contains the version, so `/latest/download/<name>` only works if you already know the name. Resolve it with the API (`api.github.com/repos/yuliskov/SmartTube/releases/latest`) and pick the asset matching `arm64-v8a`.
- **Brave**: the filename has no version, so the `/latest/download/BraveMonoarm64.apk` URL above is stable. `Bravearm64Universal.apk` is also available. Watch out: the brave-browser "latest" release is sometimes desktop-only, so fall back to the API.
- **App Manager**: the filename contains the version. Use the API.
- **Aurora Store**: `com.aurora.store_latest.apk` returns **404**. Get `suggestedVersionCode` from `https://f-droid.org/api/v1/packages/com.aurora.store` and build `com.aurora.store_<code>.apk`. GitLab releases are at https://gitlab.com/AuroraOSS/AuroraStore/-/releases.
- **RetroArch**: there is no "latest" alias. Scrape the highest `/stable/X.Y.Z/` from https://buildbot.libretro.com/stable/ (version sort).
- **Buddy-Load**: `https://github.com/charleschowsg/buddy-load/releases/download/v0.1.0/Buddy-Load_0.1.0_aarch64.dmg`

## 7. Free/legal homebrew for a 4-year-old
All URLs returned 200 and are real ROM files (sizes checked). How much text each game needs is my judgement (**UNCERTAIN**).

| Game | System | Why it suits | Direct URL |
| --- | --- | --- | --- |
| Libbet and the Magic Floor | GB | Roll a ball to flip floor tiles; no reading needed | `https://github.com/pinobatch/libbet/releases/download/v0.08/libbet.gb` (32 KB) |
| Concentration Room | NES | Memory card matching with pictures | `https://github.com/pinobatch/croom-nes/releases/download/v0.02a/croom.nes` |
| Thwaite | NES | Missile Command-style; a bit harder, some text in the intro | `https://github.com/pinobatch/thwaite-nes/releases/download/v0.04/thwaite.nes` |
| Flappy flappy | GB | One-button flapping; GB Studio game | `https://hh3.gbdev.io/static/database-gb/entries/flappy-flappy/flappy_flappy.gb` (https://hh.gbdev.io/game/flappy-flappy/) |
| Tobu Tobu Girl / Deluxe | GB / GBC | Jump-upward arcade; free, but no direct URL | https://tangramgames.itch.io/tobu-tobu-girl, https://tangramgames.itch.io/tobu-tobu-girl-deluxe (itch.io download flow, no stable direct link) |
| Spong | GBC | Pong-style game; listed on Homebrew Hub | https://hh.gbdev.io/game/spong/ (file `Spong.cgb`; **UNCERTAIN**, not opened) |

Homebrew Hub search API: `https://hh3.gbdev.io/api/search?...`

## 8. On-car setup steps quoted in the checklist (Part C)
- **CONFIRMED** (libretro docs, read 2026-10-04): cores are installed from "Online Updater" > "Core Downloader" (https://docs.libretro.com/guides/download-cores/). Scanning: "The 'Import Content' menu can be either in the 'Playlists' > 'Import Content' (default), or directly accessible from the Main Menu." and "The default, fully automatic option for scanning is strict (requires the CRC checksum or disc serial of the content to match the database)." (https://docs.libretro.com/guides/import-content/). Homebrew is not in the database, so the checklist uses "Manual Scan" (system name + file extension + default core), which adds every file with the extension. Core names "Nintendo - Game Boy / Color (Gambatte)" and "Nintendo - NES / Famicom (FCEUmm)" are the Core Downloader labels in RetroArch 1.22. **UNCERTAIN**: not yet tried on the car; the Android build's menu layout (Ozone) may put "Import Content" under "Playlists".
- **CONFIRMED**: SmartTube signs in with a code: the app shows a code and a URL (youtube.com/activate style) to open on a phone or computer. https://github.com/yuliskov/SmartTube#faq (section "How to sign in"). **UNCERTAIN** on the car's screen specifically.
