#!/bin/bash
# Fetches Waze and Brave into downloads/apks/extra/ for scripts/install-extra.sh.
# Runs at home on the Mac, no car needed.
#
# Why a separate script: Waze only ships as a split bundle (.xapk), which plain
# curl can't get and plain 'adb install' can't install. apkeep (from Homebrew)
# fetches it from APKPure; install-extra.sh then uses 'adb install-multiple'.
# Brave is a plain APK from Brave's own GitHub releases.
#
# Needs:  brew install apkeep
# Re-run any time: existing files are kept; pass --refresh to refetch.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"
X="$ROOT/downloads/apks/extra"

REFRESH=0
for arg in "$@"; do
  case "$arg" in
    --refresh) REFRESH=1 ;;
    *) echo "Unknown option: $arg (the only option is --refresh)"; exit 2 ;;
  esac
done

heading() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
ok()      { printf '    OK  %s\n' "$*"; }
fail()    { printf '\n    FAILED: %s\n' "$*" >&2; exit 1; }
GH_HINT="(check the internet connection; if it was fine, GitHub may be rate-limiting you: wait an hour)"

mkdir -p "$X"
command -v apkeep >/dev/null 2>&1 || fail "apkeep not found. Run:  brew install apkeep   (then re-run this script)"

# 1. Brave: the arm64 APK from the latest brave-browser release.
heading "Brave"
if [[ -s "$X/brave.apk" && $REFRESH -eq 0 ]]; then
  ok "brave.apk (already downloaded)"
else
  url=$(curl -fsSL https://api.github.com/repos/brave/brave-browser/releases/latest \
    | grep -o '"browser_download_url": *"[^"]*"' | sed 's/.*"\(https[^"]*\)"$/\1/' \
    | grep -E 'arm64.*\.apk$' | awk 'NR==1' || true)
  [[ -n "$url" ]] || fail "no Brave arm64 APK found on GitHub $GH_HINT"
  echo "    downloading $url"
  curl -fL --retry 3 --progress-bar -o "$X/brave.apk.part" "$url" || fail "could not download $url"
  mv "$X/brave.apk.part" "$X/brave.apk"
  ok "brave.apk"
fi

# 2. Waze: split bundle from APKPure via apkeep, unpacked into com.waze/.
heading "Waze"
if [[ -s "$X/com.waze/com.waze.apk" && $REFRESH -eq 0 ]]; then
  ok "com.waze/ (already downloaded)"
else
  rm -rf "$X/com.waze"
  rm -f "$X"/com.waze@*.xapk
  apkeep -a com.waze -d apk-pure -o 'acknowledge_dangers=true,arch=arm64-v8a' "$X" \
    || fail "apkeep could not download Waze from APKPure"
  xapk=$(find "$X" -maxdepth 1 -name 'com.waze@*.xapk' | awk 'NR==1' || true)
  [[ -n "$xapk" ]] || fail "apkeep finished but no com.waze .xapk is in downloads/apks/extra"
  mkdir -p "$X/com.waze"
  unzip -q -o "$xapk" -d "$X/com.waze" || fail "could not unpack $(basename "$xapk")"
  rm -f "$xapk"
  for part in com.waze.apk config.arm64_v8a.apk config.en.apk config.xxxhdpi.apk; do
    [[ -s "$X/com.waze/$part" ]] || fail "Waze bundle is missing $part (APKPure changed its packaging; re-run with --refresh)"
  done
  ok "com.waze/ ($(find "$X/com.waze" -type f | wc -l | tr -d ' ') files)"
fi

heading "Done"
# shellcheck disable=SC2012  # our own filenames, ls is fine
ls -lh "$X" | sed 's/^/    /'
echo
echo "    Next, in the car with Wireless ADB on:  scripts/install-extra.sh"
