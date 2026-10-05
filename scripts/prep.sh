#!/bin/bash
# Prep stage: run at home on the Mac. No car needed.
# Downloads adb, the scripted apps and the kids' games into this project folder.
# Re-run any time; existing files are kept unless you pass --refresh.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"
TOOLS="$ROOT/tools"
APKS="$ROOT/downloads/apks"
ROMS="$ROOT/downloads/ROMs"

REFRESH=0
for arg in "$@"; do   # check every word, so a typo after --refresh is caught too
  case "$arg" in
    --refresh) REFRESH=1 ;;
    *) echo "Unknown option: $arg (the only option is --refresh)"; exit 2 ;;
  esac
done

mkdir -p "$TOOLS" "$APKS" "$ROMS"

heading() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
ok()      { printf '    OK  %s\n' "$*"; }
fail()    { printf '\n    FAILED: %s\n' "$*" >&2; exit 1; }
# GitHub allows 60 anonymous lookups an hour per network; say so when one fails.
GH_HINT="(check the internet connection; if it was fine, GitHub may be rate-limiting you: wait an hour)"

# fetch URL OUTFILE: download unless the file is already there.
fetch() {
  local url="$1" out="$2"
  if [[ -s "$out" && $REFRESH -eq 0 ]]; then
    ok "$(basename "$out") (already downloaded)"
    return
  fi
  echo "    downloading $url"
  curl -fL --retry 3 --progress-bar -o "$out.part" "$url" || fail "could not download $url"
  mv "$out.part" "$out"
  ok "$(basename "$out")"
}

# gh_asset REPO REGEX [API_PATH]: first release asset URL matching REGEX.
gh_asset() {
  local repo="$1" pattern="$2" path="${3:-releases?per_page=10}"
  curl -fsSL "https://api.github.com/repos/$repo/$path" \
    | grep -o '"browser_download_url": *"[^"]*"' \
    | sed 's/.*"\(https[^"]*\)"$/\1/' \
    | grep -E "$pattern" | awk 'NR==1' || true   # awk reads all input: no SIGPIPE
}

# check_apk FILE: a real APK is a zip that contains AndroidManifest.xml.
check_apk() {
  # Capture first: piping into grep -q trips SIGPIPE under pipefail.
  local listing
  listing=$(unzip -l "$1" 2>/dev/null) || listing=""
  [[ "$listing" == *AndroidManifest.xml* ]] \
    || { rm -f "$1"; fail "$(basename "$1") is not a valid APK (deleted, re-run to retry)"; }
}

# 1. adb (Google platform-tools for macOS)
heading "adb (Android platform-tools)"
if [[ -x "$TOOLS/platform-tools/adb" && $REFRESH -eq 0 ]]; then
  ok "adb already installed"
else
  fetch "https://dl.google.com/android/repository/platform-tools-latest-darwin.zip" "$TOOLS/platform-tools.zip"
  rm -rf "$TOOLS/platform-tools"
  unzip -q "$TOOLS/platform-tools.zip" -d "$TOOLS"
  rm -f "$TOOLS/platform-tools.zip"
fi
"$TOOLS/platform-tools/adb" version | sed -n '1s/^/    /p' \
  || fail "adb was downloaded but won't run on this Mac (try: scripts/prep.sh --refresh)"

# 2. Apps installed by install.sh (Waze and Brave: scripts/fetch-extra.sh; YouTube: scripts/build-youtube.sh)
heading "App Manager (on-car installer)"
url=$(gh_asset MuntashirAkon/AppManager 'AppManager_v[0-9.]+\.apk$' releases/latest)
[[ -n "$url" ]] || fail "no App Manager APK found on GitHub $GH_HINT"
fetch "$url" "$APKS/manager.apk"; check_apk "$APKS/manager.apk"

heading "Aurora Store (on-car app store)"
code=$(curl -fsSL https://f-droid.org/api/v1/packages/com.aurora.store \
  | grep -o '"suggestedVersionCode":[0-9]*' | grep -o '[0-9]*$' || true)   # || true: let fail() explain instead of set -e
