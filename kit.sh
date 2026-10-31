#!/bin/bash
# The kit command: installs or updates SmartTube on a BYD Sealion 7
# (DiLink 5) head unit. Same command for the first install and every
# update. Run it on the Mac while the car is on the same Wi-Fi and Wireless ADB
# is switched on in the car (docs/in-car-checklist.md, Part A).
#
#   ./kit.sh             download anything newer, then install what changed
#   ./kit.sh --download  only download (no car needed)
#
# What it does, in order:
#   1. downloads adb and the newest SmartTube (stable) into downloads/ - only
#      if there is something newer
#   2. connects to the car (remembers its IP for next time)
#   3. offers to remove apps from older versions of this kit
#   4. installs SmartTube only if the car's copy is older (keeps app data)
# Overdrive and Brave are left alone if they're on the car (docs/adr/0005).
set -uo pipefail

cd "$(dirname "$0")" || exit 1
ROOT="$PWD"
TOOLS="$ROOT/tools"
APKS="$ROOT/downloads/apks"
ADB="$TOOLS/platform-tools/adb"
IP_FILE="$ROOT/downloads/car-ip"
PROBE_SECS=30  # how long to keep checking that something answers at the IP
WAIT_SECS=90   # how long to wait for the car to accept the connection

DOWNLOAD_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --download) DOWNLOAD_ONLY=1 ;;
    -h|--help) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg (the only option is --download)"; exit 2 ;;
  esac
done

heading() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
note()    { printf '    %s\n' "$*"; }
die()     { printf '\n    FAILED: %s\n' "$*" >&2; exit 1; }
GH_HINT="(check the internet connection; if it was fine, GitHub may be rate-limiting you: wait an hour)"

mkdir -p "$TOOLS" "$APKS"

# ---------------------------------------------------------------- 1. download
# gh_asset REPO REGEX API_PATH: first release asset URL whose FILE NAME matches REGEX.
gh_asset() {
  local u first=""
  while read -r u; do
    [[ -z "$first" && "${u##*/}" =~ $2 ]] && first="$u"   # no early break: never SIGPIPE curl
  done < <(curl -fsSL "https://api.github.com/repos/$1/$3" 2>/dev/null \
             | grep -o '"browser_download_url": *"[^"]*"' | sed 's/.*"\(https[^"]*\)"$/\1/')
  echo "$first"
}

# is_apk FILE: a real APK is a zip that contains AndroidManifest.xml.
is_apk() {
  local listing
  listing=$(unzip -l "$1" 2>/dev/null) || return 1   # captured: grep -q in a pipe trips pipefail
  [[ "$listing" == *AndroidManifest.xml* ]]
}

