#!/bin/bash
# Build stage (optional): makes downloads/apks/youtube.apk, the real YouTube app
# patched with ReVanced Extended (RVX) so it runs on the car without Google
# Play Services, without ads, with SponsorBlock and background play.
# Runs at home on the Mac, no car needed. Takes 20-30 minutes, nearly all of
# it the patch step. install.sh then puts the result on the car.
#
# Why this runs on the Mac and not ReVanced Manager on the car: the Sealion 7
# refuses every install started from an app on its own screen ("prohibited
# install from unknown source", seen 2026-10-04). Only adb from the Mac can
# install anything, so the patching has to happen here (docs/adr/0003).
#
# This is the one step in the kit that needs tools from Homebrew:
#     brew install openjdk apkeep
# Re-run any time: downloads are kept; pass --rebuild to patch again.
#
# The same signing key is kept in downloads/keys/youtube.keystore. Keep it:
# a rebuild with a different key can't update the copy already on the car
# (INSTALL_FAILED_UPDATE_INCOMPATIBLE) without uninstalling it first.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"
APKS="$ROOT/downloads/apks"
BUILD="$ROOT/downloads/build/youtube"
KEYS="$ROOT/downloads/keys"

# Versions. The patches declare which YouTube versions they support; pick one
# from this list when bumping RVX_PATCHES:
#   java -jar downloads/build/youtube/rvx-cli.jar list-versions \
#        -p downloads/build/youtube/rvx-patches.rvp -f com.google.android.youtube
# RVX (inotia00's fork) is used rather than ReVanced's own patches because the
# official patches repository has been unavailable since a DMCA notice in
# March 2026 (github.com/ReVanced/where-is-revanced-patches) and the GitLab
# mirror publishes source only, no patch bundles.
YOUTUBE_VERSION=19.47.53
RVX_CLI=5.0.2
RVX_PATCHES=5.14.1
APKEDITOR=1.4.9

REBUILD=0
for arg in "$@"; do
  case "$arg" in
    --rebuild) REBUILD=1 ;;
    *) echo "Unknown option: $arg (the only option is --rebuild)"; exit 2 ;;
  esac
done

heading() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
ok()      { printf '    OK  %s\n' "$*"; }
fail()    { printf '\n    FAILED: %s\n' "$*" >&2; exit 1; }

fetch() {  # fetch URL OUTFILE: download unless already there
  local url="$1" out="$2"
  if [[ -s "$out" ]]; then ok "$(basename "$out") (already downloaded)"; return; fi
  echo "    downloading $url"
  curl -fL --retry 3 --progress-bar -o "$out.part" "$url" || fail "could not download $url"
  mv "$out.part" "$out"
  ok "$(basename "$out")"
}

mkdir -p "$APKS" "$BUILD" "$KEYS"

# 1. Tools
heading "Checking tools"
JAVA=""
for j in /opt/homebrew/opt/openjdk/bin/java /usr/local/opt/openjdk/bin/java; do
  [[ -x "$j" ]] && { JAVA="$j"; break; }
done
if [[ -z "$JAVA" ]] && command -v java >/dev/null 2>&1 && java -version >/dev/null 2>&1; then
  JAVA="$(command -v java)"
fi
[[ -n "$JAVA" ]] || fail "Java not found. Run:  brew install openjdk   (then re-run this script)"
ok "java: $("$JAVA" -version 2>&1 | head -1)"
command -v apkeep >/dev/null 2>&1 || fail "apkeep not found. Run:  brew install apkeep   (then re-run this script)"
ok "apkeep: $(apkeep --version 2>/dev/null | head -1)"

fetch "https://github.com/inotia00/revanced-cli/releases/download/v${RVX_CLI}/revanced-cli-${RVX_CLI}-all.jar" "$BUILD/rvx-cli.jar"
fetch "https://github.com/inotia00/revanced-patches/releases/download/v${RVX_PATCHES}/patches-${RVX_PATCHES}.rvp" "$BUILD/rvx-patches.rvp"
fetch "https://github.com/REAndroid/APKEditor/releases/download/V${APKEDITOR}/APKEditor-${APKEDITOR}.jar" "$BUILD/APKEditor.jar"

# 2. The unmodified YouTube app (a split bundle from APKPure, 64-bit only)
heading "YouTube $YOUTUBE_VERSION (original app)"
XAPK="$BUILD/com.google.android.youtube@${YOUTUBE_VERSION}@arm64-v8a.xapk"
if [[ -s "$XAPK" ]]; then
  ok "$(basename "$XAPK") (already downloaded)"
else
  apkeep -a "com.google.android.youtube@${YOUTUBE_VERSION}" -d apk-pure \
    -o 'acknowledge_dangers=true,arch=arm64-v8a' "$BUILD" \
    || fail "apkeep could not download YouTube $YOUTUBE_VERSION from APKPure"
  [[ -s "$XAPK" ]] || fail "apkeep finished but $XAPK is missing"
  ok "$(basename "$XAPK")"
fi

# 3. Merge the bundle into one APK (adb can't install bundles; the patcher wants one file)
heading "Merging the bundle into one APK"
MERGED="$BUILD/youtube-${YOUTUBE_VERSION}-merged.apk"
if [[ -s "$MERGED" && $REBUILD -eq 0 ]]; then
  ok "$(basename "$MERGED") (already merged)"
else
  rm -f "$MERGED"
  "$JAVA" -jar "$BUILD/APKEditor.jar" m -i "$XAPK" -o "$MERGED" 2>&1 | sed 's/^/    /' | tail -3
  [[ -s "$MERGED" ]] || fail "APKEditor did not produce $MERGED"
  ok "$(basename "$MERGED")"
fi

# 4. Patch
heading "Patching with RVX $RVX_PATCHES (20-30 minutes; the Mac's fan will run)"
OUT="$APKS/youtube.apk"
if [[ -s "$OUT" && $REBUILD -eq 0 ]]; then
  ok "youtube.apk already built (use --rebuild to patch again)"
else
  [[ -s "$KEYS/youtube.keystore" ]] || echo "    first build: a new signing key will be created at downloads/keys/youtube.keystore"
  rm -rf "$BUILD/tmp"
  "$JAVA" -jar "$BUILD/rvx-cli.jar" patch \
    -p "$BUILD/rvx-patches.rvp" \
    --keystore "$KEYS/youtube.keystore" \
    -t "$BUILD/tmp" --purge \
    -o "$OUT.part" "$MERGED" 2>&1 | grep -vE '^\s*$' | sed 's/^/    /' | tail -15
  [[ -s "$OUT.part" ]] || fail "the patcher did not produce an APK (scroll up for its last messages)"
  mv "$OUT.part" "$OUT"
  listing=$(unzip -l "$OUT" 2>/dev/null) || listing=""
  [[ "$listing" == *AndroidManifest.xml* ]] || { rm -f "$OUT"; fail "youtube.apk is not a valid APK (deleted; re-run with --rebuild)"; }
  ok "youtube.apk ($(du -h "$OUT" | awk '{print $1}')B)"
fi

heading "Build done"
echo "    downloads/apks/youtube.apk installs as the app \"RVX\" (package app.rvx.android.youtube)."
echo "    It needs microG (gmscore.apk, fetched by prep.sh) on the car; install.sh puts both on."
echo "    Next: scripts/prep.sh if you haven't, then in the car: scripts/install.sh"
