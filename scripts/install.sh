#!/bin/bash
# Install stage: run when the Mac and the car are on the same Wi-Fi and
# Wireless ADB is on (docs/in-car-checklist.md). Safe to re-run: apps that
# are already on the car are skipped unless you pass --update.
#   scripts/install.sh                  install anything missing
#   scripts/install.sh --update         reinstall/update everything (keeps app data)
#   scripts/install.sh --with-overdrive also install Overdrive without asking
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1
ROOT="$PWD"
ADB="$ROOT/tools/platform-tools/adb"
APKS="$ROOT/downloads/apks"
ROMS="$ROOT/downloads/ROMs"
CAR_ROMS_PARENT="/storage/emulated/0/Download"
PROBE_SECS=30  # how long to keep checking that something answers at the IP
WAIT_SECS=90   # how long to wait for the car to accept the connection

UPDATE=0; OVERDRIVE=ask
for arg in "$@"; do
  case "$arg" in
    --update) UPDATE=1 ;;
    --with-overdrive) OVERDRIVE=yes ;;
    *) echo "Unknown option: $arg (use --update and/or --with-overdrive)"; exit 2 ;;
  esac
done

heading() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
note()    { printf '    %s\n' "$*"; }

[[ -x "$ADB" && -d "$APKS" ]] || { echo "Run scripts/prep.sh first (at home, no car needed)."; exit 1; }
"$ADB" start-server >/dev/null 2>&1   # start it quietly so its chatter doesn't mix with ours

# 1. Car IP address
heading "Car IP address"
cat <<'EOF'
    On the car screen: Settings > Connection > Wi-Fi > tap your home network.
    The address looks like 192.168.x.x. If it isn't shown there, your router's
    app lists the car as a new device.