# fetch_app NAME REPO REGEX API_PATH: keep the newest release APK under its
# upstream file name (the name carries the version); drop older copies.
fetch_app() {
  local name="$1" repo="$2" regex="$3" path="$4" url file
  heading "$name"
  url=$(gh_asset "$repo" "$regex" "$path")
  if [[ -z "$url" ]]; then
    if newest_file "$regex" >/dev/null; then
      note "Couldn't check GitHub for a newer version $GH_HINT"
      note "Carrying on with $(basename "$(newest_file "$regex")")."; return
    fi
    die "no $name download found on GitHub $GH_HINT"
  fi
  file="$APKS/$(basename "$url")"
  if [[ -s "$file" ]] && is_apk "$file"; then
    note "$(basename "$file") is the newest, already downloaded."; return
  fi
  note "Downloading $(basename "$file")"
  curl -fL --retry 3 --progress-bar -o "$file.part" "$url" || die "could not download $url"
  mv "$file.part" "$file"
  is_apk "$file" || { rm -f "$file"; die "$(basename "$file") is not a valid APK (deleted; re-run to retry)"; }
  local old
  for old in "$APKS"/*.apk; do
    [[ "$old" != "$file" && "$(basename "$old")" =~ $regex ]] && rm -f "$old"
  done
  note "Downloaded."
}

# newest_file REGEX: the downloaded APK whose name matches REGEX (one per app).
newest_file() {
  local f
  for f in "$APKS"/*.apk; do
    [[ -s "$f" && "$(basename "$f")" =~ $1 ]] && { echo "$f"; return 0; }
  done
  return 1
}

# Version in a file name: SmartTube_stable_32.56_arm64-v8a.apk -> 32.56.
# Matches the app's versionName.
file_version() { basename "$1" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | awk 'NR==1'; }

ST_RE='^SmartTube_stable_[0-9.]+_arm64-v8a\.apk$'

heading "adb (Android platform-tools)"
if [[ -x "$ADB" ]]; then
  note "Already downloaded."
else
  curl -fL --retry 3 --progress-bar -o "$TOOLS/platform-tools.zip" \
    https://dl.google.com/android/repository/platform-tools-latest-darwin.zip || die "could not download adb"
  rm -rf "$TOOLS/platform-tools"
  unzip -q "$TOOLS/platform-tools.zip" -d "$TOOLS" && rm -f "$TOOLS/platform-tools.zip"
fi
"$ADB" version >/dev/null 2>&1 || die "adb won't run on this Mac (delete the tools folder and re-run)"

if [[ "${KIT_OFFLINE:-0}" == 1 ]]; then   # tests: use what's already in downloads/
  heading "Offline: using the APKs already in downloads/apks"
else
  fetch_app "SmartTube (YouTube without ads)" yuliskov/SmartTube "$ST_RE" 'releases?per_page=10'
fi
ST_APK=$(newest_file "$ST_RE") || die "no SmartTube APK in downloads/apks"

if [[ $DOWNLOAD_ONLY -eq 1 ]]; then
  heading "Downloads ready"
  note "SmartTube $(file_version "$ST_APK")"
  note "Next, in the car: switch on Wireless ADB, then run ./kit.sh"
  exit 0
fi

# ---------------------------------------------------------------- 2. connect
"$ADB" start-server >/dev/null 2>&1

heading "Car IP address"
SAVED_IP=""; [[ -s "$IP_FILE" ]] && SAVED_IP=$(tr -d '[:space:]' < "$IP_FILE")
if [[ -z "$SAVED_IP" ]]; then
  note "On the car screen: Settings > Connection > Wi-Fi > tap your home network."
  note "The address looks like 192.168.x.x. Your router's app also lists the car."
fi
while true; do
  prompt="    Car IP address: "; [[ -n "$SAVED_IP" ]] && prompt="    Car IP address [Enter = $SAVED_IP]: "
  if ! read -r -p "$prompt" IP; then echo; note "No address entered. Nothing was changed on the car."; exit 1; fi
  IP="${IP//[[:space:]]/}"; IP="${IP%:5555}"; [[ -z "$IP" ]] && IP="$SAVED_IP"
  if [[ "$IP" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
    valid=1; IFS=. read -r o1 o2 o3 o4 <<<"$IP"
    for o in "$o1" "$o2" "$o3" "$o4"; do [[ $((10#$o)) -le 255 ]] || valid=0; done
    [[ $valid -eq 1 ]] && break
  fi
  note "That doesn't look like an IP address (example: 192.168.1.37). Try again."
done
CAR="$IP:5555"

# With a wrong IP every 'adb connect' hangs 75 s; nc answers in 3.
heading "Looking for the car at $IP"
note "If macOS asks whether Terminal may find devices on your local network, click Allow."
reachable=0; probe=""; SECONDS=0
while (( SECONDS < PROBE_SECS )); do
  if probe=$(/usr/bin/nc -z -v -G 3 "$IP" 5555 2>&1); then reachable=1; break; fi
  sleep 1
done
if [[ $reachable -eq 0 ]]; then
  echo
  if [[ "$probe" == *refused* ]]; then
    note "Something at $IP answered, but Wireless ADB isn't listening there."
    note "It switches itself off whenever the car has been parked: switch it on again"
    note "(checklist Part A), or $IP is another device."
  else
    note "No answer from $IP after $PROBE_SECS seconds."
    note "Check: right IP, car screen awake, Mac and car on the same Wi-Fi (not a guest network),"
    note "and System Settings > Privacy & Security > Local Network allows Terminal."
  fi
  note "Nothing was changed on the car."; exit 1
fi
echo "$IP" > "$IP_FILE"
note "Found it."

heading "Connecting to $CAR"
note "LOOK AT THE CAR SCREEN: if \"Allow USB debugging?\" appears, tick"
note "\"Always allow from this computer\" and tap OK. \"failed to authenticate\" is normal until then."
"$ADB" connect "$CAR" 2>&1 | sed 's/^/    /'
state=""; SECONDS=0
while (( SECONDS < WAIT_SECS )); do
  state=$("$ADB" devices | awk -v s="$CAR" '$1==s {print $2}')
  [[ "$state" == "device" ]] && break
  if [[ -z "$state" || "$state" == "offline" ]]; then
    # adb never replaces an existing connection, even a dead one: drop it first.
    [[ "$state" == "offline" ]] && "$ADB" disconnect "$CAR" >/dev/null 2>&1
    "$ADB" connect "$CAR" >/dev/null 2>&1
  fi
  sleep 1
done
if [[ "$state" != "device" ]]; then
  echo
  note "The car didn't accept the connection (state: ${state:-not connected})."
  case "$state" in
    unauthorized) note "The approval box on the car screen wasn't accepted in time. Re-run and tap OK on the car." ;;
    connecting|authorizing)
      note "Something at $IP answers on the ADB port but never finished the handshake."
      note "Switch Wireless ADB off and on again in the car, then re-run." ;;
    *) note "The car answered but then dropped off. Check the screen is awake, then re-run." ;;
  esac
  "$ADB" disconnect "$CAR" >/dev/null 2>&1; "$ADB" kill-server >/dev/null 2>&1
  exit 1
fi
note "Connected."
sleep "${KIT_SETTLE_SECS:-5}"   # 'device' can show a moment before adbd takes shell commands
A=("$ADB" -s "$CAR")
sh_car() { "${A[@]}" shell "$@" 2>/dev/null | tr -d '\r'; }
note "Car reports Android $(sh_car getprop ro.build.version.release), build $(sh_car getprop ro.build.display.id)"

# Exact package match. No 'grep -q': it can quit early and trip pipefail.
is_installed() { sh_car pm list packages "$1" | grep -Fx "package:$1" >/dev/null; }
car_version()  { sh_car dumpsys package "$1" | grep -o 'versionName=[^ ]*' | awk -F= 'NR==1{print $2}'; }

FAILED=()

# ---------------------------------------------------------------- 3. old kit apps
# Earlier versions of this kit installed these. None of them work or get used
# on the AU Sealion 7 (docs/adr/0004). Overdrive isn't on this list: the kit no
# longer installs it, but people who use it keep it (docs/adr/0005).
OLD_PKGS=(io.github.muntashirakon.AppManager com.aurora.store com.retroarch.aarch64
          org.jellyfin.mobile app.rvx.android.youtube app.revanced.android.gms
          com.waze)
leftovers=()
for p in "${OLD_PKGS[@]}"; do is_installed "$p" && leftovers+=("$p"); done
if [[ ${#leftovers[@]} -gt 0 ]]; then
  heading "Apps from an older version of this kit"
  for p in "${leftovers[@]}"; do note "$p"; done
  read -r -p "    Remove them from the car? [Y/n] " ans || ans=n
  if [[ ! "$ans" =~ ^[Nn] ]]; then
    for p in "${leftovers[@]}"; do
      out=$("${A[@]}" uninstall "$p" 2>&1 | tr -d '\r')
      if [[ "$out" == *Success* ]]; then note "removed $p"; else note "couldn't remove $p: $out"; FAILED+=("remove $p"); fi
    done
    if [[ " ${leftovers[*]} " == *" com.retroarch.aarch64 "* ]]; then
      sh_car rm -rf /storage/emulated/0/Download/ROMs >/dev/null; note "removed the games folder (Download/ROMs)"
    fi
  else
    note "Left them."
  fi
fi

# ---------------------------------------------------------------- 4. install
# install_app NAME APK PKG: install only if the car's copy is a different version.
install_app() {
  local name="$1" apk="$2" pkg="$3" want have out
  want=$(file_version "$apk")
  heading "$name $want"
  have=$(car_version "$pkg")
  if [[ -n "$have" && "$have" == "$want" ]]; then note "The car already has $want. Nothing to do."; return; fi
  if [[ -n "$have" ]]; then note "The car has $have: updating (settings are kept)."; else note "Not on the car yet: installing."; fi
  note "Sending $(du -h "$apk" | awk '{print $1}')B over Wi-Fi (a minute or two for the big one)..."
  out=$("${A[@]}" install -r -g "$apk" 2>&1)
  printf '%s\n' "$out" | tail -2 | sed 's/^/    /'
  if [[ "$out" == *Success* ]]; then return; fi
  FAILED+=("$name")
  case "$out" in
    *disabled*)             note "Hint: switch Wireless ADB off and on again in the car, then re-run." ;;
    *UPDATE_INCOMPATIBLE*)  note "Hint: a differently signed copy is on the car. Uninstall it in the car, then re-run." ;;
    *INSUFFICIENT_STORAGE*) note "Hint: the car's storage is full. Free some space, then re-run." ;;
    *VERSION_DOWNGRADE*)    note "Hint: the car has a newer version than this download. Nothing to do." ;;
    *"not found"*|*offline*|*"no devices"*) note "Hint: the connection dropped. Check the car is awake, then re-run." ;;
  esac
}

install_app "SmartTube" "$ST_APK" org.smarttube.stable

# ---------------------------------------------------------------- done
"$ADB" disconnect "$CAR" >/dev/null 2>&1
"$ADB" kill-server >/dev/null 2>&1
heading "Finished. Disconnected from the car."
if [[ ${#FAILED[@]} -eq 0 ]]; then
  note "SmartTube is up to date."
  note "To keep driver monitoring and other nags off: github.com/jasoisjaso/byd-nag-killer"
else
  note "These didn't work: ${FAILED[*]}"
  note "Fix the hint above and re-run; anything already up to date is skipped."
  exit 1
fi
