#!/bin/bash
# Dry-run scripts/install.sh against tests/mock-adb. No car needed.
# Builds a throwaway sandbox with the project's layout, swaps in the mock adb
# and short timeouts, then runs every scenario. The project folder is not
# touched. Run:  tests/dry-run.sh
set -u
cd "$(dirname "$0")/.." || exit 1
ROOT="$PWD"
SANDBOX="${TMPDIR:-/tmp}/byd-dry-run.$$"
mkdir -p "$SANDBOX/scripts" "$SANDBOX/tools/platform-tools" || exit 1

cp "$ROOT/scripts/install.sh" "$SANDBOX/scripts/install.sh"
cp "$ROOT/tests/mock-adb" "$SANDBOX/tools/platform-tools/adb"
chmod +x "$SANDBOX/tools/platform-tools/adb"
ln -s "$ROOT/downloads" "$SANDBOX/downloads"

# Short timeouts so the failure paths finish in seconds, not minutes.
sed -i '' -e 's/^PROBE_SECS=30/PROBE_SECS=5/' -e 's/^WAIT_SECS=90/WAIT_SECS=5/' "$SANDBOX/scripts/install.sh"
if ! grep -q '^PROBE_SECS=5' "$SANDBOX/scripts/install.sh" || ! grep -q '^WAIT_SECS=5' "$SANDBOX/scripts/install.sh"; then
  echo "harness: timeout lines not found in install.sh; update the sed above"; exit 1
fi

