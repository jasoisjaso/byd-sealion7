#!/bin/bash
# Dry-run kit.sh against tests/mock-adb. No car, no internet needed.
# Builds a throwaway sandbox with fake APKs, swaps in the mock adb and short
# timeouts, then runs every scenario. The project folder is not touched.
# Run:  tests/dry-run.sh
set -u
cd "$(dirname "$0")/.." || exit 1
ROOT="$PWD"
SANDBOX="${TMPDIR:-/tmp}/byd-dry-run.$$"
mkdir -p "$SANDBOX/tools/platform-tools" "$SANDBOX/downloads/apks" || exit 1

cp "$ROOT/kit.sh" "$SANDBOX/kit.sh"
cp "$ROOT/tests/mock-adb" "$SANDBOX/tools/platform-tools/adb"
chmod +x "$SANDBOX/tools/platform-tools/adb"

# Fake APKs: zips holding an AndroidManifest.xml, named like the real downloads.
mkdir -p "$SANDBOX/apk-src" && echo fake > "$SANDBOX/apk-src/AndroidManifest.xml"
(cd "$SANDBOX/apk-src" && zip -q "$SANDBOX/downloads/apks/SmartTube_stable_32.56_arm64-v8a.apk" AndroidManifest.xml)

sed -i '' -e 's/^PROBE_SECS=30/PROBE_SECS=5/' -e 's/^WAIT_SECS=90/WAIT_SECS=5/' "$SANDBOX/kit.sh"
if ! grep -q '^PROBE_SECS=5' "$SANDBOX/kit.sh" || ! grep -q '^WAIT_SECS=5' "$SANDBOX/kit.sh"; then
  echo "harness: timeout lines not found in kit.sh; update the sed above"; exit 1
fi