EOF
while true; do
  if ! read -r -p "    Car IP address: " IP; then
    echo; note "No address entered. Nothing was changed on the car."; exit 1
  fi
  IP="${IP//[[:space:]]/}"; IP="${IP%:5555}"
  if [[ "$IP" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
    # Each of the four numbers must be 0-255; a typo like 999.168.1.1 would
    # otherwise cost a 30-second wait for nothing.
    ok=1; IFS=. read -r o1 o2 o3 o4 <<<"$IP"
    for o in "$o1" "$o2" "$o3" "$o4"; do [[ $((10#$o)) -le 255 ]] || ok=0; done
    [[ $ok -eq 1 ]] && break
  fi
  note "That doesn't look like an IP address (example: 192.168.1.37). Try again."
done
CAR="$IP:5555"

# 2. Check something answers at the IP before involving adb. With a wrong IP,
# every 'adb connect' hangs for 75 seconds; nc (built into macOS) answers in 3.
heading "Looking for the car at $IP"
cat <<'EOF'
    If macOS asks whether Terminal may find devices on your local network,
    click Allow (without it the car can't be reached).
EOF
reachable=0; probe=""
SECONDS=0
while (( SECONDS < PROBE_SECS )); do
  if probe=$(/usr/bin/nc -z -v -G 3 "$IP" 5555 2>&1); then reachable=1; break; fi
  sleep 1
done
if [[ $reachable -eq 0 ]]; then
  echo
  if [[ "$probe" == *refused* ]]; then
    note "Something at $IP answered, but Wireless ADB isn't listening there."
    note "Either it's switched off on the car (redo checklist steps 1-4) or $IP is another device."
  else
    note "No answer from $IP after $PROBE_SECS seconds."
    note "Check: right IP (checklist step 5), car screen awake, Mac and car on the same Wi-Fi."
    note "A guest or isolated Wi-Fi also blocks it: use your main home Wi-Fi or your phone's hotspot for both."
    note "Also check System Settings > Privacy & Security > Local Network: Terminal must be allowed."
  fi
  note "Nothing was changed on the car."
  exit 1
fi
note "Found it."

# 3. Connect and wait for the car to authorise this Mac
heading "Connecting to $CAR"
cat <<'EOF'
    LOOK AT THE CAR SCREEN NOW.
    If an "Allow USB debugging?" box appears, tick "Always allow from this
    computer" and tap OK. (Some cars never ask; that's fine too.)
    A "failed to authenticate" line below is normal until you tap OK.
EOF
"$ADB" connect "$CAR" 2>&1 | sed 's/^/    /'
note "Waiting for the car to accept (up to $WAIT_SECS seconds)..."

state=""
SECONDS=0
while (( SECONDS < WAIT_SECS )); do
  state=$("$ADB" devices | awk -v s="$CAR" '$1==s {print $2}')
  [[ "$state" == "device" ]] && break
  if [[ -z "$state" || "$state" == "offline" ]]; then
    # adb never replaces an existing connection, even a dead "offline" one: a
    # second 'connect' just answers "already connected". Drop it first so the
    # retry really reconnects.
    [[ "$state" == "offline" ]] && "$ADB" disconnect "$CAR" >/dev/null 2>&1
    "$ADB" connect "$CAR" >/dev/null 2>&1
  fi
  sleep 1
done

if [[ "$state" != "device" ]]; then
  echo
  note "The car didn't accept the connection (state: ${state:-not connected})."
  case "$state" in
    unauthorized)
      note "The approval box on the car screen wasn't accepted in time. Re-run and tap OK on the car." ;;
    connecting|authorizing)
      note "Something at $IP answers on the ADB port but never finished the handshake."
      note "adb on this Mac has been restarted for you. Re-run the script."
      note "If it keeps happening: switch Wireless ADB off and on again (checklist steps 1-4),"
      note "and check that $IP really is the car and not another device." ;;
    *)
      note "The car answered on the ADB port but then dropped off. Check the screen is awake and re-run."
      note "If it keeps happening: switch Wireless ADB off and on again (checklist steps 1-4)." ;;
  esac
  "$ADB" disconnect "$CAR" >/dev/null 2>&1
  "$ADB" kill-server >/dev/null 2>&1   # fresh adb next run; a stale server can keep a dead connection alive
  exit 1
fi
note "Connected."
sleep 5   # 'device' can show a moment before adbd is ready for shell commands; cheap insurance against a false "dropped"
A=("$ADB" -s "$CAR")

car_release=$("${A[@]}" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')
car_build=$("${A[@]}" shell getprop ro.build.display.id 2>/dev/null | tr -d '\r')
note "Car reports Android ${car_release:-unknown}, build ${car_build:-unknown}"

# 4. Install apps. On-car installers first, so they survive a later OTA lockout.
FAILED=()

# is_installed PKG: exact package-name match. Deliberately no 'grep -q': it can
# quit before the pipe is drained and trip pipefail into a false "not installed".
is_installed() {
  "${A[@]}" shell pm list packages "$1" 2>/dev/null | tr -d '\r' | grep -Fx "package:$1" >/dev/null
}

install_app() {
  local name="$1" file="$2" pkg="$3" out
  heading "$name"
  if [[ ! -s "$APKS/$file" ]]; then
    note "$file missing. Run scripts/prep.sh at home first."; FAILED+=("$name"); return
  fi
  if [[ $UPDATE -eq 0 ]] && is_installed "$pkg"; then
    note "Already on the car, skipping."; return
  fi
  note "Sending $(du -h "$APKS/$file" | awk '{print $1}')B over Wi-Fi (the big ones take a minute or two)..."
  out=$("${A[@]}" install -r -g "$APKS/$file" 2>&1)
  printf '%s\n' "$out" | tail -3 | sed 's/^/    /'
  if [[ "$out" == *Success* ]]; then return; fi
  FAILED+=("$name")
  case "$out" in
    # "adb install be disabled": seen on a Sealion 7 (firmware 1.2.x), fixed by toggling the switch.
    *disabled*)                note "Hint: switch Wireless ADB off and on again on the car, then re-run." ;;
    *NO_MATCHING_ABIS*)        note "Hint: this APK isn't built for the car's 64-bit ARM chip." ;;
    *OLDER_SDK*)               note "Hint: this app needs a newer Android than the car's Android 11." ;;
    *UPDATE_INCOMPATIBLE*)     note "Hint: a different copy of this app is already installed. Remove it on the car, then re-run." ;;
    *INSUFFICIENT_STORAGE*)    note "Hint: the car's storage is full. Free some space on the car, then re-run." ;;
    *USER_RESTRICTED*)         note "Hint: the car's settings forbid installing apps this way. Use App Manager on the car instead." ;;
    *"safety checks"*|*VERIFICATION*) note "Hint: the car's firmware blocked sideloading. Use App Manager on the car instead." ;;
    *"not found"*|*offline*|*"no devices"*) note "Hint: the connection dropped. Check the car is awake and on Wi-Fi, then re-run." ;;
  esac
}