S="$SANDBOX/state"; O="$SANDBOX/out"
fresh() { rm -rf "$S"; mkdir -p "$S"; }
PASS=0; FAILS=0
go() { # go NAME EXPECTED_EXIT INPUT [ENV=VAL ...] -- [ARGS]
  local name="$1" want="$2" input="$3"; shift 3
  local envs=""
  while [[ $# -gt 0 && "$1" != "--" ]]; do envs="$envs $1"; shift; done
  [[ "${1:-}" == "--" ]] && shift
  local t0=$SECONDS rc
  # shellcheck disable=SC2086
  printf '%b' "$input" | env MOCK_STATE="$S" $envs /bin/bash "$SANDBOX/scripts/install.sh" "$@" > "$O.$name" 2>&1
  rc=$?
  local verdict="ok"
  if [[ $rc -ne $want ]]; then verdict="FAIL (wanted exit $want)"; FAILS=$((FAILS+1)); else PASS=$((PASS+1)); fi
  printf '%-24s exit=%-3s %3ss  %s\n' "$name" "$rc" "$((SECONDS - t0))" "$verdict"
}
# expect NAME PATTERN: the scenario's output must contain PATTERN.
expect() {
  if grep -q -E -- "$2" "$O.$1"; then PASS=$((PASS+1))
  else echo "   FAIL: $1 output lacks: $2"; FAILS=$((FAILS+1)); fi
}
# refute NAME PATTERN: the scenario's output must NOT contain PATTERN.
refute() {
  if grep -q -E -- "$2" "$O.$1"; then echo "   FAIL: $1 output contains: $2"; FAILS=$((FAILS+1))
  else PASS=$((PASS+1)); fi
}

# Fake "car": something listening on 127.0.0.1:5555 so the nc probe succeeds.
LISTENER=""
listener_on() {
  if /usr/bin/nc -z 127.0.0.1 5555 2>/dev/null; then
    echo "harness: something real is already on 127.0.0.1:5555; stop it first"; exit 1
  fi
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

echo "--- nothing on the port yet: the probe must fail fast"
fresh; go port_closed        1 '127.0.0.1\n'
       expect port_closed      "isn't listening"
fresh; go no_such_host       1 '10.255.255.1\n'
       expect no_such_host     "No answer from 10.255.255.1"

listener_on
echo "--- fake car listening on 127.0.0.1:5555"
fresh; go fresh_install      0 '127.0.0.1\nn\n'
       expect fresh_install    "on car: libbet.gb"
       go rerun_skips         0 '127.0.0.1\nn\n'
       expect rerun_skips      "Already on the car"
       go update_reinstalls   0 '127.0.0.1\nn\n' -- --update
       expect update_reinstalls "Success"
fresh; go auth_delay         0 '127.0.0.1\nn\n' MOCK_AUTH_POLLS=3
       expect auth_delay       "failed to authenticate"   # the line the script tells the owner is normal
fresh; go never_authorised   1 '127.0.0.1\n'    MOCK_AUTH_POLLS=999
       expect never_authorised "wasn't accepted in time"
fresh; go adb_refuses        1 '127.0.0.1\n'    MOCK_REFUSE=1
       expect adb_refuses      "dropped off"
# real adb ignores 'connect' while a dead connection exists; the script must disconnect first
fresh; go offline_recovers   0 '127.0.0.1\nn\n' MOCK_OFFLINE_FIRST=1
       expect offline_recovers "Connected\."
fresh; go stuck_connecting   1 '127.0.0.1\n'    MOCK_STATE_WORD=connecting MOCK_AUTH_POLLS=999
       expect stuck_connecting "never finished the handshake"
fresh; go one_install_fails  1 '127.0.0.1\nn\n' MOCK_FAIL_PKG=org.smarttube.stable MOCK_FAIL_MSG=INSTALL_FAILED_OLDER_SDK
       expect one_install_fails "These didn't work: SmartTube"
fresh; go storage_full       1 '127.0.0.1\nn\n' MOCK_FAIL_PKG=com.retroarch.aarch64 MOCK_FAIL_MSG=INSTALL_FAILED_INSUFFICIENT_STORAGE
       expect storage_full     "storage is full"
fresh; go drop_mid_run       1 '127.0.0.1\nn\n' MOCK_DROP_AFTER_INSTALLS=1
       expect drop_mid_run     "Hint: the connection dropped"
       expect drop_mid_run     "These didn't work: Aurora Store SmartTube RetroArch Jellyfin microG \(for YouTube\) YouTube \(ReVanced\) Games copy"
       expect fresh_install    "==> microG \(for YouTube\)"   # youtube.apk is built, so microG must go on first
       if [[ $(grep -n -E '==> (microG|YouTube \(ReVanced\))' "$O.fresh_install" | sed -n '1p') == *microG* ]]; then PASS=$((PASS+1))
       else echo "   FAIL: fresh_install must install microG before YouTube"; FAILS=$((FAILS+1)); fi
fresh; go push_fails         1 '127.0.0.1\nn\n' MOCK_PUSH_FAIL=1
       expect push_fails       "These didn't work: Games copy"
fresh; go appops_fails       0 '127.0.0.1\nn\n' MOCK_APPOPS_FAIL=1
       expect appops_fails     "couldn't set it"
# 'pm list packages com.aurora.store' also lists com.aurora.store.nightly; only an exact match counts
fresh; go similar_pkg_name   0 '127.0.0.1\nn\n' MOCK_PRESEED=com.aurora.store.nightly
       refute similar_pkg_name "Already on the car"
fresh; go crlf_output        0 '127.0.0.1\nn\n' MOCK_CRLF=1
       expect crlf_output      "Car reports Android 11, build DX_BYD_AUTO"
       expect crlf_output      "on car: libbet.gb"
       refute crlf_output      $'\r'
fresh; go with_overdrive     0 '127.0.0.1\n' -- --with-overdrive
       expect with_overdrive   "==> Overdrive"
fresh; go overdrive_answer_y 0 '127.0.0.1\ny\n'
       expect overdrive_answer_y "==> Overdrive"
fresh; go eof_at_prompt      1 ''
       expect eof_at_prompt    "Nothing was changed"
fresh; go bad_then_good_ip   0 'abc\n999.168.1.1\n 127.0.0.1:5555 \nn\n'
       expect bad_then_good_ip "doesn't look like an IP"
       if [[ $(grep -c "doesn't look like an IP" "$O.bad_then_good_ip") -eq 2 ]]; then PASS=$((PASS+1))
       else echo "   FAIL: bad_then_good_ip should reject both abc and 999.168.1.1"; FAILS=$((FAILS+1)); fi
fresh; go unknown_flag       2 '' -- --bogus
listener_off

echo
echo "checks passed: $PASS, failed: $FAILS"
[[ $FAILS -eq 0 ]]