S="$SANDBOX/state"; O="$SANDBOX/out"
fresh() { rm -rf "$S" "$SANDBOX/downloads/car-ip"; mkdir -p "$S"; }
PASS=0; FAILS=0
go() { # go NAME EXPECTED_EXIT INPUT [ENV=VAL ...] -- [ARGS]
  local name="$1" want="$2" input="$3"; shift 3
  local envs=()
  while [[ $# -gt 0 && "$1" != "--" ]]; do envs+=("$1"); shift; done
  [[ "${1:-}" == "--" ]] && shift
  local t0=$SECONDS rc
  printf '%b' "$input" | env MOCK_STATE="$S" KIT_OFFLINE=1 KIT_SETTLE_SECS=0 ${envs[@]+"${envs[@]}"} \
    /bin/bash "$SANDBOX/kit.sh" "$@" > "$O.$name" 2>&1
  rc=$?
  local verdict="ok"
  if [[ $rc -ne $want ]]; then verdict="FAIL (wanted exit $want)"; FAILS=$((FAILS+1)); else PASS=$((PASS+1)); fi
  printf '%-24s exit=%-3s %3ss  %s\n' "$name" "$rc" "$((SECONDS - t0))" "$verdict"
}
expect() { if grep -q -E -- "$2" "$O.$1"; then PASS=$((PASS+1)); else echo "   FAIL: $1 output lacks: $2"; FAILS=$((FAILS+1)); fi; }
refute() { if grep -q -E -- "$2" "$O.$1"; then echo "   FAIL: $1 output contains: $2"; FAILS=$((FAILS+1)); else PASS=$((PASS+1)); fi; }
# car NAME FILE PATTERN: the fake car's state file must contain PATTERN.
car() { if grep -q -E -- "$3" "$S/$2" 2>/dev/null; then PASS=$((PASS+1)); else echo "   FAIL: $1: car $2 lacks: $3"; FAILS=$((FAILS+1)); fi; }
nocar() { if grep -q -E -- "$3" "$S/$2" 2>/dev/null; then echo "   FAIL: $1: car $2 has: $3"; FAILS=$((FAILS+1)); else PASS=$((PASS+1)); fi; }

LISTENER=""
listener_on() {
  if /usr/bin/nc -z 127.0.0.1 5555 2>/dev/null; then echo "harness: something real is already on 127.0.0.1:5555; stop it first"; exit 1; fi
  ( while :; do /usr/bin/nc -l 127.0.0.1 5555 </dev/null >/dev/null 2>&1 || sleep 1; done ) &
  LISTENER=$!
  for _ in 1 2 3 4 5; do /usr/bin/nc -z 127.0.0.1 5555 2>/dev/null && return; sleep 1; done
  echo "harness: listener never came up"; exit 1
}
listener_off() {
  [[ -n "$LISTENER" ]] && { kill "$LISTENER" 2>/dev/null; wait "$LISTENER" 2>/dev/null; LISTENER=""; }
  pkill -f '^/usr/bin/nc -l 127.0.0.1 5555' 2>/dev/null
}
cleanup() { listener_off; rm -rf "$SANDBOX"; }
trap cleanup EXIT

echo "--- no car needed"
fresh; go download_only      0 '' -- --download
       expect download_only    "SmartTube 32.56$"
fresh; go unknown_flag       2 '' -- --bogus
fresh; go port_closed        1 '127.0.0.1\n'
       expect port_closed      "isn't listening"
fresh; go no_such_host       1 '10.255.255.1\n'
       expect no_such_host     "No answer from 10.255.255.1"
fresh; go eof_at_prompt      1 ''
       expect eof_at_prompt    "Nothing was changed"

listener_on
echo "--- fake car listening on 127.0.0.1:5555"
fresh; go fresh_install      0 '127.0.0.1\n'
       expect fresh_install    "Not on the car yet"
       car    fresh_install    installed "^org.smarttube.stable 32.56$"
       expect fresh_install    "SmartTube is up to date"
       expect fresh_install    "byd-nag-killer"
       refute fresh_install    "Overdrive"
# second run: remembers the IP (just Enter), installs nothing
       go rerun_up_to_date   0 '\n'
       expect rerun_up_to_date "Looking for the car at 127.0.0.1"
       expect rerun_up_to_date "already has 32.56. Nothing to do"
       if [[ $(wc -l < "$S/install_log" | tr -d ' ') -eq 1 ]]; then PASS=$((PASS+1)); else echo "   FAIL: rerun installed again"; FAILS=$((FAILS+1)); fi
# an older kit's car: old SmartTube, Overdrive, every app from the old kit, Brave
fresh; go update_and_clean   0 '127.0.0.1\n\n' "MOCK_PRESEED=org.smarttube.stable=31.0 com.overdrive.app=55.2 io.github.muntashirakon.AppManager=4.0 com.aurora.store=4.6 com.retroarch.aarch64=1.21 org.jellyfin.mobile=2.6 app.rvx.android.youtube=19.47.53 app.revanced.android.gms=0.3 com.waze=5.25 com.brave.browser=1.97"
       expect update_and_clean "The car has 31.0: updating"
       for p in io.github.muntashirakon.AppManager com.aurora.store com.retroarch.aarch64 org.jellyfin.mobile app.rvx.android.youtube app.revanced.android.gms com.waze; do
         nocar update_and_clean installed "^$p "
       done
       car    update_and_clean installed "^com.brave.browser "            # Brave left alone
       car    update_and_clean installed "^com.overdrive.app 55.2$"       # Overdrive left alone, not updated
       car    update_and_clean removed_dirs "Download/ROMs"
# say no to removing old apps
fresh; go keep_old_apps      0 '127.0.0.1\nn\n' MOCK_PRESEED=com.waze=5.25
       expect keep_old_apps    "Left them"
       car    keep_old_apps    installed "^com.waze "
# a similarly named package must not count as installed
fresh; go similar_pkg_name   0 '127.0.0.1\n' MOCK_PRESEED=com.aurora.store.nightly=1
       refute similar_pkg_name "older version of this kit"
fresh; go auth_delay         0 '127.0.0.1\n' MOCK_AUTH_POLLS=3
       expect auth_delay       "failed to authenticate"
fresh; go never_authorised   1 '127.0.0.1\n' MOCK_AUTH_POLLS=999
       expect never_authorised "wasn't accepted in time"
fresh; go adb_refuses        1 '127.0.0.1\n' MOCK_REFUSE=1
       expect adb_refuses      "dropped off"
fresh; go offline_recovers   0 '127.0.0.1\n' MOCK_OFFLINE_FIRST=1
       expect offline_recovers "Connected\."
fresh; go stuck_connecting   1 '127.0.0.1\n' MOCK_STATE_WORD=connecting MOCK_AUTH_POLLS=999
       expect stuck_connecting "never finished the handshake"
fresh; go install_fails      1 '127.0.0.1\n' MOCK_FAIL_PKG=org.smarttube.stable MOCK_FAIL_MSG=INSTALL_FAILED_INSUFFICIENT_STORAGE
       expect install_fails    "These didn't work: SmartTube"
       expect install_fails    "storage is full"
fresh; go drop_mid_run       1 '127.0.0.1\n' MOCK_DROP_BEFORE_INSTALL=1
       expect drop_mid_run     "the connection dropped"
fresh; go crlf_output        0 '127.0.0.1\n' MOCK_CRLF=1
       expect crlf_output      "Car reports Android 11, build DX_BYD_AUTO"
       refute crlf_output      $'\r'
       go crlf_rerun         0 '\n' MOCK_CRLF=1
       expect crlf_rerun       "already has 32.56"
fresh; go bad_then_good_ip   0 'abc\n999.168.1.1\n 127.0.0.1:5555 \n'
       if [[ $(grep -c "doesn't look like an IP" "$O.bad_then_good_ip") -eq 2 ]]; then PASS=$((PASS+1))
       else echo "   FAIL: bad_then_good_ip should reject both abc and 999.168.1.1"; FAILS=$((FAILS+1)); fi
listener_off

echo
echo "checks passed: $PASS, failed: $FAILS"
[[ $FAILS -eq 0 ]]
