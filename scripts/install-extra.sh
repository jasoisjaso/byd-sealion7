#!/bin/bash
# Installs Waze and Brave from the Mac over Wireless ADB.
# These two ship as split bundles that prep.sh can't fetch with plain curl,
# so they are fetched with apkeep (see scripts/fetch-extra.sh) and installed
# here with 'adb install-multiple'. Aurora Store on the car can't do it: the
# Sealion 7 refuses every on-screen install ("prohibited install from unknown
# source", seen on the AU car, 2026-10-04).
# Same mechanism as install.sh: adb install -r -g, user apps only.
#
# Usage:  scripts/install-extra.sh            (asks for the car's IP)
#         scripts/install-extra.sh 192.168.50.23
set -uo pipefail

KIT="$(cd "$(dirname "$0")/.." && pwd)"
ADB="$KIT/tools/platform-tools/adb"
X="$KIT/downloads/apks/extra"

[[ -x "$ADB" ]] || { echo "adb missing: run scripts/prep.sh first"; exit 1; }
[[ -d "$X/com.waze" && -s "$X/brave.apk" ]] || { echo "downloads/apks/extra is missing the apps: run scripts/fetch-extra.sh first"; exit 1; }

IP="${1:-}"
if [[ -z "$IP" ]]; then
  printf 'Car IP from Settings > Connection > Wi-Fi (e.g. 192.168.50.23): '
  read -r IP || exit 1
fi
IP="${IP//[[:space:]]/}"; IP="${IP%:5555}"
CAR="$IP:5555"

echo "Connecting to $CAR ..."
"$ADB" connect "$CAR" 2>&1 | sed 's/^/    /'
state=""
for _ in 1 2 3 4 5 6; do
  state=$("$ADB" -s "$CAR" get-state 2>/dev/null | tr -d '\r')
  [[ "$state" == "device" ]] && break
  [[ "$state" == "offline" ]] && "$ADB" disconnect "$CAR" >/dev/null 2>&1 && "$ADB" connect "$CAR" >/dev/null 2>&1
  sleep 5
done
if [[ "$state" != "device" ]]; then
  echo "Car not reachable at $CAR (state: ${state:-none})."
  echo "Check: car awake (screen on), on the home Wi-Fi, Wireless ADB on (Part A of the checklist)."
  echo "If the car shows 'Allow USB debugging?', tick Always allow, tap OK, and re-run."
  exit 1
fi
sleep 3
A=("$ADB" -s "$CAR")

FAILED=()
run_install() {  # run_install <label> <adb install subcommand...>
  local label=$1; shift
  echo "== $label"
  local out
  out=$("${A[@]}" "$@" 2>&1 | tr -d '\r')
  echo "$out" | tail -3 | sed 's/^/    /'
  case "$out" in
    *Success*) ;;
    *) FAILED+=("$label") ;;
  esac
}

# Brave: one plain APK from brave/brave-browser on GitHub.
run_install "Brave" install -r -g "$X/brave.apk"

# Waze is a split APK: base + 64-bit code + English + screen assets.
run_install "Waze" install-multiple -r -g \
  "$X/com.waze/com.waze.apk" \
  "$X/com.waze/config.arm64_v8a.apk" \
  "$X/com.waze/config.en.apk" \
  "$X/com.waze/config.xxxhdpi.apk"

echo
echo "On the car now:"
"${A[@]}" shell pm list packages 2>/dev/null | tr -d '\r' | grep -E 'com.brave.browser|com.waze' | sed 's/^package:/    /'
echo
echo "Waze: if the map stays blank, check on the car that it has Location allowed"
echo "(long-press the Waze icon > App info > Permissions) and that the car is on"
echo "Wi-Fi with internet, then force-close and reopen it. Report back what you see."

"$ADB" disconnect "$CAR" >/dev/null 2>&1
if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo "FAILED: ${FAILED[*]}"
  exit 1
fi
echo "Done."