install_app "App Manager"  manager.apk   io.github.muntashirakon.AppManager
install_app "Aurora Store" store.apk     com.aurora.store
install_app "SmartTube"    tube.apk      org.smarttube.stable
install_app "RetroArch"    retroarch.apk com.retroarch.aarch64
install_app "Jellyfin"     jellyfin.apk  org.jellyfin.mobile

# YouTube (ReVanced build) is optional: it only exists if scripts/build-youtube.sh
# was run. microG must go on first, or the patched app can't sign in.
if [[ -s "$APKS/youtube.apk" ]]; then
  install_app "microG (for YouTube)" gmscore.apk app.revanced.android.gms
  install_app "YouTube (ReVanced)"   youtube.apk app.rvx.android.youtube
else
  heading "YouTube (ReVanced)"
  note "Not built, skipping. To add it: run scripts/build-youtube.sh at home, then re-run this."
fi

if [[ "$OVERDRIVE" == ask ]]; then
  echo
  read -r -p "    Also install Overdrive (dashcam/sentry, alpha software)? [y/N] " ans || ans=n
  [[ "$ans" =~ ^[Yy] ]] && OVERDRIVE=yes
fi
if [[ "$OVERDRIVE" == yes ]]; then
  install_app "Overdrive" overdrive.apk com.overdrive.app
  note "After first opening Overdrive: hold the volume-down button for 5 seconds to hard-reboot the screen."
fi

# 5. Let the two on-car installers install apps. Android normally grants this
# through an "Install unknown apps" settings page that the BYD head unit may
# not have. This is an app-scoped permission for these two apps only, the same
# idea as the -g flag above; nothing system-wide is changed.
heading "Allowing App Manager and Aurora Store to install apps"
for pkg in io.github.muntashirakon.AppManager com.aurora.store; do
  is_installed "$pkg" || continue
  if "${A[@]}" shell appops set "$pkg" REQUEST_INSTALL_PACKAGES allow >/dev/null 2>&1; then
    note "$pkg: allowed"
  else
    note "$pkg: couldn't set it (not fatal; the car will ask the first time you install from it)"
  fi
done

# 6. Games
heading "Copying games to $CAR_ROMS_PARENT/ROMs"
# Make sure the parent exists first: if it didn't, adb would copy the games
# into a new "Download" folder instead of creating Download/ROMs.
"${A[@]}" shell mkdir -p "$CAR_ROMS_PARENT" >/dev/null 2>&1
if "${A[@]}" push "$ROMS" "$CAR_ROMS_PARENT/" 2>&1 | tail -1 | sed 's/^/    /'; then
  "${A[@]}" shell ls "$CAR_ROMS_PARENT/ROMs" 2>&1 | tr -d '\r' | sed 's/^/    on car: /'
else
  FAILED+=("Games copy")
fi

# 7. Done
"$ADB" disconnect "$CAR" >/dev/null 2>&1
"$ADB" kill-server >/dev/null 2>&1
heading "Finished. Disconnected from the car."
if [[ ${#FAILED[@]} -eq 0 ]]; then
  note "Everything installed. Next: PART C of docs/in-car-checklist.md (on the car screen)."
else
  note "These didn't work: ${FAILED[*]}"
  note "Fix the hint above and re-run; finished apps are skipped."
  exit 1
fi