[[ -n "$code" ]] || fail "could not read Aurora Store version from F-Droid"
fetch "https://f-droid.org/repo/com.aurora.store_${code}.apk" "$APKS/store.apk"; check_apk "$APKS/store.apk"

heading "SmartTube (ad-free YouTube)"
url=$(gh_asset yuliskov/SmartTube 'SmartTube_stable_[0-9.]+_arm64-v8a\.apk$')
[[ -n "$url" ]] || fail "no SmartTube stable arm64 APK found on GitHub $GH_HINT"
fetch "$url" "$APKS/tube.apk"; check_apk "$APKS/tube.apk"

heading "RetroArch (game emulator)"
ra_url=""
for v in $(curl -fsSL https://buildbot.libretro.com/stable/ \
            | grep -o 'href="/stable/[0-9][0-9.]*/' | grep -o '[0-9][0-9.]*[0-9]' \
            | sort -u -t. -k1,1nr -k2,2nr -k3,3nr); do
  candidate="https://buildbot.libretro.com/stable/$v/android/RetroArch_aarch64.apk"
  if curl -fsIL -o /dev/null "$candidate"; then ra_url="$candidate"; break; fi
done
[[ -n "$ra_url" ]] || fail "no RetroArch Android build found on buildbot.libretro.com"
fetch "$ra_url" "$APKS/retroarch.apk"; check_apk "$APKS/retroarch.apk"

heading "microG (ReVanced GmsCore: lets the patched YouTube sign in without Google services)"
# The "-signed.apk" without "-hw-" is the normal build; "-hw-signed" is for Huawei.
url=$(gh_asset ReVanced/GmsCore 'app\.revanced\.android\.gms-[0-9]+-signed\.apk$' releases/latest)
[[ -n "$url" ]] || fail "no GmsCore APK found on GitHub $GH_HINT"
fetch "$url" "$APKS/gmscore.apk"; check_apk "$APKS/gmscore.apk"

heading "Jellyfin (plays video from your own media server)"
url=$(gh_asset jellyfin/jellyfin-android 'jellyfin-android-v[0-9.]+-libre-release\.apk$' releases/latest)
[[ -n "$url" ]] || fail "no Jellyfin APK found on GitHub $GH_HINT"
fetch "$url" "$APKS/jellyfin.apk"; check_apk "$APKS/jellyfin.apk"

heading "Overdrive (optional dashcam/sentry, alpha)"
url=$(gh_asset yash-srivastava/Overdrive-release 'overdrive-release-alpha-.*\.apk$')
[[ -n "$url" ]] || fail "no Overdrive APK found on GitHub $GH_HINT"
fetch "$url" "$APKS/overdrive.apk"; check_apk "$APKS/overdrive.apk"

heading "YouTube (ReVanced build)"
if [[ -s "$APKS/youtube.apk" ]]; then
  ok "youtube.apk (already built)"
else
  echo "    not built yet. It is made on this Mac by:  scripts/build-youtube.sh"
  echo "    (optional; needs 'brew install openjdk apkeep' and 20-30 minutes). install.sh skips it if absent."
fi

# 3. Kids' games: free homebrew, picture-only
heading "Games for the ROMs folder"
fetch "https://github.com/pinobatch/libbet/releases/download/v0.08/libbet.gb" "$ROMS/libbet.gb"
fetch "https://github.com/pinobatch/croom-nes/releases/download/v0.02a/croom.nes" "$ROMS/croom.nes"
fetch "https://hh3.gbdev.io/static/database-gb/entries/flappy-flappy/flappy_flappy.gb" "$ROMS/flappy_flappy.gb"

heading "Prep done"
# shellcheck disable=SC2012  # our own filenames, ls is fine
ls -lh "$APKS" "$ROMS" | sed 's/^/    /'
echo
echo "    Next: in the car, follow docs/in-car-checklist.md, then run scripts/install.sh"
